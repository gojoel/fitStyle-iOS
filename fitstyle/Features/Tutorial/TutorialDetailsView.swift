//
//  TutorialDetailsView.swift
//  fitstyle
//
//  Created by Joel Goncalves on 11/25/21.
//

import SwiftUI

struct TutorialDetailsView: View {
    let index: Int
    
    var body: some View {
        let page = tutorialPages[index]
        
        GeometryReader { geometry in
            VStack(spacing: 10) {
                
                Text(page.title)
                    .font(.largeTitle)
                    .bold()
                
                Text(page.details)
                    .font(.system(size: 20.0))
                    .multilineTextAlignment(.center)
                    .padding()
                
                if !page.image.isEmpty {
                    ZStack {
                        Image(page.image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                    .frame(height: geometry.size.height * 0.65)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    
                    Spacer()
                        .frame(height: 10)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .foregroundColor(.white)
    }
}
