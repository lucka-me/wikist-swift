//
//  ModificationSizeChart.swift
//  Wikist
//
//  Created by Lucka on 10/12/2022.
//

import Charts
import SwiftUI

struct ModificationSizeChartBuilder: StatisticsChartBuilder {
    
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
    
    let briefTitleKey: LocalizedStringKey = "ModificationSizeChart.BriefTitle"
    let briefSystemImage: String = "plus.forwardslash.minus"
    
    func makeBriefChart(data: [ DataItem ]) -> some View {
        BriefChartView(data: data)
    }
    
    func makeChart(user: User) -> some View {
        ChartView(user: user)
    }
}

extension StatisticsChart where Builder == ModificationSizeChartBuilder {
    @ViewBuilder
    static func modificationSize(user: User, briefData: Builder.BriefData) -> some View {
        Self.init(user: user, briefData: briefData)
    }
}

fileprivate extension ModificationSizeChartBuilder {
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

fileprivate typealias ChartBuilder = ModificationSizeChartBuilder

fileprivate struct BriefChartView: View {
    
    @Environment(\.calendar) private var calendar
    let data: ChartBuilder.BriefData
    
    var body: some View {
        ChartBuilder.chartView(of: data, calendar: calendar)
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
    }
}

fileprivate struct ChartView: View {
    
    private typealias DataItem = ChartBuilder.DataItem
    private typealias ChartData = ChartBuilder.BriefData
    
    private enum RangeType {
        case lastTwelveMonths
        case year
    }
    
    private struct Statistics {
        var range: ClosedMonthRange? = nil
        var total = ChartBuilder.Modification(addition: 0, deletion: 0)
        var contributionsCount: Int = 0
        var data: ChartData = [ ]
    }
    
    @FetchRequest private var contributions: FetchedResults<Contribution>
    
    @Environment(\.calendar) private var calendar
    @Environment(\.layoutDirection) private var layoutDirection
    
    @State private var range: ClosedMonthRange
    @State private var rangeType = RangeType.lastTwelveMonths
    @State private var selection: DataItem? = nil
    @State private var statistics = Statistics()
    
    private let user: User
    
    init(user: User) {
        self.user = user
        
        let monthNow = Calendar.current.month(of: .init())
        let monthRange = monthNow.advanced(by: -11) ... monthNow
        let dateRange = Calendar.current.dateRange(from: monthRange.lowerBound, to: monthRange.upperBound)!
        
        self._range = .init(initialValue: monthRange)
        
        self._contributions = .init(
            entity: Contribution.entity(),
            sortDescriptors: [ .init(keyPath: \Contribution.timestamp, ascending: false) ],
            predicate: .init(
                format: "%K == %@ AND %K != 0 AND %K >= %@ AND %K < %@",
                #keyPath(Contribution.userID), user.uuid! as NSUUID,
                #keyPath(Contribution.sizeDiff),
                #keyPath(Contribution.timestamp), dateRange.lowerBound as NSDate,
                #keyPath(Contribution.timestamp), dateRange.upperBound as NSDate
            )
        )
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
                        Text(selection.date, format: .dateTime.year().month())
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
            
            ChartBuilder.chartView(of: statistics.data, calendar: calendar)
                .chartYAxis {
                    AxisMarks(format: .byteCount(style: .binary))
                }
                .chartOverlay { chartProxy in
                    GeometryReader { geometryProxy in
                        Rectangle().fill(.clear).contentShape(Rectangle())
                            .gesture(gesture(chartProxy: chartProxy, geometryProxy: geometryProxy))
                    }
                }
                .chartBackground { chartProxy in
                    GeometryReader { geonetryProxy in
                        if let selection {
                            let dateInterval = calendar.dateInterval(of: .month, for: selection.date)!
                            let startPositionX1 = chartProxy.position(forX: dateInterval.start) ?? 0
                            let startPositionX2 = chartProxy.position(forX: dateInterval.end) ?? 0
                            let midStartPositionX =
                                geonetryProxy[chartProxy.plotAreaFrame].origin.x
                                + (startPositionX1 + startPositionX2) / 2
                            let lineX =
                                layoutDirection == .rightToLeft
                                ? geonetryProxy.size.width - midStartPositionX
                                : midStartPositionX
                            let lineHeight = geonetryProxy[chartProxy.plotAreaFrame].maxY
                            Rectangle()
                                .fill(.tertiary)
                                .frame(width: 2, height: lineHeight)
                                .position(x: lineX, y: lineHeight / 2)
                        }
                    }
                }
        }
        .padding()
        .navigationTitle("ModificationSizeChart.Title")
        .onChange(of: rangeType) { newValue in
            let monthNow = calendar.month(of: .init())
            switch newValue {
            case .lastTwelveMonths:
                range = monthNow.advanced(by: -11) ... monthNow
            case .year:
                range = Month(year: monthNow.year, month: 1) ... Month(year: monthNow.year, month: 12)
            }
        }
        .onChange(of: range) { newValue in
            let dateRange = calendar.dateRange(from: newValue.lowerBound, to: newValue.upperBound)!
            contributions.nsPredicate = .init(
                format: "%K == %@ AND %K != 0 AND %K >= %@ AND %K < %@",
                #keyPath(Contribution.userID), user.uuid! as NSUUID,
                #keyPath(Contribution.sizeDiff),
                #keyPath(Contribution.timestamp), dateRange.lowerBound as NSDate,
                #keyPath(Contribution.timestamp), dateRange.upperBound as NSDate
            )
        }
        .onReceive(contributions.publisher.count()) { count in
            guard statistics.contributionsCount != count || statistics.range != range else { return }
            withAnimation(.easeInOut) {
                selection = nil
                updateStatistics()
            }
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
            
            if let range, rangeType != .lastTwelveMonths {
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
    
    private func dataItem(
        at point: CGPoint, chartProxy: ChartProxy, geometryProxy: GeometryProxy
    ) -> DataItem? {
        let relativeXPosition = point.x - geometryProxy[chartProxy.plotAreaFrame].origin.x
        guard let date: Date = chartProxy.value(atX: relativeXPosition) else { return nil }
        // Find the closest date element.
        var minDistance: TimeInterval = .infinity
        var index: Int? = nil
        for dataIndex in statistics.data.indices {
            let distance = statistics.data[dataIndex].date.distance(to: date)
            if abs(distance) < minDistance {
                minDistance = abs(distance)
                index = dataIndex
            }
        }
        guard let index else { return nil }
        return statistics.data[index]
    }
    
    private func gesture(chartProxy: ChartProxy, geometryProxy: GeometryProxy) -> some Gesture {
        SpatialTapGesture()
            .onEnded { value in
                let newSelection = dataItem(at: value.location, chartProxy: chartProxy, geometryProxy: geometryProxy)
                if selection?.date == newSelection?.date {
                    // If tapping the same element, clear the selection.
                    selection = nil
                } else {
                    selection = newSelection
                }
            }
            .exclusively(
                before: DragGesture()
                    .onChanged { value in
                        selection = dataItem(at: value.location, chartProxy: chartProxy, geometryProxy: geometryProxy)
                    }
            )
    }
    
    private func updateStatistics() {
        var statistics = Statistics(range: range, contributionsCount: contributions.count)
        defer {
            self.statistics = statistics
        }
        
        var modificationsByMonth: [ Month : ChartBuilder.Modification ] =
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
    }
}
