//
//  UserBriefView.swift
//  Wikist
//
//  Created by Lucka on 21/11/2022.
//

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
        .onReceive(
            NotificationCenter.default.publisher(for: .ContributionsUpdated)
        ) { notification in
            guard
                let notificationUUID = notification.object as? NSUUID,
                notificationUUID.compare(user.uuid!) == .orderedSame
            else {
                return
            }
            Task {
                await updateStatistics()
            }
        }
    }
    
    private func updateStatistics() async {
        guard let userID = user.uuid else { return }
        guard let statistics = await persistence.makeStatistics(of: userID, calendar: calendar) else { return }
        await MainActor.run {
            withAnimation {
                self.statistics = statistics
            }
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
        guard let startOfFiveDaysAgo = calendar.startOfDay(forNext: -5, of: .init()) else { return nil }
        let request = Contribution.fetchRequest()
        request.predicate = .init(
            format: "%K == %@ AND %K >= %@",
            #keyPath(Contribution.userID), userID as NSUUID,
            #keyPath(Contribution.timestamp), startOfFiveDaysAgo as NSDate
        )
        return await container.performBackgroundTask { context in
            guard let contributions = try? context.fetch(request) else {
                return nil
            }
            var statistics = UserBriefView.Statistics(contributionsCount: contributions.count)
            let today = Date()
            var countsByDay: [ Date : Int ] = (-4 ... 0).reduce(into: [ : ]) {
                $0[calendar.startOfDay(forNext: $1, of: today)!] = 0
            }
            for contribution in contributions {
                guard let timestamp = contribution.timestamp else { continue }
                countsByDay[calendar.startOfDay(for: timestamp)]? += 1
            }
            statistics.countsByDay = countsByDay.sorted { $0.key < $1.key }
            return statistics
        }
    }
}
