//
//  KeyModel+Training.swift
//  BNNS-Training-Sample
//
//  Created by A on 3/28/23.
//  Copyright © 2023 Apple. All rights reserved.
//

import Foundation
import Accelerate
import CoreData

extension KeyModel {
        
    func train(modelControlIdString: String, totalEpochs: Int = 20, prevRunningBestMaxMetric: Float = 0, decaySchedule: (epoch: Int, factor: Float) = (epoch: 1000, factor: 1.0), dataController: DataController, moc: NSManagedObjectContext, validationFeatureProviders: [FeatureProviderType]) async throws {//}-> ModelWeights? {
        
        // For the index model, we train with the exemplar as the input, and the model **prediction** as the ground truth label target.
        var trainingFeatureProviders = try await getFeatureProvidersDataFromDatabase(datasetId: REConstants.DatasetsEnum.train.rawValue, moc: moc, onlyIncludeInstancesWithKnownValidLabels: true, returnExemplarVectorAndPredictionAsLabel: modelControlIdString == REConstants.ModelControl.indexModelId, throwIfInsufficientTrainingLabels: modelControlIdString == REConstants.ModelControl.keyModelId)
        //try await evalFeatureProvidersWithLMOutput(featureProviders: trainingFeatureProviders)
        
        var bestModelWeights: ModelWeights?
        var runningBestMaxMetric: Float = prevRunningBestMaxMetric //0
        var runningBestMaxMetricEpoch: Int = 0
        
        let maximumIterationCount = totalEpochs //100000 //00//00
        
        // The `recentLosses` array contains the last `recentLossesCount` losses.
//        let recentLossesCount = 20
//        var recentLosses = [Float]()
        
        var totalLossForEpoch: Float32 = 0
        var numberOfMiniBatchesFloat: Float32 = 0
        // The `averageRecentLossThreshold` constant defines the loss threshold
        // at which to consider the training phase complete.
//        let averageRecentLossThreshold = Float(0.125)
        
        for epoch in 0 ..< maximumIterationCount {
            if epoch == decaySchedule.epoch {
                adam.learningRate /= decaySchedule.factor
            }
//            if epoch == 500 {
//                adam.learningRate /= 10
//            }
            //print("Currently processing epoch \(epoch)")
            if Task.isCancelled {
                return //nil
            }
            // shuffle data
            trainingFeatureProviders.shuffle()
            
            for startingIndex in stride(from: 0, to: trainingFeatureProviders.count, by: batchSize) {
                if Task.isCancelled {
                    return
                }
                try generateInputAndLabels(startingIndex: startingIndex, featureProviders: trainingFeatureProviders, training: true)
                if Task.isCancelled {
                    return
                }
                forwardPass()
                computeLoss()
                // loss is the mean loss for this mini-batch
                guard let loss = lossOutput.makeArray(of: Float.self,
                                                      batchSize: 1)?.first else {
                    //print("Unable to calculate loss.")
                    throw KeyModelErrors.trainingLossError
                }
                
                totalLossForEpoch += loss
                if epoch == 0 {
                    numberOfMiniBatchesFloat += 1
                }
                //fix the following to account for stride
                /*if recentLosses.isEmpty {
                    recentLosses = [Float](repeating: loss,
                                           count: recentLossesCount)
                }
                
                recentLosses[epoch % recentLossesCount] = loss*/
//                let tempW = exportWeights()
//                print(tempW.cnnWeights?.count)
//                print(tempW.cnnBias?.count)
//                print(tempW.fcWeights?.count)
//                print(tempW.fcBias?.count)
                
//                print("batch size: \(batchSize)")
//                if let input = input.makeArray(
//                    of: Float.self,
//                    batchSize: batchSize), let batchCNNOutput = batchCNNOutput.makeArray(
//                        of: Float.self,
//                        batchSize: batchSize), let fullyConnectedInputGradient = fullyConnectedInputGradient.makeArray(
//                            of: Float.self,
//                            batchSize: batchSize),
//                   let convolutionInputGradient = convolutionInputGradient.makeArray(
//                    of: Float.self,
//                    batchSize: batchSize),
//                   let convolutionWeightGradient = convolutionWeightGradient.makeArray(
//                    of: Float.self,
//                    batchSize: batchSize),
//                   let convolutionBiasGradient = convolutionBiasGradient.makeArray(
//                    of: Float.self,
//                    batchSize: batchSize) {
//                    print("batchCNNOutput: \(batchCNNOutput.count / batchSize)")
//                    print("fullyConnectedInputGradient: \(fullyConnectedInputGradient.count / batchSize)")
//                    print("convolutionInputGradient: \(convolutionInputGradient.count / batchSize)")
//                    print("convolutionWeightGradient: \(convolutionWeightGradient.count / batchSize)")
//                    print("convolutionBiasGradient: \(convolutionBiasGradient.count / batchSize)")
//                }
                   
                
                
                backwardPass()
            }
            totalLossForEpoch = totalLossForEpoch / max(Float(1), numberOfMiniBatchesFloat)
            if Task.isCancelled {
                return
            }
                            
//            let trainingEvalOut = try await test(featureProviders: trainingFeatureProviders, returnPredictions: false, returnLoss: true)
//            let validationEvalOut = try await test(featureProviders: validationFeatureProviders, returnPredictions: false, returnLoss: true)
            let trainingEvalOut = try await test(featureProviders: trainingFeatureProviders, returnPredictions: true, returnExemplarVectorsWithPredictions: true, returnLoss: true)
            let validationEvalOut = try await test(featureProviders: validationFeatureProviders, returnPredictions: true, returnExemplarVectorsWithPredictions: true, returnLoss: true)
            let validationScore = validationEvalOut.score
            
            var trainingDocumentIdToDocLevelPredictionStructure: [String: OutputPredictionType] = [:]
            var validationDocumentIdToDocLevelPredictionStructure: [String: OutputPredictionType] = [:]
            
            if validationScore >= runningBestMaxMetric {
                // If the data is to be saved to the database, construct a dictionary for faster core data insertion. Here, we do this on the background thread, before returning to the main thread for the update.
                if let predictions = trainingEvalOut.predictions {
                    for documentPrediction in predictions {
                        trainingDocumentIdToDocLevelPredictionStructure[documentPrediction.id] = documentPrediction
                    }
                }
                if let predictions = validationEvalOut.predictions {
                    for documentPrediction in predictions {
                        validationDocumentIdToDocLevelPredictionStructure[documentPrediction.id] = documentPrediction
                    }
                }
            }
        
            
            // update and save graph data structures. Note that unlike weights, these get saved every epoch.
            if !Task.isCancelled {
                try await MainActor.run {
                    try updateTrainingProcessData(modelControlIdString: modelControlIdString,
                                                  trainingLoss: trainingEvalOut.loss ?? Float.infinity,
                                                  validationLoss: validationEvalOut.loss ?? Float.infinity,
                                                  trainingScore: trainingEvalOut.score,
                                                  validationScore: validationEvalOut.score,
                                                  moc: moc,
                                                  inMemory_KeyModelGlobalControl: &dataController.inMemory_KeyModelGlobalControl)
                }
                if validationScore >= runningBestMaxMetric {
                    runningBestMaxMetric = validationScore
                    runningBestMaxMetricEpoch = epoch
                    bestModelWeights = exportWeights()
                    // update database and data controller
                    if let modelWeights = bestModelWeights {
                        // convert to let to pass over to the main thread
                        let runningBestMaxMetric = runningBestMaxMetric
                        let trainingDocumentIdToDocLevelPredictionStructure = trainingDocumentIdToDocLevelPredictionStructure
                        let validationDocumentIdToDocLevelPredictionStructure = validationDocumentIdToDocLevelPredictionStructure
                        try await MainActor.run {
                            try saveWeightsToCoreDataAndMemoryStructures(modelControlIdString: modelControlIdString, modelWeights: modelWeights, currentMaxMetric: runningBestMaxMetric, minLoss: trainingEvalOut.loss ?? Float.infinity, moc: moc, inMemory_KeyModelGlobalControl: &dataController.inMemory_KeyModelGlobalControl)
                        }
                        // save predictions for training
                        // Batching occurs within this function. We check for Task cancellation each chunk.
                        try await dataController.addDocumentLevelPredictionsForDataset(modelControlIdString: modelControlIdString, datasetId: REConstants.DatasetsEnum.train.rawValue, documentIdToDocLevelPredictionStructure: trainingDocumentIdToDocLevelPredictionStructure, moc: moc)
                        // save predictions for validation
                        try await dataController.addDocumentLevelPredictionsForDataset(modelControlIdString: modelControlIdString, datasetId: REConstants.DatasetsEnum.calibration.rawValue, documentIdToDocLevelPredictionStructure: validationDocumentIdToDocLevelPredictionStructure, moc: moc)
                        
                    }
                    
                    //print("Epoch \(epoch): loss: \(totalLossForEpoch): training loss (recalculated): \(trainingEvalOut.loss ?? 0) : training accuracy: \(trainingEvalOut.score) : validation loss: \(validationEvalOut.loss ?? 0) : Calibration set Balanced Accuracy: \(validationScore) :: NEW MAX")
                } /*else {
                    print("Epoch \(epoch): loss: \(totalLossForEpoch): training loss (recalculated): \(trainingEvalOut.loss ?? 0) : training accuracy: \(trainingEvalOut.score) : validation loss: \(validationEvalOut.loss ?? 0) : Calibration set Balanced Accuracy: \(validationScore)")
                }*/
            }
            
            // reset loss
            totalLossForEpoch = 0
            
            
        }
        //print("Best Calibration set Balanced Accuracy: \(runningBestMaxMetric) :: at epoch \(runningBestMaxMetricEpoch)")
        
        //return bestModelWeights
    }
    
    // The `forwardPass` function performs a forward pass by calling `apply` on
    // the fused, pooling, and fully connected layers.
    func forwardPass() {
        do {
            try cnnLayer.apply(batchSize: batchSize,
                               input: input,
                               output: batchCNNOutput)
                        
            try fullyConnectedLayer.apply(batchSize: batchSize,
                                          input: batchCNNOutput,
                                          output: fullyConnectedOutput)
            
        } catch {
            fatalError("Forward pass failed.")
        }
        
        
    }
    
    // The `backwardPass` function performs a backward pass by calling
    // `applyBackward` on the fully connected layer, pooling layer, and fused layer.
    // After completing the backward pass, the function applies an optimizer step
    // to the fully connected and fused parameters.
    func backwardPass() {
        backwardFully()
        backwardCNN()
        
        optimizerStep()
    }
    
    // MARK: Backward pass and optimization step
    
    
    
    // The `optimizerStep` function applies an optimizer step to the fully
    // connected weights, the convolution weights and bias, and the batch
    // normalization beta and gamma.
    func optimizerStep() {
        do {
            try adam.step(
                parameters: [fullyConnectedWeights, fullyConnectedBias,
                             convolutionWeights, convolutionBias],
                gradients: [fullyConnectedWeightGradient, fullyConnectedBiasGradient,
                            convolutionWeightGradient, convolutionBiasGradient],
                accumulators: [fullyConnectedWeightAccumulator1, fullyConnectedBiasAccumulator1,
                               convolutionWeightAccumulator1, convolutionBiasAccumulator1,
                               fullyConnectedWeightAccumulator2, fullyConnectedBiasAccumulator2,
                               convolutionWeightAccumulator2, convolutionBiasAccumulator2],
                filterParameters: filterParameters)
        } catch {
            fatalError("`optimizerFused()` failed.")
        }
        adam.timeStep += 1
    }
    
    func backwardCNN() {
        do {
            try cnnLayer.applyBackward(
                batchSize: batchSize,
                input: input,
                output: batchCNNOutput,
                outputGradient: fullyConnectedInputGradient,
                generatingInputGradient: convolutionInputGradient,
                generatingWeightsGradient: convolutionWeightGradient,
                generatingBiasGradient: convolutionBiasGradient)
        } catch {
            fatalError("`backwardFused()` failed.")
        }
    }
    
    func backwardFully() {
        do {
            try fullyConnectedLayer.applyBackward(
                batchSize: batchSize,
                input: batchCNNOutput,
                output: fullyConnectedOutput,
                outputGradient: lossInputGradient,
                generatingInputGradient: fullyConnectedInputGradient,
                generatingWeightsGradient: fullyConnectedWeightGradient,
                generatingBiasGradient: fullyConnectedBiasGradient)
        } catch {
            fatalError("`backwardFully()` failed.")
        }
    }
    
    func computeLoss() {
        do {
            try lossLayer.apply(batchSize: batchSize,
                                input: fullyConnectedOutput,
                                labels: oneHotLabels,
                                output: lossOutput,
                                generatingInputGradient: lossInputGradient)
        } catch {
            fatalError("`loss()` failed.")
        }
    }
}
