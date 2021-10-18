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
                
    let state = PassthroughSubject<State, Never>()

    private var bag = Set<AnyCancellable>()

    private var jobId: String?
    
    deinit {
        bag.removeAll()
    }
    
    private func getPhotoData(photo: PHAsset) -> AnyPublisher<Data, Error> {
        return Future { promise in
            let requestImageOption = PHImageRequestOptions()
            requestImageOption.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat

            let manager = PHImageManager.default()
            manager.requestImage(for: photo, targetSize: PHImageManagerMaximumSize, contentMode:PHImageContentMode.default, options: requestImageOption) { (image: UIImage?, _) in
                if let image = image, let imageData = image.jpegData(compressionQuality: 0.7) {
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
    
    private func getStyleTransferResult(jobId: String) {
        FitstyleAPI.pollStylingStatus(jobId: jobId)
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
