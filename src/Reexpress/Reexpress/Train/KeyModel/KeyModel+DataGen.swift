//
//  KeyModel+DataGen.swift
//  BNNS-Training-Sample
//
//  Created by A on 3/28/23.
//  Copyright © 2023 Apple. All rights reserved.
//

import Foundation
import Accelerate
import CoreData
import CoreML
//struct Digits {
//    let numberOfDigits = 10//3//5//2 //10
//}

extension KeyModel {
    
    /// features_LabelAndHidden_tuples labels must be 0..<numberOfClasses>
    /// Caller is reponsible for handling empty batch registers (which are 0 and occur at the end of the batch structure)
    /// usePlaceHolderGroundTruthLabelIfNecessary: If true, 0's are used in place of any ood or unlabeled labels. Use this when predicting without ground-truth (e.g., in cases of held-out test sets, or active learning pool documents). However, the Caller is reponsible for accounting for these at evaluation (e.g., if some, but not all, of the instances have valid labels and evaluation over that subset is desired).
    func generateInputAndLabels(startingIndex: Int, featureProviders features_LabelAndHidden_tuples: [FeatureProviderType], training: Bool = false, usePlaceHolderGroundTruthLabelIfNecessary: Bool = false) throws {
        //        let printDigits = false
        // Clear the input and one-hot labels arrays.
        vDSP_vclr(input.data!.assumingMemoryBound(to: Float.self), 1,
                  vDSP_Length(input.shape.batchStride * batchSize))
        vDSP_vclr(oneHotLabels.data!.assumingMemoryBound(to: Float.self), 1,
                  vDSP_Length(oneHotLabels.shape.batchStride * batchSize))
        
        // Create typed buffer pointers to the input and one-hot labels data.
        let inputBufferPointer = UnsafeMutableBufferPointer<Float>(
            start: input.data!.bindMemory(to: Float.self,
                                          capacity: input.shape.batchStride * batchSize),
            count: input.shape.batchStride * batchSize)
        
        let labelsBufferPointer = UnsafeMutableBufferPointer<Float>(
            start: oneHotLabels.data!.bindMemory(to: Float.self,
                                                 capacity: oneHotLabels.shape.batchStride * batchSize),
            count: oneHotLabels.shape.batchStride * batchSize)
        
        // For each batch, write a random digit to a random position in the
        // 20 x 20 grid.
        let convolutionInputSize = keyModelInputSize
        for batch_i in 0 ..< batchSize {
            var indexIntoFeatures = startingIndex + batch_i
            if indexIntoFeatures >= features_LabelAndHidden_tuples.count {
                if training {  // for training we fill any empty batch indexes with additional features from a random position in the features array
                    indexIntoFeatures = Int.random(in: 0 ..< features_LabelAndHidden_tuples.count)
                } else { // for test inference empty rows remain zero, so as not to bias eval; however, note the caller is reponsible for handling the index
                    break
                }
            }
            // first build one-hot for label
            var labelInt = Int(features_LabelAndHidden_tuples[indexIntoFeatures].0)
            //            if labelInt < 0 || labelInt >= numberOfClasses {
            if !DataController.isKnownValidLabel(label: labelInt, numberOfClasses: numberOfClasses) {
                if usePlaceHolderGroundTruthLabelIfNecessary {
                    labelInt = 0
                } else {
                    throw KeyModelErrors.dataFormatError
                }
            }
            labelsBufferPointer[batch_i * numberOfClasses + labelInt] = 1
            // next update input
            let embeddingInput = features_LabelAndHidden_tuples[indexIntoFeatures].1
            if embeddingInput.count != keyModelInputSize {
                throw KeyModelErrors.inputDimensionSizeMismatch
            }
            let inputOffset = batch_i * convolutionInputSize
            
            for j in 0..<convolutionInputSize {
                inputBufferPointer[inputOffset + j] = embeddingInput[j]
            }
        }
        
    }
    /// Retrieve the features for datasetId. Note that the order is *not* guaranteed.
    /// onlyIncludeInstancesWithKnownValidLabels: If true, ood and unlabeled instances are ignored. This is important in cases for training and evaluation.
    /// returnExemplarVectorAndPredictionAsLabel If true, return the Exemplar vector as the embedding and the prediction as the ground truth label (used for training approximate search); otherwise, use Embedding.
    /// if throwIfInsufficientTrainingLabels: throws KeyModelErrors.insufficientTrainingLabels if the number of labels is less than REConstants.KeyModelConstraints.minNumberOfLabelsPerClassForTraining for 1 or more classes. We use this for training the main model. For training compression, we do not enforce this. (However, if the model never predicted a class, of course the compressed model would then also typically not be able to correctly predict that class.) For inference, this is not applicable.
    func getFeatureProvidersDataFromDatabase(datasetId: Int, moc: NSManagedObjectContext, onlyIncludeInstancesWithKnownValidLabels: Bool, returnExemplarVectorAndPredictionAsLabel: Bool, throwIfInsufficientTrainingLabels: Bool) async throws -> [FeatureProviderType] {
        
        // retrieve labels and embeddings from the database
        try await MainActor.run {
            var validLabelCountDict: [Int: Int] = [:]
            for label in 0..<numberOfClasses {
                validLabelCountDict[label] = 0
            }
            // Another fecth to update the documents count. We re-fetch, because it is possible the user has uploaded duplicates.
            let fetchRequest = Dataset.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", NSNumber(value: datasetId))
            //            fetchRequest.propertiesToFetch = ["documents"]
            let datasetRequest = try moc.fetch(fetchRequest) //as [Dataset]
            
            if datasetRequest.isEmpty {
                throw CoreDataErrors.datasetNotFound
            }
            let dataset = datasetRequest[0]
            
            var features_LabelAndHidden_tuples = [FeatureProviderType]() // Note that the labels need to be Float32
            
            // Importantly, note that dataset.documents is not sorted and in practice, is not consistently sorted across fetches even with the same database data.
            if let documents = dataset.documents {
                for document in documents {
                    if !returnExemplarVectorAndPredictionAsLabel {
                        if var dataAsArray: [Float32] = document.embedding?.embedding?.toArray(type: Float32.self) {
                            let label = document.label
                            var includeInstance = true
                            if onlyIncludeInstancesWithKnownValidLabels && !DataController.isKnownValidLabel(label: label, numberOfClasses: numberOfClasses) {
                                includeInstance = false
                            }
                            if includeInstance {
                                if let documentId = document.id {
                                    validLabelCountDict[label]? += 1
                                    // Get attributes, if any. Note that the stored attributes may be less than the full size, so fill with 0's, as applicable.
                                    if var attributes = document.attributes?.vector?.toArray(type: Float32.self) {
                                        if attributes.count > REConstants.KeyModelConstraints.attributesSize {
                                            throw GeneralFileErrors.attributeMaxSizeError
                                        }
                                        // expand attributes to full size:
                                        attributes.append(contentsOf: [Float32](repeating: Float32(0.0), count: REConstants.KeyModelConstraints.attributesSize-attributes.count))
                                        // append attributes to the input embedding
                                        dataAsArray.append(contentsOf: attributes)
                                    } else { // no attributes, so fill with empty mask
                                        dataAsArray.append(contentsOf: [Float32](repeating: Float32(0.0), count: REConstants.KeyModelConstraints.attributesSize))
                                    }

                                    if dataAsArray.count != keyModelInputSize {
                                        throw KeyModelErrors.inputDimensionSizeMismatch
                                    }
                                    features_LabelAndHidden_tuples.append( (Float32(label), dataAsArray, documentId) )
                                }
                            }
                        }
                    } else {
                        if let dataAsArray: [Float32] = document.exemplar?.exemplar?.toArray(type: Float32.self) {
                            let label = document.label
                            let predictedLabel = document.prediction
                            var includeInstance = true  // here, we skip any instances also skipped during original training with the frozen network embedding
                            if onlyIncludeInstancesWithKnownValidLabels && !DataController.isKnownValidLabel(label: label, numberOfClasses: numberOfClasses) {
                                includeInstance = false
                            }
                            // also check prediction
                            if onlyIncludeInstancesWithKnownValidLabels && !DataController.isKnownValidLabel(label: predictedLabel, numberOfClasses: numberOfClasses) {
                                includeInstance = false
                            }
                            if includeInstance {
                                if let documentId = document.id {
                                    // NOTE the inclusion of the predicted label rather than the true ground-truth label. Also, in this case, there are no additional attributes, since they have already been embedding into the exemplar.
                                    validLabelCountDict[predictedLabel]? += 1
                                    if dataAsArray.count != keyModelInputSize {
                                        throw KeyModelErrors.inputDimensionSizeMismatch
                                    }
                                    features_LabelAndHidden_tuples.append( (Float32(predictedLabel), dataAsArray, documentId) )
                                }
                            }
                        }
                    }
                }
            }
            if throwIfInsufficientTrainingLabels {
                for label in 0..<numberOfClasses {
                    guard let labelCount = validLabelCountDict[label] else {
                        throw KeyModelErrors.insufficientTrainingLabels
                    }
                    if labelCount < REConstants.KeyModelConstraints.minNumberOfLabelsPerClassForTraining {
                        throw KeyModelErrors.insufficientTrainingLabels
                    }
                }
            }
            if features_LabelAndHidden_tuples.count == 0 {
                throw KeyModelErrors.noFeatureProvidersAvailable
            }
            return features_LabelAndHidden_tuples
        }
    }
    
    // The following constructs features providers using the supplied embedding (which assumes any attributes, if applicable, have already been concatenated).
    func getFeatureProvidersWithPlaceholderLabels(documentSentencesBatchedEmbeddingsArray: [[Float32]]) async throws -> [FeatureProviderType] {
        let placeholderGroundTruthLabel = 0
        var features_LabelAndHidden_tuples = [FeatureProviderType]() // Note that the labels need to be Float32
        
        for dataAsArray in documentSentencesBatchedEmbeddingsArray {
            //            let label = REConstants.DataValidator.oodLabel
            if dataAsArray.count != keyModelInputSize {
                throw KeyModelErrors.inputDimensionSizeMismatch
            }
            features_LabelAndHidden_tuples.append( (Float32(placeholderGroundTruthLabel), dataAsArray, "\(features_LabelAndHidden_tuples.count)") )  // note the document id is a placeholder
        }
        return features_LabelAndHidden_tuples
    }
    
//    func getFeatureProvidersWithPlaceholderLabelsByAttributesConcat(documentSentencesBatchedEmbeddingsArray: [[Float32]], batchAttributes: [[Float32]]) async throws -> [FeatureProviderType] {
//        let placeholderGroundTruthLabel = 0
//        var features_LabelAndHidden_tuples = [FeatureProviderType]() // Note that the labels need to be Float32
//        
//        for dataIndex in 0..<documentSentencesBatchedEmbeddingsArray.count {
//
//            var dataAsArray = documentSentencesBatchedEmbeddingsArray[dataIndex]
//            let attributes = batchAttributes[dataIndex]
//            if attributes.count != REConstants.KeyModelConstraints.attributesSize {
//                throw GeneralFileErrors.attributeMaxSizeError
//            }
//            
//            // append attributes to the input embedding
//            dataAsArray.append(contentsOf: attributes)
//            
//            if dataAsArray.count != keyModelInputSize {
//                throw KeyModelErrors.inputDimensionSizeMismatch
//            }
//            features_LabelAndHidden_tuples.append( (Float32(placeholderGroundTruthLabel), dataAsArray, "\(features_LabelAndHidden_tuples.count)") )  // note the document id is a placeholder
//        }
//        return features_LabelAndHidden_tuples
//    }
    
    
    /*
    // MARK: Todo -- can delete the following test functions
    func temp_getCombinedHiddenDimensionSize(modelGroup: SentencepieceConstants.ModelGroup) -> Int {
        switch modelGroup {
        case .Fast:
            return 2048+768
        case .Faster:
            return 768+1024
        case .Fastest:
            return 768*2
        }
    }
    
    func evalFeatureProvidersWithLMOutput(featureProviders: [FeatureProviderType], modelGroup: SentencepieceConstants.ModelGroup) async throws {
        
        
        var features_LabelAndHidden_tuples = [FeatureProviderType]() // Note that the labels need to be Float32
        var correctCount: Float32 = 0.0
        var totalCount: Float32 = 0.0
        var featureSize: Int = 0
        for indexIntoFeatures in 0..<featureProviders.count {
            // The encoder-decoder states have been concatenated, so we need to extract just the sequence output before passing to the LM head.
            //            let decoderSequenceOutputRange = REConstants.ModelControl.getKeyModelDecoderSequenceOutputArrayRange(modelTypeIdString: "MBillionM1v1C")
            //print("DataArray count: \(featureProviders[indexIntoFeatures].1.count)")
            //            let sequenceOutput = featureProviders[indexIntoFeatures].1[2048+768+1..<2048+768+1+2]
            let combinedHiddenDimension = temp_getCombinedHiddenDimensionSize(modelGroup: modelGroup)
            //            let negativeSoftmax = Float(featureProviders[indexIntoFeatures].1[combinedHiddenDimension+4]) // ▁A
            //            let positiveSoftmax = Float(featureProviders[indexIntoFeatures].1[combinedHiddenDimension+20])  // ▁B
            let negativeSoftmax = Float(featureProviders[indexIntoFeatures].1[combinedHiddenDimension+94]) // ▁negative
            let positiveSoftmax = Float(featureProviders[indexIntoFeatures].1[combinedHiddenDimension+65])  // ▁positive
            featureSize = featureProviders[indexIntoFeatures].1.count
            //            let tokenIdRelative = vDSP.indexOfMaximum(sequenceOutput).0
            //print("Predicted tokenId: \(tokenId); true label: \(featureProviders[indexIntoFeatures].0)")
            if negativeSoftmax > positiveSoftmax && featureProviders[indexIntoFeatures].0 == 0.0 {
                correctCount += 1
            } else if negativeSoftmax < positiveSoftmax && featureProviders[indexIntoFeatures].0 == 1.0 {
                correctCount += 1
            }
            totalCount += 1

        }
        print("Feature size: \(featureSize)")
        print("Accuracy by token generation: \(correctCount/max(1.0, totalCount)) (\(correctCount) / \(totalCount))")
    }
     */

}
