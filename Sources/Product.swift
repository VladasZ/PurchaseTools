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

fileprivate extension Date {
    func daysTo(_ date: Date) -> Int {
        return Int((date.timeIntervalSinceReferenceDate - timeIntervalSinceReferenceDate) / (60 * 60 * 24))
    }
}

public class Product {
    
    private var purchaseCompletion: PurchaseToolsRequestCompletion!
    private var defaultsKey: String { return "PurchaseToolsDefaultsID\(identifier)" }
    private var purchaseDateDefaultsKey: String { return defaultsKey + "purchaseDate" }
    private var subscribitionDurationDefaultsKey: String { return defaultsKey + "purchaseDate" }
    
    public var name: String { return skProduct?.localizedTitle ?? "No skProduct" }
    public var description: String { return skProduct?.localizedDescription ?? "No skProduct" }
    public var price: NSDecimalNumber { return skProduct?.price ?? 0 }
    public var identifier: ProductIdentifier
    public var type: ProductType
    public var skProduct: SKProduct!
    public var isValid: Bool { return skProduct != nil }
    
    private (set) public var purchaseDate: Date? {
        get { return UserDefaults.standard.value(forKey: purchaseDateDefaultsKey) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: purchaseDateDefaultsKey) }
    }
    
    public var purchased: Bool {
        if type == .consumable { return false }
        if type == .autoRenewSubscription {
            guard let purchaseData = self.purchaseDate else { return false }
            if Date().daysTo(purchaseData) <= 0 {
                UserDefaults.standard.set(false, forKey: defaultsKey)
                purchaseDate = nil
                return false
            }
        }
        
        return UserDefaults.standard.bool(forKey: defaultsKey)
    }
    
    public var subscribitionDuration: UInt {
        get { return UInt(UserDefaults.standard.integer(forKey: subscribitionDurationDefaultsKey)) }
        set {
            if type != .autoRenewSubscription {
                print("PurchaseTools warning: subscribitionDuration used only with autoRenewSubscription")
                return
            }
            UserDefaults.standard.set(newValue, forKey: subscribitionDurationDefaultsKey)
        }
    }
    
    public init(identifier: ProductIdentifier, type: ProductType) {
        self.identifier = identifier
        self.type = type
    }
    
    public func purchase(_ completion: @escaping PurchaseToolsRequestCompletion) {
        purchaseCompletion = completion
        PurchaseTools.purchase(self)
    }
    
    func setPurchased() {
        if type == .consumable { return }
        purchaseDate = Date()
        UserDefaults.standard.set(true, forKey: defaultsKey)
    }
    
    func invokeCompletion(_ error: String? = nil) {
        if purchaseCompletion == nil { return }
        purchaseCompletion(error)
        purchaseCompletion = nil
    }
}


