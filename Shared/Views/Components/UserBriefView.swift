//
//  UserBriefView.swift
//  Wikist
//
//  Created by Lucka on 21/11/2022.
//

import Charts
import CoreData
import SwiftUI

struct UserBriefView: View {
    
    fileprivate struct Statistics {
        var contributionsCount: Int = -1
        var countsByDay: [ (Date, Int) ] = [ ]
    }
    
    @Environment(\.calendar) private var calendar
    @Environment(\.persistence) private var persistence
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var statistics = Statistics()
    
    private let showWikiTitle: Bool
    private let user: User
    
    init(_ user: User, showWikiTitle: Bool = true) {
        self.user = user
        self.showWikiTitle = showWikiTitle
    }
    
    var body: some View {
        HStack {
            if showWikiTitle {
                VStack(alignment: .leading) {
                    Text(user.name ?? "UserBriefView.DefaultUser")
                        .font(.headline)
                    Text(user.wiki?.title ?? "UserBriefView.DefaultWiki")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .lineLimit(1)
            } else {
                Text(user.name ?? "UserBriefView.DefaultUser")
                    .font(.headline)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            ForEach(statistics.countsByDay, id: \.0) { item in
                ContributionsCell(item.1, in: item.0)
                    .frame(width: 24, height: 24)
                    .mask { Circle() }
            }
        }
        .task {
            await updateStatistics()
        }
        .onReceiveCalendarDayChanged { _ in
            Task {
                await updateStatistics()
            }
        }
        .onContributionsUpdated(userID: user.uuid, perform: updateStatistics)
    }
    
    @MainActor
    private func updateStatistics() async {
        guard let userID = user.uuid else { return }
        guard let statistics = await persistence.makeStatistics(of: userID, calendar: calendar) else { return }
        withAnimation {
            self.statistics = statistics
        }
    }
}

#if DEBUG
struct UserBriefViewPreviews: PreviewProvider {
    static let persistence = Persistence.preview
    
    static var previews: some View {
        UserBriefView(Persistence.previewUser(with: persistence.container.viewContext))
            .environment(\.managedObjectContext, persistence.container.viewContext)
    }
}
#endif

fileprivate extension Persistence {
    func makeStatistics(
        of userID: UUID,
        calendar: Calendar
    ) async -> UserBriefView.Statistics? {
        let today = Date()
        guard let startOfFourDaysAgo = calendar.startOfDay(forNext: -4, of: today) else { return nil }
        let request = Contribution.fetchRequest()
        request.propertiesToFetch = [ #keyPath(Contribution.timestamp) ]
        request.predicate = .init(
            format: "%K == %@ AND %K >= %@",
            #keyPath(Contribution.userID), userID as NSUUID,
            #keyPath(Contribution.timestamp), startOfFourDaysAgo as NSDate
        )
        let context = container.statisticsContext
        guard let contributions = try? context.fetch(request) else { return nil }
        let bins = DateBins(unit: .day, range: startOfFourDaysAgo ... today)
        var statistics = UserBriefView.Statistics(contributionsCount: contributions.count)
        statistics.countsByDay = bins.map { ($0.lowerBound, 0) }
        for contribution in contributions {
            guard let timestamp = contribution.timestamp else { continue }
            let binIndex = bins.index(for: timestamp)
            if (binIndex >= 0) && (binIndex < bins.count) {
                statistics.countsByDay[binIndex].1 += 1
            }
        }
        return statistics
    }
}
