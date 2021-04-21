//
//  IntentHandler.swift
//  WidgetConfiguration
//
//  Created by Lucka on 14/4/2021.
//

import Intents

class IntentHandler: INExtension, ContributionsMatrixConfigurationIntentHandling {
    
    func resolveSelectedUser(for intent: ContributionsMatrixConfigurationIntent, with completion: @escaping (ContributionsMatrixConfigurationUserResolutionResult) -> Void) {
        guard
            intent.customUser?.boolValue ?? false,
            let selectedUser = intent.selectedUser
        else {
            guard
                let defaultUserData = Dia.shared.firstUser(sortBy: WikiUser.sortDescriptorsByEdits),
                let site = defaultUserData.site
            else {
                completion(.success(with: .init(identifier: nil, display: "")))
                return
            }
            let defaultUser = ContributionsMatrixConfigurationUser(
                identifier: defaultUserData.objectID.uriRepresentation().absoluteString,
                display: "\(defaultUserData.username) | \(site.title)"
            )
            completion(.success(with: defaultUser))
            return
        }
        completion(.success(with: selectedUser))
    }
    
    func provideSelectedUserOptionsCollection(
        for intent: ContributionsMatrixConfigurationIntent,
        with completion: @escaping (INObjectCollection<ContributionsMatrixConfigurationUser>?, Error?) -> Void
    ) {
        let metas: [ WikiUserMeta ] = Dia.shared.list()
        let items: [ ContributionsMatrixConfigurationUser ] = metas
            .compactMap { $0.user }
            .sorted { $0.edits > $1.edits }
            .compactMap { user in
                guard let site = user.site else {
                    return nil
                }
                return .init(
                    identifier: user.objectID.uriRepresentation().absoluteString,
                    display: "\(user.username) | \(site.title)"
                )
            }
        completion(.init(items: items), nil)
    }
    
}
