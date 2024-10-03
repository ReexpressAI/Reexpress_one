//
//  HelpAssistanceView_Feature_Level_Search.swift
//  Alpha1
//
//  Created by A on 8/7/23.
//

import SwiftUI

struct HelpAssistanceView_Feature_Level_Search: View {
//    var helpMessage: LocalizedStringKey = "Feature-level matching is for **exploratory data analysis**. This is not accompanied by a formal uncertainty estimate, as the model was not trained with labeled data at this level of granularity."
    

    
    var body: some View {
        VStack {
            HStack(spacing: 0) {
                Text("Feature-level matching is for ")
                Text("exploratory data analysis")
                    .bold()
                    .foregroundStyle(REConstants.REColors.indexTrainingHighlightColor)
                    .opacity(0.75)
                Text(".")
                Spacer()
            }
            .padding()
            Text("This is not accompanied by a formal uncertainty estimate, because the model was not trained with labeled data at this level of granularity.")
                .foregroundStyle(.gray)
                .padding([.leading, .trailing, .bottom])
        }
        .font(REConstants.Fonts.baseFont)
        .padding()
        .frame(width: 500)
    }
}

struct HelpAssistanceView_Feature_Level_Search_Previews: PreviewProvider {
    static var previews: some View {
        HelpAssistanceView_Feature_Level_Search()
    }
}
