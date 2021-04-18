//
//  Support.swift
//  Wikist
//
//  Created by Lucka on 17/4/2021.
//

import StoreKit

class Support: NSObject, ObservableObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    
    static let shared = Support()
    
    static let idTier1 = "dev.lucka.Wikist.IAP.supportTire1"
    static let idTier2 = "dev.lucka.Wikist.IAP.supportTire2"
    
    #if os(macOS)
    @Published var presentingTipSheet = false
    #endif
    @Published var purchased = false
    
    var products: [SKProduct] = []
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        products = response.products
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            if transaction.transactionState == .purchased {
                purchased = true
            }
        }
    }
    
    private override init() {
        super.init()
        SKPaymentQueue.default().add(self)
        if canMakePayments {
            let request = SKProductsRequest(productIdentifiers: [
                Self.idTier1, Self.idTier2
            ])
            request.delegate = self
            request.start()
        }
    }
    
    deinit {
        SKPaymentQueue.default().remove(self)
    }
    
    var canMakePayments: Bool {
        SKPaymentQueue.canMakePayments()
    }
    
    func purchase(_ product: SKProduct) {
        if canMakePayments {
            SKPaymentQueue.default().add(.init(product: product))
        }
    }
}
