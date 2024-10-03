//
//  REConstants+StorageEstimates.swift
//  Alpha1
//
//  Created by A on 9/1/23.
//

import Foundation

extension REConstants {
    struct StorageEstimates {
        static func estimateCacheSize(numberOfDocuments: Int, modelGroup: SentencepieceConstants.ModelGroup) -> Double {
            let slackMultiplicativeFactor: Double = 2.0
            switch modelGroup {
            case .Fast:
                let mbPerDocumentEmbeddingEstimate: Double = 66.0 / 4997.0
                return Double(numberOfDocuments) * mbPerDocumentEmbeddingEstimate * slackMultiplicativeFactor
            case .Faster:
                let mbPerDocumentEmbeddingEstimate: Double = 41.1 / 4997.0
                return Double(numberOfDocuments) * mbPerDocumentEmbeddingEstimate * slackMultiplicativeFactor
            case .Fastest:
                let mbPerDocumentEmbeddingEstimate: Double = 35.1 / 4997.0
                return Double(numberOfDocuments) * mbPerDocumentEmbeddingEstimate * slackMultiplicativeFactor
            }
        }
        static func estimatePredictSizeExcludingCache(numberOfDocuments: Int, modelGroup: SentencepieceConstants.ModelGroup) -> Double {
            // Currently this is the same regardless of modelGroup since the exemplars and related embeddings are the same dimension regardless of the underlying model:
            let slackMultiplicativeFactor: Double = 2.5
            let mbPerDocumentEmbeddingEstimate: Double = 124.9 / 10_000.0 //173.6 / 14250.0
            return Double(numberOfDocuments) * mbPerDocumentEmbeddingEstimate * slackMultiplicativeFactor
        }
        
        static func getEstimatedDataSizeForDisplay(datasetId: Int, datasetId2EstimatedSize: [Int: Double]) -> String {
            if let estimateStorage = datasetId2EstimatedSize[datasetId] {
                if estimateStorage > 0.0 && estimateStorage < 1.0 {
                    return "<1 MB"
                } else {
                    let noDecimals = String(format: "%.0f", estimateStorage)
                    return "\(noDecimals) MB"
                }
            } else {
                return "0 MB"
            }
        }
    }
}
