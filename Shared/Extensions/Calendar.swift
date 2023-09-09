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
    
    func weekInterval(for date: Date) -> DateRange? {
        let start: Date
        if component(.weekday, from: date) == 1 {
            start = date
        } else {
            guard let result = nextDate(
                after: date,
                matching: .init(calendar: self, weekday: 1),
                matchingPolicy: .nextTime,
                direction: .backward
            ) else {
                return nil
            }
            start = result
        }
        guard
            let end = nextDate(
                after: date,
                matching: .init(calendar: self, weekday: 1),
                matchingPolicy: .nextTime,
                direction: .forward
            )
        else {
            return nil
        }
        return startOfDay(for: start) ..< startOfDay(for: end)
    }
    
    func nextWeekInterval(of interval: DateRange, direction: SearchDirection = .forward) -> DateRange? {
        if direction == .forward {
            return weekInterval(for: interval.upperBound)
        }
        guard let previous = date(byAdding: .day, value: -1, to: interval.lowerBound) else { return nil }
        return weekInterval(for: previous)
    }
    
    func monthInterval(for date: Date) -> DateRange? {
        let start: Date
        if component(.day, from: date) == 1 {
            start = date
        } else {
            guard let result = nextDate(
                after: date,
                matching: .init(calendar: self, day: 1),
                matchingPolicy: .nextTime,
                direction: .backward
            ) else {
                return nil
            }
            start = result
        }
        guard
            let end = nextDate(
                after: date,
                matching: .init(calendar: self, day: 1),
                matchingPolicy: .nextTime,
                direction: .forward
            )
        else {
            return nil
        }
        return startOfDay(for: start) ..< startOfDay(for: end)
    }
    
    func nextMonthInterval(of interval: DateRange, direction: SearchDirection = .forward) -> DateRange? {
        if direction == .forward {
            return monthInterval(for: interval.upperBound)
        }
        guard let previous = date(byAdding: .day, value: -1, to: interval.lowerBound) else { return nil }
        return monthInterval(for: previous)
    }
    
    func yearInterval(for date: Date) -> DateRange? {
        let start: Date
        if component(.month, from: date) == 1 && component(.day, from: date) == 1 {
            start = date
        } else {
            guard let result = nextDate(
                after: date,
                matching: .init(calendar: self, month: 1, day: 1),
                matchingPolicy: .nextTime,
                direction: .backward
            ) else {
                return nil
            }
            start = result
        }
        guard
            let end = nextDate(
                after: date,
                matching: .init(calendar: self, month: 1, day: 1),
                matchingPolicy: .nextTime,
                direction: .forward
            )
        else {
            return nil
        }
        return startOfDay(for: start) ..< startOfDay(for: end)
    }
    
    func nextYearInterval(of interval: DateRange, direction: SearchDirection = .forward) -> DateRange? {
        if direction == .forward {
            return yearInterval(for: interval.upperBound)
        }
        guard let previous = date(byAdding: .day, value: -1, to: interval.lowerBound) else { return nil }
        return yearInterval(for: previous)
    }
    
    func rangeOfYear(around date: Date) -> ClosedRange<Date>? {
        let components = DateComponents(month: 1, day: 1)
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
