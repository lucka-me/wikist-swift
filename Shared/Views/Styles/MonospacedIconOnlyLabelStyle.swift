//
//  MonospacedIconOnlyLabelStyle.swift
//  Wikist
//
//  Created by Lucka on 26/11/2022.
//

import SwiftUI

struct MonospacedIconOnlyLabelStyle : LabelStyle {
    @ScaledMetric private var iconHeight = 18
    @ScaledMetric private var iconWidth = 18
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.icon
            .frame(width: iconWidth, height: iconHeight, alignment: .center)
    }
}

extension LabelStyle where Self == MonospacedIconOnlyLabelStyle {
    static var monospacedIconOnly: MonospacedIconOnlyLabelStyle {
        .init()
    }
}
