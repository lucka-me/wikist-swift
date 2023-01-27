//
//  UserListView.swift
//  Wikist
//
//  Created by Lucka on 21/11/2022.
//

import SwiftUI

struct UserListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.persistence) private var persistence
    @Environment(\.timeZone) private var timeZone
    
    @FetchRequest(
        entity: User.entity(),
        sortDescriptors: [
            .init(keyPath: \User.wikiTitle, ascending: true),
            .init(keyPath: \User.name, ascending: true)
        ],
        animation: .default
    )
    private var users: FetchedResults<User>
    
    @State private var isAddUserSheetPresented = false
    @State private var isRefreshing = false
    
    var body: some View {
        List {
            ForEach(users) { user in
                NavigationLink(value: user) {
                    UserBriefView(user)
                }
#if os(macOS)
                .contextMenu {
                    Button("UserListView.Delete", role: .destructive) {
                        viewContext.delete(user)
                        do {
                            try viewContext.save()
                        } catch {
                            //
                            print(error)
                        }
                    }
                }
#endif
            }
            .onDelete { indexes in
                let deleteItems = indexes.map { users[$0] }
                do {
                    for item in deleteItems {
                        try item.removeAllContributions()
                        viewContext.delete(item)
                    }
                    try viewContext.save()
                } catch {
                    //
                    print(error)
                }
            }
        }
        .refreshable { await refresh() }
        .navigationTitle("UserListView.Title")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
#if os(macOS)
                ThemedButton.refresh(isRefreshing: isRefreshing) {
                    await refresh()
                }
#endif
                ThemedButton.add {
                    isAddUserSheetPresented.toggle()
                }
            }
        }
        .sheet(isPresented: $isAddUserSheetPresented, onDismiss: viewContext.rollback) {
            AddUserView()
        }
    }
    
    @MainActor
    private func refresh() async {
        guard !isRefreshing else { return }
        
        isRefreshing = true
        defer {
            isRefreshing = false
        }
        let ids = users.map { $0.objectID }
        await withTaskGroup(of: Void.self) { group in
            for id in ids {
                group.addTask {
                    try? await persistence.refresh(user: id, with: timeZone)
                }
            }
        }
    }
}

#if DEBUG
struct UserListViewPreviews: PreviewProvider {
    static var previews: some View {
        UserListView()
            .environment(\.managedObjectContext, Persistence.preview.container.viewContext)
            .environment(\.persistence, Persistence.preview)
    }
}
#endif
