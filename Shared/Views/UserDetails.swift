//
//  WikiDetails.swift
//  Wikist
//
//  Created by Lucka on 12/4/2021.
//

import SwiftUI

struct UserDetails: View {
    
    static private let matrixHeight: CGFloat = 16 * 7 + ContributionsMatrix.gridSpacing * 6
    
    @Environment(\.locale) private var locale
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
                    .frame(height: Self.matrixHeight, alignment: .top)
                
                LazyVGrid(columns: [ .init(.adaptive(minimum: 250), alignment: .top) ], alignment: .center) {
                    siteInfo
                    userInfo
                }
                .lineLimit(1)
            }
            .animation(.easeInOut)
            .padding()
        }
        .navigationTitle(user.username)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    refreshing = true
                    user.refresh(full: true) { succeed in
                        DispatchQueue.main.async {
                            if succeed {
                                Dia.shared.save()
                            }
                            refreshing = false
                        }
                    }
                } label: {
                    Label("view.details.update", systemImage: "arrow.clockwise")
                }
                .disabled(refreshing)
            }
        }
    }
    
    @ViewBuilder
    private var siteInfo: some View {
        CardView.Card {
            CardView.List.header(
                Text("view.info.site.header"),
                RemoteImage(user.site?.favicon ?? "")
                    .clipShape(Circle())
                    .frame(width: 16, height: 16)
            )
            CardView.List.row(Label("view.info.site.title", systemImage: "house"), Text(user.site?.title ?? ""))
            if let language = locale.localizedString(forLanguageCode: user.site?.language ?? "") {
                CardView.List.row(Label("view.info.site.language", systemImage: "globe"), Text(language))
            }
            CardView.List.row(openHomePage, showIndicator: true) {
                Label("view.info.site.homepage", systemImage: "safari")
            }
        }
    }
    
    @ViewBuilder
    private var userInfo: some View {
        CardView.Card {
            Text("view.info.user.header")
                .font(.headline)
            CardView.List.row(Label("view.info.user.uid", systemImage: "number"), Text("\(user.userId)"))
            CardView.List.row(Label("view.info.user.registration", systemImage: "play"), Text(user.registration, style: .date))
            CardView.List.row(Label("view.info.user.edits", systemImage: "pencil"), Text("\(user.edits)"))
            CardView.List.row(Label("view.info.user.contributionsLastYear", systemImage: "calendar"), Text("\(user.contributionsLastYear)"))
            CardView.List.row(openUserPage, showIndicator: true) {
                Label("view.info.user.userPage", systemImage: "safari")
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
        UserDetails(Dia.preview.list().first!)
    }
}
#endif
