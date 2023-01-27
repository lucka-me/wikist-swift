//
//  CardModifier.swift
//  Wikist
//
//  Created by Lucka on 26/11/2022.
//

import SwiftUI

fileprivate struct CardModifier<S: ShapeStyle> : ViewModifier {
    let style: S
    let padding: CGFloat
    let radius: CGFloat
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
    
    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
    }
}

extension View {
    func card<S: ShapeStyle>(
        style: S = Material.card,
        padding: CGFloat = 12,
        radius: CGFloat = 12,
        applyContentShape: Bool = false
    ) -> some View {
        self.modifier(
            CardModifier(
                style: style,
                padding: padding,
                radius: radius,
                applyContentShape: applyContentShape
            )
        )
    }
}

fileprivate extension Material {
#if os(macOS)
    static let card = bar
#else
    static let card = regular
#endif
}
