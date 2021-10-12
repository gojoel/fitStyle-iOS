//
//  StyledImagesViewModel.swift
//  fitstyle
//
//  Created by Joel Goncalves on 10/11/21.
//

import Foundation
import Combine
import Amplify

final class StyledImagesViewModel: ObservableObject {

    @Published private(set) var state = State.loading
    
    private var bag = Set<AnyCancellable>()
        
    deinit {
        bag.removeAll()
    }
    
    func loadStyledImages() {
        FitstyleAPI.fetchStyledImages()
            .flatMap { (items) -> Publishers.Sequence<[StyledImage], Never> in
                items.publisher
            }
            .flatMap { (item) -> AnyPublisher<StyledImage, Error> in
                return FitstyleAPI.generateStyledImageUrl(key: item.key)
                    .map { (url) -> StyledImage in
                        let styledImage = StyledImage(key: item.key, purchased: item.purchased, url: url)
                        return styledImage
                    }
                    .eraseToAnyPublisher()
            }
            .collect()
            .eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .sink { (completion) in
                switch completion {
                case .failure(let error):
                    self.state = .error(error)
                case .finished:
                    break
                }
            } receiveValue: { (styledImages) in
                self.state = .loaded(styledImages)
            }.store(in: &bag)
    }
}

extension StyledImagesViewModel {
    enum State {
        case loading
        case loaded([StyledImage])
        case error(Error)
    }
}

