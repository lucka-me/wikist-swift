//
//  ContributionsMatrix.swift
//  Wikist
//
//  Created by Lucka on 11/4/2021.
//

import SwiftUI

struct ContributionsMatrix: View {
    
    private struct LevelColor {
        static let levelNil = Color.black.opacity(0)
        static let level0   = Color.gray.opacity(0.4)
        static let level5   = Color(hue: 0.1, saturation: 0.55, brightness: 0.55, opacity: 1.0)
        static let level20  = Color(hue: 0.1, saturation: 0.70, brightness: 0.70, opacity: 1.0)
        static let level50  = Color(hue: 0.1, saturation: 0.85, brightness: 0.85, opacity: 1.0)
        static let levelMax = Color(hue: 0.1, saturation: 1.00, brightness: 1.00, opacity: 1.0)
    }
    
    static let gridSpacing: CGFloat = 2
    
    static private var rows: [GridItem] {
        .init(
            repeating: .init(.flexible(minimum: 10, maximum: .infinity), spacing: Self.gridSpacing),
            count: 7
        )
    }
    
    @EnvironmentObject private var dia: Dia
    
    private let user: WikiUser
    
    init(_ user: WikiUser) {
        self.user = user
    }
    
    var body: some View {
        GeometryReader { geometry in
            LazyHGrid(rows: Self.rows, alignment: .top, spacing: Self.gridSpacing) {
                ForEach(user.contributionsMatrix.suffix(count(geometry.size))) { raw in
                    grid(raw.count)
                }
            }
            .frame(alignment: .center)
        }
    }
    
    @ViewBuilder
    private func grid(_ count: Int64?) -> some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(color(count))
            .aspectRatio(1, contentMode: .fit)
    }
    
    private func count(_ size: CGSize) -> Int {
        let weeks = Int(floor((size.width + Self.gridSpacing) / (size.height + Self.gridSpacing) * 7))
        return weeks * 7
    }
    
    private func color(_ count: Int64?) -> Color {
        guard let solidCount = count else {
            return LevelColor.levelNil
        }
        if solidCount == 0 {
            return LevelColor.level0
        } else if solidCount < 5 {
            return LevelColor.level5
        } else if solidCount < 20 {
            return LevelColor.level20
        } else if solidCount < 50 {
            return LevelColor.level50
        }
        return LevelColor.levelMax
    }
}

#if DEBUG
struct ContributionsMatrix_Previews: PreviewProvider {
    static var previews: some View {
        ContributionsMatrix(Dia.preview.users().first!)
    }
}
#endif
