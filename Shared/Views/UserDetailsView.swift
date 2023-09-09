//
//  UserDetailsView.swift
//  Wikist
//
//  Created by Lucka on 26/11/2022.
//

import Charts
import CoreData
import SwiftUI

struct UserDetailsView: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.openURL) private var openURL
    @Environment(\.persistence) private var persistence
    @Environment(\.timeZone) private var timeZone
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var isCountsByHourChartSheetPresented = false
    @State private var isRefreshing = false
    @State private var isShowingRegistration = true
    @State private var isStatisticsReady = false
    @State private var presentedChartType: StatisticsChartType? = nil
    @State private var statistics = Statistics()
    @State private var statisticsTask: Task<(), Never>? = nil
    @State private var today = Date()
    
    private let user: User
    
    init(_ user: User) {
        self.user = user
    }
    
    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading) {
                ContributionsMatrix(fits: .vertical) { statistics.countsByDay[$0] ?? 0 }
                    .frame(
                        maxWidth: .infinity,
                        idealHeight: 20 * 7 + ContributionsMatrix.regularSpacing * 6,
                        alignment: .top
                    )
                Group {
                    actions
                    highlights
                    if statistics.contributionsCount > 0 {
                        statisticsSection
                        chartsSection
                    } else if !isStatisticsReady {
                        ProgressView()
                            .padding()
                    }
                }
                .frame(maxWidth: 640, alignment: .center)
                .frame(maxWidth: .infinity)
            }
            .padding()
        }
        .navigationTitle(user.name ?? "UserDetailsView.DefaultTitle")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if isStatisticsReady {
                    ThemedButton.refresh(isRefreshing: isRefreshing) {
                        Task { await tryRefresh() }
                    }
                }
            }
        }
        .sheet(item: $presentedChartType) { charType in
            NavigationStack {
                Group {
                    switch charType {
                    case .modificationSize:
                        ModificationSizeChart(user: user)
                    case .perDayHour:
                        PerDayHourChart(user: user)
                    case .perNamespace:
                        PerNamespaceChart(user: user)
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        ThemedButton.dismiss {
                            presentedChartType = nil
                        }
                    }
                }
#if os(macOS)
                .frame(minWidth: 320, minHeight: 320)
#else
                .navigationBarTitleDisplayMode(.inline)
#endif
            }
        }
        .onReceiveCalendarDayChanged { day in
            today = day
        }
        .task {
            try? await persistence.attachRefreshTask(of: user.objectID) { @MainActor in
                self.isRefreshing = true
                await updateStatistics {
                    isStatisticsReady = true
                }
            }
            if isRefreshing {
                self.isRefreshing = false
            }
            if !isStatisticsReady {
                await updateStatistics()
                await MainActor.run {
                    withAnimation {
                        isStatisticsReady = true
                    }
                }
            }
        }
        .onContributionsUpdated(userID: user.uuid) {
            guard isStatisticsReady else { return }
            await updateStatistics()
        }
    }
    
    @ViewBuilder
    private var actions: some View {
        EqualWidthHStack {
            if let wiki = user.wiki {
                NavigationLink(value: wiki) {
                    Label(wiki.title ?? "UserDetailsView.DefaultWiki", systemImage: "globe")
                        .labelStyle(.titleUnderIcon)
                        .card()
                }
                .buttonStyle(.borderless)
            }
            if let userPageURL = user.userPageURL {
                ThemedButton.action("UserDetailsView.Actions.UserPage", systemImage: "person.crop.rectangle") {
                    openURL(userPageURL)
                }
            }
        }
    }
    
    @ViewBuilder
    private var highlights: some View {
        FlexHStack(horizontalSpacing: 4, verticalSpacing: 4) {
            SimpleChip("UserDetailsView.Highlights.UserID", systemImage: "number") {
                Text(user.userID, format: .number)
                    .monospaced()
            }
            if let registration = user.registration {
                SimpleChip(
                    isShowingRegistration ? "UserDetailsView.Highlights.Registration" : "UserDetailsView.Highlights.Days",
                    systemImage: isShowingRegistration ? "person.badge.plus" : "calendar"
                ) {
                    ZStack(alignment: .trailing) {
                        Text(registration, format: .dateTime.year(.twoDigits).month(.abbreviated).day(.defaultDigits))
                            .opacity(isShowingRegistration ? 1 : 0)
                        Text(calendar.days(from: registration, to: today), format: .number)
                            .monospaced()
                            .opacity(isShowingRegistration ? 0 : 1)
                    }
                }
                .onTapGesture {
#if os(iOS)
                    let feedback = UIImpactFeedbackGenerator(style: .light)
                    feedback.prepare()
                    feedback.impactOccurred()
#endif
                    withAnimation(.spring()) {
                        isShowingRegistration.toggle()
                    }
                }
            }
            SimpleChip("UserDetailsView.Highlights.Contributions", systemImage: "pencil.circle") {
                Text(statistics.contributionsCount, format: .number)
                    .monospaced()
            }
        }
    }
    
    @ViewBuilder
    private var statisticsSection: some View {
        Section {
            LazyVGrid(columns: [ .init(.adaptive(minimum: 300), alignment: .top)], alignment: .leading) {
                overallStatistics
                strikesStatistics
            }
        } header: {
            Text("UserDetailsView.Statistics")
                .sectionHeader()
        }
    }
    
    @ViewBuilder
    private var overallStatistics: some View {
        StatisticsGrid.card {
            StatisticsGrid.header("UserDetailsView.Statistics.Overall")
            StatisticsGrid.row(
                "UserDetailsView.Statistics.Overall.CreatedPages",
                systemImage: "plus.circle",
                value: statistics.createdCount
            )
            StatisticsGrid.row(
                "UserDetailsView.Statistics.Overall.ModificationSize",
                systemImage: "plus.forwardslash.minus",
                value: statistics.modificationSize,
                format: .byteCount(style: .binary)
            )
            if let hour = statistics.mostActiveDayHour {
                StatisticsGrid.row(
                    "UserDetailsView.Statistics.Overall.MostActive",
                    systemImage: "sparkles",
                    value: hour,
                    format: .dateTime.hour().minute()
                )
            }
        }
    }
    
    @ViewBuilder
    private var strikesStatistics: some View {
        StatisticsGrid.card {
            StatisticsGrid.header("UserDetailsView.Strike", unitKey: "UserDetailsView.Strike.Days")
            StatisticsGrid.row("UserDetailsView.Strike.Current", systemImage: "arrow.right.to.line") {
                if let currentStrike = statistics.currentStrike {
                    Text(calendar.days(in: currentStrike), format: .number)
                } else {
                    Text(0, format: .number)
                }
            }
            StatisticsGrid.row("UserDetailsView.Strike.Longest", systemImage: "chevron.forward.2") {
                if let longestStrike = statistics.longestStrike {
                    Text(calendar.days(in: longestStrike), format: .number)
                } else {
                    Text(0, format: .number)
                }
            }
        }
    }
    
    @ViewBuilder
    private var chartsSection: some View {
        Section {
            LazyVGrid(columns: [ .init(.adaptive(minimum: 140))], alignment: .leading) {
                PerDayHourChart.card(data: statistics.countsByDayHour) {
                    presentedChartType = .perDayHour
                }
                if !statistics.countsByNamespace.isEmpty {
                    PerNamespaceChart.card(data: statistics.countsByNamespace) {
                        presentedChartType = .perNamespace
                    }
                }
                ModificationSizeChart.card(data: statistics.modificationsByMonth) {
                    presentedChartType = .modificationSize
                }
            }
        } header: {
            Text("UserDetailsView.Charts")
                .sectionHeader()
        }
    }
    
    @MainActor
    private func tryRefresh() async {
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            try await persistence.update(user: user.objectID)
            try await persistence.refresh(user: user.objectID, with: timeZone)
        } catch {
            //
            print(error)
        }
    }
    
    @MainActor
    private func updateStatistics(action: (() -> Void)? = nil) async {
        guard let userID = user.uuid else { return }
        let namespaces = user.wiki?.auxiliary?.namespaces
        let statistics = await persistence.makeStatistics(
            of: userID, today: today, calendar: calendar, namespaces: namespaces
        )
        guard let statistics else { return }
        withAnimation {
            self.statistics = statistics
            action?()
        }
    }
}

#if DEBUG
struct UserDetailsViewPreviews: PreviewProvider {
    static let persistence = Persistence.preview
    
    static var previews: some View {
        UserDetailsView(Persistence.previewUser(with: persistence.container.viewContext))
            .environment(\.managedObjectContext, persistence.container.viewContext)
    }
}
#endif

fileprivate enum StatisticsChartType : Int, Identifiable {
    case modificationSize
    case perDayHour
    case perNamespace

    var id: Int { self.rawValue }
}

fileprivate struct Statistics {
    var contributionsCount: Int = 0
    
    var countsByDay: [ Date : Int ] = [ : ]
    
    var modificationSize: Int64 = 0
    var createdCount: Int = 0
    var mostActiveDayHour: Date? = nil
    
    var currentStrike: DateRange? = nil
    var longestStrike: DateRange? = nil
    
    var countsByDayHour: PerDayHourChart.BriefData = [ ]
    var modificationsByMonth: ModificationSizeChart.BriefData = [ ]
    var countsByNamespace: PerNamespaceChart.BriefData = [ ]
}

fileprivate extension Persistence {
    func makeStatistics(
        of userID: UUID,
        today: Date,
        calendar: Calendar,
        namespaces: [ Int32 : WikiNamespace ]?
    ) async -> Statistics? {
        guard let dayHoursRange = calendar.range(covers: .init(hour: 0), around: today) else { return nil }
        guard let twelveMonthsAgo = calendar.date(byAdding: .month, value: -11, to: today) else {
            return nil
        }
        
        let request = Contribution.fetchRequest()
        request.sortDescriptors = [ .init(keyPath: \Contribution.timestamp, ascending: false) ]
        request.predicate = .init(format: "%K == %@", #keyPath(Contribution.userID), userID as NSUUID)
        return await container.performBackgroundTask { context in
            guard let contributions = try? context.fetch(request) else { return nil }
            var statistics = Statistics(contributionsCount: contributions.count)
            let dayHourBins = DateBins(unit: .hour, range: dayHoursRange, calendar: calendar)
            let lastTwelveMonthsRange = twelveMonthsAgo ... today
            let lastTwelveMonthsBins = DateBins(unit: .month, range: lastTwelveMonthsRange, calendar: calendar)
            
            statistics.countsByDayHour = dayHourBins.map { .init(hour: $0, count: 0) }
            statistics.modificationsByMonth = lastTwelveMonthsBins.map {
                .init(month: $0, modification: .init(addition: 0, deletion: 0))
            }

            var strikes: [ DateRange ] = [ ]
            var countsByNamespace: [ Int32 : Int ] = [ : ]
            
            // Decreasing
            for contribution in contributions {
                if contribution.new {
                    statistics.createdCount += 1
                }
                statistics.modificationSize += contribution.sizeDiff
                countsByNamespace[contribution.namespace, default: 0] += 1
                
                guard let timestamp = contribution.timestamp else { continue }
                let day = calendar.startOfDay(for: timestamp)
                
                statistics.countsByDay[day, default: 0] += 1
                
                statistics.countsByDayHour[calendar.component(.hour, from: timestamp)].count += 1
                
                if strikes.isEmpty {
                    if let interval = calendar.dayInterval(for: timestamp) {
                        strikes.append(interval)
                    }
                } else if
                    !strikes.last!.contains(timestamp),
                    let nextDay = calendar.date(byAdding: .day, value: 1, to: timestamp) {
                    if strikes.last!.contains(nextDay) {
                        let lastItem = strikes.removeLast()
                        strikes.append(day ..< lastItem.upperBound)
                    } else if let interval = calendar.dayInterval(for: timestamp) {
                        strikes.append(interval)
                    }
                }

                if (contribution.sizeDiff != 0) && (lastTwelveMonthsRange.contains(timestamp)) {
                    statistics
                        .modificationsByMonth[lastTwelveMonthsBins.index(for: timestamp)]
                        .modification
                        .merge(contribution.sizeDiff)
                }
            }
            
            statistics.mostActiveDayHour = statistics.countsByDayHour.max { $0.count < $1.count }?.hour.lowerBound

            if let latestStrike = strikes.first {
                if latestStrike.contains(today) {
                    statistics.currentStrike = latestStrike
                }
            }
            statistics.longestStrike = strikes.max { calendar.days(in: $0) < calendar.days(in: $1) }
            
            if let namespaces {
                var data: PerNamespaceChart.BriefData = countsByNamespace
                    .sorted { $0.value < $1.value }
                    .compactMap { item in
                        guard var namespace = namespaces[item.key] else { return nil }
                        if namespace.name.isEmpty {
                            namespace.name = .init(localized: "UserDetailsView.Namespace.Main")
                        }
                        return .init(namespace: namespace, count: item.value)
                    }
                if data.count > 5 {
                    let otherCount = data.prefix(upTo: data.count - 5).reduce(0) { $0 + $1.count }
                    data.replaceSubrange(
                        0 ..< data.count - 4,
                        with: [
                            .init(
                                namespace: .init(
                                    id: data[0].namespace.id,
                                    name: .init(localized: "UserDetailsView.Namespace.Other")
                                ),
                                count: otherCount
                            )
                        ]
                    )
                }
                statistics.countsByNamespace = data
            }
            
            return statistics
        }
    }
}
