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
        #if DEBUG
            return
        #else
            Analytics.logEvent(AnalyticsEventScreenView, parameters: [
                AnalyticsParameterScreenName: screenName,
                AnalyticsParameterScreenClass: screenClass
            ])
        #endif
    }
    
    
    static func logPurchaseButtonTapped() {
        Analytics.logEvent("clicked_purchase_button", parameters: nil)
    }
    
    static func logShareButtonTapped() {
        Analytics.logEvent("clicked_share_button", parameters: nil)
    }
}
