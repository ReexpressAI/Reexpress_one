//
//  DataController+Graphing.swift
//  Alpha1
//
//  Created by A on 9/16/23.
//

import Foundation
import CoreData

extension DataController {
    
    // In the current version, this is streamlined (e.g., document is an empty string), since full document information is displayed with a click that re-retrieves the managedObject to show in the document details navigator. We aim to keep this lightweight, to keep graph interactions smooth.
    // MARK: Note: for compositionCategory, access through the qdfCategory
    func getDataPointsForDatasetFromDatabaseAsUncertaintyStatisticsDatapoints(documentSelectionState: DocumentSelectionState, uncertaintyStatistics: UncertaintyStatistics, moc: NSManagedObjectContext) throws -> [String: UncertaintyStatistics.DataPoint] {
        //try await getCountResult(datasetId: datasetId, moc: moc)
        //let dataPoints = try await MainActor.run {
            // Another fecth to update the documents count. We re-fetch, because it is possible the user has uploaded duplicates.
            let fetchRequest = Document.fetchRequest()
            let compoundPredicate = try getFetchPredicateBasedOnDocumentSelectionState(documentSelectionState: documentSelectionState, moc: moc)
            
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: compoundPredicate)
            
            // Use default sorting, since these get re-sorted by the graph coordinator
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Document.id, ascending: true)]
            
            
            let documentRequest = try moc.fetch(fetchRequest)
            
            if documentRequest.isEmpty {
                throw CoreDataErrors.retrievalError
            }
            
            var dataPoints: [ String: UncertaintyStatistics.DataPoint ] = [:]
            
            for document in documentRequest {
                if let documentId = document.id, let uncertainty = document.uncertainty, uncertainty.uncertaintyModelUUID != nil, let qdfCategoryID = uncertainty.qdfCategoryID, let softmax = uncertainty.softmax?.toArray(type: Float32.self), document.prediction < softmax.count, let qCategory = uncertaintyStatistics.getQCategory(q: uncertainty.q) {
                    
                    let distanceCategory = uncertaintyStatistics.getDistanceCategory(prediction: document.prediction, qCategory: qCategory, d0: uncertainty.d0)
                    
                    let documentQDFCategory: UncertaintyStatistics.QDFCategory? = UncertaintyStatistics.QDFCategory.initQDFCategoryFromIdString(idString: qdfCategoryID)
                    
                    let documentText = ""
                    // Note that compositionCategory is .null and calibratedOutput is nil -- access via qdfCategory
                    let dataPoint = UncertaintyStatistics.DataPoint(id: documentId, label: document.label, prediction: document.prediction, softmax: softmax, d0: uncertainty.d0, q: uncertainty.q, topKdistances: [], topKIndexesAsDocumentIds: [], qCategory: qCategory, calibratedOutput: nil, compositionCategory: .null,  distanceCategory: distanceCategory, qdfCategory: documentQDFCategory, document: documentText,featureMatchesDocLevelSentenceRangeStart: -1, featureMatchesDocLevelSentenceRangeEnd: -1
                    )
                    
                    dataPoints[documentId] = dataPoint
                    
                }
            }
            
            return dataPoints
//        }
//        return dataPoints
    }
    
}
