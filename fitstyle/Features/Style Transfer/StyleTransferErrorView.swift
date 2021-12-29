//
//  StyleTransferErrorView.swift
//  fitstyle
//
//  Created by Joel Goncalves on 10/8/21.
//

import Foundation
import SwiftUI
import PhotosUI

struct StyleTransferErrorView: View {
    
    @Binding var popToStyleList : Bool
    
    @Environment(\.presentationMode) private var mode: Binding<PresentationMode>

    var body: some View {
        content
            .navigationBarBackButtonHidden(true)
            .navigationBarHidden(true)
            .onAppear(perform: {
                AnalyticsManager.logScreen(screenName: "\(StyleTransferErrorView.self)", screenClass: "\(StyleTransferErrorView.self)")
            })
    }
    
    private var content: some View {
        return GeometryReader { geometry in
            VStack(alignment: .center, spacing: 0) {
                LottieView(name: "error-cone", loopMode: .playOnce)
                    .frame(width: geometry.size.width * 75, height: geometry.size.width * 0.75)
                
                Text("Oh no!")
                    .foregroundColor(Constants.Theme.mainTextColor)
                    .fontWeight(.bold)
                    .font(.system(size: 35))
                    .frame(minWidth: 0, maxWidth: geometry.size.width * 0.75)

                Spacer()
                    .frame(height: 10)
                
                Text("Sorry, we were unable to process your request at this time.")
                    .foregroundColor(Constants.Theme.mainTextColor)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 20))
                    .frame(minWidth: 0, maxWidth: geometry.size.width * 0.75)

                Spacer()
                    .frame(height: 30)
                
                Button( action : {
                    self.mode.wrappedValue.dismiss()
                }) {
                    HStack() {
                        Image(systemName: "arrow.backward")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.white)
                            .frame(width: Constants.Theme.buttonIconSize, height: Constants.Theme.buttonIconSize)

                        Text("Try Again")
                            .fontWeight(.semibold)
                            .frame(minWidth: 0, maxWidth: geometry.size.width * 0.75)
                    }
                }.buttonStyle(Constants.Theme.StyledButton())
                
                Spacer()
                    .frame(height: 20)
                
                Button(action: {
                    self.popToStyleList = false
                }) {
                    HStack() {
                        Image(systemName: "arrow.counterclockwise")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.white)
                            .frame(width: Constants.Theme.buttonIconSize, height: Constants.Theme.buttonIconSize)

                        Text("Start Over")
                            .fontWeight(.semibold)
                            .frame(minWidth: 0, maxWidth: geometry.size.width * 0.75)
                    }
                }.buttonStyle(Constants.Theme.StyledButton())
            }
            .frame(maxWidth: geometry.size.width)
        }
    }
}
    
