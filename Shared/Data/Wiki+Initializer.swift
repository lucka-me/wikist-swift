//
//  Wiki+Initializer.swift
//  Wikist
//
//  Created by Lucka on 4/7/2022.
//

import CoreData

extension Wiki {
    convenience init(_ uuid: UUID = UUID(), api: URL, context: NSManagedObjectContext) {
        self.init(context: context)
        self.uuid = uuid
        self.api = api
    }
}
