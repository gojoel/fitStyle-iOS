//
//  AppDelegate.swift
//  fitstyle
//
//  Created by Joel Goncalves on 10/5/21.
//

import UIKit
import Amplify
import AWSCognitoAuthPlugin
import AWSS3StoragePlugin
import AWSPluginsCore

class AppDelegate: NSObject, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        do {
            Amplify.Logging.logLevel = .info
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.add(plugin: AWSS3StoragePlugin())
            try Amplify.configure()
            
            self.authenticateUser()
        } catch {
            //TODO: log error
        }
        
        return true
    }
    
    private func authenticateUser() {
        Amplify.Auth.fetchAuthSession { result in
            do {
                let session = try result.get()
                
                 if let identityProvider = session as? AuthCognitoIdentityProvider {
                    let identityId = try identityProvider.getIdentityId().get()
                    print("Authenticated user: \(identityId)")
                 }
            } catch {
                // TODO: log error
                print("Fetch auth session failed with error - \(error)")
            }
        }
    }
}
