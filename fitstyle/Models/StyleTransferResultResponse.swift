//
//  StyleTransferResultResponse.swift
//  fitstyle
//
//  Created by Joel Goncalves on 10/8/21.
//

import Foundation

struct StyleTransferResultResponse: Decodable {
    var status: StyleTransferStatus
    var requestId: String?

    enum CodingKeys: String, CodingKey {
        case status = "status"
        case requestId = "req_id"
    }
    
    enum StyleTransferStatus: String, Decodable {
        case failed
        case incomplete
        case complete
    }
}
