//
//  WikistApp.swift
//  Wikist
//
//  Created by Lucka on 11/4/2021.
//

import SwiftUI

@main
struct WikistApp: App {
    
    @Environment(\.scenePhase) private var scenePhase
    
    private let persistence = Persistence.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
#if os(macOS)
                .frame(minWidth: 500, minHeight: 200)
#endif
                .environment(\.managedObjectContext, persistence.container.viewContext)
                .environment(\.persistence, persistence)
        }
        .onChange(of: scenePhase) { newValue in
            if newValue == .background {
                do {
                    try persistence.clearResidualData()
                    if persistence.container.viewContext.hasChanges {
                        try persistence.container.viewContext.save()
                    }
                } catch {
                    print(error)
                }
            }
        }
#if os(macOS)
        Settings {
            SettingsView()
                .environment(\.managedObjectContext, persistence.container.viewContext)
                .environment(\.persistence, persistence)
        }
#endif
    }
}
