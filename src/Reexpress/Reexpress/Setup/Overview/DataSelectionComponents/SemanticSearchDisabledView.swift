//
//  SemanticSearchDisabledView.swift
//  Alpha1
//
//  Created by A on 9/17/23.
//

import SwiftUI

struct SemanticSearchDisabledView: View {
    var body: some View {
        
        VStack {
            VStack(alignment: .leading) {
                Text("Semantic search options")
                    .font(.title2.bold())
                
                Text("This will limit the result set to a maximum of 100 documents sorted by relevance.")
                    .font(REConstants.Fonts.baseSubheadlineFont)
                    .foregroundStyle(.gray)
                Text("The model must be trained and compressed in order to run a semantic search.")
                    .font(REConstants.Fonts.baseSubheadlineFont)
                    .foregroundStyle(.gray)
                Divider()
                    .padding(.bottom)
            }
            .opacity(0.5)
            .padding([.leading, .trailing])
            
            HStack {
                Text("To run a semantic search, go to **\(REConstants.MenuNames.exploreName)**->**\(REConstants.MenuNames.selectName)**.")
                PopoverViewWithButtonLocalStateOptionsLocalizedString(popoverViewText: "A semantic search returns documents sorted by relevance. To graph, first save any relevant document(s) to a datasplit.")
                Spacer()
            }
            .padding([.leading, .trailing, .top])
            
        }
        .font(REConstants.Fonts.baseFont)
        .padding()
        .modifier(SimpleBaseBorderModifier())
        .padding()
        
    }
}


        
