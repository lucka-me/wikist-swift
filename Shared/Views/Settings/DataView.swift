//
//  DataView.swift
//  Wikist
//
//  Created by Lucka on 6/12/2022.
//

import SwiftUI

struct DataView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.persistence) private var persistence
    
    @State private var isAlertPresented = false
    @State private var migrateError: Persistence.MigrateError? = nil
    @State private var migrateStage: Persistence.MigrateStage =
        Persistence.legacyStoreExists ? .available : .unavailable
    
    var body: some View {
        Form {
            Section {
                Button {
                    Task {
                        do {
                            try await persistence.clearResidualData()
                        } catch {
                            print(error)
                        }
                    }
                } label: {
                    Label("DataView.ResidualData.Clear", systemImage: "trash")
#if os(macOS)
                        .labelStyle(.titleOnly)
#endif
                }
            } header: {
                Text("DataView.ResidualData")
            } footer: {
                Text("DataView.ResidualData.Footer")
            }
            
            if migrateStage != .unavailable {
                Section {
                    Button {
                        Task { await tryMigrate() }
                    } label: {
                        Label("DataView.Migrate", systemImage: migrateStage.iconName)
                    }
                    .disabled(migrateStage != .available)
                    .opacity(migrateStage == .migrating ? 0 : 1)
                    .overlay {
                        if migrateStage == .migrating {
                            ProgressView()
                        }
                    }
                } header: {
                    Text("DataView.Migrate")
                } footer: {
                    Text(LocalizedStringKey(migrateStage.descriptions))
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("DataView.Title")
        .alert(isPresented: $isAlertPresented, error: migrateError) { }
    }
    
    @MainActor
    private func tryMigrate() async {
        migrateStage = .migrating
        do {
            let migratedCount = try await persistence.migrate()
            withAnimation {
                migrateStage = .done(wikis: migratedCount.0, users: migratedCount.1)
            }
        } catch {
            self.migrateError = .genericError(error: error)
            self.isAlertPresented = true
            migrateStage = .failed
        }
    }
}

#if DEBUG
struct DataViewPreviews: PreviewProvider {
    static var previews: some View {
        DataView()
    }
}
#endif
