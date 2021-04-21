//
//  UserList.swift
//  Wikist
//
//  Created by Lucka on 11/4/2021.
//

import SwiftUI

struct UserList: View {
    
    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject private var dia: Dia
    @FetchRequest(
        entity: WikiUserMeta.entity(), sortDescriptors: []
    ) private var metas: FetchedResults<WikiUserMeta>
    @State private var selection: ObjectIdentifier?
    
    var body: some View {
        #if os(macOS)
        content.frame(minWidth: 200)
        #else
        content
        #endif
    }
    
    @ViewBuilder
    private var content: some View {
        List {
            ForEach(sortedMetas) { meta in
                #if os(macOS)
                link(meta) {
                    UserListRow(meta)
                }
                .contextMenu {
                    Button("view.list.delete") {
                        dia.delete(meta)
                        dia.save()
                    }
                }
                #else
                ZStack {
                    UserListRow(meta)
                    link(meta) { EmptyView() }
                        .hidden()
                }
                #endif
            }
            .onDelete { indexSet in
                let metas = self.sortedMetas
                let deleteList = indexSet.compactMap { index in
                    index < metas.endIndex ? metas[index] : nil
                }
                for meta in deleteList {
                    dia.delete(meta)
                }
                dia.save()
            }
        }
        .listStyle(listStyle)
    }
    
    private var sortedMetas: [ WikiUserMeta ] {
        metas.sorted { $0.user?.edits ?? 0 > $1.user?.edits ?? 0 }
    }
    
    private var listStyle: some ListStyle {
        #if os(macOS)
        return SidebarListStyle()
        #else
        return InsetGroupedListStyle()
        #endif
    }
    
    @ViewBuilder
    private func link<Label: View>(_ meta: WikiUserMeta, @ViewBuilder label: () -> Label) -> some View {
        if let user = meta.user {
            NavigationLink(
                destination: UserDetails(user),
                tag: user.id,
                selection: $selection,
                label: label
            )
        } else {
            label()
        }
    }
}

#if DEBUG
struct UserList_Previews: PreviewProvider {
    
    private static let dia = Dia.preview
    
    static var previews: some View {
        UserList()
            .environment(\.managedObjectContext, dia.context)
            .environmentObject(dia)
    }
}
#endif
