//
//  PhotoSelectionView.swift
//  fitstyle
//
//  Created by Joel Goncalves on 10/6/21.
//

import Combine
import SwiftUI
import Lottie
import PhotosUI

struct PhotoSelectionView: View {
        
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>
    
    @EnvironmentObject var settings: StyleTransferSettings
    
    @ObservedObject var viewModel: PhotoSelectionViewModel
        
    @State private var showAccessAlert = false
    
    @State private var showPhotoPicker: Bool = false

    @State private var photoSelected: Bool = false
        
    @State var styleTransferView: StyleTransferView? = nil
    
    @Binding var homeViewActive : Bool

    @Binding var styleListActive : Bool
    
    var body: some View {
        content
        .navigationTitle("Upload a photo")
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: Constants.Theme.createBackButton(presentation: self.presentationMode))
        .alert(isPresented: $showAccessAlert) {
            Constants.Theme.accessDeniedAlert()
        }
        .sheet(isPresented: $showPhotoPicker) {
            let configuration = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
            PhotoPicker(configuration: configuration, isPresented: $showPhotoPicker) { (result) -> () in
                if let result = result {
                    self.settings.selectedPhoto = result
                    self.styleTransferView = StyleTransferView(viewModel: StyleTransferViewModel(), homeViewActive: self.$homeViewActive, styleListActive: self.$styleListActive)
                    self.photoSelected.toggle()
                }
            }
        }
        
        NavigationLink(destination: styleTransferView,
                       isActive: $photoSelected,
                       label: { EmptyView() })
            .isDetailLink(false)
    }
    
    private var content: some View {
        return GeometryReader { geometry in
            VStack (alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/, spacing: 50) {
                LottieView(name: "camera", loopMode: .playOnce)
                    .frame(width: geometry.size.width * 0.50, height: geometry.size.width * 0.50)
                
                Text("Choose a photo from your library that you'd like to style")
                    .foregroundColor(Constants.Theme.mainTextColor)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 18))
                
                Button(action: {
                    requestAccess()
                }) {
                    Text("Upload Photo")
                }
                .buttonStyle(Constants.Theme.StyledButton())
                
            }
            .padding(20.0)
            .frame(
                maxWidth: geometry.size.width,
                maxHeight: geometry.size.height
            )
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
    
    func launchPrivacySettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString),
            UIApplication.shared.canOpenURL(url) else {
                assertionFailure("Not able to open App privacy settings")
                return
        }

        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}
