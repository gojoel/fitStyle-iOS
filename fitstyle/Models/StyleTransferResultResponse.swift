//
//  StyleTransferResultResponse.swift
//  fitstyle
//
//  Created by Joel Goncalves on 10/8/21.
//

import Foundation

struct StyleTransferResultResponse: Decodable {
    var status: String
    var requestId: String?

    enum CodingKeys: String, CodingKey {
        case status = "status"
        case requestId = "req_id"
    }
}
