//
//  DailyContribution+CoreDataClass.swift
//  Wikist
//
//  Created by Lucka on 11/4/2021.
//
//

import Foundation
import CoreData

@objc(DailyContribution)
public class DailyContribution: NSManagedObject {

}

extension DailyContribution {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DailyContribution> {
        return NSFetchRequest<DailyContribution>(entityName: "DailyContribution")
    }

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
