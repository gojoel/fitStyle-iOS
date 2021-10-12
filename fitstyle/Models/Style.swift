//
//  Style.swift
//  fitstyle
//
//  Created by Joel Goncalves on 10/12/21.
//

import Foundation

struct Style: Hashable, Codable, Identifiable {
    var id = UUID()
    var key: String
    var url: URL?
    
    init(key: String) {
        self.key = key
    }
    
    func imageName() -> String {
        let components = key.components(separatedBy: "/")
        return components.count > 0 ? components[components.count - 1] : ""
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case key = "key"
    }
}
