//
//  AddWikiView.swift
//  Wikist
//
//  Created by Lucka on 22/11/2022.
//

import SwiftUI

struct AddWikiView: View {
    
    private enum TaskError: Error, LocalizedError {
        case invalidURL(url: String)
        case notFound
        case existed(wiki: Wiki)
        case wikiTaskFailed(error: Wiki.TaskError)
        case genericError(error: Error)
        
        var errorDescription: String? {
            switch self {
            case .invalidURL(url: let url):
                return "The URL \(url) is invalid."
            case .notFound:
                return "Unable to find the API of the Wiki."
            case .existed(wiki: let wiki):
                return "The Wiki is existed as \(wiki.title ?? "Untitled") with API \(wiki.api?.absoluteString ?? "")"
            case .wikiTaskFailed(error: let error):
                return error.errorDescription
            case .genericError(error: let error):
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
            .alert(isPresented: $isAlertPresented, error: taskError) { }
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
        do {
            guard
                let encodedText = urlText.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed),
                let url = URL(string: encodedText)?.removingAllQuries(),
                var host = url.removingAllPaths() else {
                throw TaskError.invalidURL(url: urlText)
            }
            
            host.set(scheme: "https")
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
                throw TaskError.existed(wiki: wiki)
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