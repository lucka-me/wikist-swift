//
//  URL.swift
//  Wikist
//
//  Created by Lucka on 13/4/2021.
//

import Foundation

extension URL {
    init?(raw string: String) {
        guard let encoded = string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        self.init(string: encoded)
    }
}
