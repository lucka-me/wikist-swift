//
//  AddForm.swift
//  Wikist
//
//  Created by Lucka on 11/4/2021.
//

import CoreData
import SwiftUI

struct AddForm: View {
    
    private enum AlertItem: Identifiable {
        case addSiteHelp
        case error
        
        var id: Int { hashValue }
    }
    
    private enum Status: Int, Comparable {
        case configSite             = 0
        case queryingSite           = 1
        case configUser             = 2
        case queryingUser           = 3
        case queryingContributions  = 4
        case allDone                = 10
        
        static func < (lhs: Status, rhs: Status) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
    
    @Environment(\.locale) private var locale
    @Environment(\.managedObjectContext) private var context
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var dia: Dia
    @ObservedObject private var model = Model()
    @State private var status: Status = .configSite
    @State private var alertItem: AlertItem? = nil
    @State private var errorMessage: LocalizedStringKey = ""
    
    var body: some View {
        Form {
            Section(LocalizedStringKey("view.add.site.header")) {
                if !model.sites.isEmpty {
                    Picker("view.add.site.method", selection: $model.siteMethod) {
                        Text("view.add.site.method.select").tag(Model.SiteMethod.select)
                        Text("view.add.site.method.add").tag(Model.SiteMethod.add)
                    }
                    .pickerStyle(.segmented)
                    .disabled(status != .configSite)
                }
                if model.siteMethod == .add {
                    addSiteFields
                } else {
                    siteSelector
                }
            }
            
            if status >= .configUser {
                Section(LocalizedStringKey("view.add.user.header")) {
                    userFields
                }
            }
        }
        .navigationTitle("view.add.title")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("view.action.confirm") {
                    Task.init {
                        await model.save(with: dia)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                .disabled(status != .allDone)
            }
            
            ToolbarItem(placement: .cancellationAction) {
                Button("view.action.cancel") {
                    Task.init {
                        await model.clear(with: dia)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .alert(item: $alertItem) { item in
            let title: LocalizedStringKey
            let message: LocalizedStringKey
            switch item {
                case .addSiteHelp:
                    title = "view.add.site.add.help.title"
                    message = "view.add.site.add.help.message"
                case .error:
                    title = "view.add.error.title"
                    message = errorMessage
            }
            return .init(title: .init(title), message: .init(message))
        }
    }
    
    @ViewBuilder
    private var addSiteFields: some View {
        HStack {
            let textField = TextField("view.add.site.add.hint", text: $model.url)
                .disableAutocorrection(true)
                .lineLimit(1)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .disabled(status != .configSite)
            #if os(macOS)
            textField
            #else
            textField.keyboardType(.URL)
            #endif
            Button {
                alertItem = .addSiteHelp
            } label: {
                Label("view.add.site.add.help", systemImage: "questionmark.circle")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.borderless)
        }
        if status <= .queryingSite && model.urlIsValid {
            Button {
                Task.init {
                    update(status: .queryingSite)
                    var done = false
                    do {
                        try await model.querySite(with: dia)
                        done = true
                    } catch Model.ErrorType.invalidURL {
                        errorMessage = "view.add.error.invalidURL"
                    } catch WikiSiteRAW.QueryError.invalidURL {
                        errorMessage = "view.add.error.invalidURL"
                    } catch WikiSiteRAW.QueryError.invalidResponse {
                        errorMessage = "view.add.error.invalidResponse"
                    } catch {
                        // Should never happen: Model.ErrorType.emptyURL
                        errorMessage = .init(error.localizedDescription)
                    }
                    if !done {
                        alertItem = .error
                    }
                    update(status: done ? .configUser : .configSite)
                }
            } label: {
                let querying = status == .queryingSite
                Label("view.add.query", systemImage: "magnifyingglass")
                    .opacity(querying ? 0 : 1)
                    .overlay {
                        if querying {
                            ProgressView()
                        }
                    }
            }
        }
        if status > .queryingSite, let site = model.site {
            row(titleKey: "view.add.site.title", systemImage: "house", text: .init(site.title))
            if let language = locale.localizedString(forLanguageCode: site.language) {
                row(titleKey: "view.info.site.language", systemImage: "character.book.closed", text: .init(language))
            }
        }
    }
    
    @ViewBuilder
    private var siteSelector: some View {
        Picker("view.add.site.select.hint", selection: $model.selectedSite) {
            ForEach(model.sites) { site in
                Text(site.title).tag(site.id as ObjectIdentifier?)
            }
        }
        .disabled(status != .configSite)
        if status == .configSite && model.selectedSite != nil {
            Button {
                do {
                    try model.selectSite()
                } catch Model.ErrorType.invalidSelection {
                    errorMessage = "view.add.error.invalidSelection"
                    alertItem = .error
                    return
                } catch {
                    
                }
                update(status: .configUser)
            } label: {
                Label("view.action.confirm", systemImage: "checkmark")
            }
        }
    }
    
    @ViewBuilder
    private var userFields: some View {
        TextField("view.add.user.add.hint", text: $model.username)
            .lineLimit(1)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .disabled(status != .configUser)
        if status <= .queryingContributions && !model.username.isEmpty {
            Button {
                Task.init {
                    update(status: .queryingUser)
                    var done = false
                    do {
                        try await model.queryUser()
                        update(status: .queryingContributions)
                        try await model.queryContributions()
                        done = true
                    } catch WikiUserRAW.QueryError.invalidURL {
                        errorMessage = "view.add.error.invalidURL"
                    } catch WikiUserRAW.QueryError.invalidResponse {
                        errorMessage = "view.add.error.invalidResponse"
                    } catch WikiUserRAW.QueryError.userNotFound {
                        errorMessage = "view.add.error.userNotFound"
                    } catch WikiUserRAW.QueryError.invalidResponseContent {
                        errorMessage = "view.add.error.invalidResponseContent"
                    } catch {
                        // Should never happen:
                        //   Model.ErrorType.emptyUsername
                        //   Model.ErrorType.noSiteData
                        //   Model.ErrorType.noUserData
                        errorMessage = .init(error.localizedDescription)
                    }
                    if !done {
                        alertItem = .error
                    }
                    update(status: done ? .allDone : .configUser)
                }
            } label: {
                let querying = status != .configUser
                Label("view.add.query", systemImage: "magnifyingglass")
                    .opacity(querying ? 0 : 1)
                    .overlay {
                        if querying {
                            ProgressView()
                        }
                    }
            }
        }
        if status >= .queryingContributions, let user = model.user {
            row(titleKey: "view.info.user.uid", systemImage: "number", text: .init("\(user.userId)"))
            row(titleKey: "view.info.user.since", systemImage: "play", text: .init(user.registration, style: .date))
            row(titleKey: "view.info.user.edits", systemImage: "pencil", text: .init("\(user.edits)"))
        }
    }
    
    @ViewBuilder
    private func row(titleKey: LocalizedStringKey, systemImage name: String, text: Text) -> some View {
        HStack {
            Label(titleKey, systemImage: name)
            Spacer()
            text
        }
    }
    
    @MainActor
    private func update(status: Status) {
        self.status = status
    }
}

#if DEBUG
struct AddForm_Previews: PreviewProvider {
    static var previews: some View {
        AddForm()
    }
}
#endif

fileprivate class Model: ObservableObject {
    
    enum ErrorType: Error {
        case invalidSelection
        
        case emptyURL
        case invalidURL
        
        case emptyUsername
        case noSiteData
        case noUserData
    }
    
    enum SiteMethod {
        case add
        case select
    }
    
    @Published var siteMethod: SiteMethod
    @Published var selectedSite: ObjectIdentifier?
    @Published var url = ""
    @Published var username = ""
    
    let sites: [ WikiSite ] = Dia.shared.list()
        .filter { $0.usersCount > 0 }
        .sorted { $0.usersCount > $1.usersCount }
    
    var site: WikiSite? = nil
    var user: WikiUserRAW? = nil
    
    init() {
        siteMethod = sites.isEmpty ? .add : .select
        selectedSite = sites.first?.id
    }
    
    var urlIsValid: Bool {
        URL(string: url) != nil
    }
    
    func selectSite() throws {
        guard
            let selection = selectedSite,
            let site = sites.first(where: { $0.id == selection })
        else {
            throw ErrorType.invalidSelection
        }
        self.site = site
    }
    
    func querySite(with dia: Dia) async throws {
        guard !url.isEmpty else {
            throw ErrorType.emptyURL
        }
        guard
            let cleanURL = url
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "/api\\.php$", with: "", options: .regularExpression)
                .url
        else {
            throw ErrorType.invalidURL
        }
        url = cleanURL.absoluteString
        if let existingSite = dia.site(of: url) {
            site = existingSite
            return
        }
        let raw = WikiSiteRAW(url)
        try await raw.query()
        site = .from(raw, context: dia.context)
    }
    
    func queryUser() async throws {
        guard !username.isEmpty else {
            throw ErrorType.emptyUsername
        }
        guard let solidSite = site else {
            throw ErrorType.noSiteData
        }
        let raw = WikiUserRAW(username, solidSite)
        try await raw.query(user: true, contributions: false)
        user = raw
    }
    
    func queryContributions() async throws {
        guard let raw = user else {
            throw ErrorType.noUserData
        }
        try await raw.query(user: false, contributions: true)
    }
    
    func save(with dia: Dia) async {
        guard let solidRAW = user else { return }
        let _ = WikiUser.from(solidRAW, UUID(), with: dia.context, createMeta: true)
        await dia.save()
    }
    
    func clear(with dia: Dia) async {
        guard let solidSite = site else { return }
        dia.delete(solidSite)
        await dia.save()
    }
}
