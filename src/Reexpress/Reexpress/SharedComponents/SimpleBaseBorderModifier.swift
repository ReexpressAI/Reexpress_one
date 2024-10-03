//
//  SimpleBaseBorderModifier.swift
//  Alpha1
//
//  Created by A on 7/20/23.
//

import SwiftUI

//struct SimpleBaseBorderModifier: ViewModifier {
//    func body(content: Content) -> some View {
//        content
//            .background {
//                RoundedRectangle(cornerRadius: 12, style: .continuous)
//                    .fill(
//                        AnyShapeStyle(BackgroundStyle()))
//                RoundedRectangle(cornerRadius: 12, style: .continuous)
//                    .stroke(.gray, lineWidth: 1)
//                    .opacity(0.5)
//            }
//    }
//}
struct SimpleBaseBorderModifier: ViewModifier {
    var useShadow: Bool = false
    var opacity: CGFloat = 1.0
    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(useShadow ? AnyShapeStyle(BackgroundStyle().shadow(.drop(color: .black, radius: 2, y: 3))) :
                        AnyShapeStyle(BackgroundStyle()))
                    .opacity(opacity)
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(.gray, lineWidth: 1)
                    .opacity(0.5)
            }
    }
}


