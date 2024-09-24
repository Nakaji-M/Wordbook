//
//  PopoverContainerLayout.swift
//  Wordbook
//
//  Created by Masanori on 2024/09/04.
//

import SwiftUI

struct PopoverContainer: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard subviews.count == 1 else {
            fatalError("You need to implement your layout!")
        }
        var p = proposal
        p.width = p.width ?? UIScreen.main.bounds.width
        p.height = p.height ?? UIScreen.main.bounds.height

        return subviews[0].sizeThatFits(p) // negotiates possible size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        // entrusts default
    }
}
