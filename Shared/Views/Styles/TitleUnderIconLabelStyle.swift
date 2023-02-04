//
//  TitleUnderIconLabelStyle.swift
//  Wikist
//
//  Created by Lucka on 25/11/2022.
//

import SwiftUI

struct TitleUnderIconLabelStyle : LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .center) {
            configuration.icon
            configuration.title
                .font(.caption2)
                .lineLimit(1)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

extension LabelStyle where Self == TitleUnderIconLabelStyle {
    static var titleUnderIcon: TitleUnderIconLabelStyle {
        .init()
    }
}
