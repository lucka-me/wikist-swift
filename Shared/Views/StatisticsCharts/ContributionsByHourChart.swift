//
//  ContributionsByHourChart.swift
//  Wikist
//
//  Created by Lucka on 16/7/2022.
//

import Charts
import CoreData
import SwiftUI

struct ContributionsByHourChart: View {
    struct DataItem {
        var hour: Date
        var count: Int
    }
    
    private enum RangeType {
        case all
        case year
        case month
        case week
    }
    
    typealias BriefData = [ DataItem ]
    
    @Environment(\.calendar) private var calendar
    @Environment(\.layoutDirection) private var layoutDirection
    @Environment(\.persistence) private var persistence
    
    @State private var range: DateRange? = nil
    @State private var rangeType = RangeType.all
    
    @State private var selection: Date? = nil
    @State private var statistics = Statistics()
    
    private let user: User
    
    init(user: User) {
        self.user = user
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Picker(selection: $rangeType.animation(.easeInOut)) {
                Text("ContributionsByHourChart.Range.All").tag(RangeType.all)
                Text("ContributionsByHourChart.Range.Year").tag(RangeType.year)
                Text("ContributionsByHourChart.Range.Month").tag(RangeType.month)
                Text("ContributionsByHourChart.Range.Week").tag(RangeType.week)
            } label: {
                EmptyView()
            }
            .pickerStyle(.segmented)
            
            if rangeType != .all {
                rangeSelector
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            
            VStack(alignment: .leading) {
                Group {
                    if let selection {
                        Text(selection, format: .dateTime.hour().minute())
                    } else {
                        Text("ContributionsByHourChart.AllContributions")
                    }
                }
                .font(.callout)
                .foregroundStyle(.secondary)
                
                Text(selectedDataItem?.count ?? statistics.contributionsCount, format: .number)
                    .font(.system(.title, design: .rounded, weight: .semibold))
            }

            ContributionsByHourChart.chartView(of: statistics.data, calendar: calendar)
                .chartXSelection(value: $selection)
        }
        .padding()
        .navigationTitle("ContributionsByHourChart.Title")
        .onChange(of: rangeType) { _, type in
            let now = Date()
            if type == .all {
                range = nil
            } else if let range, !range.contains(now) {
                switch rangeType {
                case .all: break
                case .year: self.range = calendar.yearInterval(for: range.lowerBound)
                case .month: self.range = calendar.monthInterval(for: range.lowerBound)
                case .week: self.range = calendar.weekInterval(for: range.lowerBound)
                }
            } else {
                switch rangeType {
                case .all: break
                case .year: range = calendar.yearInterval(for: now)
                case .month: range = calendar.monthInterval(for: now)
                case .week: range = calendar.weekInterval(for: now)
                }
            }
        }
        .onChange(of: range) { _, range in
            Task {
                await updateStatistics(in: range)
            }
        }
        .onContributionsUpdated(userID: user.uuid) {
            await updateStatistics(in: statistics.range)
        }
        .onReceiveCalendarDayChanged { day in
            Task {
                await updateStatistics(in: statistics.range, today: day)
            }
        }
        .task {
            await updateStatistics(in: nil)
        }
    }
    
    @ViewBuilder
    private var rangeSelector: some View {
        HStack {
            Button {
                guard let range else { return }
                withAnimation(.easeInOut) {
                    switch rangeType {
                    case .all: break
                    case .year: self.range = calendar.nextYearInterval(of: range, direction: .backward)
                    case .month: self.range = calendar.nextMonthInterval(of: range, direction: .backward)
                    case .week: self.range = calendar.nextWeekInterval(of: range, direction: .backward)
                    }
                }
            } label: {
                Label("ContributionsByHourChart.Range.Selector.Previous", systemImage: "chevron.backward")
                    .labelStyle(.iconOnly)
            }
            
            if let range, rangeType != .all {
                switch rangeType {
                    case .all: EmptyView()
                    case .year: Text(range.lowerBound, format: .dateTime.year())
                    case .month: Text(range.lowerBound, format: .dateTime.year().month())
                    case .week: Text(range.lowerBound, format: .dateTime.year().week())
                }
            }
            
            Button {
                guard let range else { return }
                withAnimation(.easeInOut) {
                    switch rangeType {
                    case .all: break
                    case .year: self.range = calendar.nextYearInterval(of: range, direction: .forward)
                    case .month: self.range = calendar.nextMonthInterval(of: range, direction: .forward)
                    case .week: self.range = calendar.nextWeekInterval(of: range, direction: .forward)
                    }
                }
            } label: {
                Label("ContributionsByHourChart.Range.Selector.Next", systemImage: "chevron.forward")
                    .labelStyle(.iconOnly)
            }
        }
        .buttonStyle(.bordered)
    }
    
    private var selectedDataItem: DataItem? {
        guard let selection else { return nil }
        return statistics.data.first { $0.hour == selection }
    }
    
    @MainActor
    private func updateStatistics(in range: DateRange?, today: Date = .init()) async {
        guard
            let userID = user.uuid,
            let statistics = await persistence.makeStatistics(of: userID, in: range, today: today, calendar: calendar)
        else {
            return
        }
        withAnimation(.easeInOut) {
            selection = nil
            self.statistics = statistics
        }
    }
}

fileprivate struct BriefChartView: View {
    @Environment(\.calendar) private var calendar
    
    let data: ContributionsByHourChart.BriefData
    
    var body: some View {
        ContributionsByHourChart.chartView(of: data, calendar: calendar)
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
    }
}

fileprivate struct Statistics {
    var range: DateRange? = nil
    var contributionsCount: Int = 0
    var data: ContributionsByHourChart.BriefData = [ ]
}

extension ContributionsByHourChart: StatisticsChart {
    static let briefTitleKey: LocalizedStringKey = "ContributionsByHourChart.BriefTitle"
    static let briefSystemImage: String = "clock"
    
    static func card(data: BriefData, action: @escaping () -> Void) -> some View {
        StatisticsChartCard(Self.self, action: action) {
            BriefChartView(data: data)
        }
    }
}

fileprivate extension ContributionsByHourChart {
    @ViewBuilder
    static func chartView(of data: BriefData, calendar: Calendar) -> some View {
        Chart(data, id: \.hour) { item in
            BarMark(
                x: .value("ContributionsByHourChart.Chart.XAxis", item.hour, unit: .hour, calendar: calendar),
                y: .value("ContributionsByHourChart.Chart.YAxis", item.count)
            )
        }
    }
}

fileprivate extension Persistence {
    func makeStatistics(
        of userID: UUID,
        in range: DateRange?,
        today: Date,
        calendar: Calendar
    ) async -> Statistics? {
        let request = Contribution.fetchRequest()
        request.propertiesToFetch = [ #keyPath(Contribution.timestamp) ]
        if let range {
            request.predicate = .init(
                format: "%K == %@ AND %K >= %@ AND %K < %@",
                #keyPath(Contribution.userID), userID as NSUUID,
                #keyPath(Contribution.timestamp), range.lowerBound as NSDate,
                #keyPath(Contribution.timestamp), range.upperBound as NSDate
            )
        } else {
            request.predicate = .init(format: "%K == %@", #keyPath(Contribution.userID), userID as NSUUID)
        }
        return await container.performBackgroundTask { context in
            guard let contributions = try? context.fetch(request) else { return nil }
            var statistics = Statistics(range: range, contributionsCount: contributions.count)
            var countsByHour: [ Int : Int ] = (0 ..< 24).reduce(into: [ : ]) { $0[$1] = 0 }
            for contribution in contributions {
                guard let timestamp = contribution.timestamp else { continue }
                countsByHour[calendar.component(.hour, from: timestamp), default: 0] += 1
            }
            statistics.data = countsByHour.sorted { $0.key < $1.key }.map { item in
                .init(hour: calendar.date(bySettingHour: item.key, minute: 0, second: 0, of: today)!, count: item.value)
            }
            return statistics
        }
    }
}
