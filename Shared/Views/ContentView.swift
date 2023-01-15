//
//  ContentView.swift
//  Wikist
//
//  Created by Lucka on 11/4/2021.
//

import SwiftUI

struct ContentView: View {
    
    private enum SidebarSelection : Hashable {
        case users
        case wikis
#if os(iOS)
        case settings
#endif
    }
    
    @FetchRequest(
        entity: User.entity(), sortDescriptors: [ ]
    ) private var usersRequest: FetchedResults<User>
    @FetchRequest(
        entity: Wiki.entity(), sortDescriptors: [ ]
    ) private var wikisRequest: FetchedResults<Wiki>
    
    @State private var isOnboardingSheetPresented = false
    @State private var navigationPath = NavigationPath()
    @State private var sidebarSelection: SidebarSelection? = .users
    @State private var userCount = 0
    @State private var wikiCount = 0
    
    private let currentBuild = Bundle.main.version

    var body: some View {
        NavigationSplitView {
            List(selection: $sidebarSelection) {
                Section("ContentView.Lists") {
                    Label("ContentView.Lists.Users", systemImage: "person")
                        .badge(userCount)
                        .tag(SidebarSelection.users)
                    Label("ContentView.Lists.Wikis", systemImage: "globe")
                        .badge(wikiCount)
                        .tag(SidebarSelection.wikis)
                }
#if os(iOS)
                Label("ContentView.Settings", systemImage: "gear")
                    .tag(SidebarSelection.settings)
#endif
            }
            .navigationTitle("Wikist")
            .listStyle(.sidebar)
        } detail: {
            NavigationStack(path: $navigationPath) {
                Group {
                    switch sidebarSelection {
                    case .users:
                        UserListView()
                    case .wikis:
                        WikiListView()
#if os(iOS)
                    case .settings:
                        SettingsView()
#endif
                    case .none:
                        UserListView()
                    }
                }
                .navigationDestination(for: User.self) { user in
                    UserDetailsView(user)
                }
                .navigationDestination(for: Wiki.self) { wiki in
                    WikiDetailsView(wiki)
                }
            }
        }
        .sheet(isPresented: $isOnboardingSheetPresented) {
            
        } content: {
            OnboardingView()
        }
        .onReceive(usersRequest.publisher.count()) { newValue in
            userCount = newValue
        }
        .onReceive(wikisRequest.publisher.count()) { newValue in
            wikiCount = newValue
        }
    }
}

#if DEBUG
struct ContentViewPreviews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, Persistence.preview.container.viewContext)
    }
}
#endif
