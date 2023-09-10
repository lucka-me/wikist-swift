//
//  NamespaceChart.swift
//  Wikist
//
//  Created by Lucka on 2/1/2023.
//

import Charts
import SwiftUI

struct PerNamespaceChart: View {
    struct DataItem {
        var namespace: WikiNamespace
        var count: Int
    }
    
    private enum ChartType {
        case donut
        case bar
    }
    
    private enum ValueType {
        case count
        case percentage
    }
    
    typealias BriefData = [ DataItem ]
    
    @Environment(\.persistence) private var persistence
    
    @ScaledMetric(relativeTo: .caption) private var chartBarMarkHeight = 50
    
    @State private var chartType = ChartType.donut
    @State private var enabledNamespaces: Set<Int32> = [ ]
    @State private var isReady = false
    @State private var statistics = Statistics()
    @State private var valueType = ValueType.count
    
    private let namespaces: [ Int32 : WikiNamespace ]
    private let user: User
    
    init(user: User) {
        self.user = user
        self.namespaces = user.wiki?.auxiliary?.namespaces ?? [ : ]
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Picker(selection: $chartType) {
                    Label("PerNamespaceChart.Type.Donut", systemImage: "chart.pie").tag(ChartType.donut)
                    Label("PerNamespaceChart.Type.Bar", systemImage: "chart.bar").tag(ChartType.bar)
                } label: {
                    EmptyView()
                }
                Spacer()
                Picker(selection: $valueType) {
                    Text("PerNamespaceChart.Count").tag(ValueType.count)
                    Text("PerNamespaceChart.Percentage").tag(ValueType.percentage)
                } label: {
                    EmptyView()
                }
                .pickerStyle(.menu)
                .fixedSize()
            }
            
            switch chartType {
            case .donut:
                donutChart
            case .bar:
                barChart
            }
        }
        .padding()
        .navigationTitle("PerNamespaceChart.Title")
        .toolbar {
            filterMenu
        }
        .task {
            await updateStatistics()
            enabledNamespaces = .init(statistics.data.map { $0.namespace.id })
            isReady = true
        }
        .onContributionsUpdated(userID: user.uuid) {
            await updateStatistics()
        }
    }
    
    @ViewBuilder
    private var barChart: some View {
        let enabledTotal = (valueType == .percentage) ? self.enabledTotal : 0
        GeometryReader { proxy in
            Chart(statistics.data, id: \.namespace.id) { item in
                if enabledNamespaces.contains(item.namespace.id) {
                    switch valueType {
                    case .count:
                        BarMark(
                            x: .value("PerNamespaceChart.Chart.XAxis", item.count),
                            y: .value("PerNamespaceChart.Chart.YAxis", item.namespace.name)
                        )
                        .annotation(position: .trailing, alignment: .trailing) {
                            Text(item.count, format: .number)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    case .percentage:
                        let percentage = Double(item.count) / Double(enabledTotal)
                        BarMark(
                            x: .value("NamespaceChart.Chart.XAxis", percentage),
                            y: .value("NamespaceChart.Chart.YAxis", item.namespace.name)
                        )
                        .annotation(position: .trailing, alignment: .trailing) {
                            Text(percentage, format: .percent.precision(.fractionLength(2)))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .chartScrollableAxes(.vertical)
            .chartYVisibleDomain(length: Int(proxy.size.height / chartBarMarkHeight))
        }
    }
    
    @ViewBuilder
    private var donutChart: some View {
        let enabledTotal = self.enabledTotal
        if enabledTotal > 0 {
            Chart(statistics.data, id: \.namespace.id) { item in
                let enabled = enabledNamespaces.contains(item.namespace.id)
                let percentage = enabled ? (Double(item.count) / Double(enabledTotal)) : 0.0
                
                switch valueType {
                case .count:
                    SectorMark(
                        angle: .value("PerNamespaceChart.Chart.XAxis", enabled ? item.count : 0),
                        innerRadius: .ratio(0.5),
                        angularInset: 1.0
                    )
                    .cornerRadius(4.0, style: .continuous)
                    .foregroundStyle(by: .value("PerNamespaceChart.BriefChart.Group", item.namespace.name))
                    .annotation(position: .overlay) {
                        if percentage > 0.05 {
                            VStack {
                                Text(item.namespace.name)
                                Text(item.count, format: .number)
                            }
                            .font(.caption)
                        }
                    }
                case .percentage:
                    SectorMark(
                        angle: .value("PerNamespaceChart.Chart.XAxis", percentage),
                        innerRadius: .ratio(0.5),
                        angularInset: 1.0
                    )
                    .cornerRadius(4.0, style: .continuous)
                    .foregroundStyle(by: .value("PerNamespaceChart.BriefChart.Group", item.namespace.name))
                    .annotation(position: .overlay) {
                        if percentage > 0.05 {
                            VStack {
                                Text(item.namespace.name)
                                Text(percentage, format: .percent.precision(.fractionLength(2)))
                            }
                            .font(.caption)
                        }
                    }
                }
            }
            .chartLegend(.hidden)
        } else {
            Spacer()
        }
    }
    
    @ViewBuilder
    private var filterMenu: some View {
        Menu {
            ForEach(statistics.data, id: \.namespace.id) { item in
                let selected = enabledNamespaces.contains(item.namespace.id)
                Button {
                    withAnimation {
                        if selected {
                            enabledNamespaces.remove(item.namespace.id)
                        } else {
                            enabledNamespaces.insert(item.namespace.id)
                        }
                    }
                } label: {
                    if selected {
#if os(macOS)
                        Text(item.namespace.name)
#else
                        Label(item.namespace.name, systemImage: "checkmark")
#endif
                    } else {
                        Text(item.namespace.name)
#if os(macOS)
                            .foregroundColor(.secondary)
#endif
                    }
                }
            }
        } label: {
            Label("PerNamespaceChart.Filter", systemImage: "line.3.horizontal.decrease.circle")
        }
    }
    
    @MainActor
    private func updateStatistics() async {
        guard
            let userID = user.uuid,
            let statistics = await persistence.makeStatistics(of: userID, namespaces: namespaces)
        else {
            return
        }
        withAnimation(.easeInOut) {
            self.statistics = statistics
        }
    }
    
    private var enabledTotal: Int {
        statistics.data.reduce(into: 0) { result, item in
            if (enabledNamespaces.contains(item.namespace.id)) {
                result += item.count
            }
        }
    }
}

fileprivate struct Statistics {
    var contributionsCount: Int = 0
    var data: PerNamespaceChart.BriefData = [ ]
}

extension PerNamespaceChart: StatisticsChart {
    static let briefTitleKey: LocalizedStringKey = "PerNamespaceChart.BriefTitle"
    static let briefSystemImage: String = "square.stack.3d.up"
    
    static func card(data: BriefData, action: @escaping () -> Void) -> some View {
        StatisticsChartCard(Self.self, action: action) {
            Chart(data, id: \.namespace.id) { item in
                SectorMark(
                    angle: .value("PerNamespaceChart.BriefChart.YAxis", item.count),
                    innerRadius: .ratio(0.5),
                    angularInset: 1.0
                )
                .foregroundStyle(by: .value("PerNamespaceChart.BriefChart.Group", item.namespace.name))
                .cornerRadius(4.0, style: .continuous)
            }
            .chartLegend(.hidden)
        }
    }
}

fileprivate extension Persistence {
    func makeStatistics(
        of userID: UUID,
        namespaces: [ Int32 : WikiNamespace ]
    ) async -> Statistics? {
        let request = Contribution.fetchRequest()
        request.propertiesToFetch = [ #keyPath(Contribution.namespace) ]
        request.predicate = .init(format: "%K == %@", #keyPath(Contribution.userID), userID as NSUUID)
        return await container.performBackgroundTask { context in
            guard let contributions = try? context.fetch(request) else { return nil }
            var statistics = Statistics(contributionsCount: contributions.count)
            let countsByNamespace: [ Int32 : Int ] = contributions.reduce(into: [ : ]) { result, item in
                result[item.namespace, default: 0] += 1
            }
            statistics.data = countsByNamespace
                .sorted { $0.value > $1.value }
                .compactMap { item in
                    guard var namespace = namespaces[item.key] else { return nil }
                    if namespace.name.isEmpty {
                        namespace.name = .init(localized: "PerNamespaceChart.Namespace.Main")
                    }
                    return .init(namespace: namespace, count: item.value)
                }
            return statistics
        }
    }
}
