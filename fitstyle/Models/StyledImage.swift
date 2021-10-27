//
//  StyledImage.swift
//  fitstyle
//
//  Created by Joel Goncalves on 10/10/21.
//

import Foundation

struct StyledImage: Codable, Identifiable, Hashable {
    var id = UUID()
    var key: String
    var purchased: Bool = false
    var url: URL?
    var lastUpdated = Date()
    
    func requestId() -> String {
        let components = key.components(separatedBy: "/")
        return components[components.count - 2]        
    }

    enum CodingKeys: String, CodingKey {
        case key = "key"
        case purchased = "purchased"
    }
}
