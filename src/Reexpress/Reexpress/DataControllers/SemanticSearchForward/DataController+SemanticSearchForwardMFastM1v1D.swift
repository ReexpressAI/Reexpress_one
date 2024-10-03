//
//  DataController+SemanticSearchForwardMFastM1v1D.swift
//  Alpha1
//
//  Created by A on 8/26/23.
//

import Foundation
import CoreML
import Accelerate

extension DataController {
    // Currently, attributes are always 0's for semantic search.
    func semanticSearch_forward_MFastM1v1D_singleInstance(documentSelectionState: DocumentSelectionState) async throws -> [Float32] {

        if tokenizer == nil {
            tokenizer = SentencepieceTokenizer(language: .english, isMultilingual: false)
        }
        if multiTokenizer == nil {
            multiTokenizer = SentencepieceTokenizer(language: .english, isMultilingual: true)
        }
        
        let config = MLModelConfiguration()
        // Directly set cpu and gpu, as we want GPU on the targeted M1 Max and better with Float32, as opposed to the ANE
        config.computeUnits = .cpuAndGPU
        let model = try await MFastM1v1D.load(configuration: config)
        let reduceConfig = MLModelConfiguration()
        reduceConfig.computeUnits = .cpuAndGPU
        let reduceModel = try await MFastM1v1DReduce.load(configuration: reduceConfig)
        
        // check if weights exist for model else throw since it means the model has not yet been trained
        guard let initialModelWeights: KeyModel.ModelWeights = inMemory_KeyModelGlobalControl.modelWeights else {
            throw KeyModelErrors.keyModelWeightsMissing
        }
        let keyModelInputSize = SentencepieceConstants.getKeyModelInputDimension(modelGroup: modelGroup)
        let keyModelBatchSize: Int = REConstants.KeyModelConstraints.defaultBatchSize
        let numberOfThreads = REConstants.KeyModelConstraints.numberOfThreads
        let learningRate: Float = 0.001  // placeholder
        
        let keyModelInstance = KeyModel(batchSize: keyModelBatchSize, numberOfThreads: numberOfThreads, numberOfClasses: numberOfClasses, keyModelInputSize: keyModelInputSize, numberOfFilterMaps: REConstants.ModelControl.keyModelDimension, learningRate: learningRate, initialModelWeights: initialModelWeights)
        
        guard let initialIndexModelWeights: KeyModel.ModelWeights = inMemory_KeyModelGlobalControl.indexModelWeights else {
            throw KeyModelErrors.indexModelWeightsMissing
        }
        let indexModelInstance = KeyModel(batchSize: keyModelBatchSize, numberOfThreads: numberOfThreads, numberOfClasses: numberOfClasses, keyModelInputSize: REConstants.ModelControl.keyModelDimension, numberOfFilterMaps: REConstants.ModelControl.indexModelDimension, learningRate: learningRate, initialModelWeights: initialIndexModelWeights)
        
        let batchSize: Int = 1
        //let attributesVector = [Float32](repeating: Float32(0.0), count: REConstants.KeyModelConstraints.attributesSize)
        var attributesVector: [Float32] = []
        if documentSelectionState.semanticSearchParameters.searchAttributes.count > 0 && documentSelectionState.semanticSearchParameters.searchAttributes.count <= REConstants.KeyModelConstraints.attributesSize {
            attributesVector.append(contentsOf: documentSelectionState.semanticSearchParameters.searchAttributes)
        }
        if attributesVector.count != REConstants.KeyModelConstraints.attributesSize {
            attributesVector.append(contentsOf: [Float32](repeating: Float32(0.0), count: REConstants.KeyModelConstraints.attributesSize-attributesVector.count))
        }
        
        let documentArray = [(id: UUID().uuidString, document: documentSelectionState.semanticSearchParameters.searchText, prompt: documentSelectionState.semanticSearchParameters.searchPrompt, attributes: attributesVector)]
        
        async let tokenizedDocumentDict = await tokenizer?.parallelTokenizationBySentenceWithPrompt(lines: documentArray.map { $0.document }, prompts: documentArray.map { $0.prompt } )
        async let multiTokenizedDocumentDict = await multiTokenizer?.parallelTokenizationBySentenceWithPrompt(lines: documentArray.map { $0.document }, prompts: documentArray.map { $0.prompt } )
        let tokenizations = try await [tokenizedDocumentDict, multiTokenizedDocumentDict]

        if let flanTokenization = tokenizations[0], let multiTokenization = tokenizations[1] {
            if Task.isCancelled {
                throw MLForwardErrors.forwardPassWasCancelled
            }
            
            let sentenceIndexToOutputPredictionStructure = try await forwardInterpPassEncDecBatchDual_MFastM1v1D(model: model, reduceModel: reduceModel, keyModel: keyModelInstance, indexModel: indexModelInstance, batchSize: batchSize, tokenizedInputDic: flanTokenization, multiTokenizedInputDic: multiTokenization, padId: tokenizer?.padId ?? TokenIdType(0), multiPadId: multiTokenizer?.padId ?? TokenIdType(0), batchAttributes: documentArray.map { $0.attributes })
            
            if Task.isCancelled {
                throw MLForwardErrors.forwardPassWasCancelled
            }
            guard let documentPredictionStructure = sentenceIndexToOutputPredictionStructure[0], documentPredictionStructure.documentExemplarCompressed.count == REConstants.ModelControl.indexModelDimension else {
                throw MLForwardErrors.forwardError
            }
            return documentPredictionStructure.documentExemplarCompressed
        }
        throw MLForwardErrors.forwardError
    }
}

