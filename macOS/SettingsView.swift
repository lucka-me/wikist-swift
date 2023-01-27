//
//  SettingsView.swift
//  Wikist
//
//  Created by Lucka on 10/12/2022.
//

import SwiftUI

struct SettingsView: View {
    
    var body: some View {
        TabView {
            DataView()
                .tabItem {
                    Label("SettingsView.Data", systemImage: "externaldrive.fill")
                }
            aboutPage
                .tabItem {
                    Label("SettingsView.About", systemImage: "info.circle.fill")
                }
        }
        .frame(minWidth: 500, minHeight: 300)
    }
    
    @ViewBuilder
    private var aboutPage: some View {
        Form {
            AboutSection()
        }
        .formStyle(.grouped)
        .navigationTitle("SettingsView.About")
    }
}

#if DEBUG
struct SettingsViewPreviews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
#endif
