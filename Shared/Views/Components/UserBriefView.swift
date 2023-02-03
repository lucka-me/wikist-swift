//
//  UserBriefView.swift
//  Wikist
//
//  Created by Lucka on 21/11/2022.
//

import SwiftUI

struct UserBriefView: View {
    
    private struct Statistics {
        var contributionsCount: Int = -1
        var countsByDay: [ (Date, Int) ] = [ ]
    }
    
    @Environment(\.calendar) private var calendar
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest private var contributions: FetchedResults<Contribution>
    
    @State private var statistics = Statistics()
    
    private let showWikiTitle: Bool
    private let user: User
    
    init(_ user: User, showWikiTitle: Bool = true) {
        self.user = user
        self.showWikiTitle = showWikiTitle
        
        let startOfFiveDaysAgo = Calendar.current.startOfDay(forNext: -4, of: .init())!
        
        self._contributions = .init(
            entity: Contribution.entity(),
            sortDescriptors: [ ],
            predicate: .init(
                format: "%K == %@ AND %K >= %@",
                #keyPath(Contribution.userID), user.uuid! as NSUUID,
                #keyPath(Contribution.timestamp), startOfFiveDaysAgo as NSDate
            )
        )
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
        .onReceiveCalendarDayChanged { day in
            guard let startOfFiveDaysAgo = calendar.startOfDay(forNext: -5, of: day) else { return }
            contributions.nsPredicate = .init(
                format: "%K == %@ AND %K >= %@",
                #keyPath(Contribution.userID), user.uuid! as NSUUID,
                #keyPath(Contribution.timestamp), startOfFiveDaysAgo as NSDate
            )
        }
        .onReceive(contributions.publisher.count()) { count in
            guard statistics.contributionsCount != count else { return }
            var statistics = Statistics(contributionsCount: count)
            let today = Date()
            var countsByDay: [ Date : Int ] = (-4 ... 0).reduce(into: [ : ]) {
                $0[calendar.startOfDay(forNext: $1, of: today)!] = 0
            }
            for contribution in contributions {
                guard let timestamp = contribution.timestamp else { continue }
                countsByDay[calendar.startOfDay(for: timestamp)]? += 1
            }
            statistics.countsByDay = countsByDay.sorted { $0.key < $1.key }
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
