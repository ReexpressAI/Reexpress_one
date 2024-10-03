//
//  CreateProjectViewModifiers.swift
//  Alpha1
//
//  Created by A on 7/15/23.
//

import SwiftUI

struct CreateProjectView1TitleViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            content
                .font(Font.system(size: 24))
                .offset(CGSize(width: 0, height: -165))
        }
    }
}

struct CreateProjectViewControlTitlesViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Font.system(size: 16))
            .foregroundStyle(.gray)
    }
}
struct CreateProjectViewControlViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Font.system(size: 16))
            .foregroundStyle(.white)
    }
}
struct CreateProjectBaselineFontViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Font.system(size: 16))
    }
}
