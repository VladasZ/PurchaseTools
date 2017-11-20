//
//  PurchaseTools.swift
//  PurchaseTools
//
//  Created by Vladas Zakrevskis on 10/28/17.
//  Copyright © 2017 VladasZ. All rights reserved.
//

import StoreKit

public typealias PurchaseToolsRequestCompletion = (_ error: String?) -> ()
fileprivate typealias StoreKitRequestCompletion = (_ error: String?, _ response: SKProductsResponse?) -> ()

fileprivate let PaymentQueue = SKPaymentQueue.default()

internal class PurchaseTools : NSObject {
    
    private static var productsRequest: SKProductsRequest?
    private static var productsRequestCompletionHandler: StoreKitRequestCompletion!
    private static var productsRestoreRequestCompletionHandler: PurchaseToolsRequestCompletion!
    private static let instance = PurchaseTools()
    
    private static var productsStorage: ProductsStorage.Type!
    
    private override init() { super.init(); PaymentQueue.add(self) }
    
    static var produtsIdentifiers: Set<String> {
        return Set<String>(productsStorage.allProducts.map { $0.identifier })
    }
    
    static func getProductsForStorage(_ storage: ProductsStorage.Type, _ completion: @escaping PurchaseToolsRequestCompletion) {
        
        productsStorage = storage
        
        requestProducts { error, response in
            
            if let error = error { completion(error); return }
            
            for skProduct in response!.products {
                if productsStorage.productForSKProduct(skProduct) == nil {
                    print("[❤️ PurchaseTools error ❤️]: product \(skProduct.productIdentifier) not found in products storage");
                }
            }
            
            for product in productsStorage.allProducts {
                if product.skProduct == nil {
                    print("[❤️ PurchaseTools error ❤️]: product \(product.identifier) not found in products response")
                }
            }
            
            completion(nil)
        }
    }
    
    static func restore(_ completion: @escaping PurchaseToolsRequestCompletion) {
        productsRestoreRequestCompletionHandler = completion
        PaymentQueue.restoreCompletedTransactions()
    }
    
    private static func requestProducts(_ completionHandler: @escaping StoreKitRequestCompletion) {
        productsRequestCompletionHandler = completionHandler
        productsRequest?.cancel()
        productsRequest = SKProductsRequest(productIdentifiers: produtsIdentifiers)
        productsRequest!.delegate = instance
        productsRequest!.start()
    }
    
    static func purchase(_ product: Product) {
        
        if product.purchased {
            product.invokeCompletion(nil)
            return
        }
        
        guard product.isValid else {
            product.invokeCompletion("Invalid product")
            return
        }
        
        PaymentQueue.add(SKPayment(product: product.skProduct))
    }
}

//MARK: - SKProductsRequestDelegate

extension PurchaseTools : SKProductsRequestDelegate {
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        if response.invalidProductIdentifiers.count > 0 {
            print("[❤️ PurchaseTools error ❤️]: invalid ids: \(response.invalidProductIdentifiers)");
        }
        PurchaseTools.productsRequestCompletionHandler(nil, response)
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        PurchaseTools.productsRequestCompletionHandler(error.localizedDescription, nil)
    }
}

//MARK: - SKPaymentTransactionObserver

extension PurchaseTools : SKPaymentTransactionObserver {
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        
        var restoredTransactions = [SKPaymentTransaction]()
        
        for transaction in transactions {
            switch (transaction.transactionState) {
            case .purchased: complete(transaction: transaction)
            case .failed: fail(transaction: transaction)
            case .restored: restoredTransactions.append(transaction)
            case .deferred: fallthrough
            case .purchasing:
                break
            }
        }
        
        if restoredTransactions.count > 0 {
            restore(transactions: restoredTransactions)
        }
    }
    
    private func complete(transaction: SKPaymentTransaction) {
        
        if let product = PurchaseTools.productsStorage.productForTransaction(transaction) {
            product.setPurchased()
            product.invokeCompletion()
            product.onPurchase?()
            product.onPurchase = nil
        }
        else {
            print("[❤️ PurchaseTools error ❤️]: failed to get purchased product for id: \(transaction.payment.productIdentifier)")
        }
        
        PaymentQueue.finishTransaction(transaction)
    }
    
    private func restore(transactions: [SKPaymentTransaction]) {
        
        for transaction in transactions {
            PaymentQueue.finishTransaction(transaction)
            
            guard let product = PurchaseTools.productsStorage.productForTransaction(transaction) else {
                print("[❤️ PurchaseTools error ❤️]: failed to get restored product for id: \(transaction.payment.productIdentifier)");
                continue
            }
            product.setPurchased()
        }
        
        PurchaseTools.productsRestoreRequestCompletionHandler?(nil)
        PurchaseTools.productsRestoreRequestCompletionHandler = nil
    }
    
    private func fail(transaction: SKPaymentTransaction) {
        
        if let product = PurchaseTools.productsStorage.productForTransaction(transaction) {
            product.invokeCompletion(transaction.error?.localizedDescription)
        }
        else {
            print("[❤️ PurchaseTools error ❤️]: failed to get failed product for id: \(transaction.payment.productIdentifier)")
        }
        
        PaymentQueue.finishTransaction(transaction)
    }
}

