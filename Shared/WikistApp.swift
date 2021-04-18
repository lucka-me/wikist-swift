//
//  WikistApp.swift
//  Shared
//
//  Created by Lucka on 11/4/2021.
//

import SwiftUI

@main
struct WikistApp: App {
    
    private let dia = Dia.shared
    
    var body: some Scene {
        #if os(macOS)
        WindowGroup {
            content
        }
        .commands {
            WikistCommand()
        }
        #else
        WindowGroup {
            content
        }
        #endif
    }
    
    @ViewBuilder
    private var content: some View {
        ContentView()
            .environment(\.managedObjectContext, dia.context)
            .environmentObject(dia)
    }
}
