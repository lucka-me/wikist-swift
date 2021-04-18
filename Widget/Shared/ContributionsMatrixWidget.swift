//
//  ContributesMatrixWidget.swift
//  Wikist
//
//  Created by Lucka on 13/4/2021.
//

import WidgetKit
import SwiftUI
import Intents

struct ContributionsMatrixWidget: Widget {
    
    typealias ConfigurationIntent = ContributionsMatrixConfigurationIntent
    
    struct Provider: IntentTimelineProvider {
        
        func placeholder(in context: Context) -> Entry {
            .init(user(from: nil))
        }

        func getSnapshot(
            for configuration: ConfigurationIntent,
            in context: Context,
            completion: @escaping (Entry) -> ()
        ) {
            completion(.init(user(from: configuration)))
        }
        
        func getTimeline(
            for configuration: ConfigurationIntent,
            in context: Context,
            completion: @escaping (Timeline<Entry>) -> Void
        ) {
            guard let user = user(from: configuration) else {
                completion(.init(entries: [], policy: .atEnd))
                return
            }
            let now = Date()
            user.refresh { succeed in
                if succeed {
                    Dia.shared.save()
                }
                DispatchQueue.main.async {
                    let entryDate = Calendar.current.date(byAdding: .minute, value: 30, to: now) ?? now
                    completion(.init(entries: [ .init(user, date: entryDate) ], policy: .atEnd))
                }
            }
        }
        
        private func user(from configuration: ConfigurationIntent?) -> WikiUser? {
            guard
                let solidConfiguration = configuration,
                solidConfiguration.customUser?.boolValue ?? false,
                let selectedID = solidConfiguration.selectedUser?.identifier,
                let selectedURI = URL(string: selectedID)
            else {
                return Dia.shared.firstUser(sortBy: WikiUser.sortDescriptorsByEdits)
            }
            return Dia.shared.user(with: selectedURI)
        }
    }
    
    struct Entry: TimelineEntry {
        let date: Date
        let user: WikiUser?
        
        init(_ user: WikiUser?, date: Date = .init()) {
            self.date = date
            self.user = user
        }
    }

    struct EntryView : View {
        var entry: Provider.Entry

        var body: some View {
            if let solidUser = entry.user {
                content(solidUser)
            } else {
                Text("No user")
            }
        }
        
        @ViewBuilder
        private func content(_ user: WikiUser) -> some View {
            VStack(alignment: .leading) {
                HStack {
                    Text(user.username)
                    Spacer()
                    Text(user.site?.title ?? "")
                }
                .lineLimit(1)
                .font(.callout)
                ContributionsMatrix(user)
            }
            .padding()
        }
    }
    
    let kind: String = "widget.contributionsMatrix"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            EntryView(entry: entry)
        }
        .supportedFamilies([ .systemSmall, .systemMedium ])
        .configurationDisplayName("Contributions Matrix Widget")
        .description("Display the contributions matrix.")
    }
}

#if DEBUG
struct ContributionsMatrixWidget_Previews: PreviewProvider {
    static var previews: some View {
        ContributionsMatrixWidget.EntryView(entry: .init(Dia.preview.users().first!))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
#endif
