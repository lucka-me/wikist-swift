//
//  User+Initializer.swift
//  Wikist
//
//  Created by Lucka on 4/7/2022.
//

import CoreData

extension User {
    convenience init(_ uuid: UUID = UUID(), name: String, wiki: Wiki, context: NSManagedObjectContext) {
        self.init(context: context)
        self.uuid = uuid
        self.name = name
        self.wiki = wiki
    }
}
