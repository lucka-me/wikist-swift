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
            ScrollView(.vertical) {
                content
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            
            Spacer()
            continueButton
#endif
        }
#if os(macOS)
        .frame(minWidth: 320, maxWidth: 640, maxHeight: 640, alignment: .top)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                continueButton
            }
        }
#endif
        .padding([ .horizontal, .bottom ])
        .alert(isPresented: $isAlertPresented, error: migrateError) { _ in } message: { error in
            if let reason = error.failureReason {
                Text(reason)
            }
        }
    }
    
    @ViewBuilder
    private var content: some View {
        Image(AppIcon.current.previewName)
            .resizable()
            .aspectRatio(contentMode: .fit)
#if os(iOS)
            .mask {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(.secondary.opacity(0.5), lineWidth: 1)
            }
#endif
            .frame(width: 96, height: 96, alignment: .center)
            .padding(.top, 40)
        Text("OnboardingView.Title")
            .font(.largeTitle)
            .fontWeight(.bold)
            .padding(.bottom, 40)
        
        Grid(alignment: .topLeading, horizontalSpacing: 20, verticalSpacing: 20) {
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
    private var continueButton: some View {
        Button {
            dismiss()
        } label: {
            Text("OnboardingView.Continue")
#if os(iOS)
                .frame(maxWidth: 640)
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
