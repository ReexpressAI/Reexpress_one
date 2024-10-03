//
//  TrainingProcessCacheHiddenStatesView.swift
//  Alpha1
//
//  Created by A on 7/24/23.
//

import SwiftUI

import CoreML

struct TrainingProcessCacheHiddenStatesView: View {
    @Binding var navPath: NavigationPath
    
    var modelControlIdString: String = REConstants.ModelControl.keyModelId
    var isKeyModel: Bool {
        return modelControlIdString == REConstants.ModelControl.keyModelId
    }
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var dataController: DataController
    @EnvironmentObject var programModeController: ProgramModeController
    
    @ObservedObject var viewModel: TrainingProcessView.ViewModel
    @ObservedObject var trainingProcessController: TrainingProcessController
    @Binding var trainTask: Task<Void, Error>?
    @Binding var processStartTime: Date?
    @Binding var taskWasCancelled: Bool
    
    @State private var showingTrainingErrorAlert: Bool = false
    @State private var trainingErrorMessage: String = "Training failed."
    
    @State private var trainingCacheComplete: Bool = false
    @State private var calibrationCacheComplete: Bool = false
    
    @State var totalTraining: Int = -1
    @State var currentTraining: Int = 0
    
    var trainingStatusString: String {
        if totalTraining == -1 {
            return "Not yet started"
        }
        if trainingCacheComplete {
            return "\(totalTraining) out of \(totalTraining) uncached documents"
        } else {
            return "\(currentTraining) out of \(totalTraining) uncached documents"
        }
    }
    
    @State var totalCalibration: Int = -1
    @State var currentCalibration: Int = 0
    
    var calibrationStatusString: String {
        if totalCalibration == -1 {
            return "Not yet started"
        }
        if calibrationCacheComplete {
            return "\(totalCalibration) out of \(totalCalibration) uncached documents"
        } else {
            return "\(currentCalibration) out of \(totalCalibration) uncached documents"
        }
    }
    
//    @State private var trainingProgress: Double = 0.0
//    @State private var calibrationProgress: Double = 0.0
    
    var currentTrainingProgress: Double {
        if trainingCacheComplete {
            return 1.0
        } else {
            if totalTraining > 0 {
                return Double(currentTraining) / Double(totalTraining)
            } else {
                return 0.0
            }
        }
    }
    var currentCalibrationProgress: Double {
        if calibrationCacheComplete {
            return 1.0
        } else {
            if totalCalibration > 0 {
                return Double(currentCalibration) / Double(totalCalibration)
            } else {
                return 0.0
            }
        }
    }
    

    
    // tokenization is 16.96983150045077 minutes for 250_000
    
     
//    TrainingProcessCacheHiddenStatesView+MFastestM1v1D
    
    var body: some View {
        VStack {
            HStack(alignment: .top) {
                Text("Stage 1. Parameter Caching Progress")
                    .font(.title)
                    .bold()
                    //.foregroundColor(.gray)
                    .padding([.leading, .trailing, .top])
                Spacer()
                VStack {
                    if !(calibrationCacheComplete && trainingCacheComplete) {
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
            VStack(alignment: .leading) {
                Grid(verticalSpacing: 20) {
                    GridRow(alignment: .firstTextBaseline) {
                        Image(systemName: "checkmark.circle")
                            .foregroundStyle(.green.gradient)
                            .opacity(trainingCacheComplete ? 1.0 : 0.0)
                            .gridColumnAlignment(.center)
                        Text("Training Set:")
                            .gridColumnAlignment(.trailing)
                            .foregroundStyle(.gray)
                        HStack {
                            Text(trainingStatusString)
                            Spacer()
                        }
                        .frame(minWidth: 250)
                            .gridColumnAlignment(.leading)
                    }
                    GridRow(alignment: .firstTextBaseline) {
                        Image(systemName: "checkmark.circle")
                            .hidden()
                        Text("Training Set:")
                            .hidden()
                        ProgressView(value: currentTrainingProgress,
                                     label: { Text(trainingCacheComplete ? "Complete." : "Processing...") },
                                     currentValueLabel: { Text(currentTrainingProgress.formatted(.percent.precision(.fractionLength(0)))) })
                        .gridCellUnsizedAxes([.horizontal, .vertical])
                    }
                    GridRow(alignment: .firstTextBaseline) {
                        Image(systemName: "checkmark.circle")
                            .foregroundStyle(.green.gradient)
                            .opacity(calibrationCacheComplete ? 1.0 : 0.0)
                        Text("Calibration Set:")
                            .foregroundStyle(.gray)
                            //.frame(width: 150)
//                        Text(calibrationStatusString)
                        HStack {
                            Text(calibrationStatusString)
                            Spacer()
                        }
                        .frame(minWidth: 250)
                    }
                    GridRow(alignment: .firstTextBaseline) {
                        Image(systemName: "checkmark.circle")
                            .hidden()
                        Text("Calibration Set:")
                            .hidden()
                        ProgressView(value: currentCalibrationProgress,
                                     label: { Text(calibrationCacheComplete ? "Complete." : "Processing...") },
                                     currentValueLabel: { Text(currentCalibrationProgress.formatted(.percent.precision(.fractionLength(0)))) })
                        .gridCellUnsizedAxes([.horizontal, .vertical])
                    }
                }
                .font(REConstants.Fonts.baseFont)
                .padding()
            }
            //.frame(width: 550)
            .padding()
//            .modifier(SimpleBaseBorderModifier())
//            .padding()
            Spacer()
            VStack {
                Text("All available data has been cached. Initializing Stage 2 training...")
                    .font(REConstants.Fonts.baseFont)
                    .bold()
                    .foregroundStyle(.gray)
            }
            .padding()
            .modifier(SimpleBaseBorderModifier())
            .padding()
            .opacity( (calibrationCacheComplete && trainingCacheComplete) ? 1.0 : 0.0)
            Spacer()
        }
        .padding()
        .alert("Unable to begin the training process", isPresented: $showingTrainingErrorAlert) {
            
            Button("OK") {
                trainTask?.cancel()
                dismiss()
            }
        } message: {
            Text(trainingErrorMessage)
        }
//        .alert(isPresented: $showingTrainingErrorAlert, content: {
//            showingTrainingErrorAlert = true
//            trainingErrorMessage = "Unable to begin the training process. Training requires at least \(REConstants.KeyModelConstraints.minNumberOfLabelsPerClassForTraining) labeled documents per class."
//        })
        .navigationBarBackButtonHidden(true)
        .onDisappear {
            trainTask?.cancel()
        }
        .onAppear {
            processStartTime = Date()
            trainTask = Task {
                do {

                    // MARK: need to check if sufficient labels for training; need to add cancellation; also need to show progress
                    //throw KeyModelErrors.insufficientTrainingLabels
                    //let batchSize = 100  //32 //100 //1000
                    let batchSize = programModeController.batchSize
                    switch dataController.modelGroup {
                    case .Fast:
                        try await cacheHiddenStates_MFastM1v1D(batchSize: batchSize, datasetId: REConstants.DatasetsEnum.train.rawValue)
                    case .Faster:
                        try await cacheHiddenStates_MFasterM1v1D(batchSize: batchSize, datasetId: REConstants.DatasetsEnum.train.rawValue)
                    case .Fastest:
                        try await cacheHiddenStates_MFastestM1v1D(batchSize: batchSize, datasetId: REConstants.DatasetsEnum.train.rawValue)
                    }
                    
                    await MainActor.run {
                        if totalTraining == -1 {
                            totalTraining = 0
                        }
                        withAnimation {
                            trainingCacheComplete = true
                        }
                    }
                    switch dataController.modelGroup {
                    case .Fast:
                        try await cacheHiddenStates_MFastM1v1D(batchSize: batchSize, datasetId: REConstants.DatasetsEnum.calibration.rawValue)
                    case .Faster:
                        try await cacheHiddenStates_MFasterM1v1D(batchSize: batchSize, datasetId: REConstants.DatasetsEnum.calibration.rawValue)
                    case .Fastest:
                        try await cacheHiddenStates_MFastestM1v1D(batchSize: batchSize, datasetId: REConstants.DatasetsEnum.calibration.rawValue)
                    }
                    
                    await MainActor.run {
                        if totalCalibration == -1 {
                            totalCalibration = 0
                        }
                        
                        withAnimation {
                            calibrationCacheComplete = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            if !taskWasCancelled {
                                navPath.append(TrainingProcessView.ViewModel.Destinations.training)
                            }
                        }
                        //                        navPath.append(TrainingProcessView.ViewModel.Destinations.training)
                    }
                } catch MLForwardErrors.tokenizationWasCancelled {
                    // in this case we do not need to do anything; the user canceled during tokenization
                    print("Task was cancelled by the user during tokenization.")
                    
                } catch MLForwardErrors.forwardPassWasCancelled {
                    // in this case we do not need to do anything; the user canceled during tokenization
                    print("Task was cancelled by the user during the forward pass.")
                    
                } catch KeyModelErrors.inputDimensionSizeMismatch {
                    await MainActor.run {
                        showingTrainingErrorAlert = true
                        trainingErrorMessage = "Unexpected input dimensions were encountered."
                    }
                } catch GeneralFileErrors.attributeMaxSizeError {
                    await MainActor.run {
                        showingTrainingErrorAlert = true
                        trainingErrorMessage = "Unexpected input dimensions were encountered. The stored attributes exceed the max length of \(REConstants.KeyModelConstraints.attributesSize)."
                    }
                } catch KeyModelErrors.insufficientTrainingLabels, CoreDataErrors.noDocumentsFound, CoreDataErrors.datasetNotFound, KeyModelErrors.noFeatureProvidersAvailable {
                    await MainActor.run {
                        showingTrainingErrorAlert = true
                        trainingErrorMessage = "Training requires at least \(REConstants.KeyModelConstraints.minNumberOfLabelsPerClassForTraining) labeled documents per class for both Training and Calibration. Add data and try again!"
                    }
                } catch {
                    await MainActor.run {
                        showingTrainingErrorAlert = true
                        trainingErrorMessage = "An unexpected error was encountered. Try closing the other running programs (if any) on your computer and then restart \(REConstants.ProgramIdentifiers.mainProgramName)."
                    }
                }
            }
        }
    }
}
