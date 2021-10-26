//
//  Store.swift
//  fitstyle
//
//  Created by Joel Goncalves on 10/25/21.
//

import StoreKit

typealias FetchCompletionHandler = ((Result<[SKProduct], Store.StoreError>) -> Void)
typealias PurchaseCompletionHandler = ((Result<SKPaymentTransaction?, Store.StoreError>) -> Void)

class Store: NSObject, ObservableObject {
    
    enum StoreError: Error {
         case noProductIDsFound
         case noProductsFound
         case paymentWasCancelled
         case productRequestFailed
        case unkown
     }
    
    private let watermarkRemovalProductId: String = "ai.folded.fitstyle.iap.watermark_removal"
    
    private let productIdentifiers = Set([
        "ai.folded.fitstyle.iap.watermark_removal"
    ])
    
    private var productsRequest: SKProductsRequest?
    private var fetchedProducts = [SKProduct]()
    private var fetchCompletionHandler: FetchCompletionHandler?
    private var purchaseCompletionHandler: PurchaseCompletionHandler?

    override init() {
        super.init()
        observePaymentQueue()
        fetchProducts { (result) in
            switch result {
            case .success(_):
                break
            case .failure(let error):
                // TODO: log error
                break
            }
        }
    }
    
    private func observePaymentQueue() {
        SKPaymentQueue.default().add(self)
    }
    
    func fetchProducts(_ completion: @escaping FetchCompletionHandler) {
        guard self.productsRequest == nil else { return }
        
        fetchCompletionHandler = completion
        
        productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        productsRequest?.delegate = self
        productsRequest?.start()
    }
    
    private func purchase(_ product: SKProduct, completion: @escaping PurchaseCompletionHandler) {
        purchaseCompletionHandler = completion
        
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
}

extension Store {
    func purchaseProduct(_ completion: @escaping PurchaseCompletionHandler) {
        guard let product = fetchedProducts.first(where: { $0.productIdentifier == watermarkRemovalProductId }) else { return }
        
        observePaymentQueue()
        purchase(product, completion: completion)
    }
    
    func shouldFetchProducts() -> Bool {
        return fetchedProducts.isEmpty
    }
}

extension Store: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            var shouldFininshTransaction = false
            var error: StoreError? = nil
            
            switch transaction.transactionState {
            case .purchased, .restored:
                shouldFininshTransaction = true
            case .failed:
                if let e = transaction.error as? SKError, e.code == .paymentCancelled {
                    error = .paymentWasCancelled
                } else {
                    error = .unkown
                }
                
                shouldFininshTransaction = true
            case .purchasing, .deferred:
                break
            @unknown default:
                break
            }
            
            if shouldFininshTransaction {
                SKPaymentQueue.default().finishTransaction(transaction)
                DispatchQueue.main.async {
                    if let error = error {
                        self.purchaseCompletionHandler?(.failure(error))
                    } else {
                        self.purchaseCompletionHandler?(.success(transaction))
                    }

                    self.purchaseCompletionHandler = nil
                }
            }
        }
    }
}

extension Store: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        let loadedProducts = response.products
        let invalidProducts = response.invalidProductIdentifiers
        var error: StoreError? = nil
        
        if loadedProducts.isEmpty {
            error = .noProductsFound
            
            if !invalidProducts.isEmpty {
                // TODO: log error
            }
        }
        
        // Notify observers on product load
        DispatchQueue.main.async {
            if let error = error {
                self.fetchCompletionHandler?(.failure(error))
            } else {
                // Cache the fetched products
                self.fetchedProducts = loadedProducts
                self.fetchCompletionHandler?(.success(loadedProducts))
            }

            self.fetchCompletionHandler = nil
            self.productsRequest = nil
        }
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        self.fetchCompletionHandler?(.failure(.productRequestFailed))
        self.fetchCompletionHandler = nil
        self.productsRequest = nil
    }
}

extension Store.StoreError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .noProductIDsFound: return "No In-App Purchase product identifiers were found."
        case .noProductsFound: return "No In-App Purchases were found."
        case .productRequestFailed: return "Unable to fetch available In-App Purchase products at the moment."
        case .paymentWasCancelled: return "In-App Purchase process was cancelled."
        case .unkown: return "Unkown error occured."
        }
    }
}
