//
//  IntentHandler.swift
//  WidgetConfiguration
//
//  Created by Lucka on 14/4/2021.
//

import Intents

class IntentHandler: INExtension, ContributionsMatrixConfigurationIntentHandling {
    func provideUserOptionsCollection(
        for intent: ContributionsMatrixConfigurationIntent
    ) async throws -> INObjectCollection<WidgetConfigurationUser> {
        let context = Persistence.shared.container.viewContext
        let users = await context.perform {
            let request = User.fetchRequest()
            request.sortDescriptors = [
                .init(keyPath: \User.wikiTitle, ascending: true),
                .init(keyPath: \User.name, ascending: true)
            ]
            let result = try? context.fetch(request)
            return result ?? [ ]
        }
        let items = users.map { user in
            let username = user.name ?? "Anonymous"
            let wikiTitle = user.wiki?.title ?? "Untitled"
            return WidgetConfigurationUser(
                identifier: user.objectID.uriRepresentation().absoluteString,
                display: "\(username) | \(wikiTitle)"
            )
        }
        return .init(items: items)
    }
}
