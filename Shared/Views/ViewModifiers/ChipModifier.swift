//
//  ChipModifier.swift
//  Wikist
//
//  Created by Lucka on 26/11/2022.
//

import SwiftUI

fileprivate struct ChipModifier<S: ShapeStyle> : ViewModifier {
    let style: S
    let padding: CGFloat
    let applyContentShape: Bool
    
    func body(content: Content) -> some View {
        let baseView = content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(padding)
            .background(style, in: shape)
        if applyContentShape {
            baseView.contentShape(shape)
        } else {
            baseView
        }
    }
    
    private var shape: Capsule {
        Capsule(style: .continuous)
    }
}

extension View {
    func chip<S: ShapeStyle>(
        style: S = Material.chip,
        padding: CGFloat = 12,
        applyContentShape: Bool = false
    ) -> some View {
        self.modifier(
            ChipModifier(
                style: style,
                padding: padding,
                applyContentShape: applyContentShape
            )
        )
    }
}

fileprivate extension Material {
#if os(macOS)
    static let chip = bar
#else
    static let chip = regular
#endif
}
