//
//  Persistence+Request.swift
//  Wikist
//
//  Created by Lucka on 2/2/2023.
//

import CoreData

extension Persistence {
    func clearResidualData() throws {
        try self.clearResidualContributions()
        try self.clearResidualWikiAuxiliaries()
    }

    private func clearResidualContributions() throws {
        let usersFetchRequest = User.fetchRequest()
        usersFetchRequest.propertiesToFetch = [ #keyPath(User.uuid) ]
        let users = try container.viewContext.fetch(usersFetchRequest)
        let uuids: Set<UUID> = users.reduce(into: [ ]) { result, item in
            if let id = item.uuid { result.insert(id) }
        }
        let contributionsFetchRequest = Contribution.fetchRequest() as NSFetchRequest<NSFetchRequestResult>
        contributionsFetchRequest.predicate = .init(
            format: "NOT (%K in %@)", #keyPath(Contribution.userID), uuids
        )
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: contributionsFetchRequest)
        deleteRequest.resultType = .resultTypeCount
        try container.viewContext.execute(deleteRequest)
    }

    private func clearResidualWikiAuxiliaries() throws {
        let wikisFetchRequest = Wiki.fetchRequest()
        wikisFetchRequest.propertiesToFetch = [ #keyPath(Wiki.uuid) ]
        let wikis = try container.viewContext.fetch(wikisFetchRequest)
        let uuids: Set<UUID> = wikis.reduce(into: [ ]) { result, item in
            if let id = item.uuid { result.insert(id) }
        }
        let auxiliariesFetchRequest = WikiAuxiliary.fetchRequest() as NSFetchRequest<NSFetchRequestResult>
        auxiliariesFetchRequest.predicate = .init(
            format: "NOT (%K in %@)", #keyPath(WikiAuxiliary.wikiID), uuids
        )
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: auxiliariesFetchRequest)
        deleteRequest.resultType = .resultTypeCount
        try container.viewContext.execute(deleteRequest)
    }
}

extension Persistence {
    func clearContributions(of userID: UUID, mergeChanges: Bool = false) async throws {
        let context = container.refreshContext
        let fetchRequest = Contribution.fetchRequest() as NSFetchRequest<NSFetchRequestResult>
        fetchRequest.predicate = .init(format: "%K == %@", #keyPath(Contribution.userID), userID as NSUUID)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        deleteRequest.resultType = mergeChanges ? .resultTypeObjectIDs : .resultTypeCount
        let result = try await context.perform {
            try context.execute(deleteRequest) as? NSBatchDeleteResult
        }
        guard mergeChanges, let ids = result?.result as? [ NSManagedObjectID ] else { return }
        NSManagedObjectContext.mergeChanges(
            fromRemoteContextSave: [ NSDeletedObjectsKey: ids ], into: [ container.viewContext ]
        )
    }
}
