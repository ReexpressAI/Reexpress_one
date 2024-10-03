//
//  IndexProcessTrainingMainView.swift
//  Alpha1
//
//  Created by A on 9/4/23.
//

import SwiftUI


//extension IndexProcessTrainingMainView {
//    @MainActor class ViewModel: ObservableObject {
//        @Published var showingTrainingProcessModal = false
//        //var trainingParametersTextfieldWidth: CGFloat = 100
//        
//        enum Destinations {
//            case trainingIntro
//            case trainingSetup
//            case estimateCacheSize
//            case trainingCacheHiddenStates
//            case training
//            case trainingComplete
//        }
//        @Published var currentView = Destinations.trainingSetup
//    }
//}

struct IndexProcessTrainingMainView: View {
    
    var modelControlIdString: String = REConstants.ModelControl.keyModelId
    var isKeyModel: Bool {
        return modelControlIdString == REConstants.ModelControl.keyModelId
    }
    
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = TrainingProcessView.ViewModel()
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
    var body: some View {
        NavigationStack(path: $navPath) {
            TrainingIntroView(modelControlIdString: modelControlIdString)
                .navigationDestination(for: TrainingProcessView.ViewModel.Destinations.self) { i in
                    switch i {
                    case TrainingProcessView.ViewModel.Destinations.trainingIntro:
                        TrainingIntroView(modelControlIdString: modelControlIdString)
                    case TrainingProcessView.ViewModel.Destinations.trainingSetup:
                        TrainingProcessSetupView(modelControlIdString: modelControlIdString, trainingProcessController: trainingProcessController)
                    case TrainingProcessView.ViewModel.Destinations.training:
                        IndexProcessTrainingView(navPath: $navPath, modelControlIdString: modelControlIdString, viewModel: viewModel, trainingProcessController: trainingProcessController, trainTask: $trainTask, indexTaskIsComplete: $indexTaskIsComplete, totalElapsedTime: $totalElapsedTime, taskWasCancelled: .constant(false), batchRun: false)
                    case TrainingProcessView.ViewModel.Destinations.trainingComplete:
                        TrainingCompleteView(totalElapsedTime: $totalElapsedTime, taskWasCancelled: $taskWasCancelled)
                    default:
                        TrainingCompleteView(totalElapsedTime: $totalElapsedTime, taskWasCancelled: $taskWasCancelled)
                    }
                }
        }
        /*
         Instructions
            Cancel
            Setup
         if Training
         Training Parameters
         */
        .toolbar {
            if indexTaskIsComplete {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        if !taskWasCancelled {
                            dismiss()
                        }
                    }
                    .disabled(taskWasCancelled)
                }
            } else {
                ToolbarItem(placement: .automatic) {
                    if navPath.count == 1 {
                        Button("Back") {
                            navPath.removeLast()
                        }
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    // MARK: Note: This will also be called if the user taps ESC.
                    if navPath.count == 0  || navPath.count == 1 {
                        Button("Cancel") {
                            dismiss()
                        }
                    } else {
                        Button("Stop") {
                            trainTask?.cancel()
                            trainCacheTask?.cancel()
                            //dismiss()
                            navPath.append(TrainingProcessView.ViewModel.Destinations.trainingComplete)
                            taskWasCancelled = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + REConstants.ModelControl.defaultCancellingTimeToFreeResources) {
                                taskWasCancelled = false
                                trainTaskIsComplete = true
                                indexTaskIsComplete = true
                            }
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if navPath.count == 0 {
                        Button("Setup") {
                            navPath.append(TrainingProcessView.ViewModel.Destinations.trainingSetup)
                        }
                    } else {
                            if navPath.count == 1 {
                                Button("Train") {
                                    navPath.append(TrainingProcessView.ViewModel.Destinations.training)
                                }
                            }/* else {
                                Button("Train") {
                                }
                                .disabled(true)
                            }*/
                    }
                }
            }
        }
        .onDisappear {
            // Typically, we disable ESC closing the modal, but here we just always check that the task was properly canceled to be safe.
            trainCacheTask?.cancel()
            trainTask?.cancel()
        }
    }
    
}
