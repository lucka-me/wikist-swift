//
//  WikiDetails.swift
//  Wikist
//
//  Created by Lucka on 12/4/2021.
//

import SwiftUI

struct UserDetails: View {
    
    static private let matrixHeight: CGFloat = 16 * 7 + ContributionsMatrix.gridSpacing * 6
    static private let radius: CGFloat = 12
    
    @Environment(\.openURL) private var openURL
    @State private var refreshing = false
    
    var user: WikiUser
    
    init(_ user: WikiUser) {
        self.user = user
    }
    
    var body: some View {
        if user.isFault {
            EmptyView()
        } else {
            #if os(macOS)
            content.frame(minWidth: 300)
            #else
            content
            #endif
        }
    }
    
    @ViewBuilder
    private var content: some View {
        ScrollView {
            VStack(alignment: .center) {
                ContributionsMatrix(user)
                    .frame(height: Self.matrixHeight)
                
                LazyVGrid(columns: [ .init(.adaptive(minimum: 250), alignment: .top) ], alignment: .center) {
                    siteInfo
                    userInfo
                }
                .lineLimit(1)
            }
            .padding()
            .animation(.easeInOut)
        }
        .navigationTitle(user.username)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    refreshing = true
                    user.refresh { _ in
                        DispatchQueue.main.async {
                            Dia.shared.save()
                            refreshing = false
                        }
                    }
                } label: {
                    Label("Update", systemImage: "arrow.clockwise")
                }
                .disabled(refreshing)
            }
        }
    }
    
    @ViewBuilder
    private var siteInfo: some View {
        CardView.Card(radius: Self.radius) {
            CardView.List.header(Text("Wiki"))
            CardView.List.row(Label("Title", systemImage: "globe"), Text(user.site?.title ?? ""))
            CardView.List.row(openHomePage, showIndicator: true) {
                Label("Home Page", systemImage: "house")
            }
        }
    }
    
    @ViewBuilder
    private var userInfo: some View {
        CardView.Card(radius: Self.radius) {
            Text("User")
                .font(.headline)
            CardView.List.row(Label("User ID", systemImage: "number"), Text("\(user.uid)"))
            CardView.List.row(Label("Registration", systemImage: "play"), Text(user.registration, style: .date))
            CardView.List.row(Label("Edits", systemImage: "pencil"), Text("\(user.edits)"))
            CardView.List.row(Label("Contributions Last Year", systemImage: "calendar"), Text("\(user.contributionsLastYear)"))
            CardView.List.row(openUserPage, showIndicator: true) {
                Label("User Page", systemImage: "person")
            }
        }
    }
    
    private func openHomePage() {
        if let site = user.site, let url = URL(string: site.homepage) {
            openURL(url)
        }
    }
    
    private func openUserPage() {
        if let url = user.userPage {
            openURL(url)
        }
    }
}

#if DEBUG
struct WikiDetails_Previews: PreviewProvider {
    static var previews: some View {
        UserDetails(Dia.preview.users().first!)
    }
}
#endif
