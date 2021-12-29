//
//  StyleTransferView.swift
//  fitstyle
//
//  Created by Joel Goncalves on 10/7/21.
//

import Combine
import SwiftUI
import Lottie
import PhotosUI
import Kingfisher

struct StyleTransferView: View {
    
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>
    
    @EnvironmentObject var settings: StyleTransferSettings

    @ObservedObject var viewModel: StyleTransferViewModel
    
    @State private var showStyledImage = false
    
    @State private var showErrorView = false
    
    @State private var showWarningAlert = false
    
    @State private var cancellable: AnyCancellable? = nil
    
    @State private var transferStarted = false
        
    @Binding var homeViewActive : Bool

    @Binding var styleListActive : Bool
    
    var backButton: some View {
        Button(action: {
            self.showWarningAlert = true
        }) {
            return Constants.Theme.backButtonImage
        }
    }
    
    var body: some View {
        DispatchQueue.main.async {
            if self.cancellable == nil {
                self.cancellable = viewModel.state.sink { (state) in
                    self.transferStarted = false
                    switch state {
                    case .failed:
                        self.showErrorView = true
                    case .complete(let styledImage):
                        self.settings.clear()
                        self.settings.selectedStyledImage = styledImage
                        self.showStyledImage = true
                    }
                }
            }
        }
        
        return content
            .navigationTitle("")
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(leading: backButton)
            .alert(isPresented: $showWarningAlert) {
                Alert(title: Text("Are you sure?"),
                      message: Text("Navigating back will cancel the current request."),
                    primaryButton: .default (Text("Yes, cancel")) {
                        self.cancelTransfer()
                    },
                    secondaryButton: .cancel(Text("No, continue"))
                )
            }
            .onAppear {
                AnalyticsManager.logScreen(screenName: "\(StyleTransferView.self)", screenClass: "\(StyleTransferView.self)")
                
                startTransfer()
            }
    }
    
    private var content: some View {
        return ZStack {
            loadingView.eraseToAnyView()
            
            NavigationLink(
                destination: StyleTransferErrorView(popToStyleList: self.$styleListActive),
                isActive: self.$showErrorView,
                label: { EmptyView() })
                .isDetailLink(false)
            
            NavigationLink(destination: StyledImageView(viewModel: StyledImageViewModel(), homeViewActive: self.$homeViewActive, styleListActive: self.$styleListActive),
                           isActive: $showStyledImage,
                           label: { EmptyView() })
                .isDetailLink(false)
        }
    }
    
    private func photoView(_ imageSize: CGFloat) -> some View {

        let halfImageSize = imageSize / 2
        
        guard let photo = settings.selectedPhoto else {
            return EmptyView().eraseToAnyView()
        }
        
        return Image(uiImage: getAssetThumbnail(asset: photo, size: imageSize))
            .resizable()
            .aspectRatio(1, contentMode: .fit)
            .frame(minWidth: 0, maxWidth: imageSize)
            .cornerRadius(Constants.Theme.cornerRadius)
            .offset(x: -(halfImageSize / 2), y: -(halfImageSize / 2))
            .overlay(
                RoundedRectangle(cornerRadius: Constants.Theme.cornerRadius)
                    .stroke(Color.white, lineWidth: 4)
                    .offset(x: -(halfImageSize / 2), y: -(halfImageSize / 2))
            )
            .eraseToAnyView()
    }
    
    private func styleView(_ imageSize: CGFloat) -> some View {

        let halfImageSize = imageSize / 2
        
        if let customStylePhoto = settings.customStylePhoto {
            return Image(uiImage: getAssetThumbnail(asset: customStylePhoto, size: imageSize))
                .resizable()
                .aspectRatio(1, contentMode: .fit)
                .frame(minWidth: 0, maxWidth: imageSize)
                .cornerRadius(Constants.Theme.cornerRadius)
                .offset(x: halfImageSize / 2, y: halfImageSize / 2)
                .overlay(
                    RoundedRectangle(cornerRadius: Constants.Theme.cornerRadius)
                        .stroke(Color.white, lineWidth: 4)
                        .offset(x: halfImageSize / 2, y: halfImageSize / 2)
                )
                .eraseToAnyView()
        }
        
        if let style = settings.selectedStyle, let url = style.url {
            let imageResource = ImageResource(downloadURL: url, cacheKey: style.key)
            return KFImage
                .resource(imageResource)
                .diskCacheExpiration(.days(Constants.Config.DEFAULT_DISK_EXPIRATION_DAYS))
                .resizable()
                .aspectRatio(1, contentMode: .fit)
                .frame(minWidth: 0, maxWidth: imageSize)
                .cornerRadius(Constants.Theme.cornerRadius)
                .shadow(color: Color.primary.opacity(0.3), radius: 1)
                .offset(x: halfImageSize / 2, y: halfImageSize / 2)
                .overlay(
                    RoundedRectangle(cornerRadius: Constants.Theme.cornerRadius)
                        .stroke(Color.white, lineWidth: 4)
                        .offset(x: halfImageSize / 2, y: halfImageSize / 2)
                )
                .eraseToAnyView()
        }
        
        return EmptyView().eraseToAnyView()
    }
    
    private var loadingView: some View {
        return GeometryReader { geometry in
            VStack (alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/, spacing: 25) {
                
                Text("Almost done!")
                    .foregroundColor(Constants.Theme.mainTextColor)
                    .fontWeight(.bold)
                    .font(.largeTitle)
                
                Text("Applying the style to your photo.\nThis will only take a few seconds.")
                    .foregroundColor(Constants.Theme.mainTextColor)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 18))
                
                Spacer()
                    .frame(height: 50)
                
                ZStack(alignment: .center) {
                    let imageSize: CGFloat = geometry.size.width / 2 - 16
                    
                    photoView(imageSize)
                    styleView(imageSize)
                }
                
                Spacer()
                    .frame(height: 50)
                
                ProgressView("Please wait...")
            }
            .padding(16.0)
            .frame(maxWidth: geometry.size.width)
        }
    }
    
     func startTransfer() {
        if self.transferStarted { return }
        
        guard let photo = settings.selectedPhoto else { return }
        
        if let customStyle = settings.customStylePhoto {
            self.viewModel.styleTransfer(photo: photo, styledImage: customStyle)
        } else {
            self.viewModel.styleTransfer(photo: photo, styleImageId: self.settings.selectedStyle?.imageName() ?? "")
        }
        
        self.transferStarted = true
    }
    
    func cancelTransfer() {
        self.viewModel.cancel()
        presentationMode.wrappedValue.dismiss()
    }
    
    func getAssetThumbnail(asset: PHAsset, size: CGFloat) -> UIImage {
        let manager = PHImageManager.default()
        let option = PHImageRequestOptions()
        var thumbnail = UIImage()
        option.isSynchronous = true
        manager.requestImage(for: asset, targetSize: CGSize(width: size, height: size), contentMode: .aspectFit, options: option, resultHandler: {(result, info) -> Void in
            thumbnail = result!
        })
        
        return thumbnail
    }
}
