//
//  String.swift
//  Wikist
//
//  Created by Lucka on 20/4/2021.
//

import Foundation

extension String {
    func prependingURLScheme(_ scheme: String = "https") -> Self {
        var newString = self
        if newString.starts(with: "//") {
            newString = scheme + ":" + self
        }
        return newString
    }
}
