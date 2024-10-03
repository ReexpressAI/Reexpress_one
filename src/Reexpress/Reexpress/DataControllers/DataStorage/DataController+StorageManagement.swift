//
//  DataController+StorageManagement.swift
//  Alpha1
//
//  Created by A on 9/1/23.
//

import Foundation
import CoreData

extension DataController {
    // Also includes a diff with additional needed. This is used in the Training setup.
    func estimateCacheSizeIncludingAdditionalDiffTrainingAndCalibration() async throws -> (cacheToClearDatasetIds2EstimateTotalSize: [Int: Double], cacheToClearDatasetIds2EstimateAdditionalSize: [Int: Double]) {
        
        let datasetIDs = [REConstants.DatasetsEnum.train.rawValue, REConstants.DatasetsEnum.calibration.rawValue]
        var cacheToClearDatasetIds2EstimateTotalSize: [Int: Double] = [:]
        var cacheToClearDatasetIds2EstimateAdditionalSize: [Int: Double] = [:]
        
        let taskContext = newTaskContext()
        let localModelGroup: SentencepieceConstants.ModelGroup = modelGroup  // published var, so unclear if can send to background safely, so we use a temp copy
        try taskContext.performAndWait {
            for datasetID in datasetIDs {
                let fetchRequest = Document.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "dataset.id == %@ && label != %@ && label != %@", NSNumber(value: datasetID), NSNumber(value: REConstants.DataValidator.oodLabel), NSNumber(value: REConstants.DataValidator.unlabeledLabel))
                let totalCount = try taskContext.count(for: fetchRequest)
                if totalCount > 0 {
                    cacheToClearDatasetIds2EstimateTotalSize[datasetID] = REConstants.StorageEstimates.estimateCacheSize(numberOfDocuments: totalCount, modelGroup: localModelGroup)
                    
                    let fetchRequestCurrent = Document.fetchRequest()
                    fetchRequestCurrent.predicate = NSPredicate(format: "embedding != nil && dataset.id == %@", NSNumber(value: datasetID))
                    let currentCount = try taskContext.count(for: fetchRequestCurrent)
                    cacheToClearDatasetIds2EstimateAdditionalSize[datasetID] = REConstants.StorageEstimates.estimateCacheSize(numberOfDocuments: max(0, totalCount-currentCount), modelGroup: localModelGroup)
                }
            }
        }
        if Task.isCancelled {  // not really necessary here, since just immediately returns
            throw CoreDataErrors.cacheClearTaskCancelled
        }
        return (cacheToClearDatasetIds2EstimateTotalSize: cacheToClearDatasetIds2EstimateTotalSize, cacheToClearDatasetIds2EstimateAdditionalSize: cacheToClearDatasetIds2EstimateAdditionalSize)
    }
    
    func estimateCacheSize(cacheToClearDatasetIds: Set<Int>) async throws -> [Int: Double] {
    
        var cacheToClearDatasetIds2EstimateSize: [Int: Double] = [:]
        
        let taskContext = newTaskContext()
        let localModelGroup: SentencepieceConstants.ModelGroup = modelGroup  // published var, so unclear if can send to background safely, so we use a temp copy
        try taskContext.performAndWait {
            for datasetID in cacheToClearDatasetIds {
                let fetchRequest = Document.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "embedding != nil && dataset.id == %@", NSNumber(value: datasetID))
                let count = try taskContext.count(for: fetchRequest)
                if count > 0 {
                    cacheToClearDatasetIds2EstimateSize[datasetID] = REConstants.StorageEstimates.estimateCacheSize(numberOfDocuments: count, modelGroup: localModelGroup)
                }
            }
        }
        if Task.isCancelled {  // not really necessary here, since just immediately returns
            throw CoreDataErrors.cacheClearTaskCancelled
        }
        return cacheToClearDatasetIds2EstimateSize
    }
    func deleteEmbeddingForDatasets(cacheToClearDatasetIds: Set<Int>) async throws {

        let taskContext = newTaskContext()
        try taskContext.performAndWait {  // be careful with control flow with .perform since it immediately returns (asynchronous)
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Embedding")
            
            request.predicate = NSPredicate(format: "document.dataset.id in %@", Array(cacheToClearDatasetIds))
//            let count = try taskContext.count(for: request)
//            print(count)
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: request)
            batchDeleteRequest.resultType = .resultTypeCount
            let _ = try taskContext.execute(batchDeleteRequest) as? NSBatchDeleteResult
        }
        if Task.isCancelled { 
            throw CoreDataErrors.cacheClearTaskCancelled
        }
    }
    
    func estimateInferenceSize(inferenceDatasetIds: Set<Int>) async throws -> (inferenceDatasetIds2EstimateTotalSize: [Int: Double], inferenceDatasetIds2EstimateAdditionalSize: [Int: Double]) {
    
        var inferenceDatasetIds2EstimateTotalSize: [Int: Double] = [:]
        var inferenceDatasetIds2EstimateAdditionalSize: [Int: Double] = [:]
        
        let taskContext = newTaskContext()
        let localModelGroup: SentencepieceConstants.ModelGroup = modelGroup  // published var, so unclear if can send to background safely, so we use a temp copy
//        let indexModelUUID = inMemory_KeyModelGlobalControl.indexModelUUID
//        let defaultIndexModelUUID = REConstants.ModelControl.defaultIndexModelUUID
        try taskContext.performAndWait {
            for datasetID in inferenceDatasetIds {
                let fetchRequest = Document.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "dataset.id == %@", NSNumber(value: datasetID))
                let count = try taskContext.count(for: fetchRequest)
                if count > 0 {
                    inferenceDatasetIds2EstimateTotalSize[datasetID] = REConstants.StorageEstimates.estimatePredictSizeExcludingCache(numberOfDocuments: count, modelGroup: localModelGroup)
                    
                    let fetchRequestAdditional = Document.fetchRequest()
//                    fetchRequestAdditional.predicate = NSPredicate(format: "dataset.id == %@ && modelUUID != %@ && modelUUID != %@", NSNumber(value: datasetID), defaultIndexModelUUID, indexModelUUID)
                    fetchRequestAdditional.predicate = NSPredicate(format: "dataset.id == %@ && exemplar.exemplarCompressed == nil", NSNumber(value: datasetID))
                    let countAdditional = try taskContext.count(for: fetchRequestAdditional)
                    inferenceDatasetIds2EstimateAdditionalSize[datasetID] = REConstants.StorageEstimates.estimatePredictSizeExcludingCache(numberOfDocuments: countAdditional, modelGroup: localModelGroup)
                }
            }
        }
        return (inferenceDatasetIds2EstimateTotalSize: inferenceDatasetIds2EstimateTotalSize, inferenceDatasetIds2EstimateAdditionalSize: inferenceDatasetIds2EstimateAdditionalSize)
    }
}
