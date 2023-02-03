//
//  AddWikiView.swift
//  Wikist
//
//  Created by Lucka on 22/11/2022.
//

import SwiftUI

struct AddWikiView: View {
    
    private enum TaskError: Error, LocalizedError {
        case invalidURL
        case notFound
        case existed(title: String, api: String)
        case wikiTaskFailed(error: Wiki.TaskError)
        case genericError(error: Error)
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return .init(localized: "AddWikiView.TaskError.InvalidURL")
            case .notFound:
                return .init(localized: "AddWikiView.TaskError.NotFound")
            case .existed(_, _):
                return .init(localized: "AddWikiView.TaskError.Existed")
            case .wikiTaskFailed(let error):
                return error.errorDescription
            case .genericError(let error):
                return error.localizedDescription
            }
        }
        
        var failureReason: String? {
            switch self {
            case .invalidURL:
                return .init(localized: "AddWikiView.TaskError.InvalidURL.Reason")
            case .notFound:
                return .init(localized: "AddWikiView.TaskError.NotFound.Reason")
            case .existed(let title, let api):
                return .init(localized: "AddWikiView.TaskError.Existed.Reason \(title) \(api)")
            case .wikiTaskFailed(let error):
                return error.errorDescription
            case .genericError(let error):
                return error.localizedDescription
            }
        }
    }
    
    @Binding private var wiki: Wiki?
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @FocusState private var urlTextFieldIsFocused: Bool
    
    @State private var isAlertPresented = false
    @State private var isQuerying = false
    @State private var taskError: TaskError? = nil
    @State private var urlText: String = ""
    
    init() {
        self._wiki = .constant(nil)
    }
    
    init(wiki: Binding<Wiki?>) {
        self._wiki = wiki
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("AddWikiView.URL", text: $urlText, prompt: Text("https://wiki.example.com"))
                        .lineLimit(1)
#if os(iOS)
                        .keyboardType(.URL)
#endif
                        .disableAutocorrection(true)
                        .focused($urlTextFieldIsFocused)
                        .onSubmit {
                            Task { await tryAdd() }
                        }
                        .disabled(isQuerying)
                    
                    Button("AddWikiView.Add") {
                        Task { await tryAdd() }
                    }
                    .disabled(urlText.isEmpty || isQuerying)
                } footer: {
                    Text("AddWikiView.Footer")
                }
            }
#if os(macOS)
            .frame(minWidth: 360, minHeight: 180)
#endif
            .formStyle(.grouped)
            .navigationTitle("AddWikiView.Title")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .alert(isPresented: $isAlertPresented, error: taskError) { _ in } message: { error in
                if let reason = error.failureReason {
                    Text(reason)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    ThemedButton.dismiss {
                        dismiss()
                    }
                }
            }
        }
    }
    
    @MainActor
    private func tryAdd() async {
        isQuerying = true
        defer { isQuerying = false }
        var urlText = urlText
        // If the URL contains no scheme, URLComponents will generate url as scheme:host, without the slashes
        if !urlText.starts(with: /.*?\/\//) {
            urlText = "https://" + urlText
        }
        do {
            guard
                let encodedText = urlText.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed),
                let url = URL(string: encodedText)?.removingAllQuries(),
                var host = url.removingAllPaths() else {
                throw TaskError.invalidURL
            }
            
            if host.scheme != "https" {
                host.set(scheme: "https")
            }
            
            var components = url.pathComponents.filter { $0 != "/" }
            
            var api: URL? = nil
            repeat {
                let searchURL = host.appending(path: components.joined(separator: "/"))
                if searchURL.lastPathComponent == "api.php" {
                    let (_, response) = try await URLSession.shared.data(for: .init(url: searchURL))
                    if response.isHTTP(status: 200) {
                        api = searchURL
                        break
                    }
                    continue
                }
                
                // Try /api.php
                var testURL = searchURL.appending(component: "api.php")
                var (_, response) = try await URLSession.shared.data(for: .init(url: testURL))
                if response.isHTTP(status: 200) {
                    api = testURL
                    break
                }
                // Try /w/api.php
                testURL = searchURL.appending(components: "w", "api.php")
                (_, response) = try await URLSession.shared.data(for: .init(url: testURL))
                if response.isHTTP(status: 200) {
                    api = testURL
                    break
                }
                // Try /mediawiki/api.php
                testURL = searchURL.appending(components: "mediawiki", "api.php")
                (_, response) = try await URLSession.shared.data(for: .init(url: testURL))
                if response.isHTTP(status: 200) {
                    api = testURL
                    break
                }
            } while api == nil && components.popLast() != nil
            
            guard let api else {
                throw TaskError.notFound
            }
            
            if let wiki = await Wiki.findExistedWiki(for: api, in: viewContext) {
                throw TaskError.existed(title: wiki.title ?? "Untitled", api: api.absoluteString)
            }
            guard !Task.isCancelled else { return }
            
            let wiki = Wiki(api: api, context: viewContext)
            do {
                try await wiki.update()
            } catch {
                viewContext.delete(wiki)
                throw error
            }
            
            guard !Task.isCancelled else {
                viewContext.delete(wiki)
                return
            }
            
            try viewContext.save()
            self.wiki = wiki
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
//struct AddWikiViewPreviews: PreviewProvider {
//    static var previews: some View {
//        AddWikiView()
//            .environment(\.managedObjectContext, Persistence.preview.container.viewContext)
//    }
//}
#endif
