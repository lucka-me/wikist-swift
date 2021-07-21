//
//  WikiUserRAW.swift
//  Wikist
//
//  Created by Lucka on 12/4/2021.
//

import Foundation

class WikiUserRAW {
    
    enum QueryError: Error {
        case invalidURL
        case invalidResponse
        case userNotFound
        case invalidResponseContent
    }
    
    var username: String
    var site: WikiSite
    var userId: Int64 = 0
    var registration: Date = .init()
    var edits: Int64 = 0
    var contributions: [ Date : Int64 ] = [:]
    
    init(_ username: String, _ site: WikiSite) {
        self.username = username
        self.site = site
    }
    
    func query(user: Bool = true, contributions: Bool = true) async throws {
        if user {
            try await queryUser()
        }
        if contributions {
            try await queryContributons()
        }
    }
    
    private func queryUser() async throws {
        guard let url = site.url(for: [
            .init(name: "action", value: "query"),
            
            .init(name: "list", value: "users"),
            .init(name: "ususers", value: username),
            .init(name: "usprop", value: "editcount|registration"),
            
            .init(name: "format", value: "json"),
        ]) else {
            throw QueryError.invalidURL
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let typedResponse = response as? HTTPURLResponse, typedResponse.statusCode == 200 else {
            throw QueryError.invalidResponse
        }
        let decoder = JSONDecoder()
        let queryResponse = try decoder.decode(UsersQueryResponse.self, from: data)
        guard let userData = queryResponse.query.users.first else {
            throw QueryError.userNotFound
        }
        guard let solidRegistration = ISO8601DateFormatter.shared.date(from: userData.registration) else {
            throw QueryError.invalidResponseContent
        }
        registration = solidRegistration
        userId = userData.userid
        edits = userData.editcount
    }
    
    private func queryContributons() async throws {
        let queryItems: [ URLQueryItem ] = [
            .init(name: "action", value: "query"),
            
            .init(name: "list", value: "usercontribs"),
            .init(name: "ucuser", value: username),
            .init(name: "uclimit", value: "500"),
            .init(name: "ucend", value: Date.iso8601OneYearBeforeAlignedWithWeek),
            .init(name: "ucprop", value: "timestamp"),
            
            .init(name: "format", value: "json"),
        ]
        var uccontinue: String? = nil
        repeat {
            var currentQueryItems = queryItems
            if let solidContinue = uccontinue {
                currentQueryItems.append(.init(name: "uccontinue", value: solidContinue))
            }
            guard let url = site.url(for: currentQueryItems) else {
                throw QueryError.invalidURL
            }
            let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let typedResponse = response as? HTTPURLResponse, typedResponse.statusCode == 200 else {
                throw QueryError.invalidResponse
            }
            let decoder = JSONDecoder()
            let queryResponse = try decoder.decode(ContributionsQueryResponse.self, from: data)
            for contributionData in queryResponse.query.usercontribs {
                guard let date = ISO8601DateFormatter.shared.date(from: contributionData.timestamp) else {
                    continue
                }
                let day = Calendar.iso8601.startOfDay(for: date)
                contributions[day] = contributions[day, default: 0] + 1
            }
            uccontinue = queryResponse.continueData?.uccontinue
        } while uccontinue != nil
    }
}

fileprivate struct UsersQueryResponse: Decodable {
    
    struct Item: Decodable {
        var userid: Int64
        var registration: String
        var editcount: Int64
    }
    
    struct Query: Decodable {
        var users: [ Item ]
    }
    
    var query: Query
}

fileprivate struct ContributionsQueryResponse: Decodable {
    
    enum CodingKeys: String, CodingKey {
        case query = "query"
        case continueData = "continue"
    }
    
    struct ContinueData: Decodable {
        var uccontinue: String
    }
    
    struct Item: Decodable {
        var timestamp: String
    }
    
    struct Query: Decodable {
        var usercontribs: [ Item ]
    }
    
    var query: Query
    var continueData: ContinueData?
}
