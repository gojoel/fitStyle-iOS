//
//  FitstyleApp.swift
//  fitstyle
//
//  Created by Joel Goncalves on 9/28/21.
//

import SwiftUI

@main
struct FitstyleApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject private var store = Store()
        
    var styleTransferSettings = StyleTransferSettings()
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(store)
                .environmentObject(styleTransferSettings)
        }
    }
}
