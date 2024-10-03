//
//  REConstants+REColors.swift
//  Reexpress
//
//  Created by A on 10/8/23.
//

import Foundation
import SwiftUI

extension REConstants {
    struct REColors {
        static let reBlue = Color("reBlue")
        static let reRed = Color("reRed")
        static let reGrey = Color("reGrey")
        
        static let reBackgroundDarker = Color("reBackgroundDarker")
        
        static let reHighlightNegative = Color("reHighlightNegative")
        static let reHighlightPositive = Color("reHighlightPositive")
        static let reSoftHighlight = Color("reSoftHighlight") // almost white
        static let reSoftHighlight2 = Color("reSoftHighlight2")  // light gray
        static let reHighlightLight = Color("reHighlightLight")  // yellow -- can use for search
        //static let reHighlightLight2 = Color("reHighlightLight2")
        
        static let darkerBackgroundStyle = Color("darkerBackgroundStyle")
        
        static let trainingHighlightColor: Color = Color.orange
        static let indexTrainingHighlightColor: Color = Color.teal
        
        // additional labels:
        static let reLabelUnlabeled = Color("reLabelUnlabeled")
        static let reLabelGreenLightest = Color("reLabelGreenLightest")
        static let reLabelBeigeLighter = Color("reLabelBeigeLighter")
        static let reLabelBrown = Color("reLabelBrown")
        static let reLabelMauve = Color("reLabelMauve")
        static let reLabelSlate = Color("reLabelSlate")
        static let reLabelBeige = Color("reLabelBeige")
        static let reLabelTeal = Color("reLabelTeal")
        static let reLabelLightBlueGreen = Color("reLabelLightBlueGreen")
        
        // Not currently used for class labels, but used in the category graphs:
        static let reLabelGreenLighter = Color("reLabelGreenLighter")
        
        // A light highlight against reBackgroundDarker
        static let reSoftHighlightRelativeToReBackgroundDarker = Color("reSoftHighlightRelativeToReBackgroundDarker")
        static let reSemanticHighlight = Color("reSemanticHighlight")
        
        
        // Gradients as used in the logo and App icon
        static let sphereGradient_Purple = LinearGradient(
            colors: [
                .rePurpleGradientStart,
                .rePurpleGradientEnd
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        static let sphereGradient_Blue = LinearGradient(
            colors: [
                .reBlueGradientStart,
                .reBlueGradientEnd
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        static let sphereGradient_Green = LinearGradient(
            colors: [
                .reGreenGradientStart,
                .reGreenGradientEnd
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        static let sphereGradient_Yellow = LinearGradient(
            colors: [
                .reYellowGradientStart,
                .reYellowGradientEnd
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        static let sphereGradient_Red = LinearGradient(
            colors: [
                .reRedGradientStart,
                .reRedGradientEnd
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
