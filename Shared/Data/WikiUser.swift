//
//  WikiUser+CoreDataClass.swift
//  Wikist
//
//  Created by Lucka on 11/4/2021.
//
//

import CoreData

@objc(WikiUser)
public final class WikiUser: NSManagedObject, NSManagedObjectWithFetchRequest {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<WikiUser> {
        return NSFetchRequest<WikiUser>(entityName: "WikiUser")
    }
}

extension WikiUser {

    @NSManaged public var username: String
    @NSManaged public var site: WikiSite?
    @NSManaged public var uid: Int64
    @NSManaged public var registration: Date
    @NSManaged public var edits: Int64
    @NSManaged public var contributions: NSSet?

}

// MARK: Generated accessors for contributions
extension WikiUser {

    @objc(addContributionsObject:)
    @NSManaged public func addToContributions(_ value: DailyContribution)

    @objc(removeContributionsObject:)
    @NSManaged public func removeFromContributions(_ value: DailyContribution)

    @objc(addContributions:)
    @NSManaged public func addToContributions(_ values: NSSet)

    @objc(removeContributions:)
    @NSManaged public func removeFromContributions(_ values: NSSet)

}

extension WikiUser : Identifiable {

}

extension WikiUser {
    static let sortDescriptorsByEdits = [ NSSortDescriptor(keyPath: \WikiUser.edits, ascending: false) ]
}

extension WikiUser {
    static func from(_ raw: WikiUserRAW, context: NSManagedObjectContext) -> WikiUser {
        let object = WikiUser(context: context)
        object.username = raw.username
        object.site = raw.site
        object.from(raw)
        return object
    }
    
    func from(_ raw: WikiUserRAW) {
        if raw.username != username || raw.site != site {
            return
        }
        uid = raw.uid
        registration = raw.registration
        edits = raw.edits
        guard let solidContext = managedObjectContext else {
            return
        }
        clearContributions()
        for (date, count) in raw.contributions {
            let contribution = DailyContribution(context: solidContext)
            contribution.date = date
            contribution.count = count
            addToContributions(contribution)
        }
    }
}

extension WikiUser {
    
    var userPage: URL? {
        guard let solidSite = site else {
            return nil
        }
        return solidSite.articleURL(of: "User:" + username)
    }
    
    var typedContributions: [ DailyContribution ] {
        let typedSet = contributions as? Set<DailyContribution> ?? []
        return .init(typedSet)
    }
    
    var contributionsMatrix: [ DailyContributionRAW ] {
        let today = Date.today
        let weekday = Date.weekday
        let days = Date.daysInYear + weekday - 1
        var dictContribution: [ Date : DailyContributionRAW ] = [:]
        for day in 0 ..< days {
            let date = Calendar.iso8601.startOfDay(for: .init(timeInterval: .init(-1 * day * Date.secondsInDay), since: today))
            dictContribution[date] = .init(date: date, count: 0)
        }
        for contribution in typedContributions {
            guard
                let raw = dictContribution[contribution.date],
                raw.count ?? 0 < contribution.count
            else {
                continue
            }
            dictContribution[contribution.date] = contribution.raw
        }
        var raws = dictContribution
            .sorted { $0.0 < $1.0 }
            .map { $0.value }
        for day in 0 ..< 7 - weekday {
            let date = Calendar.iso8601.startOfDay(for: .init(timeInterval: .init(day * Date.secondsInDay), since: today))
            raws.append(.init(date: date + 1, count: nil))
        }
        return raws
    }
    
    var contributionsLastYear: Int64 {
        let dateOneYearBefore = Date.dateOneYearBefore
        return typedContributions
            .reduce(into: Dictionary<Date, Int64>()) { dict, contribution in
                if contribution.date < dateOneYearBefore {
                    return
                }
                // Prevent duplicated
                if let count = dict[contribution.date], count > contribution.count {
                    return
                }
                dict[contribution.date] = contribution.count
            }
            .reduce(0) { $0 + $1.value }
    }
    
    func refresh(_ callback: @escaping WikiUserRAW.QueryCallback) {
        guard let solidSite = site else {
            callback(false)
            return
        }
        let total = 2
        var finished = 0
        var bothSucceed = true
        let raw = WikiUserRAW(username, solidSite)
        let onFinished: WikiUserRAW.QueryCallback = { succeed in
            finished += 1
            if finished < total {
                return
            }
            if !succeed {
                bothSucceed = false
            }
            if bothSucceed {
                self.from(raw)
            }
            callback(bothSucceed)
        }
        raw.queryInfo(onFinished)
        raw.queryContributions(onFinished)
    }
    
    func clearContributions() {
        for contribution in typedContributions {
            managedObjectContext?.delete(contribution)
        }
    }
}
