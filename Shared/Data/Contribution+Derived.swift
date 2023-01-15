//
//  Contribution+Derived.swift
//  Wikist
//
//  Created by Lucka on 12/12/2022.
//

import Foundation

extension Contribution {
    var user: User? {
        guard let users = value(forKey: "user") as? [ User ] else { return nil }
        return users.first
    }
}
