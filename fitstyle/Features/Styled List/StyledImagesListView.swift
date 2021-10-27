//
//  StyledImagesListView.swift
//  fitstyle
//
//  Created by Joel Goncalves on 10/11/21.
//

import Combine
import SwiftUI
import Amplify
import Kingfisher

struct StyledImagesListView: View {
    
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>
    
    @EnvironmentObject var settings: StyleTransferSettings
    
    @ObservedObject var viewModel: StyledImagesViewModel
    
    @State private var isActive : Bool = false
    
    @Binding var homeViewActive : Bool
            
    static let gridViewSpacing: CGFloat = 10
    
    var body: some View {
        content
        .navigationTitle("My Images")
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading:  Button(action: {
            self.homeViewActive = false
        }) {
            Constants.Theme.backButtonImage
        })
        .onAppear { self.viewModel.loadStyledImages() }
        
        NavigationLink(
            destination: StyledImageView(viewModel: StyledImageViewModel(),
                                         homeViewActive: self.$homeViewActive,
                                         styleListActive: .constant(false),
                                         navSourceStyleTransfer: false),
            isActive: self.$isActive,
            label: { EmptyView() }
        ).isDetailLink(false)
    }
    
    private var content: some View {
          switch viewModel.state {
          case .loading:
            return Spinner(isAnimating: true, style: .large).eraseToAnyView()
          case .error(let error):
            return ErrorView(error: error).eraseToAnyView()
          case .loaded(let images):
            if images.isEmpty {
                return emptyView().eraseToAnyView()
            }
            
            return grid(of: images).eraseToAnyView()
          }
    }
    
    private func grid(of images: [StyledImage]) -> some View {
        let gridLayout: [GridItem] = Array(repeating: .init(.flexible()), count: 2)
                
        return GeometryReader { geometry in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: gridLayout, alignment: .center, spacing: StyledImagesListView.gridViewSpacing) {
                    ForEach(images, id: \.self) { image in
                        StyledView(image: image, size: geometry.size.width)
                            .onTapGesture {
                                self.settings.selectedStyledImage = image
                                self.isActive = true
                            }
                    }
                }
                .padding(.all, StyleListView.gridViewSpacing)
            }
        }
    }
    
    private func emptyView() -> some View {
        return GeometryReader { geometry in
            
            VStack(alignment:.center, spacing: 25.0) {
                
                Spacer()
                    .frame(height: 25.0)
                
                LottieView(name: "empty-box", loopMode: .loop)
                    .frame(width: geometry.size.width * 0.75, height: geometry.size.width * 0.75)
                
                Text("Nothing Yet!")
                    .foregroundColor(Constants.Theme.mainTextColor)
                    .fontWeight(.bold)
                    .font(.largeTitle)
                
                Text("Your styled images will appear here once created.")
                    .foregroundColor(Constants.Theme.mainTextColor)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 18))
                
                NavigationLink(
                    destination: StyleListView(viewModel: StyleListViewModel(), homeViewActive: self.$homeViewActive, navSourceHome: false)
                ) {
                    HStack() {
                        Image(systemName: "paintbrush.pointed")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.white)
                            .frame(width: Constants.Theme.buttonIconSize, height: Constants.Theme.buttonIconSize)

                        Text("Style an Image")
                            .fontWeight(.semibold)
                            .frame(minWidth: 0, maxWidth: geometry.size.width * 0.75)
                    }
                }
                .isDetailLink(false)
                .buttonStyle(Constants.Theme.StyledButton())
            }
            .padding(16)
            .frame(maxWidth: geometry.size.width)
        }
    }
}

struct StyledView: View {
    let image: StyledImage
    let size: CGFloat
    
    var body: some View {
        guard let url = image.url else {
            return EmptyView().eraseToAnyView()
        }
        
        let cacheKey = CacheManager.styledImageCacheKey(image: image)
        let imageResource = ImageResource(downloadURL: url, cacheKey: cacheKey)
        
        return KFImage
            .resource(imageResource)
            .placeholder { CardPlaceholderView() }
            .diskCacheExpiration(.days(Constants.Config.DEFAULT_DISK_EXPIRATION_DAYS))
            .resizable()
            .aspectRatio(1, contentMode: .fit)
            .frame(minWidth: 0, maxWidth: size - StyleListView.gridViewSpacing)
            .cornerRadius(Constants.Theme.cornerRadius)
            .shadow(color: Color.primary.opacity(0.3), radius: 1)
            .eraseToAnyView()
    }
}
