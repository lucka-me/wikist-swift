//
//  MonospacedIconAndTitleLabelStyle.swift
//  Wikist
//
//  Created by Lucka on 26/11/2022.
//

import SwiftUI

struct MonospacedIconAndTitleLabelStyle : LabelStyle {
    @ScaledMetric private var iconHeight = 18
    @ScaledMetric private var iconWidth = 18
    
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.icon
                .frame(width: iconWidth, height: iconHeight, alignment: .center)
            configuration.title
        }
    }
}

extension LabelStyle where Self == MonospacedIconAndTitleLabelStyle {
    static var monospacedIconAndTitle: MonospacedIconAndTitleLabelStyle {
        .init()
    }
}
