//
//  AddForm.swift
//  Wikist
//
//  Created by Lucka on 11/4/2021.
//

import SwiftUI

struct AddForm: View {
    
    @Environment(\.locale) private var locale
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject private var model = AddViewModel()
    @State private var presentingAddSiteHelpAlert = false
    
    var body: some View {
        #if os(macOS)
        content
            .frame(minWidth: 350, minHeight: 400)
        #else
        NavigationView {
            content
        }
        #endif
    }
    
    @ViewBuilder
    private var content: some View {
        ScrollView {
            main
                .animation(.easeInOut, value: model.status)
                .padding()
        }
        .navigationTitle("view.add.title")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("view.action.confirm") {
                    model.save()
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(model.status != .allDone)
            }
            
            ToolbarItem(placement: .cancellationAction) {
                Button("view.action.cancel") {
                    model.clear()
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .alert(isPresented: $model.presentingAlert) {
            .init(title: Text(model.alertMessage))
        }
        .alert(isPresented: $presentingAddSiteHelpAlert) {
            .init(title: Text("view.add.site.add.help.title"), message: Text("view.add.site.add.help.message"))
        }
    }
    
    @ViewBuilder
    private var main: some View {
        VStack {
            siteField
            
            if model.status >= .inputUser {
                userField
                siteInfo
                
                if model.status >= .queryingContributions {
                    userInfo
                }
            }
            
            if model.querying {
                ProgressView()
            }
        }
    }
    
    @ViewBuilder
    private var siteField: some View {
        CardView.Card {
            CardView.List.header(Text("view.info.site.header"))
            if !model.sites.isEmpty {
                CardView.List.row {
                    Picker("view.add.site.method", selection: $model.siteMethod) {
                        Text("view.add.site.method.add").tag(AddViewModel.SiteMethod.add)
                        Text("view.add.site.method.select").tag(AddViewModel.SiteMethod.select)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .disabled(model.status != .inputSite)
                }
            }
            if model.siteMethod == .add {
                siteAddField
            } else {
                siteSelector
            }
        }
    }
    
    @ViewBuilder
    private var siteAddField: some View {
        CardView.List.row {
            HStack {
                let textField = TextField("view.add.site.add.hint", text: $model.url)
                    .disableAutocorrection(true)
                    .lineLimit(1)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(model.status != .inputSite)
                #if os(macOS)
                textField
                #else
                textField.keyboardType(.URL)
                #endif
                Button {
                    presentingAddSiteHelpAlert = true
                } label: {
                    Label("view.add.site.add.help", systemImage: "questionmark.circle")
                        .labelStyle(IconOnlyLabelStyle())
                }
                .buttonStyle(BorderlessButtonStyle())
            }
        }
        if model.status == .inputSite {
            CardView.List.row(model.querySite) {
                Label("view.add.query", systemImage: "magnifyingglass")
            }
        }
    }
    
    @ViewBuilder
    private var siteSelector: some View {
        CardView.List.row {
            Picker("view.add.site.select.hint", selection: $model.selectedSite) {
                ForEach(0 ..< model.sites.count) { index in
                    Text(model.sites[index].title).tag(index)
                }
            }
            .disabled(model.status != .inputSite)
        }
        if model.status == .inputSite {
            CardView.List.row(model.selectSite) {
                Label("view.action.confirm", systemImage: "checkmark.circle")
            }
        }
    }
    
    @ViewBuilder
    private var userField: some View {
        CardView.Card {
            CardView.List.header(Text("view.info.user.header"))
            CardView.List.row {
                TextField("User", text: $model.username)
                    .lineLimit(1)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(model.status != .inputUser)
            }
            if model.status == .inputUser {
                CardView.List.row(model.queryUser) {
                    Label("view.add.query", systemImage: "magnifyingglass")
                }
            }
        }
    }
    
    @ViewBuilder
    private var siteInfo: some View {
        CardView.Card {
            if let site = model.site {
                CardView.List.header(
                    Text("view.info.site.header"),
                    RemoteImage(site.favicon)
                        .clipShape(Circle())
                        .frame(width: 16, height: 16)
                )
            } else {
                CardView.List.header(Text("view.info.site.header"))
            }
            CardView.List.row(Label("view.info.site.title", systemImage: "house"), Text(model.site?.title ?? ""))
            if let language = locale.localizedString(forLanguageCode: model.site?.language ?? "") {
                CardView.List.row(Label("view.info.site.language", systemImage: "globe"), Text(language))
            }
        }
    }
    
    @ViewBuilder
    private var userInfo: some View {
        CardView.Card {
            CardView.List.header(Text("view.info.user.header"))
            CardView.List.row(Label("view.info.user.uid", systemImage: "number"), Text("\(model.user?.userId ?? 0)"))
            CardView.List.row(Label("view.info.user.registration", systemImage: "play"), Text(model.user?.registration ?? .init(), style: .date))
            CardView.List.row(Label("view.info.user.edits", systemImage: "pencil"), Text("\(model.user?.edits ?? 0)"))
        }
    }
}

#if DEBUG
struct AddView_Previews: PreviewProvider {
    static var previews: some View {
        AddForm()
    }
}
#endif

fileprivate class AddViewModel: ObservableObject {
    
    enum Status: Int, Comparable {
        case inputSite              = 0
        case queryingSiteInfo       = 1
        case inputUser              = 2
        case queryingUserInfo       = 3
        case queryingContributions  = 4
        case allDone                = 10
        
        static func < (lhs: AddViewModel.Status, rhs: AddViewModel.Status) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
    
    enum SiteMethod {
        case add
        case select
    }
    
    @Published var status = Status.inputSite
    @Published var siteMethod: SiteMethod
    @Published var selectedSite: Int = 0
    @Published var url = ""
    @Published var username = ""
    
    @Published var presentingAlert = false
    
    let sites: [ WikiSite ] = Dia.shared.list()
        .filter { $0.usersCount > 0 }
        .sorted { $0.usersCount > $1.usersCount }
    
    var site: WikiSite? = nil
    var user: WikiUserRAW? = nil
    var alertMessage: LocalizedStringKey = ""
    
    init() {
        siteMethod = sites.isEmpty ? .add : .select
    }
    
    var querying: Bool {
        status == .queryingSiteInfo
            || status == .queryingUserInfo
            || status == .queryingContributions
    }
    
    func selectSite() {
        if selectedSite >= sites.count {
            selectedSite = 0
            alert("Invalid Selection")
            return
        }
        site = sites[selectedSite]
        self.status = .inputUser
    }
    
    func querySite() {
        // Check
        if url.isEmpty {
            alert("view.add.alert.urlEmpty")
            return
        }
        url = url
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "/api\\.php$", with: "", options: .regularExpression)
        guard let urlString = url.urlString else {
            alert("view.add.alert.urlInvalid")
            return
        }
        url = urlString
        status = .queryingSiteInfo
        if let site = Dia.shared.site(of: url) {
            self.site = site
            self.status = .inputUser
            return
        }
        let raw = WikiSiteRAW(url)
        Task.init {
            do {
                try await raw.query()
            } catch {
                DispatchQueue.main.async {
                    self.alert("view.add.alert.querySiteFailed")
                    self.status = .inputSite
                }
                return
            }
            DispatchQueue.main.async {
                self.site = .from(raw, context: Dia.shared.context)
                self.status = .inputUser
            }
        }
    }
    
    func queryUser() {
        if username.isEmpty {
            alert("view.add.alert.usernameEmpty")
            return
        }
        guard let solidSite = site else {
            alert("view.add.alert.noSite")
            status = .inputSite
            return
        }
        status = .queryingUserInfo
        let raw = WikiUserRAW(username, solidSite)
        Task.init {
            do {
                try await raw.query(user: true, contributions: false)
                DispatchQueue.main.async {
                    self.status = .queryingContributions
                }
                self.user = raw
                try await raw.query(user: false, contributions: true)
                DispatchQueue.main.async {
                    self.status = .allDone
                }
            } catch {
                self.alert("view.add.alert.queryUserFailed")
                self.status = .inputUser
            }
        }
    }
    
    func save() {
        guard let solidRAW = user else {
            return
        }
        let _ = WikiUser.from(solidRAW, UUID(), with: Dia.shared.context, createMeta: true)
        Dia.shared.save()
    }
    
    func clear() {
        if let solidSite = site {
            Dia.shared.delete(solidSite)
        }
        Dia.shared.save()
    }
    
    private func alert(_ message: LocalizedStringKey) {
        alertMessage = message
        presentingAlert = true
    }
}
