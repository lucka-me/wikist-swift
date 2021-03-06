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
            let onFinished = { (favicon: Data?) in
                DispatchQueue.main.async {
                    let entryDate = Calendar.current.date(byAdding: .minute, value: 30, to: now) ?? now
                    completion(.init(entries: [ .init(user, favicon: favicon, date: entryDate) ], policy: .atEnd))
                }
            }
            Task.init {
                try? await user.refresh()
                await Dia.shared.save()
                guard
                    let site = user.site,
                    let url = URL(string: site.favicon),
                    let (data, _) = try? await URLSession.shared.data(from: url)
                else {
                    onFinished(nil)
                    return
                }
                onFinished(data)
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
            return Dia.shared.user(of: selectedURI)
        }
    }
    
    struct Entry: TimelineEntry {
        let date: Date
        let user: WikiUser?
        let favicon: Data?
        
        init(_ user: WikiUser?, favicon: Data? = nil, date: Date = .init()) {
            self.date = date
            self.user = user
            self.favicon = favicon
        }
    }

    struct EntryView : View {
        
        @Environment(\.widgetFamily) private var widgetFamily
        
        var entry: Provider.Entry

        var body: some View {
            if let solidUser = entry.user {
                switch widgetFamily {
                    case .systemSmall:
                        contentSmall(solidUser)
                    case .systemMedium:
                        contentMedium(solidUser)
                    default:
                        EmptyView()
                }
            } else {
                Text("widget.matrix.noUser")
            }
        }
        
        @ViewBuilder
        private func contentMedium(_ user: WikiUser) -> some View {
            VStack {
                HStack {
                    if let image = Image(data: entry.favicon) {
                        image
                            .resizable()
                            .scaledToFit()
                            .clipShape(Circle())
                            .frame(width: 12, height: 12)
                    }
                    Text(user.username.localizedUppercase)
                    Spacer()
                    Text(user.site?.title.localizedUppercase ?? "")
                }
                .lineLimit(1)
                .foregroundColor(.secondary)
                .font(.caption)
                
                ContributionsMatrix(user)
                    .frame(alignment: .bottom)
            }
            .padding()
        }
        
        @ViewBuilder
        private func contentSmall(_ user: WikiUser) -> some View {
            VStack {
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
        .configurationDisplayName("widget.matrix.name")
        .description("widget.matrix.desc")
    }
}

#if DEBUG
struct ContributionsMatrixWidget_Previews: PreviewProvider {
    static var previews: some View {
        ContributionsMatrixWidget.EntryView(entry: .init(Dia.preview.list().first!))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
#endif
