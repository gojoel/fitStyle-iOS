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
import FirebaseAnalytics

struct StyledImageView: View {
    
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>
    
    @EnvironmentObject var settings: StyleTransferSettings
    
    @EnvironmentObject private var store: Store
    
    @StateObject var viewModel: StyledImageViewModel
    
    @Binding var homeViewActive : Bool
    
    @Binding var styleListActive : Bool
    
    @State private var showPurchaseErrorAlert = false
    
    @State var purchaseError: Error? = nil
    
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
            .alert(isPresented: $showPurchaseErrorAlert) {
                let message = self.purchaseError?.localizedDescription ?? ""
                
                return Alert(title: Text("Failed to remove watermark."),
                      message: Text(message),
                      dismissButton: .cancel(Text("OK"))
                )
            }
            .navigationTitle("Styled Image")
            .onAppear {
                self.viewModel.styledImage = settings.selectedStyledImage
                self.viewModel.fetchImageUrl()
                
                if let styledImage = self.viewModel.styledImage, !styledImage.purchased, self.store.shouldFetchProducts() {
                    self.store.fetchProducts { _ in }
                }
            }
    }
    
    private var content: some View {
        switch viewModel.state {
        case .loading:
            return loadingView().eraseToAnyView()
        case .purchasing:
            return loadingView(purchasing: true).eraseToAnyView()
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
                
                if let purchased = viewModel.styledImage?.purchased, !purchased {
                    purchaseButton
                }
                
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
                
                if !purchasing {
                    purchaseButton
                        .disabled(true)
                }
                
                createButton
                    .disabled(true)
            }
            .frame(maxWidth: geometry.size.width)
            .padding(20)
        }
    }

    var shareButton: some View {
        Button(action: {
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

    var purchaseButton: some View {
        Analytics.logEvent("tapped_purchase", parameters: nil)
        
        return Button(action: {
            if store.shouldFetchProducts() {
                purchaseError = Store.StoreError.productRequestFailed
                return
            }
            
            store.purchaseProduct { (result) in
                switch result {
                case .success( _):
                        viewModel.setImagePurchased()
                    case .failure(let error):
                        self.purchaseError = error
                        self.showPurchaseErrorAlert.toggle()
                }
            }
        }) {
            HStack() {
                Image(systemName: "dollarsign.circle")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.white)
                    .frame(width: Constants.Theme.buttonIconSize, height: Constants.Theme.buttonIconSize)

                Text("Remove Watermark")
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
