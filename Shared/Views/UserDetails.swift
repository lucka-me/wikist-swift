//
//  WikiDetails.swift
//  Wikist
//
//  Created by Lucka on 12/4/2021.
//

import SwiftUI

struct UserDetails: View {
    
    static private let matrixGridSize: CGFloat = 16
    static private let matrixHeight: CGFloat = matrixGridSize * 7 + ContributionsMatrix.gridSpacing * 6
    static private let matrixMaxWidth: CGFloat = matrixGridSize * 53 + ContributionsMatrix.gridSpacing * 52
    #if os(macOS)
    static private let minWidth: CGFloat = 300
    #else
    static private let minWidth: CGFloat? = nil
    #endif
    
    @Environment(\.locale) private var locale
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var dia: Dia
    
    var meta: WikiUserMeta
    
    init(_ meta: WikiUserMeta) {
        self.meta = meta
    }
    
    var body: some View {
        if let user = meta.user, let site = user.site {
            List {
                Group {
                    ContributionsMatrix(user)
                        .frame(height: Self.matrixHeight, alignment: .top)
                    logoAndLinks(user, site)
                    language(site)
                    edits(user)
                    intervalAndID(user)
                }
                .lineLimit(1)
                .listRowSeparator(.hidden)
                .frame(minWidth: Self.minWidth, maxWidth: Self.matrixMaxWidth)
            }
            .listStyle(.plain)
            .navigationTitle(user.username)
            .refreshable {
                try? await user.refresh(onlyContributions: false)
                dia.save()
            }
        } else {
            ProgressView("Loading")
                .task {
                    try? await meta.createUser(with: dia)
                }
                .frame(minWidth: Self.minWidth)
        }
    }
    
    @ViewBuilder
    private func logoAndLinks(_ user: WikiUser, _ site: WikiSite) -> some View {
        HStack(alignment: .center) {
            AsyncImage(url: URL(string: site.logo)) { image in
                image
                    .resizable()
                    .scaledToFit()
            } placeholder: {
                ProgressView()
            }
            .frame(width: 60, height: 60, alignment: .center)
            Spacer()
            VStack(alignment: .trailing) {
                if let url = URL(string: site.homepage) {
                    Button{
                        openURL(url)
                    } label: {
                        Text(site.title)
                        Label("Open", systemImage: "chevron.forward")
                    }
                }
                Divider()
                if let url = user.userPage {
                    Button {
                        openURL(url)
                    } label: {
                        Text("view.info.user.userPage")
                        Label("Open", systemImage: "chevron.forward")
                    }
                }
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.borderless)
        }
        .card()
    }
    
    @ViewBuilder
    private func language(_ site: WikiSite) -> some View {
        HStack {
            Label("view.info.site.language", systemImage: "character.book.closed")
            Spacer()
            if let language = locale.localizedString(forLanguageCode: site.language) {
                Text(language)
            } else {
                Text("Unknown")
            }
        }
        .card()
    }
    
    @ViewBuilder
    private func edits(_ user: WikiUser) -> some View {
        VStack(alignment: .leading) {
            Text("\(user.edits)")
                .font(.system(.largeTitle, design: .rounded))
            HStack(alignment: .firstTextBaseline) {
                Spacer()
                Text("view.info.user.edits")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            Divider()
            HStack {
                let contributionsLastYear = user.contributionsLastYear
                Label("view.info.user.lastYear", systemImage: "calendar")
                ProgressView(value: Double(contributionsLastYear), total: Double(user.edits))
                Text("\(contributionsLastYear)")
                    .font(.system(.body, design: .rounded))
            }
        }
        .card()
    }
    
    @ViewBuilder
    private func intervalAndID(_ user: WikiUser) -> some View {
        VStack(alignment: .leading) {
            Text(user.registration, style: .relative)
                .font(.largeTitle)
            HStack(alignment: .firstTextBaseline) {
                let days = Int(Date.now.timeIntervalSince(user.registration)) / Date.secondsInDay
                Text("view.info.user.days \(days)")
                Spacer()
                Text("# \(user.userId)")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            Divider()
            HStack {
                Label("view.info.user.since", systemImage: "play")
                Spacer()
                Text(user.registration, style: .date)
            }
        }
        .card()
    }
}

#if DEBUG
struct WikiDetails_Previews: PreviewProvider {
    static var previews: some View {
        UserDetails(Dia.preview.list().first!)
    }
}
#endif
