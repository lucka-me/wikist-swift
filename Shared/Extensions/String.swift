//
//  String.swift
//  Wikist
//
//  Created by Lucka on 20/4/2021.
//

import Foundation

extension String {
    var url: URL? {
        var string = self.replacingOccurrences(of: "^[A-Za-z0-9-.]*:?//", with: "https://", options: .regularExpression)
        if !string.starts(with: "https://") {
            string = "https://" + string
        }
        guard
            var urlComponents = URLComponents(string: string),
            let host = urlComponents.host
        else {
            return nil
        }
        urlComponents.host = host.lowercased()
        return urlComponents.url
    }
}
