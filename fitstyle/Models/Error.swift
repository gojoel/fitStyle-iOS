//
//  Error.swift
//  fitstyle
//
//  Created by Joel Goncalves on 10/12/21.
//

import Foundation

enum FitstyleError: Error {
    case invalidResponse
    case transferFailed
    case urlGenerationFailed
    case imageDataRetrievalFailed
    case unknownError
}
