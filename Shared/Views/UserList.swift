//
//  UserList.swift
//  Wikist
//
//  Created by Lucka on 11/4/2021.
//

import SwiftUI

struct UserList: View {
    
    #if os(macOS)
    static private let minWidth: CGFloat = 200
    #else
    static private let minWidth: CGFloat? = nil
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

struct UserListRow: View {
    
    #if os(iOS)
    static private let matrixHeight: CGFloat = 12 * 7 + ContributionsMatrix.gridSpacing * 6
    #endif
    
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    @EnvironmentObject private var dia: Dia
    @State private var firstAppear = true
    
    private var meta: WikiUserMeta
    
    init(_ meta: WikiUserMeta) {
        self.meta = meta
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            #if os(macOS)
            doubleLinesLabel
            #else
            if horizontalSizeClass == .compact {
                singleLineLabel
                if let user = meta.user {
                    ContributionsMatrix(user)
                        .frame(height: Self.matrixHeight, alignment: .bottom)
                }
            } else {
                doubleLinesLabel
            }
            #endif
        }
        .lineLimit(1)
        .task {
            guard meta.user == nil else { return }
            try? await meta.createUser(with: dia)
        }
    }
    
    #if os(iOS)
    @ViewBuilder
    private var singleLineLabel: some View {
        HStack {
            Text(meta.username)
            Spacer()
            Text(siteText)
                .foregroundColor(.secondary)
        }
        .font(.subheadline)
    }
    #endif
    
    @ViewBuilder
    private var doubleLinesLabel: some View {
        Text(meta.username)
            .font(.title2)
        Text(siteText)
            .foregroundColor(.secondary)
    }
    
    private var siteText: String {
        meta.user?.site?.title ?? .init(localized: "view.list.loading")
    }
}
