//
//  TrainingProcessView.swift
//  Alpha1
//
//  Created by A on 3/31/23.
//

import SwiftUI

extension TrainingProcessView {
    @MainActor class ViewModel: ObservableObject {
        @Published var showingTrainingProcessModal = false
        //var trainingParametersTextfieldWidth: CGFloat = 100
        
        enum Destinations {
            case trainingIntro
            case trainingSetup
            case estimateCacheSize
            case trainingCacheHiddenStates
            case training
            case trainingComplete
            case batchRunSetup
            case batchRunTrainIndex
            case batchRunPredict
        }
        @Published var currentView = Destinations.trainingSetup
    }
}

struct TrainingProcessView: View {
    
    var modelControlIdString: String = REConstants.ModelControl.keyModelId
    var isKeyModel: Bool {
        return modelControlIdString == REConstants.ModelControl.keyModelId
    }
    
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = ViewModel()
    @StateObject private var trainingProcessController = TrainingProcessController()
    @State private var navPath = NavigationPath()
    @State var trainTask: Task<Void, Error>? // Currently both the train and index tasks use the same var, which is ok, since they should never be run at the same time.
    @State var trainCacheTask: Task<Void, Error>?
    
    @State var trainTaskIsComplete: Bool = false
    @State var indexTaskIsComplete: Bool = false
    
    @State var totalElapsedTime: String = ""
    @State var taskWasCancelled: Bool = false
    
    @State var datasetIds: Set<Int> = Set([REConstants.DatasetsEnum.train.rawValue, REConstants.DatasetsEnum.calibration.rawValue])  // possibly more if batch
    @State var errorAlert: Bool = false
    @State var estimatesAvailable: Bool = false
    @State var processStartTime: Date?
    @State var batchRun: Bool = false
    // The following is only used on a Batch run
    @StateObject private var trainingProcessControllerIndexForBatchRun = TrainingProcessController()
    @State var trainIndexTask: Task<Void, Error>?
    @State var dataPredictionTask: Task<Void, Error>?
    //@State var predictionTaskWasCancelled: Bool = false
    @State var predictionTaskIsComplete: Bool = false
    var body: some View {
        NavigationStack(path: $navPath) {
            TrainingIntroView(modelControlIdString: modelControlIdString)

                .navigationDestination(for: ViewModel.Destinations.self) { i in
                    switch i {
                    case ViewModel.Destinations.trainingIntro:
                        TrainingIntroView(modelControlIdString: modelControlIdString)
                    case ViewModel.Destinations.batchRunSetup:
                        TrainingProcessBatchRunSetupView(trainingProcessController: trainingProcessController, trainingProcessControllerIndexForBatchRun: trainingProcessControllerIndexForBatchRun, inferenceDatasetIds: $datasetIds)
                    case ViewModel.Destinations.trainingSetup:
                        TrainingProcessSetupView(modelControlIdString: modelControlIdString, trainingProcessController: trainingProcessController)
                    case ViewModel.Destinations.estimateCacheSize:
                            TrainingStorageEstimateView(datasetIds: $datasetIds, errorAlert: $errorAlert, estimatesAvailable: $estimatesAvailable)
                    case ViewModel.Destinations.trainingCacheHiddenStates:
                            TrainingProcessCacheHiddenStatesView(navPath: $navPath, modelControlIdString: modelControlIdString, viewModel: viewModel, trainingProcessController: trainingProcessController, trainTask: $trainCacheTask, processStartTime: $processStartTime, taskWasCancelled: $taskWasCancelled)
                    case ViewModel.Destinations.training:
                        TrainingProcessTrainingView(navPath: $navPath, modelControlIdString: modelControlIdString, viewModel: viewModel, trainingProcessController: trainingProcessController, trainTask: $trainTask, trainTaskIsComplete: $trainTaskIsComplete, totalElapsedTime: $totalElapsedTime, taskWasCancelled: $taskWasCancelled, existingProcessStartTime: processStartTime, batchRun: batchRun)
                    case ViewModel.Destinations.trainingComplete:
                        TrainingCompleteView(totalElapsedTime: $totalElapsedTime, taskWasCancelled: $taskWasCancelled, existingProcessStartTime: processStartTime)
                    case ViewModel.Destinations.batchRunTrainIndex:
                        IndexProcessTrainingView(navPath: $navPath, modelControlIdString: REConstants.ModelControl.indexModelId, viewModel: viewModel, trainingProcessController: trainingProcessControllerIndexForBatchRun, trainTask: $trainIndexTask, indexTaskIsComplete: $indexTaskIsComplete, totalElapsedTime: $totalElapsedTime, taskWasCancelled: $taskWasCancelled, batchRun: batchRun)
                    case ViewModel.Destinations.batchRunPredict:
                        MainForwardAfterTrainingView(inferenceDatasetIds: $datasetIds, dataPredictionTask: $dataPredictionTask, predictionTaskWasCancelled: .constant(false), predictionTaskIsComplete: $predictionTaskIsComplete, totalElapsedInferenceTime: $totalElapsedTime, existingProcessStartTime: processStartTime)
                    }
                }
        }

        .toolbar {

                ToolbarItem(placement: .automatic) {
                    if navPath.count == 1 {
                        Button("Back") {
                            navPath.removeLast()
                        }
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    // MARK: Note: This will also be called if the user taps ESC.
                    if navPath.count == 0  || navPath.count == 1 || navPath.count == 2 {
                        Button("Cancel") {
                            dismiss()
                        }
                    } else {
                        Button("Stop") {
                            
                            trainCacheTask?.cancel()
                            trainTask?.cancel()
                            trainIndexTask?.cancel()
                            dataPredictionTask?.cancel()
                            //dismiss()
                            navPath.append(ViewModel.Destinations.trainingComplete)
                            taskWasCancelled = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + REConstants.ModelControl.defaultCancellingTimeToFreeResources) {
                                taskWasCancelled = false
                                trainTaskIsComplete = true
                                indexTaskIsComplete = true
                                predictionTaskIsComplete = true
                            }
                        }
                        .disabled(taskWasCancelled || trainTaskIsComplete || predictionTaskIsComplete)
                    }
                }
            ToolbarItem(placement: .automatic) {
                if navPath.count == 0 {
                    Button("Batch") {
                        batchRun = true
                        navPath.append(ViewModel.Destinations.batchRunSetup)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
                ToolbarItem(placement: .confirmationAction) {
                    if (!batchRun && !trainTaskIsComplete) || (batchRun && !predictionTaskIsComplete) {
                        if navPath.count == 0 {
                            Button("Setup") {
                                navPath.append(ViewModel.Destinations.trainingSetup)
                            }
                        } else if navPath.count == 1 {
                            Button("Continue") {
                                navPath.append(ViewModel.Destinations.estimateCacheSize)
                            }
                        } else if navPath.count == 2 {
                            Button("Continue") {
                                navPath.append(ViewModel.Destinations.trainingCacheHiddenStates)
                            }
                        }
                    } else {
                        Button("Done") {
                            if !taskWasCancelled {
                                dismiss()
                            }
                        }
                        .disabled(taskWasCancelled)
                    }
                }
        }
        .onDisappear {
            // Typically, we disable ESC closing the modal, but here we just always check that the task was properly canceled to be safe.
            trainCacheTask?.cancel()
            trainTask?.cancel()
            trainIndexTask?.cancel()
            dataPredictionTask?.cancel()
        }
    }
    
}






struct TrainingProcessView_Previews: PreviewProvider {
    static var previews: some View {
        TrainingProcessView()
    }
    
}
