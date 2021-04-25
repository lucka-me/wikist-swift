//
//  Locale.swift
//  Wikist
//
//  Created by Lucka on 25/4/2021.
//

import Foundation

extension Locale {
    static func localizedString(forLanguageCode code: String) -> String? {
        Locale(identifier: code).localizedString(forLanguageCode: code)
    }
}
