//
//  TrainingProcessSetupView.swift
//  Alpha1
//
//  Created by A on 7/20/23.
//

import SwiftUI

struct TrainingProcessSetupView: View {
    var batchRun: Bool = false
    
    var modelControlIdString: String = REConstants.ModelControl.keyModelId
    var isKeyModel: Bool {
        return modelControlIdString == REConstants.ModelControl.keyModelId
    }
    var highlightColor: Color {
        if isKeyModel {
            return REConstants.REColors.trainingHighlightColor
        } else {
            return REConstants.REColors.indexTrainingHighlightColor
        }
    }
    var optionsMessage: String {
        if isKeyModel {
            return "Model training options"
        } else {
            return "Model compression training options"
        }
    }
    
    //@ObservedObject var viewModel: TrainingProcessView.ViewModel
    @ObservedObject var trainingProcessController: TrainingProcessController
    @EnvironmentObject var dataController: DataController
        
    var weightsExist: Bool {
        if isKeyModel {
            return (dataController.inMemory_KeyModelGlobalControl.modelWeights == nil) ? false : true
        } else {
            return (dataController.inMemory_KeyModelGlobalControl.indexModelWeights == nil) ? false : true
        }
    }
    
    var trainingMaxMetricDescription: String {
        if isKeyModel {
            return String(dataController.inMemory_KeyModelGlobalControl.trainingMaxMetric.description)
        } else {
            return String(dataController.inMemory_KeyModelGlobalControl.indexMaxMetric.description)
        }
    }
    
    @State private var isShowingMetricHelp: Bool = false
    @State private var isShowingResetExplainer: Bool = false
    // For the index model, the weights could be present, but could be mismatched with the primary model. In this case, we always reset the weights. This is to avoid confusion by the user when we alert to retrain Compression but then a new weight set isn't saved because the Balanced Accuracy is worse than the original.
    var isIndexModelAndNotCurrent: Bool {
        return !isKeyModel && !dataController.isModelTrainedandIndexed()
    }
    
    // If the training state has changed to Need Refresh, at least the best metric is ignored (the user still has the option to train from scratch if desired)
    var forceAKeyModelUpdateDueToRefreshNeeded: Bool {
        return dataController.inMemory_KeyModelGlobalControl.trainingState == .Stale
    }
    
    // For a batch run, to keep things simple, we always require a reset of the weights and the best calibration set metric. The only time this wouldn't be relevant is if Training was re-run and a new epoch was not found, in which case a full update of the Index model wouldn't be needed. But that's such an unusual case, it's just easier to always update. (If the user wants such functionality, they can just run training for the primary model separately (i.e., non-batch), and if the model never updates, then no update for the Index model is necessary.)
    var isIndexModelAndBatchRun: Bool {
        return !isKeyModel && batchRun
    }
    
    var body: some View {
        ScrollView {
            VStack {
                HStack {
                    Text(isKeyModel ? "Training Parameters" : "Model Compression Training Parameters")
                        .font(.title2)
                        .bold()
                    Spacer()
                }
                .padding()
                Spacer()
                
                VStack {
                    HStack {
                        Text(optionsMessage)
                            .font(REConstants.Fonts.baseFont)
                            .foregroundStyle(highlightColor)
                            .opacity(0.75)
                        Spacer()
                    }
                    Form {
                        HStack {
                            LabeledContent {
                                HStack(alignment: .lastTextBaseline) {
                                    Text(trainingMaxMetricDescription)
                                        .monospaced()
                                    Button {
                                        isShowingMetricHelp.toggle()
                                    } label: {
                                        Image(systemName: "info.circle.fill")
                                    }
                                    .buttonStyle(.borderless)
                                }
                            } label: {
                                Text("Metric:")
                            }
                            .font(REConstants.Fonts.baseFont)
                        }
                        .popover(isPresented: $isShowingMetricHelp, arrowEdge: .trailing) {
                            PopoverView(popoverViewText: "The epoch with the highest \(trainingMaxMetricDescription) on the Calibration set will determine the final model weights. (\(REConstants.Uncertainty.balancedAccuracyDescription))")
                        }
                        TextField("Max number of epochs:", text: $trainingProcessController.epochsString)
                            .font(REConstants.Fonts.baseFont)
                            .textFieldStyle(.roundedBorder)
                        Text("\(trainingProcessController.epochs)")
                            .font(REConstants.Fonts.baseSubheadlineFont)
                            .italic()
                            .foregroundStyle(.gray)
                        
                        TextField("Learning rate:", text: $trainingProcessController.learningRateString)
                            .font(REConstants.Fonts.baseFont)
                            .textFieldStyle(.roundedBorder)
                        Text("\(String(format: "%g", trainingProcessController.learningRate))")
                            .font(REConstants.Fonts.baseSubheadlineFont)
                            .italic()
                            .foregroundStyle(.gray)
                    }
                    .padding()
                    .modifier(SimpleBaseBorderModifier())
                    //}
                    //.frame(width: 150)
                    Form {
                        DisclosureGroup {
                            VStack {
                                //if trainingProcessController.useDeacySchedule {
                                VStack {
                                    HStack {
                                        Toggle("Use decay schedule", isOn: $trainingProcessController.useDeacySchedule.animation())
                                        Spacer()
                                    }
                                    Group {
                                        TextField("Decay factor:", text: $trainingProcessController.decayScheduleFactorString)
                                            .textFieldStyle(.roundedBorder)
                                            .disabled(!trainingProcessController.useDeacySchedule)
                                        TextField("Apply decay at epoch:", text: $trainingProcessController.decayScheduleEpochString)
                                            .textFieldStyle(.roundedBorder)
                                            .disabled(!trainingProcessController.useDeacySchedule)
                                        Text("The learning rate will be reduced by a factor of \(String(format: "%g", trainingProcessController.decaySchedule.factor)) at epoch \(trainingProcessController.decaySchedule.epoch).")
                                            .font(REConstants.Fonts.baseSubheadlineFont)
                                            .italic()
                                            .foregroundStyle(.gray)
                                            .opacity(trainingProcessController.useDeacySchedule ? 1.0 : 0.0)
                                    }
                                    .opacity(trainingProcessController.useDeacySchedule ? 1.0 : 0.5)
                                }
                                .padding()
                                .modifier(SimpleBaseBorderModifier())
                                
                                VStack {
                                    HStack {
                                        Text("Reset options")
                                            .foregroundStyle(.gray)
                                        PopoverViewWithButton(isShowingInfoPopover: $isShowingResetExplainer, popoverViewText: "Depending on the current Status of the model, not all options may be available.")
                                        Spacer()
                                    }
                                    VStack {
                                        HStack {
                                            Toggle("Ignore existing weights (train from scratch)", isOn: $trainingProcessController.ignoreExistingWeights.animation())
                                                .disabled(!weightsExist || isIndexModelAndNotCurrent || isIndexModelAndBatchRun)
                                            Spacer()
                                        }
                                        //.opacity(trainingProcessController.useDeacySchedule ? 1.0 : 0.0)
                                        HStack {
                                            Toggle("Ignore existing best Calibration set metric", isOn: $trainingProcessController.ignoreExistingRunningBestMaxMetric) // If the validation set has changed significantly, select this option to ignore previous metrics.
                                                .disabled(trainingProcessController.ignoreExistingWeights || !weightsExist || isIndexModelAndNotCurrent || forceAKeyModelUpdateDueToRefreshNeeded || isIndexModelAndBatchRun)
                                            Spacer()
                                        }
                                    }
                                    .opacity(weightsExist ? 1.0 : 0.5)
                                    .padding()
                                    .modifier(SimpleBaseBorderModifier())
                                }
                            }
                            .padding()
                            .modifier(SimpleBaseBorderModifier())
                        } label: {
                            Text("Less commonly used options")
                                .foregroundStyle(.gray)
                        }
                        .font(REConstants.Fonts.baseFont)
                        //.frame(width: 400) //, height: 400)
                    }
                }
                .frame(width: 450)
                //.frame(minWidth: 450, maxWidth: 450)
                //Spacer()
                //}
                Spacer()
                if !batchRun {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Next...")
                                .font(.title2)
                                .bold()
                            if isKeyModel {
                                Text("Click Train to run Stages 1 and 2. Once complete, you will have a chance to review the training process and then begin the final Stage 3 by navigating to the Train->Compress tab.")
                                    .font(.title3)
                                    .italic()
                                    .foregroundStyle(.gray)
                            } else {
                                Text("Click Train to run the final Stage 3. Once model compression has completed, you can start to analyze your data and make predictions on new data.")
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
                    }
                }
            }
        }
        .onAppear {
            if isIndexModelAndNotCurrent || isIndexModelAndBatchRun {
                trainingProcessController.ignoreExistingWeights = true
            }
            if forceAKeyModelUpdateDueToRefreshNeeded || isIndexModelAndBatchRun {
                trainingProcessController.ignoreExistingRunningBestMaxMetric = true
            }
        }
        .navigationBarBackButtonHidden(true)
        .padding()
    }
}
