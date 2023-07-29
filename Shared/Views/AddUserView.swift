//
//  AddUserView.swift
//  Wikist
//
//  Created by Lucka on 3/7/2022.
//

import CoreData
import SwiftUI

struct AddUserView: View {
    
    private enum TaskError: Error, LocalizedError {
        case notFound(username: String)
        case wikiTaskFailed(error: Wiki.TaskError)
        case genericError(error: Error)
        
        var errorDescription: String? {
            switch self {
            case .notFound(_):
                return .init(localized: "AddUserView.TaskError.NotFound")
            case .wikiTaskFailed(let error):
                return error.errorDescription
            case .genericError(_):
                return .init(localized: "AddUserView.TaskError.GenericError")
            }
        }
        
        var failureReason: String? {
            switch self {
            case .notFound(let username):
                return .init(localized: "AddUserView.TaskError.NotFound.Reason \(username)")
            case .wikiTaskFailed(let error):
                return error.failureReason
            case .genericError(let error):
                return error.localizedDescription
            }
        }
    }
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        entity: Wiki.entity(),
        sortDescriptors: [ .init(keyPath: \Wiki.title, ascending: true) ],
        animation: .default
    )
    private var wikis: FetchedResults<Wiki>
    
    @FocusState private var isUsernameTextFieldFocused: Bool
    
    @State private var isAddWikiSheetPresented = false
    @State private var isAlertPresented = false
    @State private var isQuerying = false
    @State private var selectedWiki: Wiki?
    @State private var taskError: TaskError? = nil
    @State private var username: String = ""
    
    init() {
        _selectedWiki = .init(initialValue: nil)
    }
    
    init(wiki: Wiki) {
        _selectedWiki = .init(initialValue: wiki)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("AddUserView.Wiki") {
                    if !wikis.isEmpty {
                        Picker("AddUserView.Wiki.Select", selection: $selectedWiki) {
                            Text("AddUserView.Wiki.NotSelected")
                                .tag(nil as Wiki?)
                            ForEach(wikis) { wiki in
#if os(macOS)
                                if let title = wiki.title, let api = wiki.api {
                                    Text("\(title) <\(api)>")
                                        .tag(wiki as Wiki?)
                                }
#elseif os(iOS)
                                if let title = wiki.title {
                                    Text(title)
                                        .tag(wiki as Wiki?)
                                }
#endif
                            }
                        }
                    }
#if os(iOS)
                    if let api = selectedWiki?.api {
                        Text(api.absoluteString)
                            .foregroundStyle(.secondary)
                    }
#endif
                    Button("AddUserView.Add") {
                        isAddWikiSheetPresented.toggle()
                    }
                    .disabled(isQuerying)
                }
                
                Section("AddUserView.User") {
                    TextField("AddUserView.User.Username", text: $username)
                        .lineLimit(1)
                        .focused($isUsernameTextFieldFocused)
                        .onSubmit {
                            Task { await tryAdd() }
                        }
                        .disabled(selectedWiki == nil || isQuerying)
                    Button("AddUserView.Add") {
                        Task { await tryAdd() }
                    }
                    .disabled(selectedWiki == nil || username.isEmpty || isQuerying)
                }
            }
#if os(macOS)
            .frame(minWidth: 360, minHeight: 320)
#endif
            .formStyle(.grouped)
            .navigationTitle("AddUserView.Title")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    ThemedButton.dismiss {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $isAddWikiSheetPresented) {
                AddWikiView(wiki: $selectedWiki)
            }
            .onChange(of: selectedWiki) {
                isUsernameTextFieldFocused = true
            }
        }
        .alert(isPresented: $isAlertPresented, error: taskError) { _ in } message: { error in
            if let reason = error.failureReason {
                Text(reason)
            }
        }
        .onAppear {
            if selectedWiki != nil {
                isUsernameTextFieldFocused = true
            }
        }
    }
    
    @MainActor
    private func tryAdd() async {
        isQuerying = true
        defer { isQuerying = false }
        do {
            guard let wiki = selectedWiki else { return }
            guard try await wiki.checkExistance(of: username) else {
                throw TaskError.notFound(username: username)
            }
            guard !Task.isCancelled else { return }
            
            let user = User(name: username, wiki: wiki, context: viewContext)
            try await user.update()
            guard !Task.isCancelled else {
                viewContext.delete(user)
                return
            }
            try viewContext.save()
            dismiss()
        } catch let error as TaskError {
            self.taskError = error
            self.isAlertPresented = true
        } catch let error as Wiki.TaskError {
            self.taskError = .wikiTaskFailed(error: error)
            self.isAlertPresented = true
        } catch {
            self.taskError = .genericError(error: error)
            self.isAlertPresented = true
        }
    }
}

#if DEBUG
struct AddUserViewPreviews: PreviewProvider {
    static var previews: some View {
        AddUserView()
            .environment(\.managedObjectContext, Persistence.preview.container.viewContext)
    }
}
#endif
