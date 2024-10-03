//
//  DataController+ML+EncDec+MFastesterM1v1D.swift
//  Alpha1
//
//  Created by A on 7/25/23.
//

import Foundation
import CoreML
import Accelerate

extension DataController {
    
    func forwardPassEncDecSimpleBatchDual_MFasterM1v1D(model: MFasterM1v1D, reduceModel: MFasterM1v1DReduce, batchSize: Int, tokenizedInputDic: [Int: SentencepieceTokenizer.DocumentTokenizationResult], multiTokenizedInputDic: [Int: SentencepieceTokenizer.DocumentTokenizationResult], padId: TokenIdType, multiPadId: TokenIdType) async throws -> [Int: [Float32]] {
                
        var sentenceIndexToEmbeddings: [Int: [Float32]] = [:]
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
        for batchIndex in 0..<batchGroupToModelOutputArray.count {
            if Task.isCancelled {
                throw MLForwardErrors.forwardPassWasCancelled
            }
            let modelOutput = batchGroupToModelOutputArray[batchIndex]
            let batchedInputs = batchGroupToInputStructuresInGroupArray[batchIndex]
            let sentencesInGroup = batchGroupToSentencesInGroupArray[batchIndex]
            try forwardDualReduceEncoderHiddenStates_MFasterM1v1D(modelOutput: modelOutput, batchedInputs: batchedInputs, sentencesInGroup: sentencesInGroup, reduceModel: reduceModel, sentenceIndexToEmbeddings: &sentenceIndexToEmbeddings)
        }

        
        return sentenceIndexToEmbeddings
    }
    
    func forwardDualReduceEncoderHiddenStates_MFasterM1v1D(modelOutput: [MFasterM1v1DOutput], batchedInputs: [MFasterM1v1DInput], sentencesInGroup: [Int], reduceModel: MFasterM1v1DReduce, sentenceIndexToEmbeddings: inout [Int: [Float32]]) throws {
        var batchedReduceInputs: [MFasterM1v1DReduceInput] = []
        
        for instanceIndex in 0..<modelOutput.count {
            
            let attentionMask = batchedInputs[instanceIndex].input0a
            let monoLastHiddenStateForAllTokens = modelOutput[instanceIndex].encoderLH
            
            let multiAttentionMask = batchedInputs[instanceIndex].input1a
            let multiLastHiddenStateForAllTokens = modelOutput[instanceIndex].multiEncoderLH
            
            batchedReduceInputs.append(MFasterM1v1DReduceInput(output0: monoLastHiddenStateForAllTokens, output0a: attentionMask, output1: multiLastHiddenStateForAllTokens, output1a: multiAttentionMask))
        }
        // reduction
        guard let modelReduceOutput = try? reduceModel.predictions(inputs: batchedReduceInputs) else {
            throw MLForwardErrors.forwardError
        }
        for instanceIndex in 0..<modelReduceOutput.count {
            let originalSentenceIndex = sentencesInGroup[instanceIndex]
            sentenceIndexToEmbeddings[originalSentenceIndex] = MLShapedArray<Float32>(concatenating: [modelReduceOutput[instanceIndex].reducedCombinedEncoderLHShapedArray, modelOutput[instanceIndex].decoderOutShapedArray], alongAxis: 2).scalars
            
        }
    }
}
