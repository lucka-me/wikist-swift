//
//  PersistentContainer.swift
//  Wikist
//
//  Created by Lucka on 9/12/2022.
//

import CoreData

class PersistentContainer: NSPersistentCloudKitContainer {
    
    static let refreshContextName = "refresh"
    static let statisticsContextName = "statistics"
    static let updateContextName = "update"
    static let viewContextName = "view"

    override init(name: String, managedObjectModel model: NSManagedObjectModel) {
        super.init(name: name, managedObjectModel: model)

        viewContext.name = Self.viewContextName
        viewContext.automaticallyMergesChangesFromParent = true
        viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    var refreshContext: NSManagedObjectContext {
        let context = newBackgroundContext()
        context.name = Self.refreshContextName
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.undoManager = nil
        return context
    }
    
    var statisticsContext: NSManagedObjectContext {
        let context = newBackgroundContext()
        context.name = Self.statisticsContextName
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.undoManager = nil
        return context
    }
    
    var updateContext: NSManagedObjectContext {
        let context = newBackgroundContext()
        context.name = Self.updateContextName
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.undoManager = nil
        return context
    }
}
