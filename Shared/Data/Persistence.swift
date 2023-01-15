//
//  Persistence.swift
//  Wikist
//
//  Created by Lucka on 19/6/2022.
//

import CoreData

class Persistence {
    static let shared = Persistence()
    
#if DEBUG
    static let preview = Persistence(inMemory: true)
#endif
    
    static let directoryURL = FileManager.default
        .containerURL(forSecurityApplicationGroupIdentifier: FileManager.appGroupIdentifier)!
        .appendingPathComponent("database", isDirectory: true)
    
    private static let localStoreURL = directoryURL.appendingPathComponent("local.store")
    private static let cloudStoreURL = directoryURL.appendingPathComponent("cloud.store")
    
    let container: PersistentContainer
    
    var refreshTaskManager = TaskManager<NSManagedObjectID, Void, Error>()
    var updateTaskManager = TaskManager<NSManagedObjectID, Void, Error>()
    
    private init(inMemory: Bool = false) {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: Self.directoryURL.path(percentEncoded: false)) {
            try? fileManager.createDirectory(at: Self.directoryURL, withIntermediateDirectories: true)
        }
        
        container = PersistentContainer(name: "Wikist")
        
        let localStoreDescription = NSPersistentStoreDescription(
            url: inMemory ? .init(fileURLWithPath: "/dev/null") : Self.localStoreURL
        )
        localStoreDescription.configuration = "Local"
        
        let cloudStoreDescription = NSPersistentStoreDescription(
            url: inMemory ? .init(fileURLWithPath: "/dev/null") : Self.cloudStoreURL
        )
        cloudStoreDescription.configuration = "Cloud"
        if !inMemory {
            cloudStoreDescription.cloudKitContainerOptions = .init(containerIdentifier: "iCloud.dev.lucka.Wikist")
        }
        
        self.container.persistentStoreDescriptions = [ localStoreDescription, cloudStoreDescription ]
        
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }
}

actor TaskManager<Key: Hashable, Success: Sendable, Failure: Error> {
    var tasks: [ Key : Task<Success, Failure> ] = [ : ]
}

extension TaskManager where Failure == Never {
    func attachTask(of key: Key, operation whenExists: () async -> Void) async -> Success? {
        guard let task = tasks[key] else { return nil }
        await whenExists()
        return await task.value
    }
    
    func task(of key: Key, operation: @escaping @Sendable () async -> Success) async -> Success {
        if let task = tasks[key] {
            return await task.value
        }
        let task = Task(operation: operation)
        defer { tasks.removeValue(forKey: key) }
        tasks[key] = task
        return await task.value
    }
}

extension TaskManager where Failure == Error {
    func attachTask(of key: Key, operation whenExists: () async -> Void) async throws -> Success? {
        guard let task = tasks[key] else { return nil }
        await whenExists()
        return try await task.value
    }
    
    func task(of key: Key, operation: @escaping @Sendable () async throws -> Success) async throws -> Success {
        if let task = tasks[key] {
            return try await task.value
        }
        let task = Task(operation: operation)
        defer { tasks.removeValue(forKey: key) }
        tasks[key] = task
        return try await task.value
    }
}
