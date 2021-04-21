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
    
    func createUser(with dia: Dia) {
        if user != nil {
            return
        }
        if let site = dia.site(of: site) {
            createUser(in: site, with: dia)
        } else {
            createSite(with: dia) { site in
                if self.user == nil {
                    self.createUser(in: site, with: dia)
                }
            }
        }
    }
    
    private func createSite(with dia: Dia, _ callback: @escaping (WikiSite) -> Void) {
        let raw = WikiSiteRAW(site)
        raw.query { succeed in
            guard
                succeed, let solidContext = self.managedObjectContext
            else {
                return
            }
            if let site = dia.site(of: self.site) {
                callback(site)
                return
            }
            callback(.from(raw, context: solidContext))
        }
    }
    
    private func createUser(in site: WikiSite, with dia: Dia) {
        let raw = WikiUserRAW(username, site)
        raw.queryAll { succeed in
            guard
                succeed, let solidContext = self.managedObjectContext
            else {
                dia.delete(site)
                return
            }
            if self.user == nil {
                let _ = WikiUser.from(raw, self.dataId, with: solidContext)
                dia.save()
            }
        }
    }
}
