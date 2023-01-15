//
//  ContributionsByHourChart.swift
//  Wikist
//
//  Created by Lucka on 16/7/2022.
//

import Charts
import SwiftUI

struct ContributionsByHourChartBuilder: StatisticsChartBuilder {
    struct DataItem {
        var hour: Date
        var count: Int
    }
    
    let briefTitleKey: LocalizedStringKey = "ContributionsByHourChart.BriefTitle"
    let briefSystemImage: String = "clock"
    
    func makeBriefChart(data: [ DataItem ]) -> some View {
        BriefChartView(data: data)
    }
    
    func makeChart(user: User) -> some View {
        ChartView(user: user)
    }
}

extension StatisticsChart where Builder == ContributionsByHourChartBuilder {
    @ViewBuilder
    static func contributionsByHour(user: User, briefData: Builder.BriefData) -> some View {
        Self.init(user: user, briefData: briefData)
    }
}

fileprivate extension ContributionsByHourChartBuilder {
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

fileprivate typealias ChartBuilder = ContributionsByHourChartBuilder

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
    
    private enum RangeType {
        case all
        case year
        case month
        case week
    }

    private struct Statistics {
        var range: DateRange? = nil
        var contributionsCount: Int = 0
        var data: ChartBuilder.BriefData = [ ]
    }
    
    @Environment(\.calendar) private var calendar
    @Environment(\.layoutDirection) private var layoutDirection
    
    @FetchRequest private var contributions: FetchedResults<Contribution>
    
    @State private var range: DateRange? = nil
    @State private var rangeType = RangeType.all
    
    @State private var selection: DataItem? = nil
    @State private var statistics = Statistics()
    
    private let user: User
    
    init(user: User) {
        self.user = user
        
        self._contributions = .init(
            entity: Contribution.entity(),
            sortDescriptors: [ .init(keyPath: \Contribution.timestamp, ascending: false) ],
            predicate: .init(format: "%K == %@", #keyPath(Contribution.userID), user.uuid! as NSUUID)
        )
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
                        Text(selection.hour, format: .dateTime.hour().minute())
                    } else {
                        Text("ContributionsByHourChart.AllContributions")
                    }
                }
                .font(.callout)
                .foregroundStyle(.secondary)
                
                Text(selection?.count ?? contributions.count, format: .number)
                    .font(.system(.title, design: .rounded, weight: .semibold))
            }

            ChartBuilder.chartView(of: statistics.data, calendar: calendar)
                .chartOverlay { chartProxy in
                    GeometryReader { geometryProxy in
                        Rectangle().fill(.clear).contentShape(Rectangle())
                            .gesture(gesture(chartProxy: chartProxy, geometryProxy: geometryProxy))
                    }
                }
                .chartBackground { chartProxy in
                    GeometryReader { geonetryProxy in
                        if let selection {
                            let dateInterval = calendar.dateInterval(of: .hour, for: selection.hour)!
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
        .navigationTitle("ContributionsByHourChart.Title")
        .onChange(of: rangeType) { type in
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
        .onChange(of: range) { range in
            if let range {
                contributions.nsPredicate = .init(
                    format: "%K == %@ AND %K >= %@ AND %K < %@",
                    #keyPath(Contribution.userID), user.uuid! as NSUUID,
                    #keyPath(Contribution.timestamp), range.lowerBound as NSDate,
                    #keyPath(Contribution.timestamp), range.upperBound as NSDate
                )
            } else {
                contributions.nsPredicate = .init(
                    format: "%K == %@", #keyPath(Contribution.userID), user.uuid! as NSUUID
                )
            }
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
    
    private func dataItem(
        at point: CGPoint, chartProxy: ChartProxy, geometryProxy: GeometryProxy
    ) -> DataItem? {
        let relativeXPosition = point.x - geometryProxy[chartProxy.plotAreaFrame].origin.x
        guard let date: Date = chartProxy.value(atX: relativeXPosition) else { return nil }
        // Find the closest date element.
        var minDistance: TimeInterval = .infinity
        var index: Int? = nil
        for dataIndex in statistics.data.indices {
            let distance = statistics.data[dataIndex].hour.distance(to: date)
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
                if selection?.hour == newSelection?.hour {
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
        var countsByHour: [ Int : Int ] = (0 ..< 24).reduce(into: [ : ]) { $0[$1] = 0 }
        for contribution in contributions {
            guard let timestamp = contribution.timestamp else { continue }
            countsByHour[calendar.component(.hour, from: timestamp), default: 0] += 1
        }
        let today = Date()
        statistics.data = countsByHour.sorted { $0.key < $1.key }.map { item in
            .init(hour: calendar.date(bySettingHour: item.key, minute: 0, second: 0, of: today)!, count: item.value)
        }
    }
}

#if DEBUG
struct ContributionsByHourChartPreviews: PreviewProvider {
    static let persistence = Persistence.preview
    
    static var previews: some View {
        ChartView(user: Persistence.previewUser(with: persistence.container.viewContext))
            .environment(\.managedObjectContext, persistence.container.viewContext)
    }
}
#endif
