//
//  UncertaintyStatistics+CalibrateNewData.swift
//  Alpha1
//
//  Created by A on 4/24/23.
//

import Foundation
import CoreData
import CoreML
import Accelerate

extension UncertaintyStatistics {
    
    func getDataPointIdsForDatasetFromDatabaseViaSearch(searchParameters: SearchParameters, moc: NSManagedObjectContext) async throws -> Set<String> {
        return Set<String>()
        
        /*// retrieve uncertainty structure for points with valid known labels (only 0..<numberOfClasses) from the database
        let dataPointIdsResult = try await MainActor.run {
            
            guard let datasetId = searchParameters.searchDatasetId, searchParameters.searchText != "" else {
                return Set<String>()
            }
            
            //let fetchRequest = Document.fetchRequest()
            //NSFetchRequest<NSDictionary>(entityName: "GuestsTable")
            //NSFetchRequest<Document>(entityName: "Document")
            let fetchRequest = NSFetchRequest<NSDictionary>(entityName: "Document")
            
            if searchParameters.exactMatchSearch {
                if searchParameters.caseSensitiveSearch {
                    switch searchParameters.searchField {
                    case "document":
                        fetchRequest.predicate = NSPredicate(format: "dataset.id == %@ && document CONTAINS %@", NSNumber(value: datasetId), searchParameters.searchText)
                    case "group":
                        fetchRequest.predicate = NSPredicate(format: "dataset.id == %@ && group CONTAINS %@", NSNumber(value: datasetId), searchParameters.searchText)
                    case "meta":
                        fetchRequest.predicate = NSPredicate(format: "dataset.id == %@ && info CONTAINS %@", NSNumber(value: datasetId), searchParameters.searchText)
                    case "id":
                        fetchRequest.predicate = NSPredicate(format: "dataset.id == %@ && id CONTAINS %@", NSNumber(value: datasetId), searchParameters.searchText)
                    default:
                        return Set<String>()
                    }
                } else {  // Note: Also diacritics insensitive
                    switch searchParameters.searchField {
                    case "document":
                        fetchRequest.predicate = NSPredicate(format: "dataset.id == %@ && document CONTAINS[cd] %@", NSNumber(value: datasetId), searchParameters.searchText)
                    case "group":
                        fetchRequest.predicate = NSPredicate(format: "dataset.id == %@ && group CONTAINS[cd] %@", NSNumber(value: datasetId), searchParameters.searchText)
                    case "meta":
                        fetchRequest.predicate = NSPredicate(format: "dataset.id == %@ && info CONTAINS[cd] %@", NSNumber(value: datasetId), searchParameters.searchText)
                    case "id":
                        fetchRequest.predicate = NSPredicate(format: "dataset.id == %@ && id CONTAINS[cd] %@", NSNumber(value: datasetId), searchParameters.searchText)
                    default:
                        return Set<String>()
                    }
                }
            } else { // must be regex
                switch searchParameters.searchField {
                case "document":
                    fetchRequest.predicate = NSPredicate(format: "dataset.id == %@ && document MATCHES %@", NSNumber(value: datasetId), searchParameters.searchText)
                case "group":
                    fetchRequest.predicate = NSPredicate(format: "dataset.id == %@ && group MATCHES %@", NSNumber(value: datasetId), searchParameters.searchText)
                case "meta":
                    fetchRequest.predicate = NSPredicate(format: "dataset.id == %@ && info MATCHES %@", NSNumber(value: datasetId), searchParameters.searchText)
                case "id":
                    fetchRequest.predicate = NSPredicate(format: "dataset.id == %@ && id MATCHES %@", NSNumber(value: datasetId), searchParameters.searchText)
                default:
                    return Set<String>()
                }
            }
            fetchRequest.resultType = .dictionaryResultType
            fetchRequest.propertiesToFetch = ["id"] //NSPropertyDescriptions[#keyPath(Document.id)]
            
            let documentDictionaryRequest = try moc.fetch(fetchRequest) // this is an array of dictionaries
            
            if documentDictionaryRequest.isEmpty {
                return Set<String>()
            }
            
            var dataPointIds = Set<String>()
            for dataPointDictionary in documentDictionaryRequest {
                if let dataPointId = dataPointDictionary["id"] as? String {
                    dataPointIds.insert(dataPointId)
                }
            }
            
            return dataPointIds
        }
        
        return dataPointIdsResult*/
    }
    
    
    /// This differs from getTrainingDataPointsFromDatabase() in that we return q/etc.
    /// MARK: -TODO: Currently this is not complete, because the calibrated output is not being returned
    func getNearestMatchingDataPointsFromDatabase(topKIndexesAsDocumentIds: [String]?, numberOfClasses: Int, moc: NSManagedObjectContext) async throws -> [ String: DataPoint ] {
        
        // retrieve uncertainty structure for points with valid known labels (only 0..<numberOfClasses) from the database
        let dataPointsResult = try await MainActor.run {
            var dataPoints: [ String: DataPoint ] = [:]
            
            guard let topKIndexesAsDocumentIds = topKIndexesAsDocumentIds else {
                throw CoreDataErrors.retrievalError
            }
            
            let fetchRequest = Document.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id in %@", topKIndexesAsDocumentIds)
            
            let documents = try moc.fetch(fetchRequest)
            
            if documents.isEmpty {
                throw CoreDataErrors.retrievalError
            }
            
            // Importantly, note that dataset.documents is not sorted and in practice, is not consistently sorted across fetches even with the same database data.
            for document in documents {
                if let documentId = document.id, let uncertainty = document.uncertainty, let softmax = uncertainty.softmax?.toArray(type: Float32.self), let qCategory = getQCategory(q: uncertainty.q), let documentText = document.document, let topKdistances = uncertainty.topKdistances?.toArray(type: Float32.self) { //}, let topKIndexesAsDocumentIds = uncertainty.topKIndexesAsDocumentIds?.toArray(type: String.self) {
                    //UPDATE TO GET CALIBRATED OUTPUT IF IT EXISTS
                    var topKIndexesAsDocumentIds: [String] = []
                    
                    if let topKIndexesAsDocumentIds_fromDB = uncertainty.topKIndexesAsDocumentIds {
                        topKIndexesAsDocumentIds = topKIndexesAsDocumentIds_fromDB
                    }
                    let distanceCategory = getDistanceCategory(prediction: document.prediction, qCategory: qCategory, d0: uncertainty.d0)
                    let dataPoint = DataPoint(id: documentId, label: document.label, prediction: document.prediction, softmax: softmax, d0: uncertainty.d0, q: uncertainty.q, topKdistances: topKdistances, topKIndexesAsDocumentIds: topKIndexesAsDocumentIds, qCategory: qCategory, calibratedOutput: nil, compositionCategory: .null,  distanceCategory: distanceCategory, document: documentText,
                                              
                                              featureMatchesDocLevelSentenceRangeStart: document.featureMatchesDocLevelSentenceRangeStart,
                                              featureMatchesDocLevelSentenceRangeEnd: document.featureMatchesDocLevelSentenceRangeEnd
                    )
                    
                    dataPoints[documentId] = dataPoint
                    
                }
            }
            return dataPoints
        }
        return dataPointsResult
    }
    // Data is assumed to be uncalibrated at this point:
    func getDataPointsForDatasetFromDatabase(datasetId: Int, numberOfClasses: Int, moc: NSManagedObjectContext, returnAllData: Bool = true) async throws -> [ String: DataPoint ] {
        
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

            // Importantly, note that dataset.documents is not sorted and in practice, is not consistently sorted across fetches even with the same database data.
            if let documents = dataset.documents {
                for document in documents {
                    if let documentId = document.id, let uncertainty = document.uncertainty, let softmax = uncertainty.softmax?.toArray(type: Float32.self), let qCategory = getQCategory(q: uncertainty.q), let topKdistances = uncertainty.topKdistances?.toArray(type: Float32.self) {
                        
                        var returnDocument: Bool = true
                        if !returnAllData {
                            if let documentUncertaintyModelUUID = document.uncertainty?.uncertaintyModelUUID, document.uncertainty?.qdfCategoryID != nil {
                                returnDocument = !(documentUncertaintyModelUUID == uncertaintyModelUUID && uncertaintyModelUUID != REConstants.ModelControl.defaultUncertaintyModelUUID)
                            }
                        }
                        if returnDocument {
                            var topKIndexesAsDocumentIds: [String] = []
                            
                            if let topKIndexesAsDocumentIds_fromDB = uncertainty.topKIndexesAsDocumentIds {
                                topKIndexesAsDocumentIds = topKIndexesAsDocumentIds_fromDB
                            }
                            let distanceCategory = getDistanceCategory(prediction: document.prediction, qCategory: qCategory, d0: uncertainty.d0)
                            
                            let documentText = document.documentWithPrompt
                            let dataPoint = DataPoint(id: documentId, label: document.label, prediction: document.prediction, softmax: softmax, d0: uncertainty.d0, q: uncertainty.q, topKdistances: topKdistances, topKIndexesAsDocumentIds: topKIndexesAsDocumentIds, qCategory: qCategory, calibratedOutput: nil, compositionCategory: .null,  distanceCategory: distanceCategory, document: documentText,
                                                      featureMatchesDocLevelSentenceRangeStart: document.featureMatchesDocLevelSentenceRangeStart,
                                                      featureMatchesDocLevelSentenceRangeEnd: document.featureMatchesDocLevelSentenceRangeEnd
                            )
                            
                            dataPoints[documentId] = dataPoint
                        }
                        
                    }
                }
            }
            
            return dataPoints
        }
        return dataPointsResult
    }
    
    /// if/when making this async, be careful when mutating class properties
    func calibrateTest(dataPoints: [ String: DataPoint ]) async -> [ String: DataPoint ] {
        var calibratedDataPoints: [ String: DataPoint ] = dataPoints
        for (dataPointId, var dataPoint) in dataPoints {
            if let thresholds = qCategory_To_Thresholds[dataPoint.qCategory], let predictionSet = try? await constructPredictionSetFromThresholds(numberOfClasses: numberOfClasses, prediction: dataPoint.prediction, softmax: dataPoint.softmax, thresholds: thresholds) {
                
                let predictionSetCompositionId = getPredictionSetCompositionId(numberOfClasses: numberOfClasses, prediction: dataPoint.prediction, predictionSet: predictionSet)
                
                if let calibratedOutput = vennADMITCategory_To_CalibratedOutput[VennADMITCategory(prediction: dataPoint.prediction, qCategory: dataPoint.qCategory, distanceCategory: dataPoint.distanceCategory, compositionCategory: getCompositionCategoryFromPredictionSetCompositionId(predictionSetCompositionId: predictionSetCompositionId))] {
                    dataPoint.calibratedOutput = calibratedOutput
                }
                // We still record the qdf category even if there is no associated calibrated output. However, note that no QDF category is calculatable if the thresholds do not exist for the associated q, in which case the qdf category will be nil in core data.
                    dataPoint.compositionCategory = getCompositionCategoryFromPredictionSetCompositionId(predictionSetCompositionId: predictionSetCompositionId)
//                    dataPoint.calibratedOutput = calibratedOutput
                    
                    dataPoint.qdfCategory = QDFCategory(prediction: dataPoint.prediction, qCategory: dataPoint.qCategory, distanceCategory: dataPoint.distanceCategory, compositionCategory: getCompositionCategoryFromPredictionSetCompositionId(predictionSetCompositionId: predictionSetCompositionId))
               // }
            }
            calibratedDataPoints[dataPointId] = dataPoint
        }
        return calibratedDataPoints
    }
    /* In order to calibrate a new test point, the following are needed:
     d0Stats = trueClass_To_QToD0Statistics[prediction]?[qCategory] distance category
     
     // Note that the thresholds are currently not subdivided by distance
     var qCategory_To_Thresholds: [ QCategory: [Float32] ] = [:]
     qCategory_To_CompositionId_To_PredictedClass_To_DistanceCategory_To_CalibrationVennStructure[dataPoint.qCategory]?[predictionSetCompositionId]?[dataPoint.prediction]?[dataPoint.distanceCategory]
     
     
     */
}
