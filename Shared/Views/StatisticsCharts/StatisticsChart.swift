//
//  StatisticsChart.swift
//  Wikist
//
//  Created by Lucka on 28/11/2022.
//

import SwiftUI

protocol StatisticsChart {
    associatedtype BriefData
    associatedtype Card: View
    
    static var briefTitleKey: LocalizedStringKey { get }
    static var briefSystemImage: String { get }
    
    static func card(data: BriefData, action: @escaping () -> Void) -> Card
}

struct StatisticsChartCard<Chart: StatisticsChart, Content: View>: View {
    private let action: () -> Void
    private let content: () -> Content
    
    init(
        _: Chart.Type,
        action: @escaping () -> Void,
        content: @escaping () -> Content
    ) {
        self.action = action
        self.content = content
    }
    
    var body: some View {
        GroupBox(content: content) {
            Label(Chart.briefTitleKey, systemImage: Chart.briefSystemImage)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .labelStyle(.monospacedIconAndTitle)
        }
        .aspectRatio(1, contentMode: .fit)
        .onTapGesture(perform: action)
    }
}
