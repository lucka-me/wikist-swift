//
//  WikiUserMeta+CoreDataClass.swift
//  Wikist
//
//  Created by Lucka on 21/4/2021.
//
//

import CoreData

@objc(WikiUserMeta)
public final class WikiUserMeta: NSManagedObject, NSManagedObjectWithFetchRequest {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<WikiUserMeta> {
        return NSFetchRequest<WikiUserMeta>(entityName: "WikiUserMeta")
    }
}

extension WikiUserMeta {

    @NSManaged public var dataId: UUID
    @NSManaged public var site: String
    @NSManaged public var username: String

}

extension WikiUserMeta : Identifiable {

}

extension WikiUserMeta {
    static func predicate(of dataId: UUID) -> NSPredicate {
        .init(format: "dataId = %@", dataId as CVarArg)
    }
}

extension WikiUserMeta {
    
    var userPredicate: NSPredicate {
        WikiUser.predicate(of: dataId)
    }
    
    var user: WikiUser? {
        guard let solidContext = managedObjectContext else {
            return nil
        }
        let request: NSFetchRequest<WikiUser> = WikiUser.fetchRequest()
        request.predicate = userPredicate
        return try? solidContext.fetch(request).first
    }
    
    func createUser(with dia: Dia) async throws {
        guard user == nil else { return }
        let siteRaw = WikiSiteRAW(site)
        try await siteRaw.query()
        let site: WikiSite
        // Check site
        if let existing = dia.site(of: self.site) {
            site = existing
        } else {
            site = .from(siteRaw, context: dia.context)
        }
        // Check user again
        guard user == nil else { return }
        let userRaw = WikiUserRAW(username, site)
        try await userRaw.query()
        // Check user again
        if user == nil {
            let _ = WikiUser.from(userRaw, dataId, with: dia.context)
            await dia.save()
        }
    }
}
