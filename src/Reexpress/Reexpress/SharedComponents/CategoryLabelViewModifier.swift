//
//  CategoryLabelViewModifier.swift
//  Alpha1
//
//  Created by A on 8/12/23.
//

import SwiftUI

// The larger version is used in the heads-up displays.
struct CategoryLabelViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.title2.smallCaps())
            .monospaced()
    }
}

// The smaller version is used in the main Details view.
struct CategoryLabelInLineSmallerViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.title3.smallCaps())
            .monospaced()
    }
}

