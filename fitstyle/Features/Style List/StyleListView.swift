//
//  StyleListView.swift
//  fitstyle
//
//  Created by Joel Goncalves on 10/3/21.
//

import Combine
import SwiftUI
import Amplify
import Kingfisher
import PhotosUI

struct StyleListView: View {
    
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>
    
    @EnvironmentObject var settings: StyleTransferSettings
    
    @StateObject var viewModel: StyleListViewModel
    
    @Binding var homeViewActive : Bool
    
    @State var isActive : Bool = false
    
    @State private var showAccessAlert = false

    @State private var showPhotoPicker: Bool = false
    
    var navSourceHome: Bool = true
        
    static let gridViewSpacing: CGFloat = 10
    
    var body: some View {
        content
        .navigationTitle("Select a style")
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading:  Button(action: {
            if navSourceHome {
                self.homeViewActive = false
            } else {
                presentationMode.wrappedValue.dismiss()
            }
        }) {
            Constants.Theme.backButtonImage
        })
        .sheet(isPresented: $showPhotoPicker) {
                let configuration = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
                PhotoPicker(configuration: configuration, isPresented: $showPhotoPicker) { (result) -> () in
                    if let result = result {
                        self.settings.customStylePhoto = result
                        self.isActive = true
                    }
                }
            }
        .alert(isPresented: $showAccessAlert) {
            Constants.Theme.accessDeniedAlert()
        }
        .onAppear { self.viewModel.loadStyleImages() }
        
        NavigationLink(
            destination: PhotoSelectionView(viewModel: PhotoSelectionViewModel(), homeViewActive: self.$homeViewActive, styleListActive: self.$isActive),
            isActive: self.$isActive,
            label: { EmptyView().eraseToAnyView() }
        )
        .isDetailLink(false)
        .eraseToAnyView()
    }
    
    private var content: some View {
          switch viewModel.state {
          case .loading:
            return Spinner(isAnimating: true, style: .large).eraseToAnyView()
          case .error(let error):
            return ErrorView(error: error).eraseToAnyView()
          case .loaded(let styles):
            return grid(of: styles).eraseToAnyView()
          }
    }
    
    private func grid(of styles: [Style]) -> some View {
        let gridLayout: [GridItem] = Array(repeating: .init(.flexible()), count: 2)
        
        return GeometryReader { geometry in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: gridLayout, alignment: .center, spacing: StyleListView.gridViewSpacing) {
                    
                    Button {
                        self.requestAccess()
                    } label: {
                        UploadStyleView(size: geometry.size.width)
                    }

                    ForEach(styles) { style in
                        StyleView(style: style, size: geometry.size.width)
                            .onTapGesture {
                                self.settings.selectedStyle = style
                                self.isActive = true
                        }
                    }
                }
                .padding(.all, StyleListView.gridViewSpacing)
            }
        }
    }
    
    
    private func requestAccess() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { (status) in
            DispatchQueue.main.async {
                showUI(for: status)
            }
        }
    }
    
    func showUI(for status: PHAuthorizationStatus) {
        switch status {
        case .authorized, .limited:
            self.showPhotoPicker.toggle()
        default:
            self.showAccessAlert.toggle()
            break
        }
    }
}

struct StyleView: View {
    let style: Style
    let size: CGFloat
    
    var body: some View {
        guard let url = style.url else {
            return EmptyView()
                .eraseToAnyView()
        }
        
        let imageResource = ImageResource(downloadURL: url, cacheKey: style.key)
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

struct UploadStyleView: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Constants.Theme.cornerRadius, style: .continuous)
                .fill(Constants.Theme.mainAppColor)
            
            VStack {
                Image(systemName: "square.and.arrow.up")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.white)
                    .frame(width: 30.0, height: 30.0)

                Spacer()
                    .frame(height: 15)
                
                Text("Upload your own style")
                    .foregroundColor(Constants.Theme.mainTextColor)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 18))
            }
            .padding(16.0)
        }
        .frame(minWidth: 0, maxWidth: size - 10)
        .aspectRatio(1, contentMode: .fit)
    }
}

