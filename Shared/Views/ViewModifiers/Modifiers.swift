//
//  Modifiers.swift
//  Wikist
//
//  Created by Lucka on 10/7/2022.
//

import Combine
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
    
    func onContributionsUpdated(userID: UUID?, perform action: @escaping () async -> Void) -> some View {
        self.onReceive(
            NotificationCenter.default.publisher(for: .ContributionsUpdated)
        ) { notification in
            guard
                let userID,
                let notificationUUID = notification.object as? NSUUID,
                notificationUUID.compare(userID) == .orderedSame
            else {
                return
            }
            Task {
                await action()
            }
        }
    }
}
