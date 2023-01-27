//
//  URL.swift
//  Wikist
//
//  Created by Lucka on 13/4/2021.
//

import Foundation

extension URL {
    var hasScheme: Bool {
        guard let scheme else { return false }
        return !scheme.isEmpty
    }
    
    func removingAllPaths() -> URL? {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else { return nil }
        components.path = ""
        return components.url
    }
    
    func removingAllQuries() -> URL? {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else { return nil }
        components.query = nil
        return components.url
    }
    
    mutating func set(scheme: String?) {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else { return }
        components.scheme = scheme
        guard let url = components.url else { return }
        self = url
    }
}
