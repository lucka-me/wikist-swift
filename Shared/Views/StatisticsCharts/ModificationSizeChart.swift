//
//  ModificationSizeChart.swift
//  Wikist
//
//  Created by Lucka on 10/12/2022.
//

import Charts
import SwiftUI

struct ModificationSizeChart: View {
    private enum RangeType {
        case lastTwelveMonths
        case year
    }
    
    struct Modification {
        var addition: Int64
        var deletion: Int64
        
        @inlinable mutating func add(_ sizeDiff: Int64) {
            if sizeDiff > 0 {
                addition += sizeDiff
            } else {
                deletion += sizeDiff
            }
        }
    }
    
    struct DataItem {
        var date: Date
        var modification: Modification
    }
    
    typealias BriefData = [ DataItem ]
    
    @Environment(\.calendar) private var calendar
    @Environment(\.layoutDirection) private var layoutDirection
    @Environment(\.persistence) private var persistence
    
    @State private var range: ClosedMonthRange
    @State private var rangeType = RangeType.lastTwelveMonths
    @State private var selection: Date? = nil
    @State private var statistics = Statistics()
    
    private let user: User
    
    init(user: User) {
        self.user = user
        
        let monthNow = Calendar.current.month(of: .init())
        let monthRange = monthNow.advanced(by: -11) ... monthNow
        
        self._range = .init(initialValue: monthRange)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Picker(selection: $rangeType.animation(.easeInOut)) {
                Text("ModificationSizeChart.Range.LastTwelveMonths").tag(RangeType.lastTwelveMonths)
                Text("ModificationSizeChart.Range.Year").tag(RangeType.year)
            } label: {
                EmptyView()
            }
            .pickerStyle(.segmented)
            
            if rangeType != .lastTwelveMonths {
                rangeSelector
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            
            VStack(alignment: .leading) {
                Group {
                    if let selection {
                        Text(selection, format: .dateTime.year().month())
                    } else {
                        Text("ModificationSizeChart.AllModifications")
                    }
                }
                .font(.callout)
                .foregroundStyle(.secondary)
                
                let currentSelectedItem = selectedDataItem
                
                HStack {
                    Label {
                        Text(
                            currentSelectedItem?.modification.addition ?? statistics.total.addition,
                            format: .byteCount(style: .binary)
                        )
                    } icon: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.green)
                    }
                    Spacer()
                    Label {
                        Text(
                            abs(currentSelectedItem?.modification.deletion ?? statistics.total.deletion),
                            format: .byteCount(style: .binary)
                        )
                    } icon: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.red)
                    }
                }
                .font(.system(.title, design: .rounded, weight: .semibold))
            }
            
            ModificationSizeChart.chartView(of: statistics.data, calendar: calendar)
                .chartYAxis {
                    AxisMarks(format: .byteCount(style: .binary))
                }
                .chartXSelection(value: $selection)
        }
        .padding()
        .navigationTitle("ModificationSizeChart.Title")
        .onChange(of: rangeType) { _, newValue in
            let monthNow = calendar.month(of: .init())
            switch newValue {
            case .lastTwelveMonths:
                range = monthNow.advanced(by: -11) ... monthNow
            case .year:
                range = Month(year: monthNow.year, month: 1) ... Month(year: monthNow.year, month: 12)
            }
        }
        .onChange(of: range) { _, newValue in
            Task {
                await updateStatistics(in: newValue)
            }
        }
        .onContributionsUpdated(userID: user.uuid) {
            await updateStatistics(in: range)
        }
        .task {
            await updateStatistics(in: range)
        }
    }
    
    @ViewBuilder
    private var rangeSelector: some View {
        HStack {
            Button {
                withAnimation(.easeInOut) {
                    switch rangeType {
                    case .lastTwelveMonths: break
                    case .year:
                        let year = range.lowerBound.year - 1
                        self.range = .init(year: year, month: 1) ... .init(year: year, month: 12)
                    }
                }
            } label: {
                Label("ModificationSizeChart.Range.Selector.Previous", systemImage: "chevron.backward")
                    .labelStyle(.iconOnly)
            }
            
            if rangeType != .lastTwelveMonths {
                switch rangeType {
                case .lastTwelveMonths: EmptyView()
                case .year: Text(calendar.start(of: range.lowerBound)!, format: .dateTime.year())
                }
            }
            
            Button {
                withAnimation(.easeInOut) {
                    switch rangeType {
                    case .lastTwelveMonths: break
                    case .year:
                        let year = range.lowerBound.year + 1
                        self.range = .init(year: year, month: 1) ... .init(year: year, month: 12)
                    }
                }
            } label: {
                Label("ModificationSizeChart.Range.Selector.Next", systemImage: "chevron.forward")
                    .labelStyle(.iconOnly)
            }
        }
        .buttonStyle(.bordered)
    }
    
    private var selectedDataItem: DataItem? {
        guard let selection else { return nil }
        return statistics.data.first { $0.date == selection }
    }
    
    @MainActor
    private func updateStatistics(in range: ClosedMonthRange) async {
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
    let data: ModificationSizeChart.BriefData
    
    var body: some View {
        ModificationSizeChart.chartView(of: data, calendar: calendar)
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
    }
}

fileprivate struct Statistics {
    var range: ClosedMonthRange? = nil
    var total = ModificationSizeChart.Modification(addition: 0, deletion: 0)
    var contributionsCount: Int = 0
    var data: ModificationSizeChart.BriefData = [ ]
}

extension ModificationSizeChart: StatisticsChart {
    static let briefTitleKey: LocalizedStringKey = "ModificationSizeChart.BriefTitle"
    static let briefSystemImage: String = "plus.forwardslash.minus"
    
    static func card(data: BriefData, action: @escaping () -> Void) -> some View {
        StatisticsChartCard(Self.self, action: action) {
            BriefChartView(data: data)
        }
    }
}

fileprivate extension ModificationSizeChart {
    @ViewBuilder
    static func chartView(of data: BriefData, calendar: Calendar) -> some View {
        Chart(data, id: \.date) { item in
            LineMark(
                x: .value("ModificationSizeChart.Chart.XAxis", item.date, unit: .month, calendar: calendar),
                y: .value("ModificationSizeChart.Chart.YAxis", item.modification.deletion),
                series: .value("ModificationSizeChart.Chart.Deletion", "Deletion")
            )
            .foregroundStyle(.red)
            .interpolationMethod(.monotone)
            
            AreaMark(
                x: .value("ModificationSizeChart.Chart.XAxis", item.date, unit: .month, calendar: calendar),
                y: .value("ModificationSizeChart.Chart.YAxis", item.modification.deletion)
            )
            .foregroundStyle(by: .value("ModificationSizeChart.Chart.Deletion", "Deletion"))
            .interpolationMethod(.monotone)
            
            LineMark(
                x: .value("ModificationSizeChart.Chart.XAxis", item.date, unit: .month, calendar: calendar),
                y: .value("ModificationSizeChart.Chart.YAxis", item.modification.addition),
                series: .value("ModificationSizeChart.Chart.Addition", "Addition")
            )
            .foregroundStyle(.green)
            .interpolationMethod(.monotone)

            AreaMark(
                x: .value("ModificationSizeChart.Chart.XAxis", item.date, unit: .month, calendar: calendar),
                y: .value("ModificationSizeChart.Chart.YAxis", item.modification.addition)
            )
            .foregroundStyle(by: .value("ModificationSizeChart.Chart.Addition", "Addition"))
            .interpolationMethod(.monotone)
        }
        .chartForegroundStyleScale(
            [
                "Addition": .linearGradient(
                    colors: [ .green.opacity(0.5), .clear ],
                    startPoint: .top, endPoint: .bottom
                ),
                "Deletion": .linearGradient(
                    colors: [ .red.opacity(0.5), .clear ],
                    startPoint: .bottom, endPoint: .top
                )
            ]
        )
        .chartLegend(.hidden)
    }
}

fileprivate extension Persistence {
    func makeStatistics(
        of userID: UUID,
        in range: ClosedMonthRange,
        calendar: Calendar
    ) async -> Statistics? {
        guard let dateRange = calendar.dateRange(from: range.lowerBound, to: range.upperBound) else { return nil }
        let request = Contribution.fetchRequest()
        request.propertiesToFetch = [ #keyPath(Contribution.sizeDiff), #keyPath(Contribution.timestamp) ]
        request.predicate = .init(
            format: "%K == %@ AND %K != 0 AND %K >= %@ AND %K < %@",
            #keyPath(Contribution.userID), userID as NSUUID,
            #keyPath(Contribution.sizeDiff),
            #keyPath(Contribution.timestamp), dateRange.lowerBound as NSDate,
            #keyPath(Contribution.timestamp), dateRange.upperBound as NSDate
        )
        return await container.performBackgroundTask { context in
            guard let contributions = try? context.fetch(request) else { return nil }
            var statistics = Statistics(range: range, contributionsCount: contributions.count)
            
            var modificationsByMonth: [ Month : ModificationSizeChart.Modification ] =
            range.reduce(into: [ : ]) { $0[$1] = .init(addition: 0, deletion: 0) }
            for contribution in contributions {
                guard let timestamp = contribution.timestamp else { continue }
                let month = calendar.month(of: timestamp)
                if range.contains(month) {
                    modificationsByMonth[month]?.add(contribution.sizeDiff)
                    statistics.total.add(contribution.sizeDiff)
                }
            }
            
            let components = calendar.dateComponents([ .year, .month ], from: .init())
            statistics.data = modificationsByMonth.sorted { $0.key < $1.key }.map { item in
                    .init(date: calendar.date(from: components.settingValue(item.key))!, modification: item.value)
            }
            return statistics
        }
    }
}
