//
//  StyleTransferSettings.swift
//  fitstyle
//
//  Created by Joel Goncalves on 10/16/21.
//

import Foundation
import PhotosUI
class StyleTransferSettings: ObservableObject {
    var selectedStyle: Style?
    var selectedStyledImage: StyledImage?
    var customStylePhoto: PHAsset?
    var selectedPhoto: PHAsset?
    
    func clear() {
        selectedStyle = nil
        selectedStyledImage = nil
        customStylePhoto = nil
        selectedPhoto = nil
    }
}
