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
                refreshAll()
            }
        }
    }
    
    private func refreshAll() {
        let users = dia.users()
        for user in users {
            user.refresh { succeed in
                dia.save()
            }
        }
    }
}
