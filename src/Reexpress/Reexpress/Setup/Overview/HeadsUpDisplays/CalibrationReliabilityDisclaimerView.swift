//
//  CalibrationReliabilityDisclaimerView.swift
//  Alpha1
//
//  Created by A on 8/20/23.
//

import SwiftUI

struct CalibrationReliabilityDisclaimerView: View {
    var body: some View {
        VStack {
            Text("\(REConstants.ProgramIdentifiers.mainProgramName) can only estimate a minimum probability of 0.01 and a maximum probability of 0.99, so it is neither intended nor suitable for high-risk applications.")
//                Text("The displayed calibrated probability is In the event the argmax between calibrated and uncalibrated differ...")
        }
        .foregroundStyle(.gray)
        .italic()
        .font(REConstants.Fonts.baseFont)
        .frame(maxWidth: .infinity)
        .padding()
        .modifier(PrimaryComponentsViewModifier(useReBackgroundDarker: true, viewBoxScaling: 8))
//            .modifier(SimpleBaseBorderModifier())
        .padding()
    }
}

struct CalibrationReliabilityDisclaimerView_Previews: PreviewProvider {
    static var previews: some View {
        CalibrationReliabilityDisclaimerView()
    }
}
