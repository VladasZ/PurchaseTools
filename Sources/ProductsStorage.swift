//
//  ProductsStorage.swift
//  PurchaseTools
//
//  Created by Vladas Zakrevskis on 10/28/17.
//  Copyright © 2017 VladasZ. All rights reserved.
//

import StoreKit

public protocol ProductsStorage {
    static var allProducts: [Product] { get }
}

extension ProductsStorage {
    
    static func productWithIdentifier(_ identifier: String) -> Product? {
        return (allProducts.filter { $0.identifier == identifier }).first
    }
    
    static func productForSKProduct(_ skProduct: SKProduct) -> Product? {
        guard let product = productWithIdentifier(skProduct.productIdentifier) else { return nil }
        product.skProduct = skProduct
        print("got \(product.name) product")
        return product
    }
    
    static func productForTransaction(_ transaction: SKPaymentTransaction) -> Product? {
        return productWithIdentifier(transaction.payment.productIdentifier)
    }
}
