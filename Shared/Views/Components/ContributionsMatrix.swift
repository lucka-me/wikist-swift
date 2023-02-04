//
//  ContributionsMatrix.swift
//  Wikist
//
//  Created by Lucka on 10/7/2022.
//

import SwiftUI

struct ContributionsMatrix: View {
    
    static let regularSpacing: CGFloat = 4
    static let compactSpacing: CGFloat = 3
    static let minimalRegularHeight: CGFloat = 16 * 7 + regularSpacing * 6
    
    @Environment(\.calendar) private var calendar
    
    @State private var today = Date()
    
    let countOf: (Date) -> Int
    let axisToFit: Axis
    
    init(fits axis: Axis, countOf: @escaping (Date) -> Int) {
        self.countOf = countOf
        self.axisToFit = axis
    }
    
    var body: some View {
        GeometryReader { proxy in
            let spacing = spacing(in: proxy.size)
            let cornerRadius = cornerRadius(in: proxy.size)
            let weeks = weeks(in: proxy.size, spacing: spacing)
            Grid(horizontalSpacing: spacing, verticalSpacing: spacing) {
                ForEach(1 ..< 8) { weekday in
                    GridRow {
                        ForEach(weeks, id: \.self) { week in
                            if isFuture(before: week, at: weekday) {
                                Color.clear
                            } else if let day = day(before: week, at: weekday) {
                                ContributionsCell(countOf(day), in: day)
                                    .aspectRatio(1, contentMode: .fit)
                                    .mask { RoundedRectangle(cornerRadius: cornerRadius, style: .continuous) }
                            } else {
                                Color.red
                                    .aspectRatio(1, contentMode: .fit)
                                    .mask { RoundedRectangle(cornerRadius: cornerRadius, style: .continuous) }
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .onReceiveCalendarDayChanged { day in
            today = day
        }
    }
    
    private func cornerRadius(in size: CGSize) -> CGFloat {
        if size.height >= Self.minimalRegularHeight {
            return 4
        } else {
            return 2
        }
    }
    
    private func day(before weeks: Int, at weekday: Int) -> Date? {
        calendar.startOfDay(
            forNext: -7 * weeks - calendar.component(.weekday, from: today) + weekday,
            of: today
        )
    }
    
    private func isFuture(before weeks: Int, at weekday: Int) -> Bool {
        if weeks > 0 { return false }
        if weeks == 0 { return weekday > calendar.component(.weekday, from: today) }
        return true
    }
    
    private func spacing(in size: CGSize) -> CGFloat {
        if size.height >= Self.minimalRegularHeight {
            return Self.regularSpacing
        } else {
            return Self.compactSpacing
        }
    }
    
    private func weeks(in size: CGSize, spacing: CGFloat) -> [ Int ] {
        let width = size.width + spacing
        let height = size.height + spacing
        let colums = Int(axisToFit == .horizontal ? ceil(width / height * 7) : floor(width / height * 7))
        return .init(0 ..< colums).reversed()
    }
}

#if DEBUG
struct ContributionsMatrixPreviews: PreviewProvider {
    static let persistence = Persistence.preview

    static var previews: some View {
        ContributionsMatrix(fits: .vertical) { _ in .random(in: 0 ... 100) }
    }
}
#endif

fileprivate struct MatrixSizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value.width = max(value.width, nextValue().width)
        value.height = max(value.height, nextValue().height)
    }
}
