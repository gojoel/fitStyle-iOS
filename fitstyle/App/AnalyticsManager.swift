//
//  AnalyticsManager.swift
//  fitstyle
//
//  Created by Joel Goncalves on 12/29/21.
//

import Foundation
import FirebaseAnalytics
import Amplify

class AnalyticsManager {
    
    enum FitstyleError : String, CaseIterable {
        case style_transfer = "error_style_transfer";
        case storage = "error_storage";
        case amplify = "error_amplify";
        case styled_image = "error_styled_image";
        case share = "error_share";
        case download = "error_download";
        case watermark = "error_watermark";
        case user = "error_user";
        case payment = "error_payment";
    }
    
    static func logScreen(screenName: String, screenClass: String) {
        if !Constants.isDebug {
            Analytics.logEvent(AnalyticsEventScreenView, parameters: [
                AnalyticsParameterScreenName: screenName,
                AnalyticsParameterScreenClass: screenClass
            ])
        }
    }
    
    static func logError(error: FitstyleError, description: String?) {
        let userId = UserManager.getUserId() ?? ""
        
        if !Constants.isDebug {
            Analytics.logEvent("ios_error", parameters: [
                "type": error.rawValue,
                "description": description ?? "",
                "user_id": userId,
            ])
        }
    }
    
    
    static func logPurchaseButtonTapped() {
        Analytics.logEvent("clicked_purchase_button", parameters: nil)
    }
    
    static func logShareButtonTapped() {
        Analytics.logEvent("clicked_share_button", parameters: nil)
    }
}
