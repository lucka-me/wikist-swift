//
//  ViewModifiers.swift
//  ViewModifiers
//
//  Created by Lucka on 24/7/2021.
//

import SwiftUI

extension View {
    @inlinable func card(radius: CGFloat = 12) -> some View {
        self
            .padding(radius)
            .background(
                .thickMaterial,
                in: RoundedRectangle(cornerRadius: radius, style: .continuous)
            )
    }
}
