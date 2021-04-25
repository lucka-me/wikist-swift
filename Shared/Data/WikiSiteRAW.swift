//
//  WikiSiteRAW.swift
//  Wikist
//
//  Created by Lucka on 12/4/2021.
//

import Foundation

class WikiSiteRAW {
    
    typealias QueryCallback = (Bool) -> Void
    
    var url: String
    var title: String = ""
    var homepage: String = ""
    var logo: String = ""
    var favicon: String = ""
    var server: String = ""
    var language: String = ""
    var articlePath: String = ""
    
    init(_ url: String) {
        self.url = url
    }
    
    var api: URLComponents? {
        URLComponents(string: url + "/api.php")
    }
    
    private var queryItems: [URLQueryItem] {
        [
            .init(name: "action", value: "query"),
            
            .init(name: "meta", value: "siteinfo"),
            .init(name: "siprop", value: "general"),
            
            .init(name: "format", value: "json"),
        ]
    }
    
    func query(_ callback: @escaping QueryCallback) {
        guard var queryComponents = api else {
            callback(false)
            return
        }
        queryComponents.queryItems = queryItems
        guard let queryUrl = queryComponents.url else {
            callback(false)
            return
        }
        let request = URLRequest(url: queryUrl, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
        URLSession.shared.dataTask(with: request) { data, _, error in
            if error != nil {
                callback(false)
                return
            }
            guard
                let solidData = data,
                let solidJSON = try? JSONDecoder().decode(ResponseJSON.self, from: solidData)
            else {
                callback(false)
                return
            }
            callback(self.parse(solidJSON))
        }
        .resume()
    }
    
    private func parse(_ json: ResponseJSON) -> Bool {
        title = json.query.general.sitename
        homepage = json.query.general.base
        logo = json.query.general.logo.urlString ?? ""
        favicon = json.query.general.favicon.urlString ?? ""
        server = json.query.general.server.urlString ?? ""
        language = json.query.general.lang
        articlePath = json.query.general.articlepath
        return true
    }
}

fileprivate struct ResponseJSON: Decodable {
    var query: QueryJSON
}

fileprivate struct QueryJSON: Decodable {
    var general: GeneralJSON
}

fileprivate struct GeneralJSON: Decodable {
    var base: String
    var sitename: String
    var logo: String
    var favicon: String
    var server: String
    var lang: String
    var articlepath: String
}
