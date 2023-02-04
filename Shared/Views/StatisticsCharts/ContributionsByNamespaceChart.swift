//
//  ContributionsByNamespaceChart.swift
//  Wikist
//
//  Created by Lucka on 2/1/2023.
//

import Charts
import SwiftUI

struct ContributionsByNamespaceChartBuilder: StatisticsChartBuilder {
    struct DataItem {
        var namespace: WikiNamespace
        var count: Int
    }
    
    let briefTitleKey: LocalizedStringKey = "ContributionsByNamespaceChart.BriefTitle"
    let briefSystemImage: String = "square.stack.3d.up"
    
    func makeBriefChart(data: [ DataItem ]) -> some View {
        Chart(data, id: \.namespace.id) { item in
            BarMark(y: .value("ContributionsByNamespaceChart.BriefChart.YAxis", item.count))
                .foregroundStyle(by: .value("ContributionsByNamespaceChart.BriefChart.Group", item.namespace.name))
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(position: .trailing)
    }
    
    func makeChart(user: User) -> some View {
        ChartView(user: user)
    }
}

extension StatisticsChart where Builder == ContributionsByNamespaceChartBuilder {
    @ViewBuilder
    static func contributionsByNamespace(user: User, briefData: Builder.BriefData) -> some View {
        Self.init(user: user, briefData: briefData)
    }
}

fileprivate typealias ChartBuilder = ContributionsByNamespaceChartBuilder

fileprivate struct ChartView: View {
    
    private enum ValueType {
        case count
        case percentage
    }
    
    fileprivate struct Statistics {
        var contributionsCount: Int = 0
        var data: ChartBuilder.BriefData = [ ]
    }
    
    @Environment(\.persistence) private var persistence
    
    @ScaledMetric(relativeTo: .caption) private var chartHeight = 20
    
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
                Spacer()
                Picker(selection: $valueType) {
                    Text("ContributionsByNamespaceChart.Count").tag(ValueType.count)
                    Text("ContributionsByNamespaceChart.Percentage").tag(ValueType.percentage)
                } label: {
                    EmptyView()
                }
                .pickerStyle(.menu)
                .fixedSize()
            }
            
            ScrollView(.vertical) {
                Chart(statistics.data, id: \.namespace.id) { item in
                    if enabledNamespaces.contains(item.namespace.id) {
                        switch valueType {
                        case .count:
                            BarMark(
                                x: .value("ContributionsByNamespaceChart.Chart.XAxis", item.count),
                                y: .value("ContributionsByNamespaceChart.Chart.YAxis", item.namespace.name)
                            )
                            .annotation(position: .trailing, alignment: .trailing) {
                                Text(item.count, format: .number)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        case .percentage:
                            BarMark(
                                x: .value(
                                    "ContributionsByNamespaceChart.Chart.XAxis",
                                    Double(item.count) / Double(statistics.contributionsCount)
                                ),
                                y: .value("ContributionsByNamespaceChart.Chart.YAxis", item.namespace.name)
                            )
                            .annotation(position: .trailing, alignment: .trailing) {
                                Text(
                                    Double(item.count) / Double(statistics.contributionsCount),
                                    format: .percent.precision(.fractionLength(2))
                                )
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .frame(minHeight: chartHeight * 2 * Double(enabledNamespaces.count + 1))
            }
        }
        .padding()
        .navigationTitle("ContributionsByNamespaceChart.Title")
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
            Label("ContributionsByNamespaceChart.Filter", systemImage: "line.3.horizontal.decrease.circle")
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
}

fileprivate extension Persistence {
    func makeStatistics(
        of userID: UUID,
        namespaces: [ Int32 : WikiNamespace ]
    ) async -> ChartView.Statistics? {
        let request = Contribution.fetchRequest()
        request.propertiesToFetch = [ #keyPath(Contribution.namespace) ]
        request.predicate = .init(format: "%K == %@", #keyPath(Contribution.userID), userID as NSUUID)
        return await container.performBackgroundTask { context in
            guard let contributions = try? context.fetch(request) else { return nil }
            var statistics = ChartView.Statistics(contributionsCount: contributions.count)
            let countsByNamespace: [ Int32 : Int ] = contributions.reduce(into: [ : ]) { result, item in
                result[item.namespace, default: 0] += 1
            }
            statistics.data = countsByNamespace
                .sorted { $0.value > $1.value }
                .compactMap { item in
                    guard var namespace = namespaces[item.key] else { return nil }
                    if namespace.name.isEmpty {
                        namespace.name = .init(localized: "ContributionsByNamespaceChart.Namespace.Main")
                    }
                    return .init(namespace: namespace, count: item.value)
                }
            return statistics
        }
    }
}
