//
//  TutorialTabView.swift
//  fitstyle
//
//  Created by Joel Goncalves on 11/25/21.
//

import SwiftUI

struct TutorialTabView: View {
    @Binding var selection: Int
    
    var body: some View {
        TabView(selection: $selection) {
            ForEach(tutorialPages.indices, id: \.self) { index in
                TutorialDetailsView(index: index)
            }
        }
        .tabViewStyle(PageTabViewStyle())
    }
}
