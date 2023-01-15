//
//  OnboardingView.swift
//  Wikist
//
//  Created by Lucka on 17/7/2022.
//

import SwiftUI

struct OnboardingView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.persistence) private var persistence
    @Environment(\.refresh) private var refresh
    
    @State private var isAlertPresented = false
    @State private var migrateError: Persistence.MigrateError? = nil
    @State private var migrateStage: Persistence.MigrateStage =
        Persistence.legacyStoreExists ? .available : .unavailable
    

    var body: some View {
        VStack {
#if os(macOS)
            content
#else
            ViewThatFits(in: .vertical) {
                VStack {
                    title
                        .padding(.vertical, 40)
                    content
                }
                VStack {
                    title
                        .padding(.vertical, 20)
                    ScrollView(.vertical) {
                        content
                    }
                }
            }
            Spacer()
            startButton
#endif
        }
#if os(macOS)
        .frame(minWidth: 320, idealWidth: 480, maxWidth: 640, maxHeight: 640, alignment: .top)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                startButton
            }
        }
#endif
        .padding()
        .alert(isPresented: $isAlertPresented, error: migrateError) { }
    }
    
    @ViewBuilder
    private var title: some View {
        Text("OnboardingView.Title")
            .font(.largeTitle)
            .fontWeight(.bold)
    }
    
    @ViewBuilder
    private var content: some View {
        Grid(horizontalSpacing: 20, verticalSpacing: 20) {
#if os(macOS)
            title
#endif
            row("OnboardingView.Reborn", descriptions: "OnboardingView.Reborn.Description") {
                Image(systemName: "swift")
                    .foregroundStyle(Color(red: 0xF0 / 0xFF, green: 0x51 / 0xFF, blue: 0x38 / 0xFF).gradient)
            }
            row("OnboardingView.FullHistory", descriptions: "OnboardingView.FullHistory.Description") {
                Image(systemName: "calendar")
                    .foregroundStyle(.red.gradient)
            }
            row("OnboardingView.Charts", descriptions: "OnboardingView.Charts.Description") {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(.green.gradient)
            }
            if migrateStage != .unavailable {
                Divider()
                row("OnboardingView.Migrate", descriptions: .init(migrateStage.descriptions)) {
                    Button {
                        Task { await tryMigrate() }
                    } label: {
                        Image(systemName: migrateStage.iconName)
                            .foregroundStyle(.purple.gradient)
                            .symbolVariant(.fill)
                    }
                    .buttonStyle(.plain)
                    .disabled(migrateStage != .available)
                    .opacity(migrateStage == .migrating ? 0 : 1)
                    .overlay {
                        if migrateStage == .migrating {
                            ProgressView()
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var startButton: some View {
        Button {
            dismiss()
        } label: {
            Text("OnboardingView.GetStart")
#if os(iOS)
                .frame(maxWidth: .infinity)
#endif
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(migrateStage == .migrating)
    }
    
    @ViewBuilder
    private func row<Icon: View>(
        _ titleKey: LocalizedStringKey, descriptions: LocalizedStringKey, icon: () -> Icon
    ) -> some View {
        GridRow {
            icon()
                .font(.largeTitle)
                .symbolRenderingMode(.multicolor)
                .gridColumnAlignment(.center)
            VStack(alignment: .leading, spacing: 6) {
                Text(titleKey)
                    .foregroundStyle(.primary)
                    .font(.headline)
                    .fontWeight(.semibold)
                Text(descriptions)
                    .foregroundStyle(.secondary)
            }
            .gridColumnAlignment(.leading)
        }
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
struct OnboardingViewPreviews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
            .environment(\.managedObjectContext, Persistence.preview.container.viewContext)
            .environment(\.persistence, Persistence.preview)
    }
}
#endif
