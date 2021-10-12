//
//  StyleTransferResponse.swift
//  fitstyle
//
//  Created by Joel Goncalves on 10/7/21.
//

import Foundation

struct StyleTransferResponse: Decodable {
    var jobId: String
    
    enum CodingKeys: String, CodingKey {
      case jobId = "job_id"
    }
}
