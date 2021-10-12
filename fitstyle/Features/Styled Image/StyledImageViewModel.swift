//
//  StyledImageViewModel.swift
//  fitstyle
//
//  Created by Joel Goncalves on 10/10/21.
//

import Foundation
import Combine
import Amplify
import Kingfisher

final class StyledImageViewModel: ObservableObject {
    
    @Published private(set) var state: State = .loading
            
    var styledImage: StyledImage?
    
    var current = CurrentValueSubject<KFCrossPlatformImage?, Never>(nil)

    private var bag = Set<AnyCancellable>()
    
    deinit {
        bag.removeAll()
    }
    
    func fetchImageUrl() {
        guard let styledImage = styledImage else {
            return
        }
        
        FitstyleAPI.generateStyledImageUrl(key: styledImage.key)
            .flatMap({ (url) -> AnyPublisher<KFCrossPlatformImage, Error> in
                return self.retrieveStyledImage(styledImage: styledImage, url: url)
            })
            .receive(on: DispatchQueue.main)
            .sink { (completion) in
                switch completion {
                case .failure(let error):
                    self.state = .error(error)
                case .finished:
                    break
                }
            } receiveValue: { (image) in
                self.state = .loaded(image)
                self.current.send(image)
            }
            .store(in: &bag)
    }
    
    func retrieveStyledImage(styledImage: StyledImage, url: URL) -> AnyPublisher<KFCrossPlatformImage, Error> {
        return Future { promise in
            let cacheKey = CacheManager.styledImageCacheKey(image: styledImage)
            let resource = ImageResource(downloadURL: url, cacheKey: cacheKey)
            
            KingfisherManager.shared.retrieveImage(with: resource, options: nil, progressBlock: nil) { result in
                switch result {
                case .success(let value):
                    promise(.success(value.image))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

extension StyledImageViewModel {
    enum State {
        case loading
        case loaded(KFCrossPlatformImage)
        case error(Error)
    }
}
