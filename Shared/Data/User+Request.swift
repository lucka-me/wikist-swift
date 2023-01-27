//
//  User+Request.swift
//  Wikist
//
//  Created by Lucka on 8/7/2022.
//

import CoreData

extension User {
    func removeAllContributions() throws {
        guard let managedObjectContext, let uuid else { return }
        let fetchRequest = Contribution.fetchRequest() as NSFetchRequest<NSFetchRequestResult>
        fetchRequest.predicate = .init(format: "%K == %@", #keyPath(Contribution.userID), uuid as NSUUID)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        deleteRequest.resultType = .resultTypeObjectIDs
        guard
            let result = try managedObjectContext.execute(deleteRequest) as? NSBatchDeleteResult,
            let ids = result.result as? [ NSManagedObjectID ]
        else {
            return
        }
        NSManagedObjectContext.mergeChanges(
            fromRemoteContextSave: [ NSDeletedObjectsKey: ids], into: [ managedObjectContext ]
        )
    }
}
