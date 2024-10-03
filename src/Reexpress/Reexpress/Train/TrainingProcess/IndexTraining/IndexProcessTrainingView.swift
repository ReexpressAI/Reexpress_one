//
//  IndexProcessTrainingView.swift
//  Alpha1
//
//  Created by A on 7/23/23.
//

import SwiftUI

struct IndexProcessTrainingView: View {
    @Binding var navPath: NavigationPath
    var modelControlIdString: String = REConstants.ModelControl.indexModelId
    var isKeyModel: Bool {
        return modelControlIdString == REConstants.ModelControl.keyModelId
    }
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var dataController: DataController
    
    @ObservedObject var viewModel: TrainingProcessView.ViewModel
    @ObservedObject var trainingProcessController: TrainingProcessController
    @Binding var trainTask: Task<Void, Error>?
    
    @State private var showingTrainingErrorAlert: Bool = false
    @State private var trainingErrorMessage: String = "Training failed."
    
    @Binding var indexTaskIsComplete: Bool
    @Binding var totalElapsedTime: String
    @Binding var taskWasCancelled: Bool
    
    func runModelCompressionTrainingLoop() async throws {
        let epochs = trainingProcessController.epochs
        let learningRate = trainingProcessController.learningRate
        let batchSize = trainingProcessController.batchSize
        let numberOfThreads = trainingProcessController.numberOfThreads
        let useDeacySchedule = trainingProcessController.useDeacySchedule
        
        let keyModelInputSize = REConstants.ModelControl.keyModelDimension  // here, we are compressing the exemplar vectors
        
        var decaySchedule = (epoch: 1000, factor: Float(1.0))
        if useDeacySchedule {
            decaySchedule = trainingProcessController.decaySchedule
        }
        var initialModelWeights: KeyModel.ModelWeights? = dataController.inMemory_KeyModelGlobalControl.indexModelWeights
        var prevRunningBestMaxMetric = dataController.inMemory_KeyModelGlobalControl.indexCurrentMaxMetric
        
        if trainingProcessController.ignoreExistingWeights {
            initialModelWeights = nil
            prevRunningBestMaxMetric = -Float.infinity
            dataController.inMemory_KeyModelGlobalControl.indexProcessDataStorageLoss.resetTrainingProcessData()
            dataController.inMemory_KeyModelGlobalControl.indexProcessDataStorageMetric.resetTrainingProcessData()
        }
        
        if trainingProcessController.ignoreExistingRunningBestMaxMetric {
            prevRunningBestMaxMetric = -Float.infinity
            dataController.inMemory_KeyModelGlobalControl.indexProcessDataStorageLoss.resetTrainingProcessData()
            dataController.inMemory_KeyModelGlobalControl.indexProcessDataStorageMetric.resetTrainingProcessData()
        }
        
        let indexModelInstance = KeyModel(batchSize: batchSize, numberOfThreads: numberOfThreads, numberOfClasses: dataController.numberOfClasses, keyModelInputSize: keyModelInputSize, numberOfFilterMaps: REConstants.ModelControl.indexModelDimension, learningRate: learningRate, initialModelWeights: initialModelWeights)
        
        // This includes a check for sufficient labels
        let validationFeatureProviders = try await indexModelInstance.getFeatureProvidersDataFromDatabase(datasetId: REConstants.DatasetsEnum.calibration.rawValue, moc: moc, onlyIncludeInstancesWithKnownValidLabels: true, returnExemplarVectorAndPredictionAsLabel: true, throwIfInsufficientTrainingLabels: false)
        
        //        let validationScore = try await keyModelInstance.test(featureProviders: validationFeatureProviders, returnPredictions: false).score
        //        print("Calibration pre-training Balanced Accuracy prior to compression: \(validationScore)")
        
        //let bestModelWeights =
        try await indexModelInstance.train(modelControlIdString: REConstants.ModelControl.indexModelId, totalEpochs: epochs, prevRunningBestMaxMetric: prevRunningBestMaxMetric, decaySchedule: decaySchedule, dataController: dataController, moc: moc, validationFeatureProviders: validationFeatureProviders)
    }
    
    var batchRun: Bool = false
    
    var body: some View {
        ScrollView {
            VStack {
                HStack(alignment: .top) {
                    Text("Stage 3. Model Compression Training Progress")
                        .font(.title)
                        .bold()
                        .foregroundColor(REConstants.REColors.indexTrainingHighlightColor)
                        .opacity(0.75)
                        .padding([.leading, .trailing, .top])
                    Spacer()
                    VStack {
                        if !(indexTaskIsComplete) {
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
                VStack {
                    if !totalElapsedTime.isEmpty {
                        HStack(spacing: 0) {
                            Text("Training runtime:  ")
                                .foregroundStyle(.gray)
                            Text(totalElapsedTime)
                                .monospaced()
                            Spacer()
                        }
                        .font(REConstants.Fonts.baseFont)
                        .padding([.leading, .trailing, .top])
                    }
                }
                VStack {
                    TrainingProcessDetails(modelControlIdString: modelControlIdString, metricStringName: "\(dataController.inMemory_KeyModelGlobalControl.indexMaxMetric.description)", data: dataController.inMemory_KeyModelGlobalControl.indexProcessDataStorageMetric.trainingProcessData)
                    TrainingProcessDetails(modelControlIdString: modelControlIdString, data: dataController.inMemory_KeyModelGlobalControl.indexProcessDataStorageLoss.trainingProcessData)
                }
                .padding()
                .modifier(SimpleBaseBorderModifier())
                .padding()
            }
            .padding()
            .frame(minHeight: 800, idealHeight: 800)
        }
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
            let processStartTime = Date()
            trainTask = Task {
                do {
                    //                    if true {
                    //                        try await cacheHiddenStates(datasetId: REConstants.DatasetsEnum.calibration.rawValue)
                    //                        try await cacheHiddenStates(datasetId: REConstants.DatasetsEnum.train.rawValue)
                    //
                    //
                    //
                    //                        print("finished forward cache")
                    //                        //exit(0)
                    //                    }
                    // MARK: need to check if sufficient labels for training; need to add cancellation; also need to show progress
                    //throw KeyModelErrors.insufficientTrainingLabels
                    //                    try await cacheHiddenStates(datasetId: REConstants.DatasetsEnum.calibration.rawValue)
                    //                    try await cacheHiddenStates(datasetId: REConstants.DatasetsEnum.train.rawValue)
                    
                    
                    try await runModelCompressionTrainingLoop()
                    await MainActor.run {
                        if batchRun {
                            if !taskWasCancelled {
                                navPath.append( TrainingProcessView.ViewModel.Destinations.batchRunPredict )
                            }
                        } else {
                            let processDuration = Date().timeIntervalSince(processStartTime)
                            if let processDurationString = REConstants.durationFormatter.string(from: processDuration) {
                                totalElapsedTime = processDurationString
                            }
                            indexTaskIsComplete = true
                        }
                    }
                    
                    
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
                        trainingErrorMessage = "There is insufficient Training and/or Calibration data to start compression. Data was deleted since initial training. Re-add the data and re-train, and then start compression again."
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

