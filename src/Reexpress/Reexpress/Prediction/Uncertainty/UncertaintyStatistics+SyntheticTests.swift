//
//  UncertaintyStatistics+SyntheticTests.swift
//  Alpha1
//
//  Created by A on 7/30/23.
//

import Foundation
import CoreData
import CoreML
import Accelerate

// Synthetic data for tests
extension UncertaintyStatistics {
    func getUncertaintyStructureForDatasetFromDatabaseOnlyKnownValidLabelsSynthetic(datasetId: Int, numberOfClasses: Int, moc: NSManagedObjectContext, totalPoints: Int) async throws -> [Int: [(documentId: String, prediction: Int, softmax: [Float32], d0: Float32, q: Int)]] {
        
        // retrieve uncertainty structure for points with valid known labels (only 0..<numberOfClasses) from the database
        let uncertaintyStructureByTrueClass = try await MainActor.run {

            let fetchRequest = Dataset.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", NSNumber(value: datasetId))
            //            fetchRequest.propertiesToFetch = ["documents"]
            let datasetRequest = try moc.fetch(fetchRequest) //as [Dataset]
            
            if datasetRequest.isEmpty {
                throw CoreDataErrors.retrievalError
            }
            let dataset = datasetRequest[0]
            
            var uncertaintyStructureByTrueClass: [Int: [(documentId: String, prediction: Int, softmax: [Float32], d0: Float32, q: Int)]] = [:]
            for label in 0..<numberOfClasses {
                uncertaintyStructureByTrueClass[label] = []
            }
            
            // Importantly, note that dataset.documents is not sorted and in practice, is not consistently sorted across fetches even with the same database data.
            var documentCount = 0
            if let documents = dataset.documents {
                for document in documents {
                    if let documentId = document.id, let uncertainty = document.uncertainty, let softmax = uncertainty.softmax?.toArray(type: Float32.self) {
                        let label = document.label
                        if DataController.isKnownValidLabel(label: label, numberOfClasses: numberOfClasses) {
                            uncertaintyStructureByTrueClass[label]?.append(
                                (documentId: documentId, prediction: document.prediction, softmax: softmax, d0: uncertainty.d0, q: uncertainty.q)
                            )
                            documentCount += 1
                        }
                    }
                }
            }
            
            if documentCount < totalPoints {
                // augment with additional points
                let additionalPointsNeeded = totalPoints - documentCount
                for _ in 0..<additionalPointsNeeded {
                    if let randomLabel = uncertaintyStructureByTrueClass.keys.randomElement(), let dataPoint = uncertaintyStructureByTrueClass[randomLabel]?.randomElement() {
                        uncertaintyStructureByTrueClass[randomLabel]?.append(
                            (documentId: dataPoint.documentId, prediction: dataPoint.prediction, softmax: dataPoint.softmax, d0: dataPoint.d0, q: dataPoint.q)
                        )
                    }
                }
            }
            
            return uncertaintyStructureByTrueClass
        }
        return uncertaintyStructureByTrueClass
    }
    
    func getDataPointsForDatasetFromDatabaseSynthetic(datasetId: Int, numberOfClasses: Int, moc: NSManagedObjectContext, totalPoints: Int) async throws -> [ String: DataPoint ] { //}, overallRangePoint: (minD0DataPointId: String, maxD0DataPointId: String)? ) {
        
        // retrieve uncertainty structure for points with valid known labels (only 0..<numberOfClasses) from the database
        let dataPointsResult = try await MainActor.run {
            
            // Another fecth to update the documents count. We re-fetch, because it is possible the user has uploaded duplicates.
            let fetchRequest = Dataset.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", NSNumber(value: datasetId))
            //            fetchRequest.propertiesToFetch = ["documents"]
            let datasetRequest = try moc.fetch(fetchRequest) //as [Dataset]
            
            if datasetRequest.isEmpty {
                throw CoreDataErrors.retrievalError
            }
            let dataset = datasetRequest[0]
            
            var dataPoints: [ String: DataPoint ] = [:]
            //            var minD0Point: (d0: Float32, dataPointId: String)?
            //            var maxD0Point: (d0: Float32, dataPointId: String)?
            
            //            var overallRangePoint: (minD0DataPointId: String, maxD0DataPointId: String)?
            // Importantly, note that dataset.documents is not sorted and in practice, is not consistently sorted across fetches even with the same database data.
            if let documents = dataset.documents {
                for document in documents {
                    if let documentId = document.id, let uncertainty = document.uncertainty, let softmax = uncertainty.softmax?.toArray(type: Float32.self), let qCategory = getQCategory(q: uncertainty.q), var documentText = document.document, let topKdistances = uncertainty.topKdistances?.toArray(type: Float32.self) { //}, let topKIndexesAsDocumentIds = uncertainty.topKIndexesAsDocumentIds?.toArray(type: String.self) {
                        //UPDATE TO GET CALIBRATED OUTPUT IF IT EXISTS
                        var topKIndexesAsDocumentIds: [String] = []
                        
                        if let topKIndexesAsDocumentIds_fromDB = uncertainty.topKIndexesAsDocumentIds {
                            topKIndexesAsDocumentIds = topKIndexesAsDocumentIds_fromDB
                        }
                        let distanceCategory = getDistanceCategory(prediction: document.prediction, qCategory: qCategory, d0: uncertainty.d0)
                        // MARK: temp Cat document and prompt
                        if let prompt = document.prompt {
                            if !prompt.isEmpty {
                                documentText = prompt + " " + documentText
                            }
                        }
                        let dataPoint = DataPoint(id: documentId, label: document.label, prediction: document.prediction, softmax: softmax, d0: uncertainty.d0, q: uncertainty.q, topKdistances: topKdistances, topKIndexesAsDocumentIds: topKIndexesAsDocumentIds, qCategory: qCategory, calibratedOutput: nil, compositionCategory: .null,  distanceCategory: distanceCategory, document: documentText,
                            featureMatchesDocLevelSentenceRangeStart: document.featureMatchesDocLevelSentenceRangeStart,
                            featureMatchesDocLevelSentenceRangeEnd: document.featureMatchesDocLevelSentenceRangeEnd
                        )
                        
                        
                        
                        dataPoints[documentId] = dataPoint
                        
                    }
                }
            }
            if dataPoints.count < totalPoints {
                // augment with additional points
                let additionalPointsNeeded = totalPoints - dataPoints.count
                for _ in 0..<additionalPointsNeeded {
                    if let documentId = dataPoints.keys.randomElement(), let dataPoint = dataPoints[documentId] {
                        let newDocumentId = UUID().uuidString
                        let newDataPoint = DataPoint(id: newDocumentId, label: dataPoint.label, prediction: dataPoint.prediction, softmax: dataPoint.softmax, d0: dataPoint.d0, q: dataPoint.q, topKdistances: dataPoint.topKdistances, topKIndexesAsDocumentIds: dataPoint.topKIndexesAsDocumentIds, qCategory: dataPoint.qCategory, calibratedOutput: nil, compositionCategory: .null,  distanceCategory: dataPoint.distanceCategory, document: dataPoint.document,
                                                     featureMatchesDocLevelSentenceRangeStart: dataPoint.featureMatchesDocLevelSentenceRangeStart,
                                                     featureMatchesDocLevelSentenceRangeEnd: dataPoint.featureMatchesDocLevelSentenceRangeEnd
                        )
                        dataPoints[newDocumentId] = newDataPoint
                    }
                }
            }
            return dataPoints
        }
        return dataPointsResult
    }
}
