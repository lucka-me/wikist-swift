//
//  Calendar.swift
//  Wikist
//
//  Created by Lucka on 12/4/2021.
//

import Foundation

typealias DateRange = Range<Date>

extension Calendar {
    func days(from: Date, to: Date) -> Int {
        dateComponents([ .day ], from: from, to: to).day ?? 0
    }
    
    func days(in interval: DateRange) -> Int {
        days(from: interval.lowerBound, to: interval.upperBound)
    }
    
    func startOfDay(forNext days: Int, of date: Date) -> Date? {
        guard let nextDay = self.date(byAdding: .day, value: days, to: date) else { return nil }
        return startOfDay(for: nextDay)
    }
    
    func dayInterval(for date: Date) -> DateRange? {
        guard let next = self.startOfDay(forNext: 1, of: date) else { return nil }
        return startOfDay(for: date) ..< next
    }
    
    func range(covers components: DateComponents, around date: Date) -> ClosedRange<Date>? {
        guard
            let start = nextDate(
                after: date, matching: components, matchingPolicy: .nextTime, direction: .backward
            ),
            let end = nextDate(
                after: date, matching: components, matchingPolicy: .nextTime, direction: .forward
            )
        else {
            return nil
        }
        return start ... end
    }
}
