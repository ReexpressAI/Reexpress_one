//
//  DataController+ML+EncDec+Interp+MFasterM1v1D.swift
//  Alpha1
//
//  Created by A on 8/3/23.
//

import Foundation
import CoreML
import Accelerate

extension DataController {
    
    func forwardInterpPassEncDecBatchDual_MFasterM1v1D(model: MFasterM1v1D, reduceModel: MFasterM1v1DReduce, keyModel: KeyModel, indexModel: KeyModel, batchSize: Int, tokenizedInputDic: [Int: SentencepieceTokenizer.DocumentTokenizationResult], multiTokenizedInputDic: [Int: SentencepieceTokenizer.DocumentTokenizationResult], padId: TokenIdType, multiPadId: TokenIdType, batchAttributes: [[Float32]]) async throws -> [Int: OutputFullAnalysisWithFeaturesPredictionType] {
        
        var sentenceIndexToOutputPredictionStructure: [Int: OutputFullAnalysisWithFeaturesPredictionType] = [:]
        
        let maxLength = SentencepieceConstants.maxTokenLength
        
        let decoderInput = MLShapedArray<Int32>(repeating: 0, shape: [1,1])
                
        var batchedInputs: [MFasterM1v1DInput] = []
        var sentencesInGroup: [Int] = []
        var batchedGroupIndex = 0
        
        var batchGroupToModelOutputArray: [[MFasterM1v1DOutput]] = []
        var batchGroupToInputStructuresInGroupArray: [[MFasterM1v1DInput]] = []  // Need access to array masks for reduction
        var batchGroupToSentencesInGroupArray: [[Int]] = []
        
        for (sentenceIndex, documentTokenizationResult) in tokenizedInputDic {
            let rawDocumentTokenIds = documentTokenizationResult.documentTokenIds
            guard let rawMultiDocumentTokenIds = multiTokenizedInputDic[sentenceIndex]?.documentTokenIds else {
                // Unexpectedly, the multi tokenizer is missing the sentence appearing in the other tokenized dictionary
                throw MLForwardErrors.tokenizationDictionaryMismatch
            }
            let paddedInput = getPaddedShapedArrays(documentTokenIds: rawDocumentTokenIds, padId: padId, maxLength: maxLength)
            let multiPaddedInput = getPaddedShapedArrays(documentTokenIds: rawMultiDocumentTokenIds, padId: multiPadId, maxLength: maxLength)
            
            let inputStructure = MFasterM1v1DInput(input0: paddedInput.inputShapedArray, input0a: paddedInput.attentionMaskArray, input0out: decoderInput, input1: multiPaddedInput.inputShapedArray, input1a: multiPaddedInput.attentionMaskArray, input1out: decoderInput)
            
            batchedInputs.append(inputStructure)
            sentencesInGroup.append(sentenceIndex)
            
            batchedGroupIndex += 1
            if batchedInputs.count >= batchSize || batchedGroupIndex == tokenizedInputDic.count {
                if Task.isCancelled {
                    throw MLForwardErrors.forwardPassWasCancelled
                }

                guard let modelOutput = try? model.predictions(inputs: batchedInputs) else {
                        throw MLForwardErrors.forwardError
                    }
                    batchGroupToModelOutputArray.append(modelOutput)
                    batchGroupToInputStructuresInGroupArray.append(batchedInputs)
                    batchGroupToSentencesInGroupArray.append(sentencesInGroup)

                sentencesInGroup = []
                batchedInputs = []
            }
        }
        
        if Task.isCancelled {
            throw MLForwardErrors.forwardPassWasCancelled
        }
        // Reduce, including sentence-level analysis and feature-level compressed exemplar extraction
        for batchIndex in 0..<batchGroupToModelOutputArray.count {  // each batchIndex corresponds to a batch of 1 or more documents
            if Task.isCancelled {
                throw MLForwardErrors.forwardPassWasCancelled
            }
            let modelOutput = batchGroupToModelOutputArray[batchIndex]
            let batchedInputs = batchGroupToInputStructuresInGroupArray[batchIndex]
            let sentencesInGroup = batchGroupToSentencesInGroupArray[batchIndex]
            try await forwardInterpDualReduceEncoderHiddenStates_MFasterM1v1D(modelOutput: modelOutput, batchedInputs: batchedInputs, sentencesInGroup: sentencesInGroup, reduceModel: reduceModel, keyModel: keyModel, indexModel: indexModel, tokenizedInputDic: tokenizedInputDic, multiTokenizedInputDic: multiTokenizedInputDic, batchAttributes: batchAttributes, sentenceIndexToOutputPredictionStructure: &sentenceIndexToOutputPredictionStructure)
        }

        return sentenceIndexToOutputPredictionStructure
    }
    
    func forwardInterpDualReduceEncoderHiddenStates_MFasterM1v1D(modelOutput: [MFasterM1v1DOutput], batchedInputs: [MFasterM1v1DInput], sentencesInGroup: [Int], reduceModel: MFasterM1v1DReduce, keyModel: KeyModel, indexModel: KeyModel, tokenizedInputDic: [Int: SentencepieceTokenizer.DocumentTokenizationResult], multiTokenizedInputDic: [Int: SentencepieceTokenizer.DocumentTokenizationResult], batchAttributes: [[Float32]], sentenceIndexToOutputPredictionStructure: inout [Int: OutputFullAnalysisWithFeaturesPredictionType]) async throws {
        
        // Process each document separately, since multiple sentences per document (each sentence is treated as a unique document)
        for instanceIndex in 0..<modelOutput.count {
            var batchedReduceInputs: [MFasterM1v1DReduceInput] = []
            var batchToSentenceIndex: [Int: Int] = [:]
            batchToSentenceIndex[0] = -1  // first index is full document, for which we use -1 as an indicator; Note that these are sentences *within* a document.
            
            let attentionMask = batchedInputs[instanceIndex].input0a
            let monoLastHiddenStateForAllTokens = modelOutput[instanceIndex].encoderLH
            
            let multiAttentionMask = batchedInputs[instanceIndex].input1a
            let multiLastHiddenStateForAllTokens = modelOutput[instanceIndex].multiEncoderLH
            
            // This first element is the standard full document attention mask:
            batchedReduceInputs.append(MFasterM1v1DReduceInput(output0: monoLastHiddenStateForAllTokens, output0a: attentionMask, output1: multiLastHiddenStateForAllTokens, output1a: multiAttentionMask))
            
            // next add individual sentences (for each sentence, up to the limit, within a single document):
            let originalSentenceIndex = sentencesInGroup[instanceIndex]

            if let sentenceIndexesInDictionary = tokenizedInputDic[originalSentenceIndex]?.documentSentencesToTokenArrayIndexes.keys {
                for sentenceIndex in sentenceIndexesInDictionary {  // we expect both dictionaries to have the same keys
                    if let sentenceRangeTuple = tokenizedInputDic[originalSentenceIndex]?.documentSentencesToTokenArrayIndexes[sentenceIndex], let multiSentenceRangeTuple = multiTokenizedInputDic[originalSentenceIndex]?.documentSentencesToTokenArrayIndexes[sentenceIndex] {
                        
                        // need to keep track of sentences since keys may be out of order and skipping prompt when calculating features below
                        // Note that the full document is included in the batch, so batchToSentenceIndex is indexed *including* the assumption that index 0 is the full document, which has been added above with a placeholder -1.
                        batchToSentenceIndex[batchToSentenceIndex.count] = sentenceIndex
                        let interpretabilityMaskArray = constructInterpretabilityMask(totalLength: attentionMask.count, sentenceRangeTuple: sentenceRangeTuple)
                        let multiInterpretabilityMaskArray = constructInterpretabilityMask(totalLength: multiAttentionMask.count, sentenceRangeTuple: multiSentenceRangeTuple)
                        
                        batchedReduceInputs.append(MFasterM1v1DReduceInput(output0: monoLastHiddenStateForAllTokens, output0a: interpretabilityMaskArray, output1: multiLastHiddenStateForAllTokens, output1a: multiInterpretabilityMaskArray))
                    }
                }
            }
            
            // reduction: This includes the original full document and each individual sentence within the document.
            guard let modelReduceOutput = try? reduceModel.predictions(inputs: batchedReduceInputs) else {
                throw MLForwardErrors.forwardError
            }
            
            if Task.isCancelled {
                throw MLForwardErrors.forwardPassWasCancelled
            }
            
            var documentSentencesBatchedEmbeddingsArray: [[Float32]] = []

            for (_, reducedEmbeddings) in modelReduceOutput.enumerated() {
                // first index is full document
                
                if originalSentenceIndex > batchAttributes.count {
                    throw MLForwardErrors.featureIndexingError
                }
                
                let attributes: [Float32] = batchAttributes[originalSentenceIndex]
                if attributes.count != REConstants.KeyModelConstraints.attributesSize {
                    // Any padding of the attributes must already be added
                    throw GeneralFileErrors.attributeMaxSizeError
                }
                // MARK: We concatenate the reduced embeddings with the *document* level decoder results. Note modelOutput[instanceIndex] and not modelOutput[outputIndex].
                var dataAsArray: [Float32] = MLShapedArray<Float32>(concatenating: [reducedEmbeddings.reducedCombinedEncoderLHShapedArray, modelOutput[instanceIndex].decoderOutShapedArray], alongAxis: 2).scalars
                // append attributes to the input embedding; note that attributes are always the trailing values
                dataAsArray.append(contentsOf: attributes)
                documentSentencesBatchedEmbeddingsArray.append(dataAsArray)
                
            }
            // forward -- Attributes must have already been added
                        
            let evalFeatureProviders = try await keyModel.getFeatureProvidersWithPlaceholderLabels(documentSentencesBatchedEmbeddingsArray: documentSentencesBatchedEmbeddingsArray)
            
            // ignore the score and accuracy because we're using placeholder labels
            let evalOutput = try await keyModel.test(featureProviders: evalFeatureProviders, returnPredictions: true, returnExemplarVectorsWithPredictions: true, returnLoss: false)
            var documentLevelPrediction: OutputPredictionType?
            var featureLevelAnalysisMatchesDocLevel: OutputFeaturePredictionType?
            var featureLevelAnalysisInconsistentWithDocLevel: OutputFeaturePredictionType?
            // First sentence index of non-prompt text:
            guard let startingSentenceArrayIndexOfDocument = tokenizedInputDic[originalSentenceIndex]?.startingSentenceArrayIndexOfDocument else {
                throw KeyModelErrors.inferenceError
            }
            
            var documentSentencesBatchedExamplarsArray: [[Float32]] = []
            
            if let predictions = evalOutput.predictions {
                
                for (outputIndex, outPredictionStructure) in predictions.enumerated() {
                    // For compressed embeddings, we include the full document AND the prompt:
                    guard let exemplar = outPredictionStructure.exemplar else {
                        throw KeyModelErrors.inferenceError
                    }
                    documentSentencesBatchedExamplarsArray.append(exemplar)
                    // first index is full document
                    if outputIndex == 0 {
                        documentLevelPrediction = outPredictionStructure
                    } else {
                        guard let documentLevelPrediction = documentLevelPrediction, let featureSentence = batchToSentenceIndex[outputIndex] else {
                            throw KeyModelErrors.inferenceError
                        }
                        // As noted above, for sentence embeddings, we also include the prompt. But we skipp the prompt for the feature highlighting:
                        // Skip the prompt sentence (if any) when calculating the features.
                        if featureSentence >= startingSentenceArrayIndexOfDocument {
                            let featureMatchesDocumentLevelPrediction = outPredictionStructure.predictedClass == documentLevelPrediction.predictedClass
                            if featureMatchesDocumentLevelPrediction {
                                featureLevelAnalysisMatchesDocLevel = updateFeatureAnalysis(featureLevelAnalysisMatch: featureLevelAnalysisMatchesDocLevel, outPredictionStructure: outPredictionStructure, absoluteFeatureSentenceIndex: featureSentence)
                            } else {  // highest scoring feature for a class other than that predicted for the full document
                                featureLevelAnalysisInconsistentWithDocLevel = updateFeatureAnalysis(featureLevelAnalysisMatch: featureLevelAnalysisInconsistentWithDocLevel, outPredictionStructure: outPredictionStructure, absoluteFeatureSentenceIndex: featureSentence)
                            }
                        }
                    }
                }
            }
            
            if Task.isCancelled {
                throw MLForwardErrors.forwardPassWasCancelled
            }
            
            // run index model
            let evalFeatureProvidersCompressed = try await indexModel.getFeatureProvidersWithPlaceholderLabels(documentSentencesBatchedEmbeddingsArray: documentSentencesBatchedExamplarsArray)
                        
            // ignore the score and accuracy because we're using placeholder labels
            let evalOutputCompressed = try await indexModel.test(featureProviders: evalFeatureProvidersCompressed, returnPredictions: true, returnExemplarVectorsWithPredictions: true, returnLoss: false)
            var documentExemplarCompressed: [Float32] = []
            var reOrderedDocumentSentencesRanges: [Range<String.Index>] = []
            
            var sentenceExemplarsCompressed: [Float32] = []  // A single vector. Dimension REConstants.ModelControl.indexModelDimension must be used to reconstruct.
            var featureSentence2SentenceExemplarsCompressed: [Int: [Float32]] = [:]
            
            guard let documentSentencesRanges = tokenizedInputDic[originalSentenceIndex]?.documentSentencesRanges else {
                throw KeyModelErrors.inferenceError
            }
            if let predictions = evalOutputCompressed.predictions {
                
                for (outputIndex, outPredictionStructure) in predictions.enumerated() {
                    guard let compressedExemplar = outPredictionStructure.exemplar else {
                        throw KeyModelErrors.inferenceError
                    }
                    // first index is full document
                    if outputIndex == 0 {
                        documentExemplarCompressed = compressedExemplar
                    } else {
                                                
                        guard let featureSentence = batchToSentenceIndex[outputIndex] else {
                            throw KeyModelErrors.inferenceError
                        }
                        
                        // Need the sentence ranges in the same order as sentenceExemplarsCompressed. Additionally, some sentences may be missing and not correspond to sentenceExemplarsCompressed, so we drop them.
                        if featureSentence < documentSentencesRanges.count {
                            featureSentence2SentenceExemplarsCompressed[featureSentence] = compressedExemplar
                            /* we add these below after sorting:
                            sentenceExemplarsCompressed.append(contentsOf: compressedExemplar)
                            reOrderedDocumentSentencesRanges.append( documentSentencesRanges[featureSentence] )
                             */
                        }
                    }
                }
            }
            // To help simplify things, we store the features sorted by sentence, but note that some sentences may be missing and not all of the document text is necessarily covered:
            for featureSentence in featureSentence2SentenceExemplarsCompressed.keys.sorted() {
                guard let compressedExemplar = featureSentence2SentenceExemplarsCompressed[featureSentence] else {
                    throw KeyModelErrors.inferenceError
                }
                sentenceExemplarsCompressed.append(contentsOf: compressedExemplar)
                reOrderedDocumentSentencesRanges.append( documentSentencesRanges[featureSentence] )
            }
            
            sentenceIndexToOutputPredictionStructure[originalSentenceIndex] = (documentLevelPrediction: documentLevelPrediction, featureLevelAnalysisMatchesDocLevel: featureLevelAnalysisMatchesDocLevel, featureLevelAnalysisInconsistentWithDocLevel: featureLevelAnalysisInconsistentWithDocLevel, documentExemplarCompressed: documentExemplarCompressed, documentSentencesRanges: reOrderedDocumentSentencesRanges, startingSentenceArrayIndexOfDocument: startingSentenceArrayIndexOfDocument, sentenceExemplarsCompressed: sentenceExemplarsCompressed)
        }
    }
}
