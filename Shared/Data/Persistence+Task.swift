//
//  Persistence+Task.swift
//  Wikist
//
//  Created by Lucka on 7/1/2023.
//

import CoreData

extension Persistence {
    func attachRefreshTask(of objectID: NSManagedObjectID, operation whenExists: () async -> Void) async throws {
        try await refreshTaskManager.attachTask(of: objectID, operation: whenExists)
    }
    
    func attachUpdateTask(of objectID: NSManagedObjectID, operation whenExists: () async -> Void) async throws {
        try await updateTaskManager.attachTask(of: objectID, operation: whenExists)
    }
    
    func refresh(user objectID: NSManagedObjectID, with timeZone: TimeZone) async throws {
        try await refreshTaskManager.task(of: objectID) { [ self ] in
            let context = container.refreshContext
            let user = await context.perform {
                context.object(with: objectID) as? User
            }
            guard let user else { return }
            try await user.refresh(with: timeZone, viewContext: container.viewContext)
        }
    }
    
    func update(user objectID: NSManagedObjectID) async throws {
        try await updateTaskManager.task(of: objectID) { [ self ] in
            let context = container.refreshContext
            let user = await context.perform { context.object(with: objectID) as? User }
            guard let user else { return }
            try await user.update()
            try await context.perform {
                if context.hasChanges {
                    try context.save()
                }
            }
        }
    }
    
    func update(wiki objectId: NSManagedObjectID) async throws {
        try await updateTaskManager.task(of: objectId) { [ self ] in
            let context = container.refreshContext
            let wiki = await context.perform { context.object(with: objectId) as? Wiki }
            guard let wiki else { return }
            try await wiki.update()
            try await context.perform {
                if context.hasChanges {
                    try context.save()
                }
            }
        }
    }
}

extension Persistence {
    func clearResidualData() async throws {
        let context = container.refreshContext
        try await context.perform {
            try self.clearResidualContributions(in: context)
            try self.clearResidualWikiAuxiliaries(in: context)
            try context.save()
        }
    }
    
    private func clearResidualContributions(in context: NSManagedObjectContext) throws {
        let usersFetchRequest = User.fetchRequest()
        usersFetchRequest.propertiesToFetch = [ #keyPath(User.uuid) ]
        let users = try context.fetch(usersFetchRequest)
        let uuids: Set<UUID> = users.reduce(into: [ ]) { result, item in
            if let id = item.uuid { result.insert(id) }
        }
        let contributionsFetchRequest = Contribution.fetchRequest() as NSFetchRequest<NSFetchRequestResult>
        contributionsFetchRequest.predicate = .init(
            format: "NOT (%K in %@)", #keyPath(Contribution.userID), uuids
        )
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: contributionsFetchRequest)
        deleteRequest.resultType = .resultTypeObjectIDs
        guard
            let result = try context.execute(deleteRequest) as? NSBatchDeleteResult,
            let ids = result.result as? [ NSManagedObjectID ]
        else {
            return
        }
        NSManagedObjectContext.mergeChanges(
            fromRemoteContextSave: [ NSDeletedObjectsKey: ids], into: [ context ]
        )
    }
    
    private func clearResidualWikiAuxiliaries(in context: NSManagedObjectContext) throws {
        let wikisFetchRequest = Wiki.fetchRequest()
        wikisFetchRequest.propertiesToFetch = [ #keyPath(Wiki.uuid) ]
        let wikis = try context.fetch(wikisFetchRequest)
        let uuids: Set<UUID> = wikis.reduce(into: [ ]) { result, item in
            if let id = item.uuid { result.insert(id) }
        }
        let auxiliariesFetchRequest = WikiAuxiliary.fetchRequest() as NSFetchRequest<NSFetchRequestResult>
        auxiliariesFetchRequest.predicate = .init(
            format: "NOT (%K in %@)", #keyPath(WikiAuxiliary.wikiID), uuids
        )
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: auxiliariesFetchRequest)
        deleteRequest.resultType = .resultTypeObjectIDs
        guard
            let result = try context.execute(deleteRequest) as? NSBatchDeleteResult,
            let ids = result.result as? [ NSManagedObjectID ]
        else {
            return
        }
        NSManagedObjectContext.mergeChanges(
            fromRemoteContextSave: [ NSDeletedObjectsKey: ids], into: [ context ]
        )
    }
}
