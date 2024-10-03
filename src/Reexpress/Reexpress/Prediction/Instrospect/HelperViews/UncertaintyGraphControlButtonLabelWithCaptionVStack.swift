//
//  UncertaintyGraphControlButtonLabelWithCaptionVStack.swift
//  Alpha1
//
//  Created by A on 5/8/23.
//

import SwiftUI

struct UncertaintyGraphControlButtonLabelWithCaptionVStack: View {
    var buttonImageName: String
    var buttonTextCaption: String
    
    var buttonForegroundStyle: AnyShapeStyle = AnyShapeStyle(Color.blue.gradient)
    var buttonFrameWidth: CGFloat = 70
    // Shared constants:
//    let buttonFrameWidth: CGFloat = 70
    let buttonFrameHeight: CGFloat = 40
    let buttonPadding = EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5)
    
    var body: some View {
        VStack {
            Image(systemName: buttonImageName)
                .font(.title)
                .foregroundStyle(buttonForegroundStyle)
            Text(buttonTextCaption)
                //.foregroundStyle(.secondary)
                .foregroundStyle(.gray)
        }
        .frame(width: buttonFrameWidth, height: buttonFrameHeight)
        .padding(buttonPadding)
    }
}

//struct UncertaintyGraphControlButtonLabelWithCaptionVStack_Previews: PreviewProvider {
//    static var previews: some View {
//        UncertaintyGraphControlButtonLabelWithCaptionVStack()
//    }
//}
