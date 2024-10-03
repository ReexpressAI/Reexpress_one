//
//  DiscoverViewErrorDisclaimerView.swift
//  Alpha1
//
//  Created by A on 9/5/23.
//

import SwiftUI

struct DiscoverViewErrorDisclaimerView: View {
    var body: some View {
        HStack {
            Spacer()
            VStack {
                Text("Note: Absence of a document above does not imply an absence of label errors.")
            }
            .foregroundStyle(.gray)
            .italic()
            .font(REConstants.Fonts.baseFont)
            PopoverViewWithButtonLocalStateOptions(popoverViewText: REConstants.HelpAssistanceInfo.Discover.lowProbabilityExplainer, frameWidth: 200)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .modifier(PrimaryComponentsViewModifier(useReBackgroundDarker: true, viewBoxScaling: 8))
        .padding()
    }
}

struct DiscoverViewErrorDisclaimerView_Previews: PreviewProvider {
    static var previews: some View {
        DiscoverViewErrorDisclaimerView()
    }
}
