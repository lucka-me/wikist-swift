//
//  WikiUserRAW.swift
//  Wikist
//
//  Created by Lucka on 12/4/2021.
//

import Foundation

class WikiUserRAW {
    
    typealias QueryCallback = (Bool) -> Void
    private typealias QueryJSONCallback = (ResponseJSON?) -> Void
    
    var username: String
    var site: WikiSite
    var uid: Int64 = 0
    var registration: Date = .init()
    var edits: Int64 = 0
    var contributions: [ Date : Int64 ] = [:]
    
    init(_ username: String, _ site: WikiSite) {
        self.username = username
        self.site = site
    }
    
    func queryInfo(_ callback: @escaping QueryCallback) {
        query(queryItemsForInfo) { json in
            guard
                let solidJSON = json,
                let solidUser = solidJSON.query.users?.first
            else {
                callback(false)
                return
            }
            callback(self.parse(solidUser))
        }
    }
    
    func queryContributions(_ callback: @escaping QueryCallback) {
        query(queryItemsForContributions) { json in
            self.handleContributionsQuery(json, callback)
        }
    }
    
    private var queryItemsForInfo: [URLQueryItem] {
        [
            .init(name: "action", value: "query"),
            
            .init(name: "list", value: "users"),
            .init(name: "ususers", value: username),
            .init(name: "usprop", value: "editcount|registration"),
            
            .init(name: "format", value: "json"),
        ]
    }
    
    private var queryItemsForContributions: [URLQueryItem] {
        [
            .init(name: "action", value: "query"),
            
            .init(name: "list", value: "usercontribs"),
            .init(name: "ucuser", value: username),
            .init(name: "uclimit", value: "500"),
            .init(name: "ucend", value: Date.iso8601OneYearBeforeAlignedWithWeek),
            .init(name: "ucprop", value: "timestamp"),
            
            .init(name: "format", value: "json"),
        ]
    }
    
    private func handleContributionsQuery(_ json: ResponseJSON?, _ callback: @escaping QueryCallback) {
        guard
            let solidJSON = json,
            let solidContribs = solidJSON.query.usercontribs
        else {
            callback(false)
            return
        }
        if !self.parse(solidContribs) {
            callback(false)
            return
        }
        guard let continueData = solidJSON.continueData else {
            callback(true)
            return
        }
        var queryItems = self.queryItemsForContributions
        queryItems.append(.init(name: "uccontinue", value: continueData.uccontinue))
        query(queryItems) { json in
            self.handleContributionsQuery(json, callback)
        }
    }
    
    private func query(_ queryItems: [URLQueryItem], _ callback: @escaping QueryJSONCallback) {
        guard var queryComponents = URLComponents(string: site.api) else {
            callback(nil)
            return
        }
        queryComponents.queryItems = queryItems
        guard let queryUrl = queryComponents.url else {
            callback(nil)
            return
        }
        let request = URLRequest(url: queryUrl)
        URLSession.shared.dataTask(with: request) { data, _, error in
            if error != nil {
                callback(nil)
                return
            }
            guard
                let solidData = data,
                let solidJSON = try? JSONDecoder().decode(ResponseJSON.self, from: solidData)
            else {
                callback(nil)
                return
            }
            callback(solidJSON)
        }
        .resume()
    }
    
    private func parse(_ json: UserJSON) -> Bool {
        uid = json.userid
        guard let solidRegistration = ISO8601DateFormatter.shared.date(from: json.registration) else {
            return false
        }
        registration = solidRegistration
        edits = json.editcount
        return true
    }
    
    private func parse(_ list: [UserContribJSON]) -> Bool {
        for json in list {
            guard let solidDate = ISO8601DateFormatter.shared.date(from: json.timestamp) else {
                continue
            }
            let day = Calendar.iso8601.startOfDay(for: solidDate)
            contributions[day] = contributions[day, default: 0] + 1
        }
        return true
    }
}

fileprivate struct ResponseJSON: Decodable {
    var query: QueryJSON
    var continueData: ContinueJSON?
    
    enum CodingKeys: String, CodingKey {
        case query = "query"
        case continueData = "continue"
    }
}

fileprivate struct ContinueJSON: Decodable {
    var uccontinue: String
}

fileprivate struct QueryJSON: Decodable {
    var users: [UserJSON]?
    var usercontribs: [UserContribJSON]?
}

fileprivate struct UserJSON: Decodable {
    var userid: Int64
    var registration: String
    var editcount: Int64
}

fileprivate struct UserContribJSON: Decodable {
    var timestamp: String
}
