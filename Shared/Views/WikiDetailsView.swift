//
//  WikiDetailsView.swift
//  Wikist
//
//  Created by Lucka on 25/11/2022.
//

import SwiftUI

struct WikiDetailsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.locale) private var locale
    @Environment(\.openURL) private var openURL
    @Environment(\.persistence) private var persistence
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest private var users: FetchedResults<User>
    
    @State private var isAddUserSheetPresented = false
    @State private var isRefreshing = false
    
    private let wiki: Wiki
    
    init(_ wiki: Wiki) {
        self.wiki = wiki
        
        self._users = .init(
            sortDescriptors: [ .init(\.name, order: .forward) ],
            predicate: .init(format: "%K == %@", #keyPath(User.wiki), self.wiki)
        )
    }
    
    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading) {
                logo
                Group {
                    actions
                    highlights
                    if let auxiliary = wiki.auxiliary {
                        statisticsSection(auxiliary)
                    }
                    usersSection
                }
                .frame(maxWidth: 640, alignment: .center)
                .frame(maxWidth: .infinity)
            }
            .padding()
        }
        .navigationTitle(wiki.title ?? "WikiDetailsView.DefaultTitle")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                ThemedButton.refresh(isRefreshing: isRefreshing) {
                    Task { await tryUpdate() }
                }
            }
        }
        .sheet(isPresented: $isAddUserSheetPresented, onDismiss: viewContext.rollback) {
            AddUserView(wiki: wiki)
        }
    }
    
    @ViewBuilder
    private var logo: some View {
        AsyncImage(url: wiki.logo) { image in
            image
                .resizable()
                .scaledToFit()
        } placeholder: {
            ProgressView()
        }
        .frame(width: 90, height: 90, alignment: .center)
        .card(style: (colorScheme == .dark ? Color.white : Color.clear).gradient)
        .fixedSize()
        .frame(maxWidth: .infinity, alignment: .center)
    }
    
    @ViewBuilder
    private var actions: some View {
        EqualWidthHStack {
            if let mainPageURL = wiki.mainPageURL {
                ThemedButton.action("WikiDetailsView.Actions.MainPage", systemImage: "house") {
                    openURL(mainPageURL)
                }
            }
            ThemedButton.action("WikiDetailsView.Actions.AddUser", systemImage: "person.badge.plus") {
                isAddUserSheetPresented.toggle()
            }
        }
    }
    
    @ViewBuilder
    private var highlights: some View {
        FlexHStack(horizontalSpacing: 4, verticalSpacing: 4) {
            if let language = wiki.language, let languageName = locale.localizedString(forLanguageCode: language) {
                SimpleChip(
                    "WikiDetailsView.Highlights.Language",
                    systemImage: "character.book.closed",
                    contentText: languageName
                )
            }
            if let version = wiki.generatorVersion {
                SimpleChip("WikiDetailsView.Highlights.Generator", systemImage: "gearshape.2", contentText: version)
            }
        }
    }
    
    @ViewBuilder
    private var usersSection: some View {
        Section {
            LazyVGrid(columns:  [ .init(.adaptive(minimum: 240)) ], alignment: .leading) {
                ForEach(users) { user in
                    NavigationLink(value: user) {
                        UserBriefView(user, showWikiTitle: false)
                            .card()
                    }
                    .buttonStyle(.borderless)
                }
            }
        } header: {
            HStack {
                Text("WikiDetailsView.Users")
                Spacer()
                Text(users.count, format: .number)
            }
            .sectionHeader()
        }
    }
    
    @ViewBuilder
    private func statisticsSection(_ auxiliary: WikiAuxiliary) -> some View {
        Section {
            StatisticsGrid.card {
                StatisticsGrid.row(
                    "WikiDetailsView.Statistics.Pages", systemImage: "doc", value: auxiliary.pages
                )
                StatisticsGrid.row(
                    "WikiDetailsView.Statistics.Articles", systemImage: "doc.append", value: auxiliary.articles
                )
                StatisticsGrid.row(
                    "WikiDetailsView.Statistics.Edits", systemImage: "pencil", value: auxiliary.edits
                )
                StatisticsGrid.row(
                    "WikiDetailsView.Statistics.Images", systemImage: "photo", value: auxiliary.images
                )
                StatisticsGrid.row(
                    "WikiDetailsView.Statistics.Users", systemImage: "person.crop.circle", value: auxiliary.users
                )
            }
        } header: {
            Text("WikiDetailsView.Statistics")
                .sectionHeader()
        }
    }
    
    @MainActor
    private func tryUpdate() async {
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            try await persistence.update(wiki: wiki.objectID)
        } catch {
            //
        }
    }
}

#if DEBUG
struct WikiDetailsViewPreviews: PreviewProvider {
    static let persistence = Persistence.preview
    
    static var previews: some View {
        WikiDetailsView(Persistence.previewWiki(with: persistence.container.viewContext))
            .environment(\.managedObjectContext, persistence.container.viewContext)
    }
}
#endif
