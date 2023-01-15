//
//  ContributionsCell.swift
//  Wikist
//
//  Created by Lucka on 8/7/2022.
//

import SwiftUI

struct ContributionsCell: View {
    private let count: Int
    private let day: Date
    
    init(_ count: Int, in day: Date) {
        self.count = count
        self.day = day
    }
    
    var body: some View {
        if count > 0 {
            Rectangle()
                .fill(.tint.opacity(opacity))
                .help("ContributionsCell.Help \(count) \(day, format: .dateTime.year().month().day())")
        } else {
            Rectangle()
                .fill(.gray.opacity(0.4))
                .help("ContributionsCell.Help.Zero \(day, format: .dateTime.year().month().day())")
        }
    }
    
    private var opacity: Double {
        if count < 5 {
            return 0.3
        } else if count < 20 {
            return 0.5
        } else if count < 50 {
            return 0.8
        } else {
            return 1.0
        }
    }
}

#if DEBUG
struct ContributionsCellPreviews: PreviewProvider {
    
    static let persistence = Persistence.preview
    
    static var previews: some View {
        ContributionsCell(50, in: Date())
            .environment(\.managedObjectContext, persistence.container.viewContext)
            .frame(width: 24, height: 24)
            .mask { RoundedRectangle(cornerRadius: 4) }
    }
}
#endif
