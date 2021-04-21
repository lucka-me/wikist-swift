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
                .lineLimit(1)
            Text(meta.user?.site?.title ?? "Loading")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        #else
        VStack(alignment: .leading) {
            HStack {
                Text(meta.username)
                Spacer()
                Text(meta.user?.site?.title ?? "Loading")
                    .foregroundColor(.secondary)
            }
            .font(.subheadline)
            .lineLimit(1)
            
            if let user = meta.user {
                ContributionsMatrix(user)
                    .frame(height: Self.matrixHeight)
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
        UserListRow(dia.users().first!.meta!)
            .environmentObject(dia)
    }
}
#endif
