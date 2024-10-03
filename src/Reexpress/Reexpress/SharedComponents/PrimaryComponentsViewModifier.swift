//
//  PrimaryComponentsViewModifier.swift
//  Alpha1
//
//  Created by A on 7/17/23.
//

import SwiftUI

struct PrimaryComponentsViewModifier: ViewModifier {
    var useReBackgroundDarker: Bool = false
    var viewBoxScaling: CGFloat = 2
    var backgroundStrokeColor: Color = .gray
    var maxWidth: CGFloat = .infinity
    
    var useShadow: Bool = false
    var opacity: CGFloat = 1.0
    
    
    func body(content: Content) -> some View {
        content
            .frame(
                minWidth: 800/viewBoxScaling, maxWidth: maxWidth) //.infinity)
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
                    .stroke(backgroundStrokeColor)
                    .opacity(0.5)
            }
    }
}

//struct PrimaryComponentsViewModifier_Previews: PreviewProvider {
//    static var previews: some View {
//        PrimaryComponentsViewModifier()
//    }
//}
