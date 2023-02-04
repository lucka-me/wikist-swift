//
//  Persistence+Task.swift
//  Wikist
//
//  Created by Lucka on 7/1/2023.
//

import CoreData

extension Persistence {
    func attachRefreshTask(of objectID: NSManagedObjectID, operation whenExists: () async -> Void) async throws {
        try await refreshTaskManager.attachTask(of: objectID, operation: whenExists)
    }
    
    func attachUpdateTask(of objectID: NSManagedObjectID, operation whenExists: () async -> Void) async throws {
        try await updateTaskManager.attachTask(of: objectID, operation: whenExists)
    }
    
    func refresh(user objectID: NSManagedObjectID, with timeZone: TimeZone) async throws {
        try await refreshTaskManager.task(of: objectID) { [ self ] in
            let context = container.refreshContext
            let user = await context.perform {
                context.object(with: objectID) as? User
            }
            guard let user else { return }
            try await user.refresh(with: timeZone, viewContext: container.viewContext)
        }
    }
    
    func update(user objectID: NSManagedObjectID) async throws {
        try await updateTaskManager.task(of: objectID) { [ self ] in
            let context = container.refreshContext
            let user = await context.perform { context.object(with: objectID) as? User }
            guard let user else { return }
            try await user.update()
            try await context.perform {
                if context.hasChanges {
                    try context.save()
                }
            }
        }
    }
    
    func update(wiki objectId: NSManagedObjectID) async throws {
        try await updateTaskManager.task(of: objectId) { [ self ] in
            let context = container.refreshContext
            let wiki = await context.perform { context.object(with: objectId) as? Wiki }
            guard let wiki else { return }
            try await wiki.update()
            try await context.perform {
                if context.hasChanges {
                    try context.save()
                }
            }
        }
    }
}
