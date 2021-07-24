//
//  ContentView.swift
//  Shared
//
//  Created by Lucka on 11/4/2021.
//

import SwiftUI

struct ContentView: View {
    
    private enum SheetItem: Identifiable {
        case addSheet
        #if os(iOS)
        case preferences
        #endif
        
        var id: Int { self.hashValue }
    }
    
    @State private var sheetItem: SheetItem? = nil
    
    var body: some View {
        NavigationView {
            UserList()
                .navigationTitle("view.list")
                .sheet(item: $sheetItem) { item in
                    #if os(macOS)
                    sheetContent(of: item)
                        .frame(minWidth: 350, minHeight: 400)
                    #else
                    NavigationView {
                        sheetContent(of: item)
                    }
                    .navigationViewStyle(.stack)
                    #endif
                }
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            sheetItem = .addSheet
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
                            sheetItem = .preferences
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
                    sheetItem = .addSheet
                } label: {
                    Label("view.list.empty.add", systemImage: "plus")
                }
            }
        }
    }
    
    @ViewBuilder
    private func sheetContent(of item: SheetItem) -> some View {
        switch item {
            case .addSheet:
                AddForm()
            #if os(iOS)
            case .preferences:
                PreferencesView()
            #endif
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
