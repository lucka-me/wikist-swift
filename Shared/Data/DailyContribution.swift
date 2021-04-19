//
//  DailyContribution+CoreDataClass.swift
//  Wikist
//
//  Created by Lucka on 11/4/2021.
//
//

import CoreData

@objc(DailyContribution)
public final class DailyContribution: NSManagedObject, NSManagedObjectWithFetchRequest {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<DailyContribution> {
        return NSFetchRequest<DailyContribution>(entityName: "DailyContribution")
    }
}

extension DailyContribution {

    @NSManaged public var date: Date
    @NSManaged public var count: Int64
    @NSManaged public var user: WikiUser?

}

extension DailyContribution : Identifiable {

}

extension DailyContribution {
    var raw: DailyContributionRAW {
        .init(date: date, count: count)
    }
}
