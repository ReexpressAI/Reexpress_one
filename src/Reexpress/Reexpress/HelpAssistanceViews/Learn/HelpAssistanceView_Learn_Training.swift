//
//  HelpAssistanceView_Learn_Training.swift
//  Alpha1
//
//  Created by A on 7/22/23.
//

import SwiftUI

struct HelpAssistanceView_Learn_Training_Content: View {
    var body: some View {
        VStack(alignment: .leading) {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Text("Train the primary model ")
                        .bold()
                        .foregroundStyle(REConstants.REColors.trainingHighlightColor)
                        .opacity(0.75)
                    Text("in order to make predictions on new data ")
                    Spacer()
                }
                HStack(spacing: 0) {
                    Text("and analyze existing data.")
                    Spacer()
                }
            }
            .padding()
            VStack(alignment: .leading) {
                Text("At least two examples for each class must be uploaded to the Training and Calibration sets to get started.")
                Text("Go to **\(REConstants.MenuNames.setupName)**->**Add** to upload documents.")
                    .padding()
                Text("(We generally recommend having at least 1000 examples per class in both the Training and Calibration sets to get reliable uncertainty estimates.)")
            }
                .foregroundStyle(.gray)
                .padding([.leading, .trailing, .bottom])
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Text("Compressing the model ")
                        .bold()
                        .foregroundStyle(REConstants.REColors.indexTrainingHighlightColor)
                        .opacity(0.75)
                    Text("is a required step after training ")
                    Spacer()
                }
                HStack(spacing: 0) {
                    Text("the primary model.")
                    Spacer()
                }
            }
            .padding()
            VStack(alignment: .leading) {
                Text("Once all stages of training are complete, go to **\(REConstants.MenuNames.setupName)**->**Predict** to generate predictions and enable semantic search and feature-level analysis.")
  
                Text(REConstants.HelpAssistanceInfo.StateChanges.stateChangeTip_Training_Focus)
                    .padding([.top, .bottom])
            }
                .foregroundStyle(.gray)
                .padding([.leading, .trailing, .bottom])
        }
        .fixedSize(horizontal: false, vertical: true)  // This will cause Text() to wrap.
        .font(REConstants.Fonts.baseFont)
        .padding()
        .frame(width: 600)
    }
}
struct HelpAssistanceView_Learn_Training: View {
    @State private var showingHelpAssistanceView: Bool = false
    var body: some View {
        Button {
            showingHelpAssistanceView.toggle()
        } label: {
            UncertaintyGraphControlButtonLabelWithCaptionVStack(buttonImageName: "questionmark.circle", buttonTextCaption: "Help", buttonForegroundStyle: AnyShapeStyle(Color.gray.gradient))
        }
        .buttonStyle(.borderless)
        .popover(isPresented: $showingHelpAssistanceView) {
            HelpAssistanceView_Learn_Training_Content()
        }
    }
}
