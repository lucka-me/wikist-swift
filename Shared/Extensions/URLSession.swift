//
//  URLSession.swift
//  Wikist
//
//  Created by Lucka on 20/4/2021.
//

import Foundation

extension URLSession {
    
    func dataTask(with urlString: String, completionHandler: @escaping (Data?) -> Void) {
        guard let url = URL(string: urlString) else {
            completionHandler(nil)
            return
        }
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
        URLSession.shared.dataTask(with: request) { data, _, _ in
            completionHandler(data)
        }
        .resume()
    }
}
