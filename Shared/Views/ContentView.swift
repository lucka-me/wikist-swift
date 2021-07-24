//
//  ContentView.swift
//  Shared
//
//  Created by Lucka on 11/4/2021.
//

import SwiftUI

struct ContentView: View {
    
    private enum SheetContent: Identifiable {
        case addSheet
        #if os(iOS)
        case preferences
        #endif
        
        var id: Int { self.hashValue }
    }
    
    #if os(macOS)
    @ObservedObject private var support = Support.shared
    #endif
    @State private var sheetContent: SheetContent? = nil
    
    var body: some View {
        NavigationView {
            UserList()
                .navigationTitle("view.list")
                .sheet(item: $sheetContent) { content in
                    switch content {
                        case .addSheet:
                            AddForm()
                        #if os(iOS)
                        case .preferences:
                            PreferencesView()
                        #endif
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            sheetContent = .addSheet
                        } label: {
                            Label("view.list.add", systemImage: "plus")
                        }
                    }
                    #if os(macOS)
                    ToolbarItem {
                        Button(action: toggleSidebar) {
                            Label("view.list.toggleSidebar", systemImage: "sidebar.left")
                        }
                    }
                    #else
                    ToolbarItem(placement: .navigation) {
                        Button {
                            sheetContent = .preferences
                        } label: {
                            Label("view.preferences", systemImage: "gear")
                        }
                    }
                    #endif
                }
            
            VStack {
                Text("view.list.empty.select")
                Text("view.list.empty.or")
                    .foregroundColor(.secondary)
                Button {
                    sheetContent = .addSheet
                } label: {
                    Label("view.list.empty.add", systemImage: "plus")
                }
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
