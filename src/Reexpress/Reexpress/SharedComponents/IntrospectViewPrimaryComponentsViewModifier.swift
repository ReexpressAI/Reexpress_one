//
//  IntrospectViewPrimaryComponentsViewModifier.swift
//  Alpha1
//
//  Created by A on 9/15/23.
//

import SwiftUI

struct IntrospectViewPrimaryComponentsViewModifier: ViewModifier {
    var useReBackgroundDarker: Bool = false
    let viewBoxScaling: CGFloat = 2
    
    var useShadow: Bool = false
    var opacity: CGFloat = 1.0
    
    func body(content: Content) -> some View {
        HStack {
            content
                .frame(
                    minWidth: 800/viewBoxScaling, maxWidth: .infinity)
                .background {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(useShadow
                              ?
                              ( useReBackgroundDarker ? AnyShapeStyle(REConstants.REColors.reBackgroundDarker.shadow(.drop(color: .black, radius: 2, y: 3))) : AnyShapeStyle(BackgroundStyle().shadow(.drop(color: .black, radius: 2, y: 3))) )
                              :
                                ( useReBackgroundDarker ? AnyShapeStyle(REConstants.REColors.reBackgroundDarker) : AnyShapeStyle(BackgroundStyle()) ) )
                        .opacity(opacity)
//                    RoundedRectangle(cornerRadius: 12, style: .continuous)
//                        .fill(
//                            useReBackgroundDarker ? AnyShapeStyle(REConstants.REColors.reBackgroundDarker) : AnyShapeStyle(BackgroundStyle()))
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(.gray)
                        .opacity(0.5)
                }
                .padding()
        }
    }
}
