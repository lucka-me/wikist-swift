//
//  WikistCommands.swift
//  macOS
//
//  Created by Lucka on 18/4/2021.
//

import SwiftUI

struct WikistCommand: Commands {
    
    @Environment(\.openURL) private var openURL
    
    var body: some Commands {
        SidebarCommands()
        CommandGroup(after: .help) {
            Button("Tip") {
                Support.shared.presentingTipSheet = true
            }
            .disabled(!Support.shared.canMakePayments)
            Button("Source Code") {
                openURL(URL(string: "https://github.com/lucka-me/wikist-swift")!)
            }
        }
    }
}
