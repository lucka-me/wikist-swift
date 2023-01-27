//
//  Wiki+Request.swift
//  Wikist
//
//  Created by Lucka on 10/7/2022.
//

import CoreData

extension Wiki {
    static func findExistedWiki(for api: URL, in context: NSManagedObjectContext) async -> Wiki? {
        let request = Self.fetchRequest()
        request.predicate = .init(format: "%K == %@", #keyPath(Wiki.api), api as CVarArg)
        request.fetchLimit = 1
        return await context.perform {
            guard let result = try? context.fetch(request) else { return nil }
            return result.first
        }
    }
    
    static func findExistedWiki(for api: URL, in context: NSManagedObjectContext) -> Wiki? {
        let request = Self.fetchRequest()
        request.predicate = .init(format: "%K == %@", #keyPath(Wiki.api), api as CVarArg)
        request.fetchLimit = 1
        guard let result = try? context.fetch(request) else { return nil }
        return result.first
    }
}

extension Wiki {
    func url(of page: String) -> URL? {
        guard
            let api, let articlePath,
            let root = api.removingAllPaths()
        else {
            return nil
        }
        let path = articlePath.replacingOccurrences(of: "$1", with: page)
        return root.appending(path: path)
    }
}

extension Wiki {
    func contains(user: String) -> Bool {
        guard let managedObjectContext else { return false }
        let request = User.fetchRequest()
        request.predicate = .init(
            format: "%K == %@ AND %K == %@",
            #keyPath(User.name), user,
            #keyPath(User.wiki), self
        )
        guard let result = try? managedObjectContext.count(for: request) else { return false }
        return result > 0
    }
}

extension Wiki {
    func deleteAuxilary() throws {
        guard let managedObjectContext, let auxiliary else { return }
        managedObjectContext.delete(auxiliary)
        managedObjectContext.refresh(self, mergeChanges: true)
    }
}
