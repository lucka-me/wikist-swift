//
//  UserList.swift
//  Wikist
//
//  Created by Lucka on 11/4/2021.
//

import SwiftUI

struct UserList: View {
    
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(
        entity: WikiUser.entity(),
        sortDescriptors: WikiUser.sortDescriptorsByEdits
    ) private var users: FetchedResults<WikiUser>
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
            ForEach(users) { user in
                #if os(macOS)
                link(user) {
                    UserListRow(user)
                }
                #else
                ZStack {
                    UserListRow(user)
                    link(user) { EmptyView() }
                        .hidden()
                }
                #endif
            }
            .onDelete { indexSet in
                for index in indexSet {
                    if index < users.endIndex {
                        let user = users[index]
                        if selection == user.id {
                            selection = nil
                        }
                        Dia.shared.delete(user)
                    }
                }
                Dia.shared.save()
            }
        }
        .listStyle(listStyle)
    }
    
    private var listStyle: some ListStyle {
        #if os(macOS)
        return InsetListStyle()
        #else
        return InsetGroupedListStyle()
        #endif
    }
    
    @ViewBuilder
    private func link<Label: View>(_ user: WikiUser, @ViewBuilder label: () -> Label) -> some View {
        NavigationLink(
            destination: UserDetails(user),
            tag: user.id,
            selection: $selection,
            label: label
        )
    }
}

#if DEBUG
struct UserList_Previews: PreviewProvider {
    static var previews: some View {
        UserList()
            .environment(\.managedObjectContext, Dia.preview.context)
    }
}
#endif
