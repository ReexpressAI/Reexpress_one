//
//  TrainingExplanationView.swift
//  Alpha1
//
//  Created by A on 7/23/23.
//

import SwiftUI

struct TrainingExplanationView: View {
    var isKeyModel: Bool = false
    var highlightColor: Color {
        if isKeyModel {
            return REConstants.REColors.trainingHighlightColor
        } else {
            return REConstants.REColors.indexTrainingHighlightColor
        }
    }
    var explanationMessage: String {
        if isKeyModel {
            return "Train the primary model, optimizing parameters to maximize correct predictions.\nLoss and Balanced Accuracy are calculated based on the ground truth labels."
        } else {
            return "Train a compressed model that approximates the primary model to enable fast on-device search.\nLoss and Balanced Accuracy are calculated based on the predicted labels of the primary model."
        }
    }
    @EnvironmentObject var dataController: DataController
    @State private var isShowingMetricInfoPopover: Bool = false
    
    var body: some View {
        VStack(alignment: .leading) {
            if isKeyModel {
                Text(explanationMessage)
                    .monospaced()
                    .foregroundStyle(highlightColor)
                    .opacity(0.75)
                    .font(REConstants.Fonts.baseFont)
            } else {
                HStack(alignment: .lastTextBaseline) {
                    Text(explanationMessage)
                        .monospaced()
                        .foregroundStyle(highlightColor)
                        .opacity(0.75)
                        .font(REConstants.Fonts.baseFont)
                    Button {
                        isShowingMetricInfoPopover.toggle()
                    } label: {
                        Image(systemName: "info.circle.fill")
                    }
                    .buttonStyle(.borderless)
                    .popover(isPresented: $isShowingMetricInfoPopover, arrowEdge: .trailing) {
                        PopoverView(popoverViewText: REConstants.HelpAssistanceInfo.compressedModelSufficientBalancedAccuracy) 
                    }
                }
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill( //.black)
                    AnyShapeStyle(BackgroundStyle()))
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.gray)
                .opacity(0.5)
        }
    }
}

struct TrainingExplanationView_Previews: PreviewProvider {
    static var previews: some View {
        TrainingExplanationView()
    }
}
