//
//  URLResponse.swift
//  Wikist
//
//  Created by Lucka on 2/7/2022.
//

import Foundation

extension URLResponse {
    func isHTTP(status code: Int) -> Bool {
        guard let typed = self as? HTTPURLResponse else { return false }
        return typed.statusCode == code
    }
}
