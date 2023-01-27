//
//  EqualWidthHStack.swift
//  Wikist
//
//  Created by Lucka on 17/7/2022.
//

import SwiftUI

struct EqualWidthHStack: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxSize = maxSize(of: subviews)
        let totalSpacing = spacings(of: subviews).reduce(0) { $0 + $1 }
        return .init(width: maxSize.width * CGFloat(subviews.count) + totalSpacing, height: maxSize.height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxSize = maxSize(of: subviews)
        let spacings = spacings(of: subviews)
        
        let sizeProposal = ProposedViewSize(maxSize)
        var x = bounds.minX + maxSize.width / 2
        for index in subviews.indices {
            subviews[index].place(at: .init(x: x, y: bounds.midY), anchor: .center, proposal: sizeProposal)
            x += maxSize.width + spacings[index]
        }
    }
    
    private func maxSize(of subviews: Subviews) -> CGSize {
        subviews.map {
            $0.sizeThatFits(.unspecified)
        }.reduce(.zero) { currentMax, item in
            .init(width: max(currentMax.width, item.width), height: max(currentMax.height, item.height))
        }
    }
    
    private func spacings(of subviews: Subviews) -> [ CGFloat ] {
        subviews.indices.map { index in
            guard index < subviews.count - 1 else { return 0.0 }
            return subviews[index].spacing.distance(to: subviews[index + 1].spacing, along: .horizontal)
        }
    }
}
