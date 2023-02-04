//
//  StatisticsGrid.swift
//  Wikist
//
//  Created by Lucka on 27/11/2022.
//

import SwiftUI

struct StatisticsGrid {
    @ViewBuilder
    static func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        Grid(verticalSpacing: 6, content: content)
            .card()
            .fixedSize(horizontal: false, vertical: true)
    }
    
    @ViewBuilder
    static func header(
        _ titleKey: LocalizedStringKey, unitKey: LocalizedStringKey? = nil
    ) -> some View {
        GridRow {
            Color.clear
                .gridCellUnsizedAxes(.horizontal)
            Text(titleKey)
                .gridColumnAlignment(.leading)
            if let unitKey {
                Color.clear
                    .gridCellUnsizedAxes(.horizontal)
                Text(unitKey)
                    .gridColumnAlignment(.trailing)
            }
        }
        .textCase(.uppercase)
        .font(.footnote)
        .foregroundColor(.secondary)
    }
    
    @ViewBuilder
    static func row<ValueContent: View>(
        _ title: LocalizedStringKey,
        systemImage: String,
        @ViewBuilder valueContent: @escaping () -> ValueContent
    ) -> some View {
        GridRow {
            Image(systemName: systemImage)
                .foregroundStyle(.tint)
                .gridColumnAlignment(.center)
            Text(title)
                .fixedSize()
                .gridColumnAlignment(.leading)
            Spacer(minLength: 4)
            valueContent()
                .gridColumnAlignment(.trailing)
                .monospaced()
        }
        .lineLimit(1)
    }
}

extension StatisticsGrid {
    @ViewBuilder
    @inlinable static func row<F: FormatStyle>(
        _ title: LocalizedStringKey, systemImage: String, value: F.FormatInput, format: F
    ) -> some View where F.FormatInput: Equatable, F.FormatOutput == String {
        row(title, systemImage: systemImage) {
            Text(value, format: format)
        }
    }
    
    @ViewBuilder
    @inlinable static func row(_ title: LocalizedStringKey, systemImage: String, value: Int64) -> some View {
        row(title, systemImage: systemImage, value: value, format: .number)
    }
    
    @ViewBuilder
    @inlinable static func row(_ title: LocalizedStringKey, systemImage: String, value: Int) -> some View {
        row(title, systemImage: systemImage, value: value, format: .number)
    }
}

#if DEBUG
struct StatisticsGridPreviews: PreviewProvider {
    static var previews: some View {
        StatisticsGrid.row("Pages", systemImage: "doc", value: 100)
    }
}
#endif
