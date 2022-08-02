//
//  UserManager.swift
//  fitstyle
//
//  Created by Joel Goncalves on 8/1/22.
//

import Foundation

class UserManager {
    static func saveUserId(userId: String) {
        let defaults = UserDefaults.standard
        defaults.set(userId, forKey: "user_id")
    }
    
    static func getUserId() -> String? {
        let defaults = UserDefaults.standard
        return defaults.string(forKey: "user_id")
    }
}
