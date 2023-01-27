//
//  ContributesMatrixWidget.swift
//  Widget
//
//  Created by Lucka on 13/4/2021.
//

import WidgetKit
import SwiftUI
import Intents

struct ContributionsMatrixWidget: Widget {
    let kind: String = "widget.contributionsMatrix"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            EntryView(entry: entry)
        }
        .supportedFamilies([ .systemSmall, .systemMedium ])
        .configurationDisplayName("ContributionsMatrixWidget.Name")
        .description("ContributionsMatrixWidget.Description")
    }
}

fileprivate typealias ConfigurationIntent = ContributionsMatrixConfigurationIntent

fileprivate struct Entry: TimelineEntry {
    var date = Date()
    var username = "User"
    var faviconData: Data? = nil
    var countsByDay: [ Date : Int ] = [ : ]
}

fileprivate struct EntryView: View {
    @Environment(\.widgetFamily) private var widgetFamily
    
    @ScaledMetric(relativeTo: .caption) private var faviconSize = 16
    
    var entry: Entry
    
    var body: some View {
        VStack {
            if widgetFamily == .systemMedium {
                HStack {
                    if let data = entry.faviconData, let image = Image(data: data) {
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(width: faviconSize, height: faviconSize)
                    }
                    Spacer()
                    Text(entry.username)
                }
                .lineLimit(1)
                .foregroundColor(.secondary)
                .font(.caption)
            }
            ContributionsMatrix { entry.countsByDay[$0] ?? 0 }
        }
        .padding()
    }
}

fileprivate struct Provider: IntentTimelineProvider {
    func placeholder(in context: Context) -> Entry {
        .init()
    }
    
    func getSnapshot(
        for configuration: ConfigurationIntent,
        in context: Context,
        completion: @escaping (Entry) -> Void
    ) {
        var entry = Entry()
        defer {
            completion(entry)
        }
        let persistence = Persistence.shared
        let coordinator = persistence.container.persistentStoreCoordinator
        let context = persistence.container.viewContext
        guard
            let userIdentifier = configuration.user?.identifier,
            let uri = URL(string: userIdentifier),
            let objectId = coordinator.managedObjectID(forURIRepresentation: uri),
            let user = context.object(with: objectId) as? User
        else {
            return
        }
        
        if let username = user.name {
            entry.username = username
        }
        
        let contributions = user.contributions
        for contribution in contributions {
            guard let timestamp = contribution.timestamp else { continue }
            let day = Calendar.current.startOfDay(for: timestamp)
            entry.countsByDay[day, default: 0] += 1
        }
    }
    
    func getTimeline(
        for configuration: ConfigurationIntent,
        in context: Context,
        completion: @escaping (Timeline<Entry>) -> Void
    ) {
        Task {
            var entry = Entry()
            let calendar = Calendar.current
            if let entryDate = calendar.date(byAdding: .minute, value: 30, to: entry.date) {
                entry.date = entryDate
            }
            defer {
                completion(.init(entries: [ entry ], policy: .atEnd))
            }
            
            let container = Persistence.shared.container
            let coordinator = container.persistentStoreCoordinator
            
            guard
                let userIdentifier = configuration.user?.identifier,
                let uri = URL(string: userIdentifier),
                let objectId = coordinator.managedObjectID(forURIRepresentation: uri)
            else {
                return
            }
            
            let context = container.viewContext
            guard let user = await context.perform({ context.object(with: objectId) as? User }) else { return }
            try? await user.refresh(viewContext: context)
            if let username = user.name {
                entry.username = username
            }
            entry.countsByDay = await context.perform {
                try? context.save()
                var reuslt = entry.countsByDay
                let contributions = user.contributions
                for contribution in contributions {
                    guard let timestamp = contribution.timestamp else { continue }
                    let day = calendar.startOfDay(for: timestamp)
                    reuslt[day, default: 0] += 1
                }
                return reuslt
            }
            if let favicon = await context.perform({ user.wiki?.favicon }),
               let (data, _) = try? await URLSession.shared.data(from: favicon) {
                entry.faviconData = data
            }
        }
    }
}

#if DEBUG
//struct ContributionsMatrixWidgetPreviews: PreviewProvider {
//    static var previews: some View {
//        EntryView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent()))
//            .previewContext(WidgetPreviewContext(family: .systemSmall))
//    }
//}
#endif
