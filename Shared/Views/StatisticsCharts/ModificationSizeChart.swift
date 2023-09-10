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
        
        @inlinable mutating func merge(_ sizeDiff: Int64) {
            if sizeDiff > 0 {
                addition += sizeDiff
            } else {
                deletion += sizeDiff
            }
        }
    }
    
    struct DataItem {
        var month: ChartBinRange<Date>
        var modification: Modification
    }
    
    typealias BriefData = [ DataItem ]
    
    @Environment(\.calendar) private var calendar
    @Environment(\.layoutDirection) private var layoutDirection
    @Environment(\.persistence) private var persistence
    
    @State private var dateInRange = Date()
    @State private var rangeType = RangeType.lastTwelveMonths
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
                Text("ModificationSizeChart.Range.LastTwelveMonths").tag(RangeType.lastTwelveMonths)
                Text("ModificationSizeChart.Range.Year").tag(RangeType.year)
            } label: {
                EmptyView()
            }
            .pickerStyle(.segmented)
            
            if rangeType != .lastTwelveMonths {
                rangeSelector(for: .year, format: .dateTime.year())
            }
            
            VStack(alignment: .leading) {
                Group {
                    if let selection {
                        Text(selection.month.lowerBound, format: .dateTime.year().month())
                    } else {
                        Text("ModificationSizeChart.AllModifications")
                    }
                }
                .font(.callout)
                .foregroundStyle(.secondary)
                
                HStack {
                    Label {
                        Text(
                            selection?.modification.addition ?? statistics.total.addition,
                            format: .byteCount(style: .binary)
                        )
                    } icon: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.green)
                    }
                    Spacer()
                    Label {
                        Text(
                            abs(selection?.modification.deletion ?? statistics.total.deletion),
                            format: .byteCount(style: .binary)
                        )
                    } icon: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.red)
                    }
                }
                .font(.system(.title, design: .rounded, weight: .semibold))
            }
            Chart {
                ForEach(statistics.data, id: \.month.lowerBound) { item in
                    Self.chartContent(of: item, calendar: calendar)
                }
                if let selection {
                    RuleMark(x: .value("ModificationSizeChart.Chart.XAxis", selection.month))
                        .foregroundStyle(Color.secondary)
                }
            }
            .chartForegroundStyleScale(Self.chartForegroundStyles)
            .chartLegend(.hidden)
            .chartXAxis {
                AxisMarks(format: .dateTime.month(), preset: .aligned)
            }
            .chartYAxis {
                AxisMarks(format: .byteCount(style: .binary))
            }
            .chartXSelection(value: $selectedDate)
            .onChange(of: selectedDate) { _, newValue in
                guard let newValue else {
                    selection = nil
                    return
                }
                selection = statistics.data.first { $0.month.contains(newValue) }
            }
            .sensoryFeedback(.selection, trigger: selection) { $1 != nil }
            
        }
        .padding()
        .navigationTitle("ModificationSizeChart.Title")
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
                Label("ModificationSizeChart.Range.Selector.Previous", systemImage: "chevron.backward")
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
                Label("ModificationSizeChart.Range.Selector.Next", systemImage: "chevron.forward")
                    .labelStyle(.iconOnly)
            }
            .disabled(nextDate == nil)
        }
        .buttonStyle(.bordered)
        .frame(maxWidth: .infinity, alignment: .center)
    }
    
    @MainActor
    private func updateStatistics(for dateInRange: Date, in rangeType: RangeType) async {
        let range: ClosedRange<Date>
        switch rangeType {
        case .lastTwelveMonths:
            let today = Date()
            guard let start = calendar.date(byAdding: .month, value: -11, to: today) else { return }
            range = start ... today
        case .year:
            guard
                let yearRange = calendar.range(covers: .init(month: 1, day: 1), around: dateInRange)
            else {
                return
            }
            range = yearRange
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
    let data: ModificationSizeChart.BriefData
    
    var body: some View {
        Chart(data, id: \.month.lowerBound) { item in
            ModificationSizeChart.chartContent(of: item, calendar: calendar)
        }
        .chartForegroundStyleScale(ModificationSizeChart.chartForegroundStyles)
        .chartLegend(.hidden)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
    }
}

fileprivate struct Statistics {
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

extension ModificationSizeChart.DataItem: Equatable {
    static func == (lhs: ModificationSizeChart.DataItem, rhs: ModificationSizeChart.DataItem) -> Bool {
        lhs.month.lowerBound == rhs.month.lowerBound && lhs.month.upperBound == rhs.month.upperBound
    }
}

fileprivate extension ModificationSizeChart {
    static let chartForegroundStyles: KeyValuePairs<String, LinearGradient> = [
        "+": .linearGradient(
            colors: [ .green.opacity(0.5), .clear ],
            startPoint: .top, endPoint: .bottom
        ),
        "-": .linearGradient(
            colors: [ .red.opacity(0.5), .clear ],
            startPoint: .bottom, endPoint: .top
        )
    ]
    
    @ChartContentBuilder
    static func chartContent(of item: DataItem, calendar: Calendar) -> some ChartContent {
        LineMark(
            x: .value("ModificationSizeChart.Chart.XAxis", item.month),
            y: .value("ModificationSizeChart.Chart.YAxis", item.modification.deletion),
            series: .value("ModificationSizeChart.Chart.Deletion", "-")
        )
        .foregroundStyle(.red)
        .interpolationMethod(.monotone)
        
        AreaMark(
            x: .value("ModificationSizeChart.Chart.XAxis", item.month),
            y: .value("ModificationSizeChart.Chart.YAxis", item.modification.deletion)
        )
        .foregroundStyle(by: .value("ModificationSizeChart.Chart.Deletion", "-"))
        .interpolationMethod(.monotone)
        
        LineMark(
            x: .value("ModificationSizeChart.Chart.XAxis", item.month),
            y: .value("ModificationSizeChart.Chart.YAxis", item.modification.addition),
            series: .value("ModificationSizeChart.Chart.Addition", "+")
        )
        .foregroundStyle(.green)
        .interpolationMethod(.monotone)

        AreaMark(
            x: .value("ModificationSizeChart.Chart.XAxis", item.month),
            y: .value("ModificationSizeChart.Chart.YAxis", item.modification.addition)
        )
        .foregroundStyle(by: .value("ModificationSizeChart.Chart.Addition", "+"))
        .interpolationMethod(.monotone)
    }
}

fileprivate extension Persistence {
    func makeStatistics(
        of userID: UUID,
        in range: ClosedRange<Date>,
        calendar: Calendar
    ) async -> Statistics? {
        let bins = DateBins(unit: .month, range: range, calendar: calendar)
        guard !bins.isEmpty else { return nil }
        
        let request = Contribution.fetchRequest()
        request.propertiesToFetch = [ #keyPath(Contribution.sizeDiff), #keyPath(Contribution.timestamp) ]
        request.predicate = .init(
            format: "%K == %@ AND %K != 0 AND %K >= %@ AND %K < %@",
            #keyPath(Contribution.userID), userID as NSUUID,
            #keyPath(Contribution.sizeDiff),
            #keyPath(Contribution.timestamp), bins[bins.startIndex].lowerBound as NSDate,
            #keyPath(Contribution.timestamp), bins[bins.endIndex].upperBound as NSDate
        )
        return await container.performBackgroundTask { context in
            guard let contributions = try? context.fetch(request) else { return nil }

            var statistics = Statistics(
                contributionsCount: contributions.count,
                data: bins.map { .init(month: $0, modification: .init(addition: 0, deletion: 0))}
            )
            
            for contribution in contributions {
                guard let timestamp = contribution.timestamp else { continue }
                let binIndex = bins.index(for: timestamp)
                if (binIndex >= 0) && (binIndex < bins.count) {
                    statistics.data[binIndex].modification.merge(contribution.sizeDiff)
                    statistics.total.merge(contribution.sizeDiff)
                }
            }
            
            return statistics
        }
    }
}
