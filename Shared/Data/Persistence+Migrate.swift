//
//  Persistence+Migrate.swift
//  Wikist
//
//  Created by Lucka on 5/12/2022.
//

import CoreData

extension Persistence {
    
    enum MigrateStage : Equatable {
        case unavailable
        case available
        case migrating
        case done(wikis: Int, users: Int)
        case failed
    }
    
    enum MigrateError: Error, LocalizedError {
        case genericError(error: Error)
        
        var errorDescription: String? {
            switch self {
            case .genericError(error: let error):
                return error.localizedDescription
            }
        }
    }
    
    private static let legacyLocalStoreURL = directoryURL.appendingPathComponent("local.sqlite")
    private static let legacyCloudStoreURL = directoryURL.appendingPathComponent("cloud.sqlite")
    
    static var legacyStoreExists: Bool {
        FileManager.default.fileExists(atPath: Self.legacyLocalStoreURL.path(percentEncoded: false))
    }
    
    func migrate() async throws -> (Int, Int) {
        let legacyContainer = NSPersistentCloudKitContainer(name: "Legacy")
        let localStoreDescription = NSPersistentStoreDescription(url: Self.legacyLocalStoreURL)
        localStoreDescription.configuration = "Local"
        legacyContainer.persistentStoreDescriptions = [ localStoreDescription ]
        var loadError: Error? = nil
        legacyContainer.loadPersistentStores { description, error in
            if let error {
                loadError = error
            }
        }
        if let loadError { throw loadError }
        
        defer {
            let coordinator = legacyContainer.persistentStoreCoordinator
            let stores = coordinator.persistentStores
            for store in stores {
                var url = coordinator.url(for: store)
                try? coordinator.remove(store)
                // Seems not working?
                try? coordinator.destroyPersistentStore(at: url, type: .sqlite)
                // Delete manually...
                try? FileManager.default.removeItem(at: url)
                url.deletePathExtension()
                try? FileManager.default.removeItem(at: url.appendingPathExtension("sqlite-shm"))
                try? FileManager.default.removeItem(at: url.appendingPathExtension("sqlite-wal"))
            }
        }
        
        let context = container.newBackgroundContext()
        context.name = "migrate"
        let legacyContext = legacyContainer.newBackgroundContext()
        legacyContext.name = "migrate-legacy"
        
        let legacySites = try await legacyContext.perform {
            let fetchRequest = LegacyWikiSite.fetchRequest()
            return try legacyContext.fetch(fetchRequest)
        }
        guard !legacySites.isEmpty else { return (0, 0) }
        
        var migratedWikisCount = 0
        var migratedUsersCount = 0
        try await context.perform {
            for legacySite in legacySites {
                guard
                    let url = legacySite.url,
                    let api = URL(string: url + "/api.php")
                else {
                    continue
                }
                let wiki: Wiki
                if let existedWiki = Wiki.findExistedWiki(for: api, in: context) {
                    wiki = existedWiki
                } else {
                    wiki = .init(api: api, context: context)
                    wiki.migrate(from: legacySite)
                    migratedWikisCount += 1
                }
                let legacyUsers = legacyContext.performAndWait {
                    let fetchRequest = LegacyWikiUser.fetchRequest()
                    fetchRequest.predicate = .init(format: "%K == %@", #keyPath(LegacyWikiUser.site), legacySite)
                    let result = try? legacyContext.fetch(fetchRequest)
                    return result ?? [ ]
                }
                guard !legacyUsers.isEmpty else { continue }
                for legacyUser in legacyUsers {
                    guard
                        let username = legacyUser.username,
                        !wiki.contains(user: username)
                    else {
                        continue
                    }
                    let user = User(name: username, wiki: wiki, context: context)
                    user.registration = legacyUser.registration
                    user.userID = legacyUser.userId
                    migratedUsersCount += 1
                }
            }
            if context.hasChanges {
                try context.save()
            }
        }
        
        return (migratedWikisCount, migratedUsersCount)
    }
}

extension Persistence.MigrateStage {
    var descriptions: String {
        switch self {
        case .unavailable:
            return ""
        case .available:
            return "It seems that you've updated from a former version and may have already added some users. Tap the icon to migrate the data."
        case .migrating:
            return "Migrating..."
        case .done(wikis: let wikis, users: let users):
            return "Migrated \(wikis) wikis and \(users) users."
        case .failed:
            return "Failed."
        }
    }
    
    var iconName: String {
        switch self {
        case .done(count: _):
            return "checkmark.seal"
        case .failed:
            return "exclamationmark.octagon"
        default:
            return "shippingbox.and.arrow.backward"
        }
    }
}

fileprivate extension Wiki {
    func migrate(from site: LegacyWikiSite) {
        self.articlePath = site.articlePath
        if let favicon = site.favicon, var favicon = URL(string: favicon) {
            favicon.set(scheme: "https")
            self.favicon = favicon
        }
        self.language = site.language
        if let logo = site.logo, var logo = URL(string: logo) {
            logo.set(scheme: "https")
            self.logo = logo
        }
        self.title = site.title
    }
}
