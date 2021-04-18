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
                .navigationViewStyle(DoubleColumnNavigationViewStyle())
                .tabItem { Label("view.navi.list", systemImage: "list.bullet") }
                .tag("list")
            NavigationView { preferences }
                .navigationViewStyle(StackNavigationViewStyle())
                .tabItem { Label("view.navi.preferences", systemImage: "gearshape") }
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
            .navigationTitle("view.navi.list")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        presentingAddSheet.toggle()
                    } label: {
                        Label("view.navi.list.add", systemImage: "plus")
                    }
                }
                #if os(macOS)
                ToolbarItem {
                    Button(action: toggleSidebar) {
                        Label("view.navi.list.toggleSidebar", systemImage: "sidebar.left")
                    }
                }
                #endif
            }
        
        emptyView
    }
    
    #if os(iOS)
    @ViewBuilder
    private var preferences: some View {
        PreferencesView()
            .navigationTitle("view.navi.preferences")
    }
    
    #endif
    
    @ViewBuilder
    private var emptyView: some View {
        VStack {
            Text("view.navi.list.empty.select")
            Text("view.navi.list.empty.or")
                .foregroundColor(.secondary)
            Button {
                presentingAddSheet.toggle()
            } label: {
                Label("view.navi.list.empty.add", systemImage: "plus")
            }
        }
    }
    
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
