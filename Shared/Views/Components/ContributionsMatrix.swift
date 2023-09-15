//
//  ContributionsMatrix.swift
//  Wikist
//
//  Created by Lucka on 10/7/2022.
//

import Charts
import SwiftUI

struct ContributionsMatrix: View {
    private struct Week {
        var range: ChartBinRange<Date>
        var weekdays: [ ChartBinRange<Date> ]
    }
    
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
            LazyHGrid(rows: .init(repeating: .init(spacing: spacing), count: 7), spacing: spacing) {
                ForEach(weeks, id: \.range.lowerBound) { week in
                    ForEach(week.weekdays, id: \.lowerBound) { day in
                        ContributionsCell(countOf(day.lowerBound), in: day.lowerBound)
                            .aspectRatio(1, contentMode: .fit)
                            .mask { RoundedRectangle(cornerRadius: cornerRadius, style: .continuous) }
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
    
    private func spacing(in size: CGSize) -> CGFloat {
        if size.height >= Self.minimalRegularHeight {
            return Self.regularSpacing
        } else {
            return Self.compactSpacing
        }
    }
    
    private func weeks(in size: CGSize, spacing: CGFloat) -> [ Week ]  {
        let width = size.width + spacing
        let height = size.height + spacing
        let colums = Int(axisToFit == .horizontal ? ceil(width / height * 7) : floor(width / height * 7))
        let start = calendar.startOfDay(forNext: (1 - colums) * 7, of: today) ?? today
        return DateBins(unit: .weekOfYear, range: start ... today).map { week in
            let weekdayBins = DateBins(unit: .day, range: week.lowerBound ... min(week.upperBound, today))
            return .init(range: week, weekdays: weekdayBins.map { $0 })
        }
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
