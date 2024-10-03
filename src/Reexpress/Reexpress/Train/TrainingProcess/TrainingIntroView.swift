//
//  TrainingIntroView.swift
//  Alpha1
//
//  Created by A on 7/24/23.
//

import SwiftUI

struct TrainingIntroView: View {
    
    var modelControlIdString: String = REConstants.ModelControl.keyModelId
    var isKeyModel: Bool {
        return modelControlIdString == REConstants.ModelControl.keyModelId
    }
    @State private var batchInfoPopover: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                VStack(alignment: .leading) {
                    Text("Training is a 3-Stage process.")
                        .font(.title2)
                        .bold()
                    Text("All stages must be completed before predictions on new data can be made.")
                        .font(.title3)
                        .italic()
                        .foregroundStyle(.gray)
                }
                .padding()
                Spacer()
                Grid(verticalSpacing: 20) {
                    GridRow(alignment: .firstTextBaseline) {
                        Image(systemName: "checkmark.circle")
                            .foregroundStyle(.green.gradient)
                            .gridColumnAlignment(.center)
                            .hidden()  // not currently using the checkmarks
                        Text("Stage 1:")
                            .gridColumnAlignment(.trailing)
                            .foregroundStyle(.gray)
                        VStack(alignment: .leading) {
                            Text("Parameter Caching.")
                                .bold()
                                .padding([.bottom], 5)
                            Text("First, we strategically cache the model's hidden states via an initial forward pass through the model. Typically, the majority of the overall training time will be spent on this stage. (Once training has been completed, the cache can be retained to enable fast updating, or cleared to save disk space.)")
                                .multilineTextAlignment(.leading)
                                .lineSpacing(10)
                            
                        }
                        .gridColumnAlignment(.leading)
                    }
                    .opacity(isKeyModel ? 1.0 : 0.5)
                    GridRow(alignment: .firstTextBaseline) {
                        Image(systemName: "checkmark.circle")
                            .foregroundStyle(.green.gradient)
                            .hidden()  // not currently using the checkmarks
                        Text("Stage 2:")
                            .foregroundStyle(.gray)
                        VStack(alignment: .leading) {
                            Text("Primary Model Training.")
                                .bold()
                                .foregroundStyle(REConstants.REColors.trainingHighlightColor)
                                .opacity(0.75)
                                .padding([.bottom], 5)
                            Text("We optimize the parameters of the model in order to maximize correct predictions on the labeled data.")
                                .multilineTextAlignment(.leading)
                                .lineSpacing(10)
                        }
                        .gridColumnAlignment(.leading)
                    }
                    .opacity(isKeyModel ? 1.0 : 0.5)
                    GridRow(alignment: .firstTextBaseline) {
                        Image(systemName: "checkmark.circle")
                            .foregroundStyle(.green.gradient)
                            .hidden()  // not currently using the checkmarks
                        Text("Stage 3:")
                            .foregroundStyle(.gray)
                        VStack(alignment: .leading) {
                            Text("Model Compression.")
                                .bold()
                                .foregroundStyle(REConstants.REColors.indexTrainingHighlightColor)
                                .opacity(0.75)
                                .padding([.bottom], 5)
                            Text("To enable fast on-device indexing and analysis, we additionally train a compressed approximation of the primary model.")
                                .multilineTextAlignment(.leading)
                                .lineSpacing(10)
                        }
                        .gridColumnAlignment(.leading)
                    }
                }
                .font(REConstants.Fonts.baseFont)
                .padding()
                Spacer()
                VStack(alignment: .leading) {
                    Text("Next...")
                        .font(.title2)
                        .bold()
                    if isKeyModel {
                        Text("Click Setup to choose training options for Stage 2.")
                            .font(.title3)
                            .italic()
                            .foregroundStyle(.gray)
                    } else {
                        Text("Click Setup to choose training options for Stage 3.")
                            .font(.title3)
                            .italic()
                            .foregroundStyle(.gray)
                    }
                }
                .font(REConstants.Fonts.baseFont)
                .padding()
                .modifier(SimpleBaseBorderModifier())
                .padding()
                Spacer()
                if isKeyModel {
                    VStack(alignment: .leading) {
                        Text("Alternatively...")
                            .font(.title2)
                            .bold()
                        HStack(alignment: .firstTextBaseline) {
                            Text("Click Batch to setup and run all stages of training and prediction consecutively.")
                                .font(.title3)
                                .italic()
                                .foregroundStyle(.gray)
                            PopoverViewWithButton(isShowingInfoPopover: $batchInfoPopover, popoverViewText: "This is a useful option if you have a large dataset and want the entire process to complete while you are away from your Mac (e.g., overnight).")
                        }
                    }
                    .font(REConstants.Fonts.baseFont)
                    .padding()
                    .modifier(SimpleBaseBorderModifier())
                    .padding()
                    Spacer()
                }
            }
            .padding()
        }
    }
}

struct TrainingIntroView_Previews: PreviewProvider {
    static var previews: some View {
        TrainingIntroView()
    }
}
