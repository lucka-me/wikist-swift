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

    @NSManaged public var dataId: UUID
    @NSManaged public var username: String
    @NSManaged public var site: WikiSite?
    @NSManaged public var userId: Int64
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
    
    static func predicate(of dataId: UUID) -> NSPredicate {
        .init(format: "dataId = %@", dataId as CVarArg)
    }
}

extension WikiUser {
    static func from(
        _ raw: WikiUserRAW, _ dataId: UUID,
        with context: NSManagedObjectContext,
        createMeta: Bool = false
    ) -> WikiUser {
        let object = WikiUser(context: context)
        object.dataId = dataId
        object.username = raw.username
        object.site = raw.site
        object.from(raw)
        if createMeta {
            object.createMeta()
        }
        return object
    }
    
    func from(_ raw: WikiUserRAW) {
        if raw.username != username || raw.site != site {
            return
        }
        userId = raw.userId
        registration = raw.registration
        edits = raw.edits
        guard let solidContext = managedObjectContext else {
            return
        }
        let existings = typedContributions
        for (date, count) in raw.contributions {
            if let existing = existings.first(where: { $0.date == date }) {
                existing.count = count
                continue
            }
            let contribution = DailyContribution(context: solidContext)
            contribution.date = date
            contribution.count = count
            addToContributions(contribution)
        }
        let deadline = Date.dateOneYearBeforeAlignedWithWeek
        for contribution in existings {
            if contribution.date < deadline {
                solidContext.delete(contribution)
            }
        }
    }
}

extension WikiUser {
    
    var metaPredicate: NSPredicate {
        return WikiUserMeta.predicate(of: dataId)
    }
    
    var meta: WikiUserMeta? {
        guard let solidContext = managedObjectContext else {
            return nil
        }
        let request: NSFetchRequest<WikiUserMeta> = WikiUserMeta.fetchRequest()
        request.predicate = metaPredicate
        return try? solidContext.fetch(request).first
    }
    
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
    
    func refresh(full: Bool = false, _ callback: @escaping WikiUserRAW.QueryCallback) {
        if full {
            guard let solidSite = site else {
                callback(false)
                return
            }
            solidSite.refresh { succeed in
                if !succeed {
                    callback(false)
                    return
                }
                self.refreshSelf(callback)
            }
        } else {
            refreshSelf(callback)
        }
    }
    
    private func refreshSelf(_ callback: @escaping WikiUserRAW.QueryCallback) {
        guard let solidSite = site else {
            callback(false)
            return
        }
        let raw = WikiUserRAW(username, solidSite)
        raw.queryAll { succeed in
            if succeed {
                self.from(raw)
            }
            callback(succeed)
        }
    }
    
    private func createMeta() {
        guard
            let solidContext = managedObjectContext,
            let solidSite = site
        else {
            return
        }
        let meta = WikiUserMeta(context: solidContext)
        meta.dataId = dataId
        meta.username = username
        meta.site = solidSite.url
    }
}
