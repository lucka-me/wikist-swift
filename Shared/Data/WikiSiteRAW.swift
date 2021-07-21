//
//  WikiSiteRAW.swift
//  Wikist
//
//  Created by Lucka on 12/4/2021.
//

import Foundation

class WikiSiteRAW {
    
    enum QueryError: Error {
        case invalidURL
        case invalidResponse
    }
    
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
    
    func query() async throws {
        guard var urlComponents = api else {
            throw QueryError.invalidURL
        }
        urlComponents.queryItems = [
            .init(name: "action", value: "query"),
            
            .init(name: "meta", value: "siteinfo"),
            .init(name: "siprop", value: "general"),
            
            .init(name: "format", value: "json"),
        ]
        guard let url = urlComponents.url else {
            throw QueryError.invalidURL
        }
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw QueryError.invalidResponse
        }
        let decoder = JSONDecoder()
        let json = try decoder.decode(ResponseJSON.self, from: data)
        title = json.query.general.sitename
        homepage = json.query.general.base
        logo = json.query.general.logo.urlString ?? ""
        favicon = json.query.general.favicon.urlString ?? ""
        server = json.query.general.server.urlString ?? ""
        language = json.query.general.lang
        articlePath = json.query.general.articlepath
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
