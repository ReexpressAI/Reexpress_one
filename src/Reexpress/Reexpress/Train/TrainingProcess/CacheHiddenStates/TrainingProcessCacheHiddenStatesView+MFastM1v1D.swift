//
//  TrainingProcessCacheHiddenStatesView+MFastM1v1D.swift
//  Alpha1
//
//  Created by A on 7/25/23.
//

import SwiftUI
import CoreML

extension TrainingProcessCacheHiddenStatesView {
    func cacheHiddenStates_MFastM1v1D(batchSize: Int, datasetId: Int) async throws {
        // First, find uncached documents
        
        let start = Date.now

        let documentArrayFull = try await dataController.getJSONDocumentArrayFromDatabaseOnlyUncached(datasetId: datasetId, moc: moc, onlyLabeled: true)

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
            if datasetId == REConstants.DatasetsEnum.train.rawValue {
                totalTraining = documentArrayFull.count
            } else if datasetId == REConstants.DatasetsEnum.calibration.rawValue {
                totalCalibration = documentArrayFull.count
            }
        }
        
        let config = MLModelConfiguration()
        // Directly set cpu and gpu, as we want GPU on the targeted M1 Max and better with Float32, as opposed to the ANE
        config.computeUnits = .cpuAndGPU
        let model = try await MFastM1v1D.load(configuration: config)
        let reduceConfig = MLModelConfiguration()
        reduceConfig.computeUnits = .cpuAndGPU
        let reduceModel = try await MFastM1v1DReduce.load(configuration: reduceConfig)
        
        let chunkSize = batchSize //REConstants.ModelControl.forwardCacheAndSaveChunkSize
        for chunkIndex in stride(from: 0, to: documentArrayFull.count, by: chunkSize) {
            //print("Proccessing chunkIndex: \(chunkIndex)")
            await MainActor.run {
                if datasetId == REConstants.DatasetsEnum.train.rawValue {
                    currentTraining = chunkIndex
                } else if datasetId == REConstants.DatasetsEnum.calibration.rawValue {
                    currentCalibration = chunkIndex
                }
            }
            
            if Task.isCancelled {
                break
            }
            
            let startIndex = chunkIndex
            let endIndex = min(startIndex + chunkSize, documentArrayFull.count)
            let documentArray: [(id: String, document: String, prompt: String)] = Array(documentArrayFull[startIndex..<endIndex])
            
            if documentArray.isEmpty {
                break
            }
            
            async let tokenizedDocumentDict = await dataController.tokenizer?.parallelTokenizationBySentenceWithPrompt(lines: documentArray.map { $0.document }, prompts: documentArray.map { $0.prompt } )
            async let multiTokenizedDocumentDict = await dataController.multiTokenizer?.parallelTokenizationBySentenceWithPrompt(lines: documentArray.map { $0.document }, prompts: documentArray.map { $0.prompt } )
            let tokenizations = try await [tokenizedDocumentDict, multiTokenizedDocumentDict]

            if let flanTokenization = tokenizations[0], let multiTokenization = tokenizations[1] {
                // Spliting this into macro batches -- forward + core data save to avoid memory pressure + if user cancels, so that partial progress is saved
                if Task.isCancelled {
                    break
                }
                
                let sentenceIndexToEmbeddings = try await dataController.forwardPassEncDecSimpleBatchDual_MFastM1v1D(model: model, reduceModel: reduceModel, batchSize: batchSize, tokenizedInputDic: flanTokenization, multiTokenizedInputDic: multiTokenization, padId: dataController.tokenizer?.padId ?? TokenIdType(0), multiPadId: dataController.multiTokenizer?.padId ?? TokenIdType(0))
                
                if Task.isCancelled {
                    break
                }
                
                /// no longer in-order; need ids
                try await dataController.addEmbeddingsForExistingDocuments(documentArray: documentArray, sentenceIndexToEmbeddings: sentenceIndexToEmbeddings, moc: moc)
                // Unnecessary here, since count does not change.
                // try await dataController.updateInMemoryDatasetStats(moc: moc, dataController: dataController)
                //}
            }
        }
        
        print("Duration of Cache: \(Date.now.timeIntervalSince(start))")
    }
}


/*
 3414+1583
 chunk 10_000; batch 1000
 peak memory at 54.31
 Duration of Cache: 481.7191250324249
 Proccessing chunkIndex: 0
 Duration of Cache: 229.10890400409698
 
 3414+1583
 chunk 1000; batch 1000
 peak memory at 43.2
 Duration of Cache: 469.6426589488983
 Proccessing chunkIndex: 0
 Proccessing chunkIndex: 1000
 Duration of Cache: 230.24115598201752
 
 */
