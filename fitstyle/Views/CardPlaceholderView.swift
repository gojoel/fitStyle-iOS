//
//  CardPlaceholderView.swift
//  fitstyle
//
//  Created by Joel Goncalves on 10/19/21.
//

import SwiftUI

struct CardPlaceholderView: View {
    let showSpinner: Bool
    var style: UIActivityIndicatorView.Style = .medium

    
    var body: some View {
        ZStack(alignment: .center) {
            Color.white.opacity(0.09)
                .cornerRadius(Constants.Theme.cornerRadius)

            Color.white.opacity(0.09)
                .cornerRadius(Constants.Theme.cornerRadius)
            
            Spinner(isAnimating: self.showSpinner, style: style).eraseToAnyView()
        }
    }
}
