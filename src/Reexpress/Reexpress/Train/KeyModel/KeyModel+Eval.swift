//
//  KeyModel+Eval.swift
//  BNNS-Training-Sample
//
//  Created by A on 3/28/23.
//  Copyright © 2023 Apple. All rights reserved.
//

import Foundation
import Accelerate
import CoreData

extension KeyModel {
    /// Note that score is only calculated for instances with validKnown labels. Note that this function is also used for model appoximation. In that case, the "true labels" are the predicted labels from the original model.
    func test(featureProviders: [FeatureProviderType], returnPredictions: Bool=false, returnExemplarVectorsWithPredictions: Bool=false, returnLoss: Bool = false) async throws -> (score: Float, predictions: [OutputPredictionType]?, loss: Float?) {
        //var featureProviders = try getDataFromDatabase(datasetId: 2, moc: moc)
        if featureProviders.count == 0 {
            return (score: Float(0.0), predictions: nil, loss: nil)
        }
        var documentIndex = 0
        var correctCount = 0
        var predictions = [OutputPredictionType]()
        var numberOfMiniBatchesFloat: Float32 = 0  // this is used to normalize the loss value
        var cumulativeLoss: Float32 = 0
        
        var validLabelCountDict: [Int: Int] = [:]
        var validLabelCorrectCountDict: [Int: Int] = [:]
        for label in 0..<numberOfClasses {
            validLabelCountDict[label] = 0
            validLabelCorrectCountDict[label] = 0
        }
                
        for startingIndex in stride(from: 0, to: featureProviders.count, by: batchSize) {
            if Task.isCancelled {
                return (score: Float(0.0), predictions: nil, loss: nil)
            }
            try generateInputAndLabels(startingIndex: startingIndex, featureProviders: featureProviders, training: false, usePlaceHolderGroundTruthLabelIfNecessary: true)
            
            // Perform the forward pass over the *mini-batch*. We ignore any empty registers below when calculating the evaluation metrics.
            do {
                
                try cnnLayer.apply(batchSize: batchSize,
                                   input: input,
                                   output: batchCNNOutput)
                
                try fullyConnectedLayer.apply(batchSize: batchSize,
                                              input: batchCNNOutput,
                                              output: fullyConnectedOutput)
                // Only needed when returning predictions:
                if returnPredictions {
                    try softmaxLayer.apply(batchSize: batchSize,
                                           input: fullyConnectedOutput,
                                           output: softmaxOutput)
                }
                if returnLoss {
                    computeLoss()
                }
            } catch {
                throw KeyModelErrors.inferenceError
            }
            
            // Calculate the accuracy of the model.
            guard
                let fullyConnected = fullyConnectedOutput.makeArray(
                    of: Float.self,
                    batchSize: batchSize),
                let labels = oneHotLabels.makeArray(
                    of: Float.self,
                    batchSize: batchSize) else { //,
//                let exemplars = batchCNNOutput.makeArray(of: Float.self, batchSize: batchSize),
//                let predictions = softmaxOutput.makeArray(of: Float.self, batchSize: batchSize) else {
                throw KeyModelErrors.inferenceError
            }
            var softmaxPredictions: [Float32]?
            var exemplarVectors: [Float32]?
            if returnPredictions {
                guard
                    let softmaxLayerOut = softmaxOutput.makeArray(of: Float.self, batchSize: batchSize) else {
                    throw KeyModelErrors.inferenceError
                }
                softmaxPredictions = softmaxLayerOut
                if returnExemplarVectorsWithPredictions {
                    guard
                        let exemplarVectorsOut = batchCNNOutput.makeArray(of: Float.self, batchSize: batchSize) else {
                        throw KeyModelErrors.inferenceError
                    }
                    exemplarVectors = exemplarVectorsOut
                }
            }
            
            if returnLoss {
                guard let lossOut = lossOutput.makeArray(of: Float.self,
                                                      batchSize: 1)?.first else {
                    print("Unable to calculate loss.")
                    throw KeyModelErrors.trainingLossError
                }
                // Should still be correct if empty registers since loss will be against 0's
                cumulativeLoss += lossOut
            }
            numberOfMiniBatchesFloat += 1
            for sample in 0 ..< batchSize {
                let offset = numberOfClasses * sample // offset is only valid for datastructures with #columns == numberOfClasses (i.e., not for the exemplar vectors)
                
                let fullyConnectedBatch = fullyConnected[offset ..< offset + numberOfClasses]
                let predictedLabel = vDSP.indexOfMaximum(fullyConnectedBatch).0
                
                let originalStoredLabelInt = Int(featureProviders[documentIndex].0)
                if DataController.isKnownValidLabel(label: originalStoredLabelInt, numberOfClasses: numberOfClasses) {
                    // Only calculate metrics for known valid labels (i.e., ignore ood and unlabeled cases)
                    let oneHotLabelsBatch = labels[offset ..< offset + numberOfClasses]
                    let trueLabel = vDSP.indexOfMaximum(oneHotLabelsBatch).0
                    if originalStoredLabelInt != Int(trueLabel) {
                        throw KeyModelErrors.dataFormatError
                    }
                    validLabelCountDict[originalStoredLabelInt]? += 1
                    if trueLabel == predictedLabel {  // NOTE: In the case of compression, the "true label" is in fact the predicted label class from the original model
                        correctCount += 1
                        validLabelCorrectCountDict[originalStoredLabelInt]? += 1
                    }
                }
                if returnPredictions {
                    guard let softmaxPredictionBatch = softmaxPredictions else {
                        throw KeyModelErrors.inferenceError
                    }
                    let softmaxAllClasses = Array(softmaxPredictionBatch[offset ..< offset + numberOfClasses])
                    let documentId = featureProviders[documentIndex].2
                    if returnExemplarVectorsWithPredictions {
                        guard let exemplarVectorsBatch = exemplarVectors else {
                            throw KeyModelErrors.inferenceError
                        }
                        let exemplarOffset = numberOfFilterMaps * sample
                        let exemplarVector = Array(exemplarVectorsBatch[exemplarOffset ..< exemplarOffset + numberOfFilterMaps])
                        predictions.append( (id: documentId, softmax: softmaxAllClasses, predictedClass: Int(predictedLabel), exemplar: exemplarVector) )
                    } else {
                        predictions.append( (id: documentId, softmax: softmaxAllClasses, predictedClass: Int(predictedLabel), exemplar: nil) )
                    }
                }
                
                documentIndex += 1
                if documentIndex >= featureProviders.count {
                    break
                }
            }
        }
        // Return the accuracy as a percentage.
//        let score = 100 * (Float(correctCount) / Float(featureProviders.count))
        
        var validLabelAccuracyByPresentLabel: [Float32] = []
//        var validLabelCorrectCountDict: [Int: Int] = [:]
        for label in 0..<numberOfClasses {
            if let groundtruthCount = validLabelCountDict[label], groundtruthCount > 0 {
                let predictedCorrectCount = validLabelCorrectCountDict[label] ?? 0
                // Return the accuracy as a percentage.
                let scorePerClass = 100 * (Float(predictedCorrectCount) / Float(groundtruthCount))
                validLabelAccuracyByPresentLabel.append(scorePerClass)
            }
        }
        let balancedAccuracy = vDSP.mean(validLabelAccuracyByPresentLabel)
        
        
        var loss: Float32? = nil
        if numberOfMiniBatchesFloat > 0 {
            loss = cumulativeLoss / numberOfMiniBatchesFloat
        }
        
        //        print("Emplars shape: \(exemplars.count / batchSize)")
        //        print(exemplars[0..<10])
        //        print(exemplarsRelu[0..<10])
        //        print("fc output batch 0: \(fullyConnected[0..<10])")
        //        print("fc output batch 0 softmax: \(predictions[0..<10])")
        return (score: balancedAccuracy, predictions: (returnPredictions ? predictions : nil), loss: (returnLoss ? (loss ?? 0) : nil))
//        return (score: score, predictions: (returnPredictions ? predictions : nil), loss: (returnLoss ? (loss ?? 0) : nil))
//        return score
    }
    
}

