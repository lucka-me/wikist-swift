//
//  Modifiers.swift
//  Wikist
//
//  Created by Lucka on 10/7/2022.
//

import SwiftUI

extension View {
    @inlinable func sectionHeader(padding: CGFloat = 12) -> some View {
        self
            .frame(maxWidth: .infinity, alignment: .leading)
#if os(iOS)
            .font(.footnote)
            .textCase(.uppercase)
#else
            .font(.callout)
            .fontWeight(.medium)
#endif
            .foregroundColor(.secondary)
            .padding(.horizontal, padding)
    }
    
    @inlinable func onReceiveCalendarDayChanged(perform action: @escaping (Date) -> Void) -> some View {
        self.onReceive(
            NotificationCenter.default.publisher(for: .NSCalendarDayChanged).receive(on: RunLoop.main)
        ) { _ in
            action(.init())
        }
    }
}
