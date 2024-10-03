//
//  HelpAssistanceView_Document_Level_Matching.swift
//  Alpha1
//
//  Created by A on 9/12/23.
//

import SwiftUI

struct HelpAssistanceView_Document_Level_Matching: View {
    var body: some View {
        VStack {
            VStack {
                HStack(spacing: 0) {
                    Text("Document-level matching ")
                    Text("against the Training set ")
                        .bold()
                        .foregroundStyle(REConstants.REColors.trainingHighlightColor)
                        .opacity(0.75)
                    Spacer()
                }
                HStack(spacing: 0) {
                    Text("is used to introspect the model and uncertainty estimates.")
                    Spacer()
                }
            }
            .padding()
                Text("Matching against training determines the similarity score (q), and the distance to the first match in training determines the distance score (d).\n\nFor reference, matching can also be run against non-training datasplits.")
                    .foregroundStyle(.gray)
                .padding([.leading, .trailing, .bottom])
        }
        .fixedSize(horizontal: false, vertical: true)  // This will cause Text() to wrap.
        .font(REConstants.Fonts.baseFont)
        .padding()
        .frame(width: 500)
    }
}

struct HelpAssistanceView_Document_Level_Matching_Previews: PreviewProvider {
    static var previews: some View {
        HelpAssistanceView_Document_Level_Matching()
    }
}
