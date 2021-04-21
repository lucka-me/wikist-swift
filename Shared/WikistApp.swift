//
//  WikistApp.swift
//  Shared
//
//  Created by Lucka on 11/4/2021.
//

import SwiftUI

@main
struct WikistApp: App {
    
    @Environment(\.scenePhase) private var scenePhase : ScenePhase
    @State private var lastRefresh = Date(timeIntervalSince1970: 0)
    private let dia = Dia.shared
    
    var body: some Scene {
        #if os(macOS)
        content
            .commands {
                WikistCommand()
            }
        #else
        content
        #endif
    }
    
    @SceneBuilder
    private var content: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, dia.context)
                .environmentObject(dia)
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                dia.clear()
                let now = Date()
                if now.distance(to: lastRefresh) >= 30 * 3600 {
                    dia.refresh()
                    lastRefresh = now
                }
            }
        }
    }
}
