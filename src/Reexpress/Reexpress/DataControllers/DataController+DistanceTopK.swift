//
//  DataController+Uncertainty.swift
//  Alpha1
//
//  Created by A on 4/10/23.
//

import Foundation
import CoreData
import CoreML
import Accelerate




extension DataController {
    
    func getExemplarDataFromDatabase(modelControlIdString: String, datasetId: Int, moc: NSManagedObjectContext, returnAllData: Bool = true) async throws -> [String: (label: Int, prediction: Int, exemplar: [Float32], softmax: [Float32])] {
        
        // retrieve labels and embeddings from the database
        let predictionOutput = try await MainActor.run {
            // Another fecth to update the documents count. We re-fetch, because it is possible the user has uploaded duplicates.
            let fetchRequest = Dataset.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", NSNumber(value: datasetId))
            //            fetchRequest.propertiesToFetch = ["documents"]
            let datasetRequest = try moc.fetch(fetchRequest) //as [Dataset]
            
            if datasetRequest.isEmpty {
                throw CoreDataErrors.retrievalError
            }
            let dataset = datasetRequest[0]
            
            var predictionOutput: [String: (label: Int, prediction: Int, exemplar: [Float32], softmax: [Float32])] = [:]
            
            var count = 0
            var correct = 0
            // Importantly, note that dataset.documents is not sorted and in practice, is not consistently sorted across fetches even with the same database data.
            if let documents = dataset.documents {
                for document in documents {
                    if modelControlIdString == REConstants.ModelControl.indexModelId {
                        if let dataAsArray: [Float32] = document.exemplar?.exemplarCompressed?.toArray(type: Float32.self), let documentId = document.id, let softmax = document.uncertainty?.softmax?.toArray(type: Float32.self) {
                            predictionOutput[documentId] =
                            (label: document.label, prediction: document.prediction, exemplar: dataAsArray, softmax: softmax)
                            
                        }
                    } else if modelControlIdString == REConstants.ModelControl.keyModelId {
                        if let dataAsArray: [Float32] = document.exemplar?.exemplar?.toArray(type: Float32.self), let documentId = document.id, let softmax = document.uncertainty?.softmax?.toArray(type: Float32.self) {
                            
                            var returnDocument: Bool = true
                            if !returnAllData {
                                if let documentUncertaintyModelUUID = document.uncertainty?.uncertaintyModelUUID, document.uncertainty?.qdfCategoryID != nil {
                                    returnDocument = !isPredictionUncertaintyCurrent(documentUncertaintyModelUUID: documentUncertaintyModelUUID)
                                }
                            }
                            if returnDocument {
                                predictionOutput[documentId] =
                                (label: document.label, prediction: document.prediction, exemplar: dataAsArray, softmax: softmax)
                                
                                if document.label == document.prediction {
                                    correct += 1
                                }
                                count += 1
                            }
                        }
                    } else {
                        throw CoreDataErrors.retrievalError
                    }
                    
                }
            }
            //print("Marginal accuracy (in getExemplarDataFromDatabase()): \(Double(correct)/Double(max(1, count))) out of \(Double(max(1, count)))")
            return predictionOutput
        }
        return predictionOutput
    }
    

    /// q is currently always calculated, but note that it typically should only be used when the support is the training set
    func runForwardIndex(query: [String: (label: Int, prediction: Int, exemplar: [Float32], softmax: [Float32])], support: [String: (label: Int, prediction: Int, exemplar: [Float32], softmax: [Float32])]) async throws -> [String: (d0: Float32, q: Int, topKdistances: [Float32], topKIndexesAsDocumentIds: [String])] {
        
        if support.count > REConstants.ModelControl.forwardIndexMaxSupportSize {
            throw IndexErrors.supportMaxSizeError
        }
        var queryToUncertaintyStructure: [String: (d0: Float32, q: Int, topKdistances: [Float32], topKIndexesAsDocumentIds: [String])] = [:]
        
        
        let minSupportSize = 100  // support must be at least as large as the top k in the IndexOperator model
        let unaugmentedSupportSize = support.count
        let config = MLModelConfiguration()
        // Directly set cpu and gpu, as we want GPU on the targeted M1 Max and better with Float32, as opposed to the ANE
        config.computeUnits = .cpuAndGPU
        
        let model = try await IndexOperator100.load(configuration: config)
        
        var supportExemplarArray: [Float32] = []
        var supportDocumentIdArray: [String] = []
        var exemplarDimension = -1
        for (documentId, predictionOutput) in support {
            supportExemplarArray.append(contentsOf: predictionOutput.exemplar)
            supportDocumentIdArray.append(documentId)
            if exemplarDimension == -1 {
                exemplarDimension = predictionOutput.exemplar.count
            } else {
                if exemplarDimension != predictionOutput.exemplar.count {
                    throw IndexErrors.exemplarDimensionError
                }
            }
        }
        if exemplarDimension < 1  {
            throw IndexErrors.exemplarDimensionError
        }
        var supportMLShapedArray = MLShapedArray<Float32>(scalars: supportExemplarArray, shape: [supportDocumentIdArray.count, exemplarDimension])
        if unaugmentedSupportSize < minSupportSize {
            // fill with zeros:
            let extendedSupport = MLShapedArray<Float32>(repeating: 0.0, shape: [minSupportSize-unaugmentedSupportSize, exemplarDimension])
            supportMLShapedArray = MLShapedArray<Float32>(concatenating: [supportMLShapedArray, extendedSupport], alongAxis: 0)
        }
        
        for (queryDocumentId, predictionOutput) in query {
            let queryExemplarArray = predictionOutput.exemplar
            if queryExemplarArray.count != exemplarDimension {
                throw IndexErrors.exemplarDimensionError
            }
            let queryMLShapedArray = MLShapedArray<Float32>(scalars: queryExemplarArray, shape: [1, exemplarDimension])
            let output = try model.prediction(query: queryMLShapedArray, support: supportMLShapedArray)
            let topKdistances = output.topKDistancesShapedArray.scalars  // Float32
            let topKIndexes = output.topKDistancesIdxShapedArray.scalars  // Int32 -- these get converted to document id's (String) below
            
            let topKCount = topKdistances.count
            var foundQ: Bool = false
            var q: Int = 0
            var d0: Float32 = -1
            var filteredTopKdistances: [Float32] = []  // We drop any padding indexes and verbatim matches, as applicable. This is consistent with topKIndexesAsDocumentIds.
            var topKIndexesAsDocumentIds: [String] = []
            var validMatchIndex: Int = 0  // separate index to account for possible padding indexes
            for matchIndex in 0..<topKCount {
                let indexIntoSupport = Int(topKIndexes[matchIndex])
                if indexIntoSupport < unaugmentedSupportSize {  // otherwise, must be an augmented padding index
                    let matchedSupportDocumentId = supportDocumentIdArray[ Int(topKIndexes[matchIndex]) ]
                    if matchedSupportDocumentId != queryDocumentId {  // If/when calculating distances for the training set, the query could be part of the support.
//                        if matchIndex == 0 {
//                            d0 = topKdistances[0]
//                        }
                        if validMatchIndex == 0 {
//                            d0 = topKdistances[0]
                            d0 = topKdistances[matchIndex]
//                            print("d0: \(d0)")
//                            print("\(matchedSupportDocumentId), \(queryDocumentId): \(matchedSupportDocumentId != queryDocumentId)")
                        }
                        validMatchIndex += 1
                        // Convert Int indexes to String document ids (from support):
                        topKIndexesAsDocumentIds.append(matchedSupportDocumentId)
                        filteredTopKdistances.append(topKdistances[matchIndex])
                        
                        // query prediction matches the prediction of the support match AND the support match is a TP
                        if predictionOutput.prediction == support[matchedSupportDocumentId]?.label && support[matchedSupportDocumentId]?.label == support[matchedSupportDocumentId]?.prediction && !foundQ {
                            q += 1
                        } else {
                            foundQ = true  // Importantly, we only want to consider the nearest until a mismatch
                        }
                    }
                }
            }
            queryToUncertaintyStructure[queryDocumentId] = (d0: d0, q: q, topKdistances: filteredTopKdistances, topKIndexesAsDocumentIds: topKIndexesAsDocumentIds)
        }
        return queryToUncertaintyStructure
        //return try await runForwardIndexCalibration(query: query, support: support)
    }
    /// This assumes that the Document already exists in its associated Dataset in Core Data. 
    func addUncertaintyStructureForDataset(datasetId: Int, queryToUncertaintyStructure: [String: (d0: Float32, q: Int, topKdistances: [Float32], topKIndexesAsDocumentIds: [String])], moc: NSManagedObjectContext) async throws {
        
        try await MainActor.run {
            let fetchRequest = Dataset.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", NSNumber(value: datasetId))
            let datasetRequest = try moc.fetch(fetchRequest) //as [Dataset]
            
            if datasetRequest.isEmpty {
                throw CoreDataErrors.saveError
            }
            let dataset = datasetRequest[0]
            
            // Importantly, note that dataset.documents is not sorted and in practice, is not consistently sorted across fetches even with the same database data.
            if let documents = dataset.documents {
                for document in documents {
                    if let documentId = document.id {
                        if let uncertaintyForDocument = queryToUncertaintyStructure[documentId] {
                            document.uncertainty?.d0 = uncertaintyForDocument.d0
                            document.uncertainty?.q = uncertaintyForDocument.q
                            document.uncertainty?.topKdistances = Data(fromArray: uncertaintyForDocument.topKdistances)
                            document.uncertainty?.topKIndexesAsDocumentIds = uncertaintyForDocument.topKIndexesAsDocumentIds
                            // reset uncertainty model property and connection
                            document.uncertainty?.qdfCategoryID = nil
                            document.uncertainty?.uncertaintyModelUUID = nil
                        }
                    }
                }
            }
            
            do {
                if moc.hasChanges {
                    try moc.save()
                }
            } catch {
                throw CoreDataErrors.saveError
            }
        }
    }
    
    // This assumes the other uncertainty structures have already been added.
    func addCalibratedUncertaintyStructureForDataset(datasetId: Int, dataChunk: [String: UncertaintyStatistics.DataPoint], moc: NSManagedObjectContext) async throws {
        
        try await MainActor.run {
            let fetchRequest = Dataset.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", NSNumber(value: datasetId))
            let datasetRequest = try moc.fetch(fetchRequest) //as [Dataset]
            
            if datasetRequest.isEmpty {
                throw CoreDataErrors.saveError
            }
            let dataset = datasetRequest[0]
            
            // Importantly, note that dataset.documents is not sorted and in practice, is not consistently sorted across fetches even with the same database data.
            guard let uncertaintyModelUUID = uncertaintyStatistics?.uncertaintyModelUUID else {
                throw UncertaintyErrors.uncertaintyStatisticsIsUnexepctedlyMissing
            }
            if let documents = dataset.documents {
                for document in documents {
                    if let documentId = document.id {
                        if let dataPoint = dataChunk[documentId], let qdfCategoryID = dataPoint.qdfCategory?.id, document.uncertainty != nil {
                            document.uncertainty?.qdfCategoryID = qdfCategoryID
                            document.uncertainty?.uncertaintyModelUUID = uncertaintyModelUUID
                        }
                    }
                }
            }
            
            do {
                if moc.hasChanges {
                    try moc.save()
                }
            } catch {
                throw CoreDataErrors.saveError
            }
        }
    }
    
    func getUncertaintyStructureForDatasetFromDatabaseOnlyKnownValidLabels(datasetId: Int, numberOfClasses: Int, moc: NSManagedObjectContext) async throws -> [Int: [(documentId: String, prediction: Int, softmax: [Float32], d0: Float32, q: Int)]] {
        
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
            if let documents = dataset.documents {
                for document in documents {
                    if let documentId = document.id, let uncertainty = document.uncertainty, let softmax = uncertainty.softmax?.toArray(type: Float32.self) {
                        let label = document.label
                        if DataController.isKnownValidLabel(label: label, numberOfClasses: numberOfClasses) {
                            uncertaintyStructureByTrueClass[label]?.append(
                                (documentId: documentId, prediction: document.prediction, softmax: softmax, d0: uncertainty.d0, q: uncertainty.q)
                            )
                        }
                    }
                }
            }
            return uncertaintyStructureByTrueClass
        }
        return uncertaintyStructureByTrueClass
    }
}


