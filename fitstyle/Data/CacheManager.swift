//
//  CacheManager.swift
//  fitstyle
//
//  Created by Joel Goncalves on 10/12/21.
//

import Foundation

class CacheManager {
    
    private let STYLED_IMAGE_CACHE_NAME = "styledImages"
    
    private let styleCache = Cache<Style.ID, Style>()
    
    private lazy var styledCache = Cache<String, StyledImage>()
    
    init() {
        loadStyledImagesCache()
    }
    
    func isStylesCacheEmpty() -> Bool {
        return styleCache.isEmpty()
    }
    
    func cache(style: Style) {
        styleCache.insert(style, forKey: style.id)
    }
    
    func cache(styledImage: StyledImage) {
        if !styledImage.requestId().isEmpty {
            styledCache.insert(styledImage, forKey: styledImage.requestId())
        }
    }
    
    func retrieveStyledImage(key: String) -> StyledImage? {
        styledCache.value(forKey: key)
    }
        
    func retrieveStyles() -> [Style] {
        return styleCache.all()
    }
    
    func retrieveStyledImages() -> [StyledImage] {
        return styledCache.all()
    }
    
    func saveStyledImages() {
        do {
            try styledCache.saveToDisk(withName: STYLED_IMAGE_CACHE_NAME)
        } catch {
            // TODO: log error
            print("Saving styled images to disk failed with error: \(error)")
        }
    }
    
    func loadStyledImagesCache() {
        do {
            let cache: Cache<String, StyledImage> = try Cache.readFromDisk(withName: STYLED_IMAGE_CACHE_NAME)
            self.styledCache = cache
        } catch {
            // TODO: log error
            print("Faied to load styled images cache with error: \(error)")
            self.styledCache = Cache<String, StyledImage>()
        }
    }
    
    func removeFile() {
        do {
            try styledCache.removeCachedFile(withName: STYLED_IMAGE_CACHE_NAME)
        } catch {
            // TODO: log error
            print("Faied to remove cached file with error: \(error)")
        }
    }
    
    static func styledImageCacheKey(image: StyledImage) -> String {
        return "\(image.key)_\(image.purchased)"
    }
}
