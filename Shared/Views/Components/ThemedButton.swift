//
//  Buttons.swift
//  Wikist
//
//  Created by Lucka on 17/7/2022.
//

import CoreData
import SwiftUI

struct ThemedButton {
    typealias Action = () -> Void
    
    @ViewBuilder
    static func action(_ titleKey: LocalizedStringKey, systemImage: String, action: @escaping Action) -> some View {
        Button(action: action) {
            Label(titleKey, systemImage: systemImage)
                .labelStyle(.titleUnderIcon)
                .card()
        }
        .buttonStyle(.borderless)
    }
    
    @ViewBuilder
    static func add(action: @escaping Action) -> some View {
        Button(action: action) {
            Label("ThemedButton.Add", systemImage: "plus")
                .labelStyle(.iconOnly)
        }
    }
    
    @ViewBuilder
    static func confirm(action: @escaping Action) -> some View {
        Button("ThemedButton.Confirm", action: action)
    }
    
    @ViewBuilder
    static func dismiss(action: @escaping Action) -> some View {
#if os(iOS)
        Button(action: action) {
            Label("ThemedButton.Dismiss", systemImage: "xmark")
                .labelStyle(.iconOnly)
                .fontWeight(.bold)
        }
        .foregroundStyle(.secondary)
        .buttonStyle(.bordered)
        .mask {
            Circle()
        }
#elseif os(macOS)
        Button("ThemedButton.Dismiss", action: action)
#endif
    }
    
    @ViewBuilder
    static func refresh(isRefreshing: Bool, action: @escaping () async -> Void) -> some View {
        Button {
            Task { await action() }
        } label: {
            Label("ThemedButton.Refresh", systemImage: "arrow.clockwise")
        }
        .disabled(isRefreshing)
        .opacity(isRefreshing ? 0 : 1)
        .overlay {
            if isRefreshing {
                ProgressView()
                    .progressViewStyle(.circular)
            }
        }
        .animation(.easeInOut, value: isRefreshing)
    }
    
    private init() { }
}
