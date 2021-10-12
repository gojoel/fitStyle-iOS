//
//  ErrorView.swift
//  fitstyle
//
//  Created by Joel Goncalves on 10/17/21.
//

import Foundation
import SwiftUI
import Amplify

struct ErrorView: View {
    struct ErrorMessage {
        var title: String = "Oh no!"
        var message: String = "Looks like something went wrong. Please try again"
    }
        
    var error: Error
        
    var body: some View {
        return content
    }
    
    private var content: some View {
        let errorMessage = parseError()
        
        return GeometryReader { geometry in
            VStack(alignment: .center, spacing: 0) {
                LottieView(name: "error-cone", loopMode: .playOnce)
                    .frame(width: geometry.size.width * 75, height: geometry.size.width * 0.75)
                
                Text(errorMessage.title)
                    .foregroundColor(Constants.Theme.mainTextColor)
                    .fontWeight(.bold)
                    .font(.system(size: 35))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .frame(minWidth: 0, maxWidth: geometry.size.width * 0.75)

                Spacer()
                    .frame(height: 10)
                
                Text(errorMessage.message)
                    .foregroundColor(Constants.Theme.mainTextColor)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 20))
                    .frame(minWidth: 0, maxWidth: geometry.size.width * 0.75)

                Spacer()
                    .frame(height: 30)
            }
            .frame(maxWidth: geometry.size.width)
        }
    }
    
    private func parseError() -> ErrorMessage {
        if let storageError = error as? StorageError {
            switch storageError {
            case .unknown(_, _):
                if storageError.errorDescription.contains("\(NSURLErrorNotConnectedToInternet)") {
                    return networkMessage()
                }
            default:
                break
            }
        }
      
        switch error {
        case (let error as NSError) where error.code == NSURLErrorNotConnectedToInternet,
             (let error as NSError) where error.code == NSURLErrorNetworkConnectionLost:
            return networkMessage()
        default:
            break
        }
    
        return ErrorMessage()
    }
    
    private func networkMessage() -> ErrorMessage {
        var message = ErrorMessage()
        message.title = "Network Unavailable"
        message.message = "Please check your network connection and try again."
        return message
    }
}
