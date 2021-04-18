//
//  ContentView.swift
//  Shared
//
//  Created by Lucka on 11/4/2021.
//

import SwiftUI

struct ContentView: View {
    
    #if os(macOS)
    @ObservedObject private var support = Support.shared
    #endif
    @State private var presentingAddSheet = false
    
    var body: some View {
        #if os(macOS)
        NavigationView {
            list
        }
        .sheet(isPresented: $support.presentingTipSheet) {
            TipView()
        }
        #else
        TabView {
            NavigationView { list }
                .tabItem { Label("List", systemImage: "list.bullet") }
                .tag("list")
            NavigationView { preferences }
                .tabItem { Label("Preferences", systemImage: "gearshape") }
                .tag("preferences")
        }
        #endif
    }
    
    @ViewBuilder
    private var list: some View {
        UserList()
            .sheet(isPresented: $presentingAddSheet) {
                AddView()
            }
            .navigationTitle("Wikist")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        presentingAddSheet.toggle()
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                }
                #if os(macOS)
                ToolbarItem {
                    Button(action: toggleSidebar) {
                        Label("Toggle Sidebar", systemImage: "sidebar.left")
                    }
                }
                #endif
            }
        
        EmptyView()
    }
    
    #if os(iOS)
    @ViewBuilder
    private var preferences: some View {
        PreferencesView()
            .navigationTitle("Preferences")
    }
    #endif
    
    #if os(macOS)
    private func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }
    #endif
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
