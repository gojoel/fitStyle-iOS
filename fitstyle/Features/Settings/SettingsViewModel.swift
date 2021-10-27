//
//  SettingsViewModel.swift
//  fitstyle
//
//  Created by Joel Goncalves on 10/26/21.
//

import Foundation
import Amplify
import AWSPluginsCore

final class SettingsViewModel: ObservableObject {

    @Published private(set) var userId = ""
    
    init() {
        fetchUserId()
    }
    
    func fetchUserId() {
        Amplify.Auth.fetchAuthSession { result in
            do {
                let session = try result.get()
                
                 if let identityProvider = session as? AuthCognitoIdentityProvider {
                    let identityId = try identityProvider.getIdentityId().get()
                    
                    if let index = identityId.firstIndex(of: ":") {
                        let startIndex = identityId.index(after: index)
                        let substring = identityId.suffix(from: startIndex)
                        if let endIndex = substring.firstIndex(of: "-") {
                            let range = startIndex..<endIndex
                            let id = substring[range]
                            DispatchQueue.main.async {
                                self.userId = String(id)
                            }
                        }
                    }
                 }
            } catch {
                // TODO: log error
            }
        }
    }
}
    
