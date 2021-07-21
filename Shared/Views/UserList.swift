//
//  UserList.swift
//  Wikist
//
//  Created by Lucka on 11/4/2021.
//

import SwiftUI

struct UserList: View {
    
    #if os(macOS)
    private static let minWidth: CGFloat = 200
    #else
    private static let minWidth: CGFloat? = nil
    #endif
    
    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject private var dia: Dia
    @FetchRequest(
        entity: WikiUserMeta.entity(), sortDescriptors: []
    ) private var metas: FetchedResults<WikiUserMeta>
    @State private var selection: ObjectIdentifier?
    
    var body: some View {
        List {
            ForEach(sortedMetas) { meta in
                NavigationLink(tag: meta.id, selection: $selection) {
                    UserDetails(meta)
                } label: {
                    UserListRow(meta)
                }
                .buttonStyle(.plain)
            }
            .onDelete { indexSet in
                let sortedIndexes = indexSet.sorted(by: >)
                let sortedMetas = self.sortedMetas
                for index in sortedIndexes {
                    if index < sortedMetas.endIndex {
                        dia.delete(sortedMetas[index])
                    }
                }
                dia.save()
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: Self.minWidth)
    }
    
    private var sortedMetas: [ WikiUserMeta ] {
        metas.sorted { $0.user?.edits ?? 0 > $1.user?.edits ?? 0 }
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
