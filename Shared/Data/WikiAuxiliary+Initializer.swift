//
//  WikiAuxiliary+Initializer.swift
//  Wikist
//
//  Created by Lucka on 2/1/2023.
//

import CoreData

extension WikiAuxiliary {
    convenience init(_ wiki: Wiki, context: NSManagedObjectContext) {
        self.init(context: context)
        self.wikiID = wiki.uuid
    }
}
