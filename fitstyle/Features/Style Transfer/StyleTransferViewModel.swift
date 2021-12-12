//
//  StyleTransferViewModel.swift
//  fitstyle
//
//  Created by Joel Goncalves on 10/7/21.
//

import Foundation
import Combine
import Alamofire
import PhotosUI

final class StyleTransferViewModel: ObservableObject {
    
    private let TRANSFER_RETRIES = 10

    private let targetSize: CGSize = CGSize(width: 1500, height: 1500)
                
    let state = PassthroughSubject<State, Never>()

    private var bag = Set<AnyCancellable>()

    private var jobId: String?
    
    deinit {
        bag.removeAll()
    }
    
    private func getPhotoData(photo: PHAsset) -> AnyPublisher<Data, Error> {
        return Future { promise in
            let requestImageOption = PHImageRequestOptions()
            requestImageOption.resizeMode = .exact
            requestImageOption.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat

            let manager = PHImageManager.default()
            let useTargetSize = photo.pixelWidth > Int(self.targetSize.width) || photo.pixelHeight > Int(self.targetSize.height)
            manager.requestImage(for: photo, targetSize: useTargetSize ? self.targetSize : PHImageManagerMaximumSize, contentMode:PHImageContentMode.default, options: requestImageOption) { (image: UIImage?, _) in

                if let image = image, let imageData = image.jpegData(compressionQuality: 0.5) {
                    promise(.success(imageData))
                    return
                }
                
                promise(.failure(FitstyleError.imageDataRetrievalFailed))
            }
        }.eraseToAnyPublisher()
    }
   
    func styleTransfer(photo: PHAsset, styledImage: PHAsset) {
        Publishers.Zip(
            getPhotoData(photo: photo),
            getPhotoData(photo: styledImage)
        )
        .flatMap { (photoData, styleData) -> AnyPublisher<StyleTransferResponse, Error> in
            return FitstyleAPI.styleTransfer(contentImage: photoData, styleImage: styleData, styleImageId: nil)
        }.sink { (completion) in
            self.handleCompletion(completion: completion)
        } receiveValue: { (response) in
            self.jobId = response.jobId
            self.getStyleTransferResult(jobId: response.jobId)
        }.store(in: &bag)
    }
    
    func styleTransfer(photo: PHAsset, styleImageId: String) {
        getPhotoData(photo: photo)
            .flatMap { (data) -> AnyPublisher<StyleTransferResponse, Error> in
                return FitstyleAPI.styleTransfer(contentImage: data, styleImage: nil, styleImageId: styleImageId)
            }.sink { (completion) in
                self.handleCompletion(completion: completion)
            } receiveValue: { (response) in
                self.jobId = response.jobId
                self.getStyleTransferResult(jobId: response.jobId)
            }.store(in: &bag)
    }
    
    func cancel() {
        if let jobId = self.jobId {
            FitstyleAPI.cancelStyleTransfer(jobId: jobId)
        }
    }
    
    private func getStyleTransferResult(jobId: String, retries: Int = 0) {
        if retries >= TRANSFER_RETRIES {
            self.state.send(.failed)
            return
        }
        
        FitstyleAPI.pollStylingStatus(jobId: jobId)
            .sink { (completion) in
                self.handleCompletion(completion: completion)
            } receiveValue: { (response) in
                if response.status == .failed || (response.status == .complete && response.requestId == nil) {
                    self.state.send(.failed)
                } else if (response.status == .incomplete) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                        self.getStyleTransferResult(jobId: jobId, retries: retries + 1)
                    }
                } else {
                    self.imageFromResult(response.requestId!)
                }
            }.store(in: &bag)
    }
    
    private func imageFromResult(_ requestId: String) {
        FitstyleAPI.styledImageFromResult(requestId: requestId)
            .sink { (completion) in
                self.handleCompletion(completion: completion)
            } receiveValue: { (styledImage) in
                self.state.send(.complete(styledImage))
            }.store(in: &bag)
        
    }
    
    private func handleCompletion(completion: Subscribers.Completion<Error>) {
        switch completion {
        case .failure( _):
            self.state.send(.failed)
        case .finished:
            break
        }
    }
}

extension StyleTransferViewModel {
    enum State {
        case failed
        case complete(StyledImage)
    }
}
