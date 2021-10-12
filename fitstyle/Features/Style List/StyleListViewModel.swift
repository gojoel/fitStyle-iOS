//
//  StyleListViewModel.swift
//  fitstyle
//
//  Created by Joel Goncalves on 10/3/21.
//

import Foundation
import Combine
import Amplify

final class StyleListViewModel: ObservableObject {
    
    @Published private(set) var state = State.loading
    
    private var styles: [Style] = []
    
    private var bag = Set<AnyCancellable>()
    
    deinit {
        bag.removeAll()
    }
    
    func loadStyleImages() {
        FitstyleAPI.styles()
            .receive(on: RunLoop.main)
            .sink { (completion) in
                switch completion {
                case .failure(let error):
                    self.state = .error(error)
                case .finished:
                    break
                }
            } receiveValue: { (styles) in
                self.styles = styles
                self.state = .loaded(styles)
            }.store(in: &bag)
    }
    
    func style(position: Int) -> Style {
        return styles[position]
    }
}

extension StyleListViewModel {
    enum State {
        case loading
        case loaded([Style])
        case error(Error)
    }
}
