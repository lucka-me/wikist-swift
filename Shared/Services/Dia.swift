//
//  Dia.swift
//  Wikist
//
//  Created by Lucka on 12/4/2021.
//

import CoreData

class Dia: ObservableObject {

    static let shared = Dia()
    
    private static let directoryURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: FileManager.appGroupIdentifier)!
        .appendingPathComponent("database", isDirectory: true)
    private static let localStoreURL = directoryURL
        .appendingPathComponent("local.sqlite")
    private static let cloudStoreURL = directoryURL
        .appendingPathComponent("cloud.sqlite")
    
    /// Refresh it to force UI refresh after save Core Data
//    @Published private var saveID = UUID()
    
    let context: NSManagedObjectContext
    
    private init(inMemory: Bool = false) {
        let container = NSPersistentCloudKitContainer(name: "Wikist")
        if inMemory {
            #if DEBUG
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
            #endif
        } else {
            if !FileManager.default.fileExists(atPath: Self.localStoreURL.path) {
                try? FileManager.default.createDirectory(
                    at: Self.directoryURL, withIntermediateDirectories: true, attributes: nil
                )
            }
            
            let localStoreDescription = NSPersistentStoreDescription(url: Self.localStoreURL)
            localStoreDescription.configuration = "Local"
            
            let cloudStoreDescription = NSPersistentStoreDescription(url: Self.cloudStoreURL)
            cloudStoreDescription.configuration = "Cloud"
            cloudStoreDescription.cloudKitContainerOptions = .init(containerIdentifier: "iCloud.dev.lucka.Wikist")
            
            container.persistentStoreDescriptions = [
                localStoreDescription, cloudStoreDescription
            ]
        }
        container.loadPersistentStores { storeDescription, error in
            if let solidError = error {
                // Handle error
                print("[CoreData] Failed to load: \(solidError.localizedDescription)")
            }
        }
        context = container.viewContext
        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
    }
    
    func site(of url: String) -> WikiSite? {
        let request: NSFetchRequest<WikiSite> = WikiSite.fetchRequest()
        request.predicate = .init(format: "url = %@", url)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }
    
    func firstUser(sortBy descriptors: [ NSSortDescriptor ]) -> WikiUser? {
        let request: NSFetchRequest<WikiUser> = WikiUser.fetchRequest()
        request.sortDescriptors = descriptors
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }
    
    func user(of id: URL) -> WikiUser? {
        guard
            let coordinator = context.persistentStoreCoordinator,
            let objectID = coordinator.managedObjectID(forURIRepresentation: id)
        else {
            return nil
        }
        return context.object(with: objectID) as? WikiUser
    }
    
    func delete(_ meta: WikiUserMeta) {
        let user = meta.user
        context.delete(meta)
        if let solidUser = user {
            context.delete(solidUser)
        }
    }
    
    func delete(_ site: WikiSite) {
        if site.usersCount == 0 {
            context.delete(site)
        }
    }
    
    func refresh() async {
        let metas: [ WikiUserMeta ] = list()
        await withTaskGroup(of: Void.self) { taskGroup in
            for meta in metas {
                guard let user = meta.user else { continue }
                taskGroup.async {
                    try? await user.refresh()
                }
            }
        }
        await save()
    }
    
    func removeUsersWithoutMeta() {
        let targets: [ WikiUser ] = list().filter { $0.meta == nil }
        for user in targets {
            context.delete(user)
        }
    }
    
    @MainActor
    func save() {
        removeContributionsWithoutUser()
        if !context.hasChanges {
            return
        }
        do {
            try context.save()
//            saveID = .init()
        } catch {
            print("[CoreData][Save] Failed: \(error.localizedDescription)")
        }
    }
    
    func list<T: NSManagedObjectWithFetchRequest>(matches predicate: NSPredicate? = nil) -> [ T ] {
        let request: NSFetchRequest<T> = T.fetchRequest()
        request.predicate = predicate
        return (try? context.fetch(request)) ?? []
    }
    
    /// Clear contributions not linked with user
    private func removeContributionsWithoutUser() {
        let contributions: [ DailyContribution ] = list().filter { $0.user == nil }
        for contribution in contributions {
            context.delete(contribution)
        }
    }
    
    #if DEBUG
    static var preview: Dia = {
        let dia = Dia(inMemory: true)
        let site = WikiSite(context: dia.context)
        site.url = "https://wiki.52poke.com"
        site.title = "Example"
        let user = WikiUser(context: dia.context)
        user.dataId = UUID()
        user.username = "User"
        user.site = site
        let meta = WikiUserMeta(context: dia.context)
        meta.dataId = user.dataId
        meta.username = user.username
        meta.site = site.url
        for _ in 0...100 {
            let date = Date(timeIntervalSinceNow: .init(Int.random(in: 0 ..< Date.daysInYear) * Date.secondsInDay))
            let contribution = DailyContribution(context: dia.context)
            contribution.date = date
            contribution.count = .random(in: 1 ..< 60)
            user.addToContributions(contribution)
        }
        return dia
    }()
    #endif
}
