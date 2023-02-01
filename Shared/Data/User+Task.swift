//
//  User+Task.swift
//  Wikist
//
//  Created by Lucka on 3/7/2022.
//

import CoreData
import Foundation

extension User {
    enum TaskError : Error, LocalizedError {
        case dataInterrupted
        case userNotFound
        
        var errorDescription: String? {
            switch self {
            case .dataInterrupted:
                return .init(localized: "User.TaskError.DataInterrupted")
            case .userNotFound:
                return .init(localized: "User.TaskError.UserNotFound")
            }
        }
        
        var failureReason: String? {
            switch self {
            case .dataInterrupted:
                return .init(localized: "User.TaskError.DataInterrupted.Reason")
            case .userNotFound:
                return .init(localized: "User.TaskError.UserNotFound.Reason")
            }
        }
    }
}

extension User {
    fileprivate struct UserInfoQuery : WikiQuery {
        fileprivate struct UserInfo : Decodable {
            var userid: Int64?
            var name: String
            var missing: String?
            var registration: String?
        }
        fileprivate struct Result : Decodable {
            var users: [ UserInfo ]
        }
        
        let user: String
        
        var queryItems: [ URLQueryItem ] {
            [
                .init(name: "list", value: "users"),
                .init(name: "ususers", value: user),
                .init(name: "usprop", value: "registration")
            ]
        }
    }
    
    func update() async throws {
        guard let managedObjectContext else { return }
        guard let wiki, let name else {
            throw TaskError.dataInterrupted
        }
        let data = try await wiki.query(UserInfoQuery(user: name))
        guard
            data.users.count == 1,
            data.users[0].name == name,
            data.users[0].missing == nil
        else {
            throw TaskError.userNotFound
        }
        guard !Task.isCancelled else { return }
        
        await managedObjectContext.perform {
            self.userID = data.users[0].userid!
            if let registration = data.users[0].registration {
                self.registration = ISO8601DateFormatter.shared.date(from: registration)
            }
        }
    }
}

extension User {
    fileprivate struct UserContributionQuery : ContinuableWikiQuery {
        fileprivate struct UserContribution : Decodable {
            var pageid: Int64
            var revid: Int64
            var ns: Int32
            var title: String
            var timestamp: String
            var new: String?
            var sizediff: Int64?
        }
        fileprivate struct Result : Decodable {
            var usercontribs: [ UserContribution ]
        }
        fileprivate struct Continue : Decodable {
            var uccontinue: String
        }
        
        var queryItems: [ URLQueryItem ]
        
        init(_ user: String, end: Date) {
            queryItems = [
                .init(name: "list", value: "usercontribs"),
                .init(name: "ucuser", value: user),
                .init(name: "ucprop", value: "ids|title|timestamp|sizediff|flags"),
                .init(name: "uclimit", value: "500"),
                .init(name: "ucend", value: ISO8601DateFormatter.shared.string(from: end)),
            ]
        }
        
        mutating func next(_ token: String) {
            queryItems.removeAll { $0.name == "uccontinue" }
            queryItems.append(.init(name: "uccontinue", value: token ))
        }
    }
    
    func refresh(with timeZone: TimeZone = .current, viewContext: NSManagedObjectContext) async throws {
        guard let managedObjectContext else { return }
        guard let wiki, let name, let uuid else {
            throw TaskError.dataInterrupted
        }
        let latestContribution = await managedObjectContext.perform { self.latestContribution }

        var query = UserContributionQuery(
            name, end: latestContribution?.timestamp?.advanced(by: 1) ?? registration ?? Date(timeIntervalSince1970: 0)
        )
        var continueToken: String? = nil
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            var bufferedContributions: [ UserContributionQuery.UserContribution ] = [ ]
            var bufferCapacity = 500
            repeat {
                if let continueToken {
                    query.next(continueToken)
                }
                let (result, continueData) = try await wiki.query(query)
                bufferedContributions.append(contentsOf: result.usercontribs)
                continueToken = continueData?.uccontinue
                guard
                    !bufferedContributions.isEmpty
                        && (continueToken == nil || bufferedContributions.count >= bufferCapacity) else {
                    continue
                }
                let contributions = bufferedContributions
                group.addTask {
                    try await managedObjectContext.perform {
                        var index = 0
                        let total = contributions.count
                        let request = NSBatchInsertRequest(
                            entity: Contribution.entity(),
                            managedObjectHandler: { object in
                                guard index < total else { return true }
                                let contributionObject = object as! Contribution
                                let contribution = contributions[index]
                                contributionObject.userID = uuid
                                contributionObject.namespace = contribution.ns
                                contributionObject.pageID = contribution.pageid
                                contributionObject.revisionID = contribution.revid
                                if let sizeDiff = contribution.sizediff {
                                    contributionObject.sizeDiff = sizeDiff
                                }
                                contributionObject.timestamp = ISO8601DateFormatter.shared.date(
                                    from: contribution.timestamp
                                )
                                contributionObject.title = contribution.title
                                if contribution.new != nil {
                                    contributionObject.new = true
                                }
                                index += 1
                                return false
                            }
                        )
                        request.resultType = .objectIDs
                        guard
                            let result = try managedObjectContext.execute(request) as? NSBatchInsertResult,
                            let ids = result.result as? [ NSManagedObjectID ] else {
                            return
                        }
                        NSManagedObjectContext.mergeChanges(
                            fromRemoteContextSave: [ NSInsertedObjectsKey: ids ],
                            into: [ managedObjectContext, viewContext ]
                        )
                        if managedObjectContext.hasChanges {
                            try managedObjectContext.save()
                        }
                    }
                }
                bufferedContributions.removeAll(keepingCapacity: true)
                bufferCapacity = Int(1.6 * Double(bufferCapacity))
            } while continueToken != nil && !Task.isCancelled
        }
    }
}
