//
//  MainForwardAfterTrainingView.swift
//  Alpha1
//
//  Created by A on 7/25/23.
//

import SwiftUI
import CoreML

struct MainForwardAfterTrainingView: View {

    
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var dataController: DataController
    @EnvironmentObject var programModeController: ProgramModeController
    
    @Binding var inferenceDatasetIds: Set<Int>
    @Binding var dataPredictionTask: Task<Void, Error>?
    @Binding var predictionTaskWasCancelled: Bool
    @Binding var predictionTaskIsComplete: Bool
    
    @State private var showingInferenceErrorAlert: Bool = false
    @State private var inferenceErrorMessage: String = "Prediction failed."
    
    @State var inferenceDatasetIds2InferenceProgress: [Int: InferenceProgress] = [:]
    @State var allPredictionsComplete: Bool = false
        
    @Binding var totalElapsedInferenceTime: String
    
    func getInferenceProgressStatusForDatasetId(datasetId: Int) -> InferenceProgressStatus {
        guard let inferenceProgress = inferenceDatasetIds2InferenceProgress[datasetId] else {
            return .noDocumentsAvailable
        }
        return inferenceProgress.inferenceProgressStatus
    }
    
    var existingProcessStartTime: Date?
        
    var body: some View {
        //
        ZStack {
            CancellingAndFreeingResourcesView(taskWasCancelled: $predictionTaskWasCancelled)
            VStack {
                HStack(alignment: .top) {
                    Text("Prediction Progress")
                        .font(.title)
                        .bold()
                    //.foregroundColor(.gray)
                        .padding([.leading, .trailing, .top])
                    Spacer()
                    VStack {
                        if !(allPredictionsComplete) {
                            ProgressView()
                        } else {
                            VStack {
                                Image(systemName: "checkmark.circle")
                                    .foregroundStyle(.green.gradient)
                                Text("Complete")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .frame(height: 20)
                    .padding(EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 30))
                }
                Spacer()
                ScrollView {
                    VStack(alignment: .leading) {
                        Grid(verticalSpacing: 20) {
                            ForEach(inferenceDatasetIds.sorted(), id: \.self) { datasetId in
                                GridRow(alignment: .firstTextBaseline) {
                                    Image(systemName: "checkmark.circle")
                                        .foregroundStyle(.green.gradient)
                                        .opacity(getInferenceProgressStatusForDatasetId(datasetId: datasetId) == .complete ? 1.0 : 0.0)
                                        .gridColumnAlignment(.center)
                                    Text("\(dataController.getDatasplitNameForDisplay(datasetId: datasetId)):")
                                        .gridColumnAlignment(.trailing)
                                        .foregroundStyle(.gray)
                                    HStack {
                                        Text(inferenceDatasetIds2InferenceProgress[datasetId]?.statusString ?? "")
                                        Spacer()
                                    }
                                    .frame(minWidth: 250)
                                    .gridColumnAlignment(.leading)
                                }
                                GridRow(alignment: .firstTextBaseline) {
                                    Image(systemName: "checkmark.circle")
                                        .hidden()
                                    Text("\(dataController.getDatasplitNameForDisplay(datasetId: datasetId)):")  // placeholder
                                        .hidden()
                                    ProgressView(value: inferenceDatasetIds2InferenceProgress[datasetId]?.progressProportion ?? 0.0,
                                                 label: { Text(inferenceDatasetIds2InferenceProgress[datasetId]?.progressTitleString ?? "") },
                                                 currentValueLabel: { Text((inferenceDatasetIds2InferenceProgress[datasetId]?.progressProportion ?? 0.0).formatted(.percent.precision(.fractionLength(0)))) })
                                    .gridCellUnsizedAxes([.horizontal, .vertical])
                                }
                            }
                        }
                        .font(REConstants.Fonts.baseFont)
                        .padding()
                        if !totalElapsedInferenceTime.isEmpty {
                            HStack(spacing: 0) {
                                Text("Runtime:  ")  // just "runtime" since this will also be displayed on a training+predict run
//                                Text("Prediction runtime:  ")
                                    .foregroundStyle(.gray)
                                Text(totalElapsedInferenceTime)
                                    .monospaced()
                            }
                            .font(REConstants.Fonts.baseFont)
                            .padding()
                        }
                    }
                }
                .padding()
                Spacer()
            }
            .padding()
        }
        .alert("Unable to begin inference.", isPresented: $showingInferenceErrorAlert) {
            
            Button("OK") {
                dataPredictionTask?.cancel()
                dismiss()
            }
        } message: {
            Text(inferenceErrorMessage)
        }
        .navigationBarBackButtonHidden(true)
        .onDisappear {
            dataPredictionTask?.cancel()
        }
        .onAppear {
            // Initialize progress outside of task. Note that any modifications need to occur on the main queue:
            for evalDatasetId in inferenceDatasetIds {
                inferenceDatasetIds2InferenceProgress[evalDatasetId] = InferenceProgress(datasetId: evalDatasetId)
            }
            
            let processStartTime = Date()
            
            dataPredictionTask = Task {
                do {
                    
                    try await mainForwardAfterTraining()

                    await MainActor.run {
                        predictionTaskIsComplete = true
                        
                        if let processStartTime = existingProcessStartTime {  // takes an existing time as argument
                            let processDuration = Date().timeIntervalSince(processStartTime)
                            if let processDurationString = REConstants.durationFormatter.string(from: processDuration) {
                                totalElapsedInferenceTime = processDurationString
                            }
                        } else {
                            let processDuration = Date().timeIntervalSince(processStartTime)
                            if let processDurationString = REConstants.durationFormatter.string(from: processDuration) {
                                totalElapsedInferenceTime = processDurationString
                            }
                        }
                    }
                } catch KeyModelErrors.keyModelWeightsMissing {
                    await MainActor.run {
                        showingInferenceErrorAlert = true
                        inferenceErrorMessage = "The model must be trained prior to making predictions."
                    }
                } catch KeyModelErrors.indexModelWeightsMissing {
                    await MainActor.run {
                        showingInferenceErrorAlert = true
                        inferenceErrorMessage = "The model must be compressed prior to making predictions."
                    }
                } catch KeyModelErrors.compressionNotCurrent {
                    await MainActor.run {
                        showingInferenceErrorAlert = true
                        inferenceErrorMessage = "The model must be trained and compressed prior to making predictions. Train the compressed model before continuing."
                    }
                } catch MLForwardErrors.tokenizationWasCancelled {
                    // in this case we do not need to do anything; the user canceled during tokenization
                    //print("Task was cancelled by the user during tokenization.")
                    
                } catch MLForwardErrors.forwardPassWasCancelled {
                    // in this case we do not need to do anything; the user canceled during tokenization
                    //print("Task was cancelled by the user during the forward pass.")
                } catch IndexErrors.supportMaxSizeError {
                    await MainActor.run {
                        showingInferenceErrorAlert = true
                        inferenceErrorMessage = "The support index is unexpectedly large. Reduce the training set size to \(REConstants.DatasetsConstraints.maxTotalLines) or fewer documents before continuing."
                    }
                } catch KeyModelErrors.inputDimensionSizeMismatch {
                    await MainActor.run {
                        showingInferenceErrorAlert = true
                        inferenceErrorMessage = "Unexpected input dimensions were encountered."
                    }
                } catch GeneralFileErrors.attributeMaxSizeError {
                    await MainActor.run {
                        showingInferenceErrorAlert = true
                        inferenceErrorMessage = "Unexpected input dimensions were encountered. The stored attributes exceed the max length of \(REConstants.KeyModelConstraints.attributesSize)."
                    }
                } catch KeyModelErrors.insufficientTrainingLabels, CoreDataErrors.noDocumentsFound, CoreDataErrors.datasetNotFound, KeyModelErrors.noFeatureProvidersAvailable {
                    await MainActor.run {
                        showingInferenceErrorAlert = true
                        inferenceErrorMessage = "Calculating uncertainty requires at least \(REConstants.KeyModelConstraints.minNumberOfLabelsPerClassForTraining) labeled documents per class for both Training and Calibration. Add data and try again!"
                    }
                } catch {
                    await MainActor.run {
                        showingInferenceErrorAlert = true
                        inferenceErrorMessage = "An unexpected error was encountered. Try closing the other running programs (if any) on your computer and then restart \(REConstants.ProgramIdentifiers.mainProgramName)."
                    }
                }
            }
        }
    }
}
