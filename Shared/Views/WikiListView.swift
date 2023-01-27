//
//  WikiListView.swift
//  Wikist
//
//  Created by Lucka on 22/11/2022.
//

import SwiftUI

struct WikiListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.persistence) private var persistence
    
    @FetchRequest(
        entity: Wiki.entity(),
        sortDescriptors: [ .init(keyPath: \Wiki.title, ascending: true) ],
        animation: .default
    )
    private var wikis: FetchedResults<Wiki>
    
    @State private var isAddWikiSheetPresented = false
    @State private var isRefreshing = false
    @State private var selection: Wiki? = nil
    @State private var wikiToAddUser: Wiki? = nil
    
    var body: some View {
        List {
            ForEach(wikis) { wiki in
                NavigationLink(value: wiki) {
                    row(for: wiki)
                }
#if os(macOS)
                .contextMenu {
                    leadingActions(wiki)
                    trailingActions(wiki)
                }
#endif
                .swipeActions(edge: .leading) {
                    leadingActions(wiki)
                }
                .swipeActions(edge: .trailing) {
                    trailingActions(wiki)
                }
            }
        }
        .refreshable { await refresh() }
        .navigationTitle("WikiListView.Title")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
#if os(macOS)
                ThemedButton.refresh(isRefreshing: isRefreshing) {
                    await refresh()
                }
#endif
                ThemedButton.add {
                    isAddWikiSheetPresented.toggle()
                }
            }
        }
        .sheet(isPresented: $isAddWikiSheetPresented) {
            AddWikiView(wiki: $selection)
        }
        .sheet(item: $wikiToAddUser, onDismiss: viewContext.rollback) { wiki in
            AddUserView(wiki: wiki)
        }
    }
    
    @ViewBuilder
    private func leadingActions(_ wiki: Wiki) -> some View {
        Button {
            wikiToAddUser = wiki
        } label: {
            Label("WikiListView.AddUser", systemImage: "person.badge.plus")
        }
        .tint(.blue)
    }
    
    @ViewBuilder
    private func trailingActions(_ wiki: Wiki) -> some View {
        if wiki.usersCount == 0 {
            Button(role: .destructive) {
                do {
                    try wiki.deleteAuxilary()
                    viewContext.delete(wiki)
                    try viewContext.save()
                } catch {
                    // TODO: Alert?
                    print(error)
                }
            } label: {
                Label("WikiListView.Delete", systemImage: "trash")
            }
        }
    }
    
    @ViewBuilder
    private func row(for wiki: Wiki) -> some View {
        VStack(alignment: .leading) {
            HStack {
                AsyncImage(url: wiki.favicon) { image in
                    image
                        .resizable()
                } placeholder: {
                    Circle()
                        .fill(.secondary)
                }
                .frame(width: 12, height: 12, alignment: .center)
                Text(wiki.title ?? "WikiListView.Row.DefaultTitle")
                    .font(.headline)
            }
            Text(wiki.api?.absoluteString ?? "WikiListView.Row.DefaultAPI")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .lineLimit(1)
    }
    
    @MainActor
    private func refresh() async {
        guard !isRefreshing else { return }
        
        isRefreshing = true
        defer {
            isRefreshing = false
        }
        let ids = wikis.map { $0.objectID }
        await withTaskGroup(of: Void.self) { group in
            for id in ids {
                group.addTask {
                    try? await persistence.update(wiki: id)
                }
            }
        }
    }
}

#if DEBUG
struct WikiListViewPreviews: PreviewProvider {
    static var previews: some View {
        WikiListView()
            .environment(\.managedObjectContext, Persistence.preview.container.viewContext)
            .environment(\.persistence, Persistence.preview)
    }
}
#endif
