//
//  AnalyticsManager.swift
//  fitstyle
//
//  Created by Joel Goncalves on 12/29/21.
//

import Foundation
import FirebaseAnalytics

class AnalyticsManager {
    
    static func logScreen(screenName: String, screenClass: String) {
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: screenName,
            AnalyticsParameterScreenClass: screenClass
        ])
    }
    
    
    static func logPurchaseButtonTapped() {
        Analytics.logEvent("clicked_purchase_button", parameters: nil)
    }
    
    static func logShareButtonTapped() {
        Analytics.logEvent("clicked_share_button", parameters: nil)
    }
}
