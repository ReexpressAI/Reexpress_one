//
//  SetupMainForwardView.swift
//  Alpha1
//
//  Created by A on 7/27/23.
//

import SwiftUI


extension SetupMainForwardView {
    @MainActor class ViewModel: ObservableObject {
        //@Published var showingTrainingProcessModal = false
        //var trainingParametersTextfieldWidth: CGFloat = 100
        
        enum Destinations {
            case inferenceSetup
            case inferenceStorageEstimate
            case inference
        }
        @Published var currentView = Destinations.inferenceSetup
    }
}

struct SetupMainForwardView: View {
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var dataController: DataController
    
    @StateObject var viewModel: ViewModel = ViewModel()
    
    var datasetId: Int = 0
    
    @State var dataPredictionTask: Task<Void, Error>?
    @State var isShowingRequiredDatasetInfo: Bool = false
    
    @State var selectAll: Bool = false
    
    
    
    
//    var modelControlIdString: String = REConstants.ModelControl.keyModelId
//    var isKeyModel: Bool {
//        return modelControlIdString == REConstants.ModelControl.keyModelId
//    }
//
//    @Environment(\.dismiss) var dismiss
//    @StateObject private var viewModel = ViewModel()
//    @StateObject private var trainingProcessController = TrainingProcessController()
    @State private var navPath = NavigationPath()
//    @State var trainTask: Task<Void, Error>? // Currently both the train and index tasks use the same var, which is ok, since they should never be run at the same time.
//    @State var trainCacheTask: Task<Void, Error>?
//    @State var trainTaskIsComplete: Bool = false
//    @State var indexTaskIsComplete: Bool = false
    
    @State var inferenceDatasetIds: Set<Int> = Set<Int>([REConstants.DatasetsEnum.train.rawValue, REConstants.DatasetsEnum.calibration.rawValue])
    
    @State var predictionTaskWasCancelled: Bool = false
    @State var predictionTaskIsComplete: Bool = false
    
    @State var errorAlert: Bool = false
    @State var estimatesAvailable: Bool = false
    
    @State var totalElapsedInferenceTime: String = ""
    
    var body: some View {
        NavigationStack(path: $navPath) {
            SetupMainForwardAfterTrainingView(inferenceDatasetIds: $inferenceDatasetIds, datasetId: datasetId)
            
                .navigationDestination(for: ViewModel.Destinations.self) { i in
                    switch i {
                    case ViewModel.Destinations.inferenceSetup:
                        SetupMainForwardAfterTrainingView(inferenceDatasetIds: $inferenceDatasetIds, datasetId: datasetId)
                    case ViewModel.Destinations.inferenceStorageEstimate:
                        SetupMainForwardAfterTrainingEstimateStorageView(inferenceDatasetIds: $inferenceDatasetIds, errorAlert: $errorAlert, estimatesAvailable: $estimatesAvailable)
                    case ViewModel.Destinations.inference:
                        MainForwardAfterTrainingView(inferenceDatasetIds: $inferenceDatasetIds, dataPredictionTask: $dataPredictionTask, predictionTaskWasCancelled: $predictionTaskWasCancelled, predictionTaskIsComplete: $predictionTaskIsComplete, totalElapsedInferenceTime: $totalElapsedInferenceTime) //, datasetId: datasetId)
                    }
                }
        }
        .alert("An unexpected error was encountered.", isPresented: $errorAlert) {
            Button {
                dismiss()
            } label: {
                Text("OK")
            }
        } message: {
            Text("Unable to predict.")
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
                
                Button("Cancel") {
                    // it takes some time to cancel if in a forward pass, so need to show a screen
                    dataPredictionTask?.cancel()
                    if navPath.count == 2 {
                        predictionTaskWasCancelled = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + REConstants.ModelControl.defaultCancellingTimeToFreeResources) {
                            dismiss()
                        }
                    } else {
                        dismiss()
                    }
                }
                .disabled(predictionTaskIsComplete || predictionTaskWasCancelled)
            }
            ToolbarItem(placement: .confirmationAction) {
                if navPath.count == 0 {
                    Button("Continue") {
                        navPath.append(ViewModel.Destinations.inferenceStorageEstimate)
                    }
                } else if navPath.count == 1 {
                    Button("Start") {
                        navPath.append(ViewModel.Destinations.inference)
                    }
                    .disabled(!estimatesAvailable)
                } else {
                    Button("Done") {
                        dataPredictionTask?.cancel()
                        dismiss()
                    }
                    .disabled(!predictionTaskIsComplete || predictionTaskWasCancelled)
                }/*else {
                    Button("Pause") {
//                        navPath.append(ViewModel.Destinations.inference)
                    }
                    .disabled(predictionTaskWasCancelled)
                }*/
                
            }
        }
        .onDisappear {
            // Typically, we disable ESC closing the modal, but here we just always check that the task was properly canceled to be safe.
            dataPredictionTask?.cancel()
        }
    }
    
}
