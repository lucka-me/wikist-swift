//
//  AddView.swift
//  Wikist
//
//  Created by Lucka on 11/4/2021.
//

import SwiftUI

struct AddView: View {
    
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject private var model = AddViewModel()
    
    var body: some View {
        #if os(macOS)
        content
            .frame(minWidth: 300, minHeight: 400)
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
    }
    
    @ViewBuilder
    private var main: some View {
        VStack {
            urlField
            
            if model.status >= .inputUsername {
                usernameField
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
    private var urlField: some View {
        CardView.Card {
            CardView.List.header(Text("view.add.url"))
            CardView.List.row {
                let textField = TextField("https://example.wiki", text: $model.url)
                    .lineLimit(1)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(model.status != .inputUrl)
                #if os(macOS)
                textField
                #else
                textField.keyboardType(.URL)
                #endif
            }
            if model.status == .inputUrl {
                CardView.List.row(model.querySite) {
                    Label("view.add.query", systemImage: "magnifyingglass")
                }
            }
        }
    }
    
    @ViewBuilder
    private var usernameField: some View {
        CardView.Card {
            CardView.List.header(Text("view.add.username"))
            CardView.List.row {
                TextField("User", text: $model.username)
                    .lineLimit(1)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(model.status != .inputUsername)
            }
            if model.status == .inputUsername {
                CardView.List.row(model.queryUser) {
                    Label("view.add.query", systemImage: "magnifyingglass")
                }
            }
        }
    }
    
    @ViewBuilder
    private var siteInfo: some View {
        CardView.Card {
            CardView.List.header(Text("view.info.site.header"))
            CardView.List.row(Label("view.info.site.title", systemImage: "globe"), Text(model.site?.title ?? ""))
        }
    }
    
    @ViewBuilder
    private var userInfo: some View {
        CardView.Card {
            CardView.List.header(Text("view.info.user.header"))
            CardView.List.row(Label("view.info.user.uid", systemImage: "number"), Text("\(model.user?.uid ?? 0)"))
            CardView.List.row(Label("view.info.user.registration", systemImage: "play"), Text(model.user?.registration ?? .init(), style: .date))
            CardView.List.row(Label("view.info.user.edits", systemImage: "pencil"), Text("\(model.user?.edits ?? 0)"))
        }
    }
}

#if DEBUG
struct AddView_Previews: PreviewProvider {
    static var previews: some View {
        AddView()
    }
}
#endif

fileprivate class AddViewModel: ObservableObject {
    
    enum Status: Int, Comparable {
        case inputUrl               = 0
        case queryingSiteInfo       = 1
        case inputUsername          = 2
        case queryingUserInfo       = 3
        case queryingContributions  = 4
        case allDone                = 10
        
        static func < (lhs: AddViewModel.Status, rhs: AddViewModel.Status) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
    
    @Published var status = Status.inputUrl
    @Published var url = ""
    @Published var username = ""
    
    @Published var presentingAlert = false
    
    var site: WikiSite? = nil
    var user: WikiUserRAW? = nil
    var alertMessage = ""
    
    var querying: Bool {
        status == .queryingSiteInfo
            || status == .queryingUserInfo
            || status == .queryingContributions
    }
    
    func querySite() {
        // Check
        if url.isEmpty {
            alert("view.add.alert.urlEmpty")
            return
        }
        guard let _ = URL(string: url) else {
            alert("view.add.alert.urlInvalid")
            return
        }
        status = .queryingSiteInfo
        if let site = Dia.shared.site(of: url) {
            self.site = site
            self.status = .inputUsername
            return
        }
        let raw = WikiSiteRAW(url)
        raw.query { succeed in
            DispatchQueue.main.async {
                if succeed {
                    self.site = .from(raw, context: Dia.shared.context)
                    self.status = .inputUsername
                } else {
                    self.alert("view.add.alert.querySiteFailed")
                    self.status = .inputUrl
                }
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
            status = .inputUrl
            return
        }
        status = .queryingUserInfo
        let raw = WikiUserRAW(username, solidSite)
        raw.queryInfo { succeed in
            DispatchQueue.main.async {
                if succeed {
                    self.queryContributions(raw)
                } else {
                    self.alert("view.add.alert.queryUserFailed")
                    self.status = .inputUsername
                }
            }
        }
    }
    
    func queryContributions(_ user: WikiUserRAW) {
        self.user = user
        status = .queryingContributions
        user.queryContributions { succeed in
            DispatchQueue.main.async {
                if succeed {
                    self.status = .allDone
                } else {
                    self.alert("view.add.alert.queryContributionsFailed")
                    self.status = .inputUsername
                }
            }
        }
    }
    
    func save() {
        guard let solidRAW = user else {
            return
        }
        let _ = WikiUser.from(solidRAW, context: Dia.shared.context)
        Dia.shared.save()
    }
    
    func clear() {
        if let solidSite = site {
            Dia.shared.delete(solidSite)
        }
        Dia.shared.save()
    }
    
    private func alert(_ message: String) {
        alertMessage = message
        presentingAlert = true
    }
}
