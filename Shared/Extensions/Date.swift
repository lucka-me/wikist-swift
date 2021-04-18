//
//  Date.swift
//  Wikist
//
//  Created by Lucka on 12/4/2021.
//

import Foundation

extension Date {
    static let secondsInDay = 24 * 3600
    static let daysInYear = 365
    
    static var today: Date {
        Calendar.iso8601.startOfDay(for: Date())
    }
    
    static var weekday: Int {
        Calendar.iso8601.component(.weekday, from: today)
    }
    
    static var dateOneYearBefore: Date {
        .init(timeInterval: .init(-1 * secondsInDay * daysInYear), since: today)
    }
    
    static var dateOneYearBeforeAlignedWithWeek: Date {
        .init(timeInterval: .init(-1 * secondsInDay * (daysInYear + weekday - 1)), since: today)
    }
    
    static var iso8601OneYearBefore: String {
        ISO8601DateFormatter.shared.string(from: dateOneYearBefore)
    }
    
    static var iso8601OneYearBeforeAlignedWithWeek: String {
        ISO8601DateFormatter.shared.string(from: dateOneYearBeforeAlignedWithWeek)
    }
}
