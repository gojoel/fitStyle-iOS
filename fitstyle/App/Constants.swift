//
//  Constants.swift
//  fitstyle
//
//  Created by Joel Goncalves on 10/5/21.
//

import Foundation
import SwiftUI

struct Constants {
    
    struct Config {
        static let DEFAULT_DISK_EXPIRATION_DAYS = 7
    }
    
    struct Theme {
        @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

        static let mainAppColor = Color(red: 98/255, green: 0/255, blue: 238/255)
        static let mainTextColor = Color.white
        static let buttonIconSize: CGFloat = 25.0
        static let cornerRadius: CGFloat = 10.0
        
        struct StyledButton: ButtonStyle {
            func makeBody(configuration: Configuration) -> some View {
                return configuration
                    .label
                    .foregroundColor(Constants.Theme.mainTextColor)
                    .padding()
                    .background(Constants.Theme.mainAppColor)
                    .cornerRadius(8)
                
            }
        }
        
        static func createBackButton(presentation: Binding<PresentationMode>) -> some View {
            return Button(action: {
                presentation.wrappedValue.dismiss()
            }) {
                return backButtonImage
            }
        }
        
        static var backButtonImage: some View {
            return Image(systemName: "arrow.backward")
                .aspectRatio(contentMode: .fit)
                .accentColor(.white)
                .imageScale(.large)
        }
        
        static var homeButtonImage: some View {
            return Image(systemName: "house")
                .aspectRatio(contentMode: .fit)
                .accentColor(.white)
                .imageScale(.large)
        }
        
        static func accessDeniedAlert() -> Alert {
            return Alert(title: Text("Photo Access"),
                  message: Text("Access to your photos is necessary so you can choose a photo for styling. You can provide access from the app settings > Photos"),
                primaryButton: .default (Text("Open Settings")) {
                    launchPrivacySettings()
                },
                secondaryButton: .cancel()
            )
        }
        
        private static func launchPrivacySettings() {
            guard let url = URL(string: UIApplication.openSettingsURLString),
                UIApplication.shared.canOpenURL(url) else {
                    assertionFailure("Not able to open App privacy settings")
                    return
            }

            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    struct Aws {
        static let BUCKET_PRIVATE_PREFIX = "private/"
        static let BUCKET_PUBLIC_PREFIX = "public/"
        static let BUCKET_REQUESTS = "requests/"
        static let STYLED_IMAGE = "styled.jpg"
        private static let DEV_BUCKET = "foldedai-fitstyle-dev"
        private static let PROD_BUCKET = "foldedai-fitstyle"
        
        static func buildStyledKey(userId: String, requestId: String) -> String {
            return "\(BUCKET_PRIVATE_PREFIX)\(userId)/\(BUCKET_REQUESTS)\(requestId)/\(STYLED_IMAGE)"
        }
        
        static var bucket: String {
            return isDebug ? DEV_BUCKET : PROD_BUCKET
        }
    }
    
    static let version: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    static let build: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String

    static var isDebug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
}
