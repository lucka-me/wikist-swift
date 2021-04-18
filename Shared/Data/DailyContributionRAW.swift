//
//  DailyContributionRAW.swift
//  Wikist
//
//  Created by Lucka on 15/4/2021.
//

import Foundation

struct DailyContributionRAW: Identifiable {
    
    var id: Date { date }
    
    var date: Date
    var count: Int64?
}
