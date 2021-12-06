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
    
    @AppStorage("completed_tutorial") private var completedTutorial = false
        
    var styleTransferSettings = StyleTransferSettings()
    
    var body: some Scene {
        WindowGroup {
            if completedTutorial {
                HomeView()
                    .environmentObject(store)
                    .environmentObject(styleTransferSettings)
            } else {
                TutorialView()
            }
        }
    }
}
