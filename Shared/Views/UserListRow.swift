//
//  UserListRow.swift
//  Wikist
//
//  Created by Lucka on 11/4/2021.
//

import SwiftUI

struct UserListRow: View {
    
    #if os(iOS)
    static private let matrixHeight: CGFloat = 12 * 7 + ContributionsMatrix.gridSpacing * 6
    #endif
    
    @EnvironmentObject private var dia: Dia
    @State private var firstAppear = true
    
    private var meta: WikiUserMeta
    
    init(_ meta: WikiUserMeta) {
        self.meta = meta
    }
    
    var body: some View {
        content
            .lineLimit(1)
            .onAppear {
                if firstAppear {
                    firstAppear = false
                    if meta.user == nil {
                        meta.createUser(with: dia)
                    }
                }
            }
    }
    
    @ViewBuilder
    private var content: some View {
        #if os(macOS)
        VStack(alignment: .leading) {
            Text(meta.username)
                .font(.title2)
            if let site = meta.user?.site {
                Text(site.title)
                    .foregroundColor(.secondary)
            } else {
                Text("view.list.loading")
                    .foregroundColor(.secondary)
            }
        }
        #else
        VStack {
            HStack {
                Text(meta.username)
                Spacer()
                if let site = meta.user?.site {
                    Text(site.title)
                        .foregroundColor(.secondary)
                } else {
                    Text("view.list.loading")
                        .foregroundColor(.secondary)
                }
                
            }
            .font(.subheadline)
            
            if let user = meta.user {
                ContributionsMatrix(user)
                    .frame(height: Self.matrixHeight, alignment: .bottom)
            }
        }
        .padding(.vertical, 5)
        #endif
    }
}

#if DEBUG
struct UserListRow_Previews: PreviewProvider {
    
    private static let dia = Dia.preview
    
    static var previews: some View {
        UserListRow(dia.list().first!)
            .environmentObject(dia)
    }
}
#endif
