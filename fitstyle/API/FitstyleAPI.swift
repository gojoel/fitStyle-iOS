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
    private static let baseUrlString = "https://foldedai.com/api"
    private static let baseUrl = URL(string: baseUrlString)!
    private static let agent = Agent()
    private static let cacheManager = CacheManager()

    private static let TRANSFER_RETRIES = 10
    
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
            .map({ (images) -> [StyledImage] in
                let sortedImages = images.sorted(by: {
                    $0.lastUpdated.compare($1.lastUpdated) == .orderedDescending
                })
                
                return sortedImages
            })
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
                let params: [String: Any] = ["style_id": styleImageId ?? "", "user_id": userId]
                return styleTransferRequest(contentImage: contentImage, styleImage: nil, params: params)
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
                    multiPart.append(styleImage, withName: "custom_style", fileName: "custom_style.png", mimeType: "image/png")
                }
                
                // add photo
                multiPart.append(contentImage, withName: "content", fileName: "content.png", mimeType: "image/png")
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
    
    static func pollStylingStatus(jobId: String) -> AnyPublisher<StyledImage, Error> {
        let request = URLComponents(url: baseUrl.appendingPathComponent("style_transfer/results/\(jobId)"), resolvingAgainstBaseURL: true)?
            .request
        
        return agent.run(request!)
            .catch({ (error: Error) -> AnyPublisher<StyleTransferResultResponse, Error> in
                return Fail(error: error)
                    .delay(for: 5, scheduler: DispatchQueue.main)
                    .eraseToAnyPublisher()
            })
            .retry(TRANSFER_RETRIES)
            .flatMap({ (response) -> AnyPublisher<StyledImage, Error> in
                if (response.status == "failed" || response.requestId == nil) {
                    return Fail(error: FitstyleError.transferFailed)
                        .eraseToAnyPublisher()
                }
                
                return FitstyleAPI.fetchUserId()
                    .map { (userId) -> StyledImage in
                        let key = Constants.Aws.buildStyledKey(userId: userId, requestId: response.requestId!)
                        let styledImage = StyledImage(key: key)
                        
                        // save to memory and disk
                        self.cacheManager.cache(styledImage: styledImage)
                        self.cacheManager.saveStledImages()
                        
                        return styledImage
                    }
                    .eraseToAnyPublisher()
            })
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
}

private extension URLComponents {
    var request: URLRequest? {
        url.map { URLRequest.init(url: $0) }
    }
}
