//
//  ForwardWithInterpretability+MFasterM1v1D.swift
//  Alpha1
//
//  Created by A on 8/3/23.
//

import SwiftUI
import CoreML

extension MainForwardAfterTrainingView {
    
    // Note that forwardInterpPassEncDecBatchDual_X called in this function is unique to each model, as with model and reduceModel.
    func forward_MFasterM1v1D(batchSize: Int, datasetId: Int) async throws {
        
        // First, find uncached documents
        let documentArrayFull = try await dataController.getJSONDocumentArrayFromDatabaseOnlyUnpredicted(datasetId: datasetId, moc: moc)
        
        if documentArrayFull.isEmpty {
            return // available labeled documents are already cached
        }
        if dataController.tokenizer == nil {
            dataController.tokenizer = SentencepieceTokenizer(language: .english, isMultilingual: false)
        }
        if dataController.multiTokenizer == nil {
            dataController.multiTokenizer = SentencepieceTokenizer(language: .english, isMultilingual: true)
        }
        await MainActor.run {
            // update progress
            let _ = inferenceDatasetIds2InferenceProgress.updateValue(
                InferenceProgress(datasetId: datasetId,
                                  totalDocuments: documentArrayFull.count,
                                  currentDocumentProgress: 0,
                                  inferenceProgressStatus: .inference),
                forKey: datasetId)
        }
        
        let config = MLModelConfiguration()
        // Directly set cpu and gpu, as we want GPU on the targeted M1 Max and better with Float32, as opposed to the ANE
        config.computeUnits = .cpuAndGPU
        let model = try await MFasterM1v1D.load(configuration: config)
        let reduceConfig = MLModelConfiguration()
        reduceConfig.computeUnits = .cpuAndGPU
        let reduceModel = try await MFasterM1v1DReduce.load(configuration: reduceConfig)
        
        // check if weights exist for model else throw since it means the model has not yet been trained
        guard let initialModelWeights: KeyModel.ModelWeights = dataController.inMemory_KeyModelGlobalControl.modelWeights else {
            throw KeyModelErrors.keyModelWeightsMissing
        }
        let keyModelInputSize = SentencepieceConstants.getKeyModelInputDimension(modelGroup: dataController.modelGroup)
        let keyModelBatchSize: Int = REConstants.KeyModelConstraints.defaultBatchSize
        let numberOfThreads = REConstants.KeyModelConstraints.numberOfThreads
        let learningRate: Float = 0.001  // placeholder
        
        let keyModelInstance = KeyModel(batchSize: keyModelBatchSize, numberOfThreads: numberOfThreads, numberOfClasses: dataController.numberOfClasses, keyModelInputSize: keyModelInputSize, numberOfFilterMaps: REConstants.ModelControl.keyModelDimension, learningRate: learningRate, initialModelWeights: initialModelWeights)
        
        guard let initialIndexModelWeights: KeyModel.ModelWeights = dataController.inMemory_KeyModelGlobalControl.indexModelWeights else {
            throw KeyModelErrors.indexModelWeightsMissing
        }
        let indexModelInstance = KeyModel(batchSize: keyModelBatchSize, numberOfThreads: numberOfThreads, numberOfClasses: dataController.numberOfClasses, keyModelInputSize: REConstants.ModelControl.keyModelDimension, numberOfFilterMaps: REConstants.ModelControl.indexModelDimension, learningRate: learningRate, initialModelWeights: initialIndexModelWeights)
        
        let chunkSize = batchSize //REConstants.ModelControl.forwardCacheAndSaveChunkSize
        for chunkIndex in stride(from: 0, to: documentArrayFull.count, by: chunkSize) {

            await MainActor.run {
                // update progress
                let _ = inferenceDatasetIds2InferenceProgress.updateValue(
                    InferenceProgress(datasetId: datasetId,
                                      totalDocuments: documentArrayFull.count,
                                      currentDocumentProgress: chunkIndex,
                                      inferenceProgressStatus: .inference),
                    forKey: datasetId)
            }
            
            if Task.isCancelled {
                throw MLForwardErrors.forwardPassWasCancelled
            }
            
            let startIndex = chunkIndex
            let endIndex = min(startIndex + chunkSize, documentArrayFull.count)
            
            let documentArray: [(id: String, document: String, prompt: String, attributes: [Float32])] = Array(documentArrayFull[startIndex..<endIndex])
            
            if documentArray.isEmpty {
                break
            }
            
            async let tokenizedDocumentDict = await dataController.tokenizer?.parallelTokenizationBySentenceWithPrompt(lines: documentArray.map { $0.document }, prompts: documentArray.map { $0.prompt } )
            async let multiTokenizedDocumentDict = await dataController.multiTokenizer?.parallelTokenizationBySentenceWithPrompt(lines: documentArray.map { $0.document }, prompts: documentArray.map { $0.prompt } )
            let tokenizations = try await [tokenizedDocumentDict, multiTokenizedDocumentDict]
            
            if let flanTokenization = tokenizations[0], let multiTokenization = tokenizations[1] {
                // Spliting this into macro batches -- forward + core data save to avoid memory pressure + if user cancels, so that partial progress is saved
                if Task.isCancelled {
                    throw MLForwardErrors.forwardPassWasCancelled
                }

                let sentenceIndexToOutputPredictionStructure = try await dataController.forwardInterpPassEncDecBatchDual_MFasterM1v1D(model: model, reduceModel: reduceModel, keyModel: keyModelInstance, indexModel: indexModelInstance, batchSize: batchSize, tokenizedInputDic: flanTokenization, multiTokenizedInputDic: multiTokenization, padId: dataController.tokenizer?.padId ?? TokenIdType(0), multiPadId: dataController.multiTokenizer?.padId ?? TokenIdType(0), batchAttributes: documentArray.map { $0.attributes })
                
                
                if Task.isCancelled {
                    throw MLForwardErrors.forwardPassWasCancelled
                }
                
                try await dataController.addOutputPredictionStructuresForExistingDocuments(documentArray: documentArray, tokenizedDocumentDict: flanTokenization, multiTokenizedDocumentDict: multiTokenization, sentenceIndexToOutputPredictionStructure: sentenceIndexToOutputPredictionStructure, moc: moc)
                
                /// no longer in-order; need ids
                // Unnecessary here, since count does not change.
                // try await dataController.updateInMemoryDatasetStats(moc: moc, dataController: dataController)
                //}
            }
        }
        
        await MainActor.run {
            // update progress
            let _ = inferenceDatasetIds2InferenceProgress.updateValue(
                InferenceProgress(datasetId: datasetId,
                                  totalDocuments: documentArrayFull.count,
                                  currentDocumentProgress: documentArrayFull.count,
                                  inferenceProgressStatus: .inference),
                forKey: datasetId)
        }
    }
}
