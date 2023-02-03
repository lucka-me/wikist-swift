//
//  Wiki+Task.swift
//  Wikist
//
//  Created by Lucka on 2/7/2022.
//

import Foundation

protocol WikiQuery {
    associatedtype Result: Decodable
    var queryItems: [ URLQueryItem ] { get }
}

protocol ContinuableWikiQuery: WikiQuery {
    associatedtype Continue: Decodable
}

extension Wiki {
    enum TaskError : Error, LocalizedError {
        case invalidQuery
        case invalidResponse(code: Int)
        case invalidURL
        
        var errorDescription: String? {
            switch self {
            case .invalidQuery:
                return .init(localized: "Wiki.TaskError.InvalidQuery")
            case .invalidResponse(let code):
                return .init(localized: "Wiki.TaskError.InvalidResponse \(code).")
            case .invalidURL:
                return .init(localized: "Wiki.TaskError.InvalidURL")
            }
        }
        
        var failureReason: String? {
            switch self {
            case .invalidQuery:
                return .init(localized: "Wiki.TaskError.InvalidQuery.Reason")
            case .invalidResponse(let code):
                return .init(localized: "Wiki.TaskError.InvalidResponse.Reason \(code).")
            case .invalidURL:
                return .init(localized: "Wiki.TaskError.InvalidURL.Reason")
            }
        }
    }
}

extension Wiki {
    struct QueryResult<Query: Decodable, Continue: Decodable> : Decodable {
        var query: Query
        var `continue`: Continue?
    }
    
    func query<Result: Decodable>(with queryItems: [ URLQueryItem ]) async throws -> Result {
        let data = try await self.query(with: queryItems)
        let decoder = JSONDecoder()
        return try decoder.decode(QueryResult<Result, [ String : String ]>.self, from: data).query
    }
    
    func query<Query: WikiQuery>(_ query: Query) async throws -> Query.Result {
        try await self.query(with: query.queryItems)
    }
    
    func query<Result: Decodable, Continue: Decodable>(with queryItems: [ URLQueryItem ]) async throws -> (Result, Continue?) {
        let data = try await query(with: queryItems)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(QueryResult<Result, Continue>.self, from: data)
        return (decoded.query, decoded.continue)
    }
    
    func query<Query: ContinuableWikiQuery>(_ query: Query) async throws -> (Query.Result, Query.Continue?) {
        try await self.query(with: query.queryItems)
    }
    
    fileprivate func query(with queryItems: [ URLQueryItem ]) async throws -> Data {
        var items: [ URLQueryItem ] = [
            .init(name: "action", value: "query"),
            .init(name: "format", value: "json")
        ]
        items.append(contentsOf: queryItems)
        let queryURL = try url(with: items)
        let (data, response) = try await URLSession.shared.data(
            for: .init(url: queryURL, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
        )
        if !response.isHTTP(status: 200) {
            throw TaskError.invalidResponse(code: (response as? HTTPURLResponse)?.statusCode ?? -1)
        }
        return data
    }
}

extension Wiki {
    fileprivate struct SiteInfoQuery : WikiQuery {
        fileprivate struct General : Decodable {
            var articlepath: String
            var favicon: String
            var generator: String
            var lang: String
            var logo: String
            var mainpage: String
            var sitename: String
        }
        fileprivate struct Statistics : Decodable {
            var pages: Int64
            var articles: Int64
            var edits: Int64
            var images: Int64
            var users: Int64
        }
        fileprivate struct Namespace : Decodable {
            var id: Int32
            var name: String
            var canonical: String?
            
            private enum CodingKeys: String, CodingKey {
                case id
                case name = "*"
            }
        }
        fileprivate struct Result : Decodable {
            var general: General
            var statistics: Statistics
            var namespaces: [ String : Namespace ]
        }
        
        var queryItems: [ URLQueryItem ] = [
            .init(name: "meta", value: "siteinfo"),
            .init(name: "siprop", value: "general|statistics|namespaces"),
        ]
    }
    
    func update() async throws {
        guard let managedObjectContext else { return }
        let result = try await query(SiteInfoQuery())
        
        guard !Task.isCancelled else { return }
        
        await managedObjectContext.perform { [ self ] in
            articlePath = result.general.articlepath
            if var favicon = URL(string: result.general.favicon) {
                if !favicon.hasScheme {
                    favicon.set(scheme: "https")
                }
                self.favicon = favicon
            }
            generator = result.general.generator
            language = result.general.lang
            if var logo = URL(string: result.general.logo) {
                if !logo.hasScheme {
                    logo.set(scheme: "https")
                }
                self.logo = logo
            }
            mainPage = result.general.mainpage
            title = result.general.sitename
            
            let auxiliary: WikiAuxiliary
            if let existingAuxiliary = self.auxiliary {
                auxiliary = existingAuxiliary
            } else {
                auxiliary = WikiAuxiliary(self, context: managedObjectContext)
            }
            
            auxiliary.pages = result.statistics.pages
            auxiliary.articles = result.statistics.articles
            auxiliary.edits = result.statistics.edits
            auxiliary.images = result.statistics.images
            auxiliary.users = result.statistics.users
            
            let namespaces: [ Int32 : WikiNamespace ] = result.namespaces.reduce(into: [ : ]) { result, item in
                result[item.value.id] = .init(
                    id: item.value.id, name: item.value.name, canonical: item.value.canonical
                )
            }
            auxiliary.namespaces = namespaces
            
            managedObjectContext.refresh(self, mergeChanges: true)
        }
    }
}

extension Wiki {
    fileprivate struct UsersQuery: WikiQuery {
        fileprivate struct UserInfo : Decodable {
            var name: String
            var missing: String?
        }
        fileprivate struct Result : Decodable {
            var users: [ UserInfo ]
        }
        
        let user: String
        
        var queryItems: [ URLQueryItem ] {
            [
                .init(name: "list", value: "users"),
                .init(name: "ususers", value: user),
            ]
        }
    }
    
    func checkExistance(of user: String) async throws -> Bool {
        let data = try await query(UsersQuery(user: user))
        guard
            data.users.count == 1,
            data.users[0].name == user,
            data.users[0].missing == nil
        else {
            return false
        }
        return true
    }
}

extension Wiki {
    fileprivate func url(with queryItems: [ URLQueryItem ]) throws -> URL {
        guard
            let api,
            var components = URLComponents(url: api, resolvingAgainstBaseURL: true)
        else {
            throw TaskError.invalidURL
        }
        components.queryItems = queryItems
        guard let queryURL = components.url else { throw TaskError.invalidQuery }
        return queryURL
    }
}
