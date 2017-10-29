//
//  Product.swift
//  PurchaseTools
//
//  Created by Vladas Zakrevskis on 10/28/17.
//  Copyright © 2017 VladasZ. All rights reserved.
//

import StoreKit

public typealias ProductIdentifier = String

public enum ProductType {
    
    case consumable
    case nonConsumable
    case subscription
    case autoRenewSubscription
}

public class Product {
    
    private var purchaseCompletion: PurchaseToolsRequestCompletion!
    private var _name: String?
    
    private var defaultsKey: String {
        return "PurchaseToolsDefaultsID\(identifier)"
    }
    
    public var name: String { return _name ?? identifier }
    public var identifier: ProductIdentifier
    public var type: ProductType
    public var skProduct: SKProduct!
    public var isValid: Bool { return skProduct != nil }
    
    public var purchased: Bool {
        if type == .consumable { return false }
        return UserDefaults.standard.bool(forKey: defaultsKey)
    }
    
    public init(identifier: ProductIdentifier, type: ProductType, name: String? = nil) {
        self._name = name
        self.identifier = identifier
        self.type = type
    }
    
    public func purchase(_ completion: @escaping PurchaseToolsRequestCompletion) {
        purchaseCompletion = completion
        PurchaseTools.purchase(self)
    }
    
    func setPurchased() {
        if type == .consumable { return }
        UserDefaults.standard.set(true, forKey: defaultsKey)
    }
    
    func invokeCompletion(_ error: String? = nil) {
        if purchaseCompletion == nil { return }
        purchaseCompletion(error)
        purchaseCompletion = nil
    }
}
