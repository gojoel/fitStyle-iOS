//
//  FitstyleAPI.swift
//  fitstyle
//
//  Created by Joel Goncalves on 10/4/21.
//

import Foundation
import Amplify
import Combine
import Alamofire
import AWSPluginsCore
import AWSS3StoragePlugin
import AWSS3
import Kingfisher

enum FitstyleAPI {
    private static let baseUrlString = Constants.baseURL
    private static let baseUrl = URL(string: baseUrlString)!
    private static let agent = Agent()
    private static let cacheManager = CacheManager()
    
    static func styles() -> AnyPublisher<[Style], Error> {
        let path = "style_images/"
        let options = StorageListRequest.Options(accessLevel: .guest, path: path)
        
        if !cacheManager.isStylesCacheEmpty() {
            let styles = cacheManager.retrieveStyles()
            return Just(styles)
                .mapError({ $0 as Error })
                .eraseToAnyPublisher()
        }
        
        return Amplify.Storage.list(options: options)
            .resultPublisher
            .map { $0.items }
            .mapError({ $0 as Error })
            .flatMap { (items) -> Publishers.Sequence<[StorageListResult.Item], Never> in
                items.publisher
            }
            .filter({ (item) -> Bool in
                item.key != path
            })
            .flatMap { (item) -> AnyPublisher<Style, Error> in
                return Amplify.Storage.getURL(key: item.key)
                    .resultPublisher
                    .mapError({ $0 as Error })
                    .map { (url) -> Style in
                        var style = Style(key: item.key)
                        style.url = url
                        return style
                    }.eraseToAnyPublisher()
            }
            .map({ (style) -> Style in
                self.cacheManager.cache(style: style)
                return style
            })
            .collect()
            .eraseToAnyPublisher()
    }
    
    static func fetchStyledImages() -> AnyPublisher<[StyledImage], Error> {
        return Just(cacheManager.retrieveStyledImages())
            .mapError({ $0 as Error })
            .eraseToAnyPublisher()
    }
    
    static func fetchUserId() -> AnyPublisher<String, Error> {
        return Future { promise in
            Amplify.Auth.fetchAuthSession { result in
                do {
                    let session = try result.get()
                     if let identityProvider = session as? AuthCognitoIdentityProvider {
                        let identityId = try identityProvider.getIdentityId().get()
                        promise(.success(identityId))
                     }
                } catch {
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    static func generateStyledImageUrl(key: String) -> AnyPublisher<URL, Error> {
        return generateImageUrlLegacy(key: key)
    }
    
    static func styleTransfer(contentImage: Data, styleImage: Data?, styleImageId: String?) -> AnyPublisher<StyleTransferResponse, Error> {
        return fetchUserId()
            .flatMap { (userId) -> AnyPublisher<StyleTransferResponse, Error> in
                var params: [String: Any] = ["user_id": userId]
                if let id = styleImageId {
                    params["style_id"] = id
                }
                                
                return styleTransferRequest(contentImage: contentImage, styleImage: styleImage, params: params)
                    .eraseToAnyPublisher()
            }.eraseToAnyPublisher()
    }
    
    private static func styleTransferRequest(contentImage: Data, styleImage: Data?, params: [String: Any]) -> Future<StyleTransferResponse, Error> {
                    
        return Future { promise in
            let url = "\(baseUrlString)/style_transfer"

            AF.upload(multipartFormData: { multiPart in
                for (key, value) in params {
                    if let temp = value as? String {
                        multiPart.append(temp.data(using: .utf8)!, withName: key)
                    }
                    
                    if let temp = value as? Int {
                        multiPart.append("\(temp)".data(using: .utf8)!, withName: key)
                    }
                }
                
                // add custom style image if provided
                if let styleImage = styleImage {
                    multiPart.append(styleImage, withName: "custom_style", fileName: "custom_style.png", mimeType: "image/jpeg")
                }
                
                // add photo
                multiPart.append(contentImage, withName: "content", fileName: "content.png", mimeType: "image/jpeg")
            }, to: url, method: .post)
            .responseDecodable(of: StyleTransferResponse.self) { response in
                switch response.result {
                case .success(let response):
                    promise(Result.success(response))
                break
                case .failure(let error):
                    promise(Result.failure(error))
                break
                }
            }
        }
    }
    
    static func pollStylingStatus(jobId: String) -> AnyPublisher<StyleTransferResultResponse, Error> {
        let request = URLComponents(url: baseUrl.appendingPathComponent("style_transfer/results/\(jobId)"), resolvingAgainstBaseURL: true)?
            .request
        
        return agent.run(request!)
            .eraseToAnyPublisher()
    }
    
    static func styledImageFromResult(requestId: String) -> AnyPublisher<StyledImage, Error> {
        return FitstyleAPI.fetchUserId()
            .map { (userId) -> StyledImage in
                let key = Constants.Aws.buildStyledKey(userId: userId, requestId: requestId)
                let styledImage = StyledImage(key: key, lastUpdated: Date())
                
                // save to memory and disk
                self.cacheManager.cache(styledImage: styledImage)
                self.cacheManager.saveStyledImages()
                
                return styledImage
            }
            .eraseToAnyPublisher()
    }
    
    static func cancelStyleTransfer(jobId: String) {
        _ = AF.request("\(baseUrlString)/style_transfer/cancel/\(jobId)", method: .post)
    }
    
    private static func generateImageUrlLegacy(key: String) -> AnyPublisher<URL, Error> {
        return Future { promise in
            do {
                let plugin = try Amplify.Storage.getPlugin(for: "awsS3StoragePlugin") as! AWSS3StoragePlugin
                let awsS3 = plugin.getEscapeHatch()

                AWSServiceManager.default().defaultServiceConfiguration = awsS3.configuration
                
                let getPreSignedURLRequest = AWSS3GetPreSignedURLRequest()
                getPreSignedURLRequest.httpMethod = AWSHTTPMethod.GET
                getPreSignedURLRequest.key = key
                getPreSignedURLRequest.bucket = Constants.Aws.bucket
                getPreSignedURLRequest.expires = Date(timeIntervalSinceNow: 3600)
            
                AWSS3PreSignedURLBuilder.default()
                    .getPreSignedURL(getPreSignedURLRequest)
                    .continueWith { (task) -> Void in
                        if let error = task.error {
                            promise(.failure(error))
                        } else {
                            if let result = task.result {
                                promise(.success(result as URL))
                                return
                            }
                        }
                        
                        promise(.failure(FitstyleError.urlGenerationFailed))
                }
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    static func removeWatermark(styledImage: StyledImage) -> AnyPublisher<Bool, Error> {
        fetchUserId()
            .flatMap { (userId) -> AnyPublisher<Bool, Error> in
                return Future { promise in
                    let parameters = ["userId": userId, "requestId": styledImage.requestId()]
                    
                    AF.request("\(baseUrlString)/remove_watermark", method: .post, parameters: parameters)
                        .responseString { (response) in
                            guard let httpResponse = response.response else {
                                promise(.failure(FitstyleError.unknownError))
                                return
                            }
                            
                            if httpResponse.statusCode != 200 {
                                promise(.failure(FitstyleError.unknownError))
                            } else {
                                promise(.success(true))
                            }
                        }
                }.eraseToAnyPublisher()
                
            }.mapError({ $0 as Error })
            .eraseToAnyPublisher()
    }
    
    static func savePurchasedImage(_ styledImage: StyledImage) -> StyledImage {
        let updatedStyledImage = StyledImage(id: styledImage.id, key: styledImage.key, purchased: true, url: styledImage.url, lastUpdated: Date())
        
        cacheManager.cache(styledImage: updatedStyledImage)
        cacheManager.saveStyledImages()
        
        return updatedStyledImage
    }
}

private extension URLComponents {
    var request: URLRequest? {
        url.map { URLRequest.init(url: $0) }
    }
}
