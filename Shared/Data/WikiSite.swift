//
//  WikiSite+CoreDataClass.swift
//  Wikist
//
//  Created by Lucka on 11/4/2021.
//
//

import CoreData

@objc(WikiSite)
public final class WikiSite: NSManagedObject, NSManagedObjectWithFetchRequest {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<WikiSite> {
        return NSFetchRequest<WikiSite>(entityName: "WikiSite")
    }
}

extension WikiSite {

    @NSManaged public var url: String
    @NSManaged public var title: String
    @NSManaged public var homepage: String
    @NSManaged public var logo: String
    @NSManaged public var favicon: String
    @NSManaged public var server: String
    @NSManaged public var articlePath: String
    @NSManaged public var users: NSSet?

}

// MARK: Generated accessors for users
extension WikiSite {

    @objc(addUsersObject:)
    @NSManaged public func addToUsers(_ value: WikiUser)

    @objc(removeUsersObject:)
    @NSManaged public func removeFromUsers(_ value: WikiUser)

    @objc(addUsers:)
    @NSManaged public func addToUsers(_ values: NSSet)

    @objc(removeUsers:)
    @NSManaged public func removeFromUsers(_ values: NSSet)

}

extension WikiSite : Identifiable {

}

extension WikiSite {    
    static func from(_ raw: WikiSiteRAW, context: NSManagedObjectContext) -> WikiSite {
        let object = WikiSite(context: context)
        object.url = raw.url
        object.from(raw)
        return object
    }
    
    func from(_ raw: WikiSiteRAW) {
        if raw.url != url {
            return
        }
        title = raw.title
        homepage = raw.homepage
        logo = raw.logo
        server = raw.server
        articlePath = raw.articlePath
    }
}

extension WikiSite {
    
    var api: String {
        url + "/api.php"
    }
    
    var usersCount: Int {
        users?.count ?? 0
    }
    
    func articleURL(of title: String) -> URL? {
        return URL(raw: server + articlePath.replacingOccurrences(of: "$1", with: title))
    }
    
    func refresh(_ callback: @escaping WikiSiteRAW.QueryCallback) {
        let raw = WikiSiteRAW(url)
        raw.query { succeed in
            if succeed {
                self.from(raw)
            }
            callback(succeed)
        }
    }
}
