//
//  HelpAssistanceView_Uncache.swift
//  Alpha1
//
//  Created by A on 9/1/23.
//

import SwiftUI

struct HelpAssistanceView_Uncache_Content: View {
    

    var body: some View {
        VStack(alignment: .leading) {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Text("The model's hidden states can be ")
                    Text("uncached ")
                        .bold()
                        .foregroundStyle(REConstants.REColors.reRed)
                        .opacity(0.75)
                    Text("to save space, ")
                    Spacer()
                }
                HStack(spacing: 0) {
                    Text("as necessary, but re-training will be significantly slower.")
                    Spacer()
                }
            }
            .padding()
            VStack(alignment: .leading) {
                VStack(alignment: .leading) {
                    Text("We recommend retaining the hidden states if you anticipate changing labels in the Training set, adding additional data, and/or otherwise re-training.")
                }
                .padding(.bottom)
                //.foregroundStyle(.gray)
                //.frame(width: 400)
                //.padding([.leading, .trailing, .bottom])
                VStack(alignment: .leading) {
                    Text("Documents transferred out of the Training or Calibration sets may have associated cached states if they were present during training. The cached states of these other datasplits can be cleared without impacting re-training time.")
                }
                .padding(.bottom)
                VStack(alignment: .leading) {
                    Text(REConstants.HelpAssistanceInfo.storageEstimateDisclaimer)
                        .italic()
                }
                .padding(.bottom)
            }
            .foregroundStyle(.gray)
            .frame(width: 400)
            .padding([.leading, .trailing, .bottom])
        }
        .fixedSize(horizontal: false, vertical: true)  // This will cause Text() to wrap.
        .font(REConstants.Fonts.baseFont)
        .padding()
        //.frame(idealHeight: 400, maxHeight: 600)
        //.frame(maxHeight: .infinity)
        //.frame(width: 600)
    }
}
struct HelpAssistanceView_Uncache: View {
    @State private var showingHelpAssistanceView: Bool = false
    var body: some View {
        Button {
            showingHelpAssistanceView.toggle()
        } label: {
            UncertaintyGraphControlButtonLabelWithCaptionVStack(buttonImageName: "questionmark.circle", buttonTextCaption: "Help", buttonForegroundStyle: AnyShapeStyle(Color.gray.gradient))
        }
        .buttonStyle(.borderless)
        .popover(isPresented: $showingHelpAssistanceView) {
            ScrollView {
                HelpAssistanceView_Uncache_Content()
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        
    }
}
