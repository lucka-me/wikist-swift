//
//  SKProduct.swift
//  Wikist
//
//  Created by Lucka on 18/4/2021.
//

import StoreKit

extension SKProduct {
    var localizedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = priceLocale
        return formatter.string(from: price) ?? "\(price)"
    }
    
    var localizedText: String {
        "\(localizedTitle) - \(localizedPrice)"
    }
}
