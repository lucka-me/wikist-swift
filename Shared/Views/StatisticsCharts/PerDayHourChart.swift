//
//  HoursChart.swift
//  Wikist
//
//  Created by Lucka on 16/7/2022.
//

import Charts
import CoreData
import SwiftUI

struct PerDayHourChart: View {
    struct DataItem {
        var hour: ChartBinRange<Date>
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
    
    @State private var dateInRange = Date()
    @State private var rangeType = RangeType.all
    @State private var selectedDate: Date? = nil
    @State private var selection: DataItem? = nil
    @State private var statistics = Statistics()
    
    private let user: User
    
    init(user: User) {
        self.user = user
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Picker(selection: $rangeType.animation(.easeInOut)) {
                Text("PerDayHourChart.Range.All").tag(RangeType.all)
                Text("PerDayHourChart.Range.Year").tag(RangeType.year)
                Text("PerDayHourChart.Range.Month").tag(RangeType.month)
                Text("PerDayHourChart.Range.Week").tag(RangeType.week)
            } label: {
                EmptyView()
            }
            .pickerStyle(.segmented)
            
            switch rangeType {
            case .all:
                EmptyView()
            case .year:
                rangeSelector(for: .year, format: .dateTime.year())
            case .month:
                rangeSelector(for: .month, format: .dateTime.year().month())
            case .week:
                rangeSelector(for: .weekOfYear, format: .dateTime.year().week())
            }
            
            VStack(alignment: .leading) {
                Group {
                    if let selection {
                        Text(selection.hour.lowerBound, format: .dateTime.hour().minute())
                    } else {
                        Text("PerDayHourChart.AllContributions")
                    }
                }
                .font(.callout)
                .foregroundStyle(.secondary)
                
                Text(selection?.count ?? statistics.contributionsCount, format: .number)
                    .font(.system(.title, design: .rounded, weight: .semibold))
            }
            
            Chart {
                ForEach(statistics.data, id: \.hour.lowerBound) { item in
                    Self.chartContent(of: item, calendar: calendar)
                }
                if let selection {
                    RuleMark(x: .value("PerDayHourChart.Chart.XAxis", selection.hour))
                    .foregroundStyle(Color.secondary)
                }
            }
            .chartXSelection(value: $selectedDate)
            .onChange(of: selectedDate) { _, newValue in
                guard let newValue else {
                    selection = nil
                    return
                }
                selection = statistics.data.first { $0.hour.contains(newValue) }
            }
        }
        .padding()
        .navigationTitle("PerDayHourChart.Title")
        .onChange(of: rangeType) { _, newValue in
            Task {
                await updateStatistics(for: dateInRange, in: newValue)
            }
        }
        .onChange(of: dateInRange) { _, newValue in
            Task {
                await updateStatistics(for: newValue, in: rangeType)
            }
        }
        .onContributionsUpdated(userID: user.uuid) {
            await updateStatistics(for: dateInRange, in: rangeType)
        }
        .onReceiveCalendarDayChanged { day in
            Task {
                await updateStatistics(for: dateInRange, in: rangeType)
            }
        }
        .task {
            await updateStatistics(for: dateInRange, in: rangeType)
        }
    }
    
    @ViewBuilder
    private func rangeSelector(for component: Calendar.Component, format: Date.FormatStyle) -> some View {
        HStack {
            let previousDate = calendar.date(byAdding: component, value: -1, to: dateInRange)
            Button {
                if let previousDate {
                    withAnimation(.easeInOut) {
                        dateInRange = previousDate
                    }
                }
            } label: {
                Label("PerDayHourChart.Range.Selector.Previous", systemImage: "chevron.backward")
                    .labelStyle(.iconOnly)
            }
            .disabled(previousDate == nil)
            
            Text(dateInRange, format: format)
            
            let nextDate: Date? = {
                guard
                    let value = calendar.date(byAdding: component, value: 1, to: dateInRange),
                    value <= Date()
                else {
                    return nil
                }
                return value
            }()
            Button {
                if let nextDate {
                    withAnimation(.easeInOut) {
                        dateInRange = nextDate
                    }
                }
            } label: {
                Label("PerDayHourChart.Range.Selector.Next", systemImage: "chevron.forward")
                    .labelStyle(.iconOnly)
            }
            .disabled(nextDate == nil)
        }
        .buttonStyle(.bordered)
        .frame(maxWidth: .infinity, alignment: .center)
    }
    
    @MainActor
    private func updateStatistics(for dateInRange: Date, in rangeType: RangeType) async {
        let range: ClosedRange<Date>?
        switch rangeType {
        case .all:
            range = nil
        case .year:
            range = calendar.range(covers: .init(month: 1, day: 1), around: dateInRange)
        case .month:
            range = calendar.range(covers: .init(day: 1), around: dateInRange)
        case .week:
            range = calendar.range(covers: .init(weekday: 1), around: dateInRange)
        }
        guard
            let userID = user.uuid,
            let statistics = await persistence.makeStatistics(of: userID, in: range, calendar: calendar)
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
    
    let data: PerDayHourChart.BriefData
    
    var body: some View {
        Chart(data, id: \.hour.lowerBound) { item in
            PerDayHourChart.chartContent(of: item, calendar: calendar)
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
    }
}

fileprivate struct Statistics {
    var contributionsCount: Int = 0
    var data: PerDayHourChart.BriefData = [ ]
}

extension PerDayHourChart: StatisticsChart {
    static let briefTitleKey: LocalizedStringKey = "PerDayHourChart.BriefTitle"
    static let briefSystemImage: String = "clock"
    
    static func card(data: BriefData, action: @escaping () -> Void) -> some View {
        StatisticsChartCard(Self.self, action: action) {
            BriefChartView(data: data)
        }
    }
}

fileprivate extension PerDayHourChart {
    @ChartContentBuilder
    static func chartContent(of item: DataItem, calendar: Calendar) -> some ChartContent {
        BarMark(
            x: .value("PerDayHourChart.Chart.XAxis", item.hour),
            y: .value("PerDayHourChart.Chart.YAxis", item.count)
        )
    }
}

fileprivate extension Persistence {
    func makeStatistics(
        of userID: UUID,
        in range: ClosedRange<Date>?,
        calendar: Calendar
    ) async -> Statistics? {
        let today = Date()
        guard let hoursRange = calendar.range(covers: .init(hour: 0), around: today) else { return nil }
        let bins = DateBins(unit: .hour, range: hoursRange, calendar: calendar)
        
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
            var statistics = Statistics(
                contributionsCount: contributions.count,
                data: bins.map { .init(hour: $0, count: 0) }
            )
            for contribution in contributions {
                guard let timestamp = contribution.timestamp else { continue }
                statistics.data[calendar.component(.hour, from: timestamp)].count += 1
            }
            return statistics
        }
    }
}
