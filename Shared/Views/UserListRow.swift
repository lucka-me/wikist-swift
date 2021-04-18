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
    
    var user: WikiUser
    
    init(_ user: WikiUser) {
        self.user = user
    }
    
    var body: some View {
        content
    }
    
    @ViewBuilder
    private var content: some View {
        #if os(macOS)
        VStack(alignment: .leading) {
            Text(user.username)
                .font(.title2)
                .lineLimit(1)
            Text(user.site?.title ?? "")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        #else
        VStack(alignment: .leading) {
            HStack {
                Text(user.username)
                Spacer()
                Text(user.site?.title ?? "")
                    .foregroundColor(.secondary)
            }
            .font(.subheadline)
            .lineLimit(1)
            
            ContributionsMatrix(user)
                .frame(height: Self.matrixHeight)
        }
        .padding(.vertical, 5)
        #endif
    }
}

#if DEBUG
struct UserListRow_Previews: PreviewProvider {
    static var previews: some View {
        UserListRow(Dia.preview.users().first!)
    }
}
#endif
