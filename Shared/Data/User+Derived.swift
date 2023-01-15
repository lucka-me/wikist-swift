//
//  User+Derived.swift
//  Wikist
//
//  Created by Lucka on 26/11/2022.
//

import Foundation

extension User {
    var contributions: [ Contribution ] {
        value(forKey: "contributions") as? [ Contribution ] ?? [ ]
    }
}

extension User {
    var userPageURL: URL? {
        guard let name, let wiki else { return nil }
        return wiki.url(of: "User:\(name)")
    }
}

extension User {
    var latestContribution: Contribution? {
        guard let managedObjectContext, let uuid else { return nil }
        let request = Contribution.fetchRequest()
        request.predicate = .init(format: "%K == %@", #keyPath(Contribution.userID), uuid as NSUUID)
        request.sortDescriptors = [ .init(keyPath: \Contribution.timestamp, ascending: false) ]
        request.fetchLimit = 1
        return try? managedObjectContext.fetch(request).first
    }
    
    var latestContributionDate: Date {
        let defaultDate = registration ?? Date(timeIntervalSince1970: 0)
        guard let managedObjectContext, let uuid else { return defaultDate }
        let request = Contribution.fetchRequest()
        request.predicate = .init(format: "%K == %@", #keyPath(Contribution.userID), uuid as NSUUID)
        request.sortDescriptors = [
            .init(keyPath: \Contribution.timestamp, ascending: false)
        ]
        request.fetchLimit = 1
        guard
            let result = try? managedObjectContext.fetch(request),
            !result.isEmpty
        else {
            return defaultDate
        }
        return result[0].timestamp ?? defaultDate
    }
}
