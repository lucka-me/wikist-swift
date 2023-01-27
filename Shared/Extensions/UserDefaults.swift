//
//  UserDefaults.swift
//  Wikist
//
//  Created by Lucka on 15/1/2023.
//

import Foundation

extension UserDefaults {
    func value<Value>(for item: UserDefaultsItem<Value>) -> Value {
        guard let result = object(forKey: item.key) as? Value else { return item.defaultValue }
        return result
    }
    
    func set<Value>(_ value: Value, for item: UserDefaultsItem<Value>) {
        setValue(value, forKey: item.key)
    }
}

struct UserDefaultsItem<Value> {
    let key: String
    let defaultValue: Value
    
    fileprivate init(key: String, defaultValue: Value) {
        self.key = key
        self.defaultValue = defaultValue
    }
}

extension UserDefaultsItem where Value == Int {
    static let onboardingVersion = Self.init(key: "onboardingVersion", defaultValue: 0)
}
