//
//  ForwardWithInterpretability+ForwardIndex.swift
//  Alpha1
//
//  Created by A on 8/3/23.
//

import SwiftUI
import CoreML

extension MainForwardAfterTrainingView {
    func batchForwardIndex(datasetId: Int, chunkSize: Int = 1000, query: [String: (label: Int, prediction: Int, exemplar: [Float32], softmax: [Float32])], support: [String: (label: Int, prediction: Int, exemplar: [Float32], softmax: [Float32])]) async throws {

        let documentIds = Array(query.keys)
        for chunkIndex in stride(from: 0, to: documentIds.count, by: chunkSize) {
            await MainActor.run {
                // update progress
                let _ = inferenceDatasetIds2InferenceProgress.updateValue(
                    InferenceProgress(datasetId: datasetId,
                                      totalDocuments: documentIds.count,
                                      currentDocumentProgress: chunkIndex,
                                      inferenceProgressStatus: .indexing),
                    forKey: datasetId)
            }
            if Task.isCancelled {
                throw MLForwardErrors.forwardPassWasCancelled
            }
            var dataChunk: [String: (label: Int, prediction: Int, exemplar: [Float32], softmax: [Float32])] = [:]
            
            let startIndex = chunkIndex
            let endIndex = min(startIndex + chunkSize, documentIds.count)
            let documentIdsChunkArray: [String] = Array(documentIds[startIndex..<endIndex])
            
            if documentIdsChunkArray.isEmpty {
                break
            }
            for documentId in documentIdsChunkArray {
                dataChunk[documentId] = query[documentId]
            }
            let queryToUncertaintyStructure = try await dataController.runForwardIndex(query: dataChunk, support: support)
            
            try await dataController.addUncertaintyStructureForDataset(datasetId: datasetId, queryToUncertaintyStructure: queryToUncertaintyStructure, moc: moc)
        }
        
        await MainActor.run {
            // update progress
            let _ = inferenceDatasetIds2InferenceProgress.updateValue(
                InferenceProgress(datasetId: datasetId,
                                  totalDocuments: documentIds.count,
                                  currentDocumentProgress: documentIds.count,
                                  inferenceProgressStatus: .indexing),
                forKey: datasetId)
        }
    }
}
