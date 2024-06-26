//
//  StyledImageView.swift
//  fitstyle
//
//  Created by Joel Goncalves on 10/10/21.
//

import Foundation
import SwiftUI
import PhotosUI
import Kingfisher
import Combine

struct StyledImageView: View {
    
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>
    
    @EnvironmentObject var settings: StyleTransferSettings
        
    @StateObject var viewModel: StyledImageViewModel
    
    @Binding var homeViewActive : Bool
    
    @Binding var styleListActive : Bool
            
    var navSourceStyleTransfer = true
        
    var body: some View {
        content
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(leading:  Button(action: {
                if navSourceStyleTransfer {
                    self.homeViewActive = false
                } else {
                    presentationMode.wrappedValue.dismiss()
                }
            }) {
                Constants.Theme.backButtonImage
            })
            .navigationTitle("Styled Image")
            .onAppear {
                AnalyticsManager.logScreen(screenName: "\(StyledImageView.self)", screenClass: "\(StyledImageView.self)")
                
                self.viewModel.styledImage = settings.selectedStyledImage
                self.viewModel.fetchImageUrl()
            }
    }
    
    private var content: some View {
        switch viewModel.state {
        case .loading:
            return loadingView().eraseToAnyView()
        case .loaded(let image):
            return imageView(image: image).eraseToAnyView()
        case .error(let error):
            return ErrorView(error: error).eraseToAnyView()
        }
    }
    
    private func imageView(image: KFCrossPlatformImage) -> some View {
        return GeometryReader { geometry in
            VStack() {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(0.8, contentMode: .fit)
                    .frame(minWidth: 0, maxWidth: geometry.size.width)
                    .cornerRadius(Constants.Theme.cornerRadius)
                    .shadow(color: Color.primary.opacity(0.3), radius: 1)

                Spacer()
                    .frame(height: 25)

                shareButton
                
                createButton
            }
            .frame(maxWidth: geometry.size.width)
            .padding(20)
        }
    }
    
    private func loadingView(purchasing: Bool = false) -> some View {
        return GeometryReader { geometry in
            VStack {
                ZStack(alignment: .center) {
                    CardPlaceholderView(showSpinner: !purchasing, style: .large)
                        .aspectRatio(0.8, contentMode: .fit)
                        .frame(minWidth: 0, maxWidth: .infinity)
                    
                    VStack(alignment: .center) {
                        if purchasing {
                            Spinner(isAnimating: true, style: .large)

                            Text("Removing watermark...")
                                .foregroundColor(Constants.Theme.mainTextColor)
                                .fontWeight(.semibold)
                                .multilineTextAlignment(.center)
                                .font(.system(size: 16))
                        }
                    }
                }
                .frame(minWidth: 0, maxWidth: geometry.size.width)
                .aspectRatio(0.8, contentMode: .fit)

                Spacer()
                    .frame(height: 25)

                shareButton
                    .disabled(true)
                
                createButton
                    .disabled(true)
            }
            .frame(maxWidth: geometry.size.width)
            .padding(20)
        }
    }

    var shareButton: some View {
        Button(action: {
            AnalyticsManager.logShareButtonTapped()
            actionSheet()
        }) {
            HStack() {
                Image(systemName: "square.and.arrow.up")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.white)
                    .frame(width: Constants.Theme.buttonIconSize, height: Constants.Theme.buttonIconSize)

                Text("Share")
                    .fontWeight(.semibold)
                    .frame(minWidth: 0, maxWidth: .infinity)
            }
        }
        .buttonStyle(Constants.Theme.StyledButton())
    }

    var createButton: some View {
        if !navSourceStyleTransfer { return EmptyView() .eraseToAnyView() }
        
        return Button(action: {
            self.styleListActive = false
        }) {
            HStack() {
                Image(systemName: "arrow.backward")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.white)
                    .frame(width: Constants.Theme.buttonIconSize, height: Constants.Theme.buttonIconSize)

                Text("Create Another")
                    .fontWeight(.semibold)
                    .frame(minWidth: 0, maxWidth: .infinity)
            }
        }
        .buttonStyle(Constants.Theme.StyledButton())
        .eraseToAnyView()
    }

    func actionSheet() {
        var cancellable: AnyCancellable?
        cancellable = self.viewModel.current
            .sink(receiveValue: { image in
                if let image = image {
                    let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
                    UIApplication.shared.windows.first?.rootViewController?.present(activityVC, animated: true, completion: nil)
                }
                cancellable?.cancel()
        })
    }
}
