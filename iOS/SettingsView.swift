//
//  SettingsView.swift
//  Wikist
//
//  Created by Lucka on 23/7/2022.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        List {
            NavigationLink {
                DataView()
            } label: {
                Label("SettingsView.Data", systemImage: "externaldrive")
            }
            
            AboutSection()
        }
        .navigationTitle("SettingsView.Title")
    }
}

#if DEBUG
struct SettingsViewPreviews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
#endif
