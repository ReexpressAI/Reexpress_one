//
//  DataController+MatchingUtilities.swift
//  Alpha1
//
//  Created by A on 9/13/23.
//

import Foundation
import CoreData

extension DataController {
    
    // Handles the case when the support id has disappeared from training (either due to deletion or transfer). In these cases, the original ranks are still maintained via documentIdToOriginalRank. The user will see a gap. However, we do not currently check on a per-document basis if the label or prediction changed for a support ID (after uncertainty was calculated for the document).
    func getMatchedManagedObjectsForOneDocumentFromTopK(supportDatasetId: Int, topKdistances: [Float32], topKIndexesAsDocumentIds: [String], moc: NSManagedObjectContext) throws -> (documentObjects: [Document], documentIdToOriginalRank: [String: Int], documentId2queryDistance: [String: Float32]) {
        
        var documentObjects: [Document] = []
        var documentId2queryDistance: [String: Float32] = [:]
        var documentIdToOriginalRank: [String: Int] = [:]
                
        let fetchRequest = Document.fetchRequest()
        // Document must be in its expected dataset to be considered here. This typically only makes a difference for training: We do this so that we do not return training instances that have been transferred since topKIndexesAsDocumentIds was archived in the database. It typically does not matter for matching to other datasets, since in those cses, topKIndexesAsDocumentIds is typically retrieved immeidately before calling this method.
        fetchRequest.predicate = NSPredicate(format: "dataset.id == %@ && id in %@", NSNumber(value: supportDatasetId), topKIndexesAsDocumentIds)
        
        let documentRequest = try moc.fetch(fetchRequest)
        
        if documentRequest.isEmpty {
            throw MatchingErrors.topKIndexesMissing
        }
        // re-sort to ensure in top-k order (additionally, some original indexes may be missing):
        var documentId2DocumentObject: [String: Document] = [:]
        for documentObject in documentRequest {
            if let id = documentObject.id {
                documentId2DocumentObject[id] = documentObject
            }
        }
        
        for (originalRank, topKIndexesAsDocumentId) in topKIndexesAsDocumentIds.enumerated() {
            if let documentObj = documentId2DocumentObject[topKIndexesAsDocumentId] {
                
                if originalRank < topKdistances.count {
                    documentIdToOriginalRank[topKIndexesAsDocumentId] = originalRank
                    documentId2queryDistance[topKIndexesAsDocumentId] = topKdistances[originalRank]
                    documentObjects.append(documentObj)
                }
            }
        }
        
        return (documentObjects: documentObjects, documentIdToOriginalRank: documentIdToOriginalRank, documentId2queryDistance: documentId2queryDistance)
    }
    
    func getExemplarDataFromOneFetchedManagedObject(modelControlIdString: String, document: Document) throws -> [String: (label: Int, prediction: Int, exemplar: [Float32], softmax: [Float32])] {
        
        var predictionOutput: [String: (label: Int, prediction: Int, exemplar: [Float32], softmax: [Float32])] = [:]
        
        if modelControlIdString == REConstants.ModelControl.indexModelId {
            if let dataAsArray: [Float32] = document.exemplar?.exemplarCompressed?.toArray(type: Float32.self), let documentId = document.id, let softmax = document.uncertainty?.softmax?.toArray(type: Float32.self) {
                predictionOutput[documentId] =
                (label: document.label, prediction: document.prediction, exemplar: dataAsArray, softmax: softmax)
            }
        } else if modelControlIdString == REConstants.ModelControl.keyModelId {
            if let dataAsArray: [Float32] = document.exemplar?.exemplar?.toArray(type: Float32.self), let documentId = document.id, let softmax = document.uncertainty?.softmax?.toArray(type: Float32.self) {
                predictionOutput[documentId] =
                (label: document.label, prediction: document.prediction, exemplar: dataAsArray, softmax: softmax)
            }
        } else {
            throw CoreDataErrors.retrievalError
        }
        
        return predictionOutput
        
    }
    
    /// Retrieve matches between a documentId and a datasplit. If the documentId is in the datasplit, we do not include self in the returned results. (An exact match could still occur, but only if it is associated with another documentId.) This assumes the exemplar data has already been generated.
    // MARK: - Note: Currently we always use the keyModel rather than the compressed indexModel.
    func getTopKForNearestMatchesForOneDocument(queryDocumentId: String, queryOutput: [String: (label: Int, prediction: Int, exemplar: [Float32], softmax: [Float32])], datasetIdToMatchAgainst: Int, moc: NSManagedObjectContext) async throws -> (topKdistances: [Float32], topKIndexesAsDocumentIds: [String]) {
        var matchingData = try await getExemplarDataFromDatabase(modelControlIdString: REConstants.ModelControl.keyModelId, datasetId: datasetIdToMatchAgainst, moc: moc)
        // Remove queryDocumentId if it is present in matchingData
        matchingData.removeValue(forKey: queryDocumentId)
        
        let queryToUncertaintyStructure = try await runForwardIndex(query: queryOutput, support: matchingData)
        guard let nearestMatchesStructure = queryToUncertaintyStructure[queryDocumentId] else {
            throw CoreDataErrors.retrievalError
        }
        
        return (topKdistances: nearestMatchesStructure.topKdistances, topKIndexesAsDocumentIds: nearestMatchesStructure.topKIndexesAsDocumentIds)
    }
    
    func generalMatchingTraining(documentMatchingState: DocumentMatchingState, queryDocumentObject: Document, moc: NSManagedObjectContext) throws -> (documentObjects: [Document], documentIdToOriginalRank: [String: Int], documentId2queryDistance: [String: Float32]) {
        
        // main actor
        if documentMatchingState.selectedDatasetIdToMatch == REConstants.DatasetsEnum.train.rawValue && !documentMatchingState.reIndexTraining {
            guard let topKIndexesAsDocumentIds = queryDocumentObject.uncertainty?.topKIndexesAsDocumentIds, let topKdistances = queryDocumentObject.uncertainty?.topKdistances?.toArray(type: Float32.self), topKIndexesAsDocumentIds.count == topKdistances.count else {
                throw MatchingErrors.topKIndexesMissing
            }
            return try getMatchedManagedObjectsForOneDocumentFromTopK(supportDatasetId: REConstants.DatasetsEnum.train.rawValue, topKdistances: topKdistances, topKIndexesAsDocumentIds: topKIndexesAsDocumentIds, moc: moc)
        }
        throw MatchingErrors.topKIndexesMissing
    }
}


