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
        contents
    }
    
    @ViewBuilder
    private var contents: some View {
        #if os(macOS)
        VStack(alignment: .leading) {
            HStack {
                Text("卢卡")
                    .font(.title2)
                    .lineLimit(1)
            }
            Text("神奇宝贝百科")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        #else
        VStack(alignment: .leading) {
            HStack {
                Text("卢卡")
                Text("神奇宝贝百科")
                    .foregroundColor(.secondary)
            }
            .font(.title2)
            .lineLimit(1)
            
            ContributionsMatrix(user)
        }
        .padding(.vertical, 5)
        #endif
    }
}

#if DEBUG
struct WikiListRow_Previews: PreviewProvider {
    static var previews: some View {
        UserListRow(Dia.preview.users().first!)
    }
}
#endif
