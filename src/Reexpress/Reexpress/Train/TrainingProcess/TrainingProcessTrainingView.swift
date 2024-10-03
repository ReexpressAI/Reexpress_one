//
//  TrainingProcessTrainingView.swift
//  Alpha1
//
//  Created by A on 7/20/23.
//

import SwiftUI

struct TrainingProcessTrainingView: View {
    @Binding var navPath: NavigationPath
    var modelControlIdString: String = REConstants.ModelControl.keyModelId
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
    
    @Binding var trainTaskIsComplete: Bool
    @Binding var totalElapsedTime: String
    @Binding var taskWasCancelled: Bool
    var existingProcessStartTime: Date?
    
    func runTrainingLoop() async throws {
        let epochs = trainingProcessController.epochs
        let learningRate = trainingProcessController.learningRate
        let batchSize = trainingProcessController.batchSize
        let numberOfThreads = trainingProcessController.numberOfThreads
        let useDeacySchedule = trainingProcessController.useDeacySchedule
        
        let keyModelInputSize = SentencepieceConstants.getKeyModelInputDimension(modelGroup: dataController.modelGroup)
        
        var decaySchedule = (epoch: 1000, factor: Float(1.0))
        if useDeacySchedule {
            decaySchedule = trainingProcessController.decaySchedule
        }
        var initialModelWeights: KeyModel.ModelWeights? = dataController.inMemory_KeyModelGlobalControl.modelWeights
        var prevRunningBestMaxMetric = dataController.inMemory_KeyModelGlobalControl.trainingCurrentMaxMetric
        
        if trainingProcessController.ignoreExistingWeights {
            initialModelWeights = nil
            prevRunningBestMaxMetric = -Float.infinity
            dataController.inMemory_KeyModelGlobalControl.trainingProcessDataStorageLoss.resetTrainingProcessData()
            dataController.inMemory_KeyModelGlobalControl.trainingProcessDataStorageMetric.resetTrainingProcessData()
        }
        
        if trainingProcessController.ignoreExistingRunningBestMaxMetric {
            prevRunningBestMaxMetric = -Float.infinity
            dataController.inMemory_KeyModelGlobalControl.trainingProcessDataStorageLoss.resetTrainingProcessData()
            dataController.inMemory_KeyModelGlobalControl.trainingProcessDataStorageMetric.resetTrainingProcessData()
        }
        
        let keyModelInstance = KeyModel(batchSize: batchSize, numberOfThreads: numberOfThreads, numberOfClasses: dataController.numberOfClasses, keyModelInputSize: keyModelInputSize, numberOfFilterMaps: REConstants.ModelControl.keyModelDimension, learningRate: learningRate, initialModelWeights: initialModelWeights)
        
        // This includes a check for sufficient labels
        
        /*if trainingProcessController.validationFeatureProviders == nil {
         trainingProcessController.validationFeatureProviders = try await keyModelInstance.getDataFromDatabaseForTraining(datasetId: REConstants.DatasetsEnum.calibration.rawValue, moc: moc, onlyIncludeInstancesWithKnownValidLabels: true, returnExemplarVectorAndPredictionAsLabel: false)
         }
         
         guard let validationFeatureProviders = trainingProcessController.validationFeatureProviders else {
         throw KeyModelErrors.validationDataError
         }*/
        
        //try await keyModelInstance.evalFeatureProvidersWithLMOutput(featureProviders: validationFeatureProviders, modelGroup: dataController.modelGroup)
        //        print(keyModelInputSize)
        let validationFeatureProviders = try await keyModelInstance.getFeatureProvidersDataFromDatabase(datasetId: REConstants.DatasetsEnum.calibration.rawValue, moc: moc, onlyIncludeInstancesWithKnownValidLabels: true, returnExemplarVectorAndPredictionAsLabel: false, throwIfInsufficientTrainingLabels: true)
        
        //let validationScore = try await keyModelInstance.test(featureProviders: validationFeatureProviders, returnPredictions: false).score
        //print("Validation pre-training accuracy: \(validationScore)")
        
        //let bestModelWeights =
        try await keyModelInstance.train(modelControlIdString: REConstants.ModelControl.keyModelId, totalEpochs: epochs, prevRunningBestMaxMetric: prevRunningBestMaxMetric, decaySchedule: decaySchedule, dataController: dataController, moc: moc, validationFeatureProviders: validationFeatureProviders)
    }
    
    var batchRun: Bool = false
    var body: some View {
        ScrollView {
            VStack {
                HStack(alignment: .top) {
                    Text("Stage 2. Primary Model Training Progress")
                        .font(.title)
                        .bold()
                        .foregroundColor(REConstants.REColors.trainingHighlightColor)
                        .opacity(0.75)
                        .padding([.leading, .trailing, .top])
                    Spacer()
                    VStack {
                        if !(trainTaskIsComplete) {
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
                    TrainingProcessDetails(modelControlIdString: modelControlIdString, metricStringName: "\(dataController.inMemory_KeyModelGlobalControl.trainingMaxMetric.description)", data: dataController.inMemory_KeyModelGlobalControl.trainingProcessDataStorageMetric.trainingProcessData)
                    TrainingProcessDetails(modelControlIdString: modelControlIdString, data: dataController.inMemory_KeyModelGlobalControl.trainingProcessDataStorageLoss.trainingProcessData)
                    Spacer()
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
                    
                    try await runTrainingLoop()
                    await MainActor.run {
                        if batchRun {
                            if !taskWasCancelled {
                                navPath.append( TrainingProcessView.ViewModel.Destinations.batchRunTrainIndex )
                            }
                        } else {
                            if let processStartTime = existingProcessStartTime {  // takes an existing time as argument
                                let processDuration = Date().timeIntervalSince(processStartTime)
                                if let processDurationString = REConstants.durationFormatter.string(from: processDuration) {
                                    totalElapsedTime = processDurationString
                                }
                            } else {
                                let processDuration = Date().timeIntervalSince(processStartTime)
                                if let processDurationString = REConstants.durationFormatter.string(from: processDuration) {
                                    totalElapsedTime = processDurationString
                                }
                            }
                            trainTaskIsComplete = true
                        }
                    }
                    
                    
                } catch KeyModelErrors.trainingWasCancelled {
                    // in this case we do not need to do anything; the user canceled
                    print("Task was cancelled by the user during training.")
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
