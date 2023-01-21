//
//  SettingsView.swift
//  Wikist
//
//  Created by Lucka on 23/7/2022.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    DataView()
                } label: {
                    Label("SettingsView.Data", systemImage: "externaldrive")
                }
                
                AboutSection()
            }
            .navigationTitle("SettingsView.Title")
            .toolbar {
                ThemedButton.dismiss {
                    dismiss()
                }
            }
        }
    }
}

#if DEBUG
struct SettingsViewPreviews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
#endif
