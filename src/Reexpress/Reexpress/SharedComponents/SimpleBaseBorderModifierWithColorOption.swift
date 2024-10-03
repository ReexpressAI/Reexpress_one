//
//  SimpleBaseBorderModifierWithColorOption.swift
//  Alpha1
//
//  Created by A on 9/8/23.
//

import SwiftUI

struct SimpleBaseBorderModifierWithColorOption: ViewModifier {
    var useReBackgroundDarker: Bool = false
    var useShadow: Bool = false
    var opacity: CGFloat = 1.0
    func body(content: Content) -> some View {
        content
            .background {
//                RoundedRectangle(cornerRadius: 12, style: .continuous)
//                    .fill(
//                        useReBackgroundDarker ? AnyShapeStyle(REConstants.REColors.reBackgroundDarker) : AnyShapeStyle(BackgroundStyle()))
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(useShadow 
                          ?
                          ( useReBackgroundDarker ? AnyShapeStyle(REConstants.REColors.reBackgroundDarker.shadow(.drop(color: .black, radius: 2, y: 3))) : AnyShapeStyle(BackgroundStyle().shadow(.drop(color: .black, radius: 2, y: 3))) )
                          :
                            ( useReBackgroundDarker ? AnyShapeStyle(REConstants.REColors.reBackgroundDarker) : AnyShapeStyle(BackgroundStyle()) ) )
                    .opacity(opacity)
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(.gray, lineWidth: 1)
                    .opacity(0.5)
            }
    }
}
