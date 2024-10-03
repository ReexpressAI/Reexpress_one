//
//  DataController+CoreData.swift
//  Alpha1
//
//  Created by A on 3/21/23.
//

import Foundation
import CoreData

extension DataController {
    
    /// Re-fetch to update dataController.inMemory_Datasets[datasetId]?.count. We have to do this for all in-memory datasets, in case duplicates have been added.
    func updateInMemoryDatasetStats(moc: NSManagedObjectContext, dataController: DataController) async throws {
        try await MainActor.run {
            // Another fecth to update the documents count. We re-fetch, because it is possible the user has uploaded duplicates.
            let fetchRequest = Dataset.fetchRequest()
            //            fetchRequest.predicate = NSPredicate(format: "id == %@", NSNumber(value: datasetId))
            fetchRequest.propertiesToFetch = ["id", "count"]
            let datasetCountRequest = try moc.fetch(fetchRequest) //as [Dataset]
            
            if datasetCountRequest.isEmpty {
                for datasetId in dataController.inMemory_Datasets.keys {
                    dataController.inMemory_Datasets[datasetId]?.count = 0
                }
                throw CoreDataErrors.saveError
            }
            var coveredDatasetIds = Set<Int>()
            for fetchResult in datasetCountRequest {
                dataController.inMemory_Datasets[fetchResult.id]?.count = fetchResult.count
                coveredDatasetIds.insert(fetchResult.id)
            }
            // If a dataset goes to 0 documents, it may not be retrieved, so we need to update:
            for datasetId in dataController.inMemory_Datasets.keys {
                if !coveredDatasetIds.contains(datasetId) {
                    dataController.inMemory_Datasets[datasetId]?.count = 0
                }
            }
        }
    }
    
    // We process in chunks in order to enable cancellation and extended blocking of the main queue.
    func addPreTokenizationDocumentsForDatasetSerial(jsonDocumentArray: [JSONDocument], datasetId: Int, moc: NSManagedObjectContext) async throws {
        
        let chunkSize = REConstants.Persistence.defaultCoreDataBatchSize
        for chunkIndex in stride(from: 0, to: jsonDocumentArray.count, by: chunkSize) {
            if Task.isCancelled {
                return
            }
                        
            let startIndex = chunkIndex
            let endIndex = min(startIndex + chunkSize, jsonDocumentArray.count)
            let dataChunk: [JSONDocument] = Array(jsonDocumentArray[startIndex..<endIndex])
            
            if dataChunk.isEmpty {
                break
            }
            try await _addPreTokenizationDocumentsForDatasetSerial(jsonDocumentArray: dataChunk, datasetId: datasetId, moc: moc)
        }
        
    }
    /// Add just the JSON fields to the database. Tokenization and inference have not yet run at this point.
    func _addPreTokenizationDocumentsForDatasetSerial(jsonDocumentArray: [JSONDocument], datasetId: Int, moc: NSManagedObjectContext) async throws {
        // The fetch is on the main thread since there are not that many items and we need to update the UI
        try await MainActor.run {

            let fetchRequest = Dataset.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", NSNumber(value: datasetId))
            let datasetRequest = try moc.fetch(fetchRequest) as [Dataset]

            if datasetRequest.isEmpty {
                throw CoreDataErrors.saveError
            }
            let dataset = datasetRequest[0]
            for jsonDocumentInstance in jsonDocumentArray {

                let newDocument = Document(context: moc)
                newDocument.id = jsonDocumentInstance.id
                // do some checks here
                newDocument.label = jsonDocumentInstance.label
                newDocument.document = jsonDocumentInstance.document
                newDocument.info = jsonDocumentInstance.info ?? ""

                newDocument.group = jsonDocumentInstance.group ?? ""
                newDocument.prediction = -1 //jsonDocumentInstance.prediction ?? -1
                newDocument.modified = false
                newDocument.viewed = false
                newDocument.prompt = jsonDocumentInstance.prompt
                
                newDocument.modelUUID = REConstants.ModelControl.defaultIndexModelUUID
                newDocument.dateAdded = Date()

                if let attributes = jsonDocumentInstance.attributes {
                    let attrObject = Attributes(context: moc)
                    attrObject.vector = Data(fromArray: attributes)
                    newDocument.attributes = attrObject
                }

                dataset.addToDocuments(newDocument)
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
    
    func deleteExistingDocumentsBatch(jsonDocumentArray: [JSONDocument], datasetId: Int, moc: NSManagedObjectContext) async throws -> Int? {
        var existingDocumentIds: [String] = []
        for jsonDocumentInstance in jsonDocumentArray {
            existingDocumentIds.append(jsonDocumentInstance.id)
        }
        
        let taskContext = newTaskContext()
        // switching to performAndWait to be on the safe side until this control flow is finalized
        return try taskContext.performAndWait {
//        return try await taskContext.perform {

            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Document")

            request.predicate = NSPredicate(format: "id in %@", existingDocumentIds)
            
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: request)
            batchDeleteRequest.resultType = .resultTypeCount
            let resultCount = try taskContext.execute(batchDeleteRequest) as? NSBatchDeleteResult

            return resultCount?.result as? Int
        }
        
    }
    
    func addPreTokenizationDocumentsForDataset(jsonDocumentArray: [JSONDocument], datasetId: Int, moc: NSManagedObjectContext) async throws {
        // We need to run a query to search for duplicates, as updating relying on the id constraint can result in a *very* slow core data save().
        let _ = try await deleteExistingDocumentsBatch(jsonDocumentArray: jsonDocumentArray, datasetId: datasetId, moc: moc)
        //print("Del count: \(delCount)")
        //return ()
        try await addPreTokenizationDocumentsForDatasetSerial(jsonDocumentArray: jsonDocumentArray, datasetId: datasetId, moc: moc)
        // check for state changes
        try await MainActor.run {
            try updateStateForDataUpload_Coarse(datasetId: datasetId, moc: moc)
        }
    }
    
    // Note that tokenization information is *not* included, as a separate pass is needed in those cases (and tokenization information isn't otherwise saved to conserve disk space)
    func addEmbeddingsForExistingDocuments(documentArray: [(id: String, document: String, prompt: String)], sentenceIndexToEmbeddings: [Int: [Float32]], moc: NSManagedObjectContext) async throws {
        // update the published properties via the existing database
        // The fetch is on the main thread since there are not that many items and we need to update the UI
        try await MainActor.run {
            var documentIds: [String] = []
            var documentIdsToSentenceIndex: [String: Int] = [:]
            for sentenceIndex in 0..<documentArray.count {
                documentIds.append(documentArray[sentenceIndex].id)
                documentIdsToSentenceIndex[documentArray[sentenceIndex].id] = sentenceIndex
            }
            //documentArray.map { $0.id }
            let fetchRequest = Document.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id in %@", documentIds)
            let datasetRequest = try moc.fetch(fetchRequest) as [Document]
            
            if datasetRequest.isEmpty {
                throw CoreDataErrors.saveError
            }
            
            for documentObj in datasetRequest {
                if let documentId = documentObj.id, let sentenceIndex = documentIdsToSentenceIndex[documentId], let embedding = sentenceIndexToEmbeddings[sentenceIndex] {
                    let newEmbedding = Embedding(context: moc)
                    newEmbedding.id = documentId
                    newEmbedding.embedding = Data(fromArray: embedding)
                    newEmbedding.document = documentObj
                    // make a connection from the document to the embedding
                    //                        documentObj.embedding = newEmbedding
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
    
    
    /// This assumes that the Document already exists in its associated Dataset in Core Data. This should be called from the main thread. This batches the data structure for the save.
    func addDocumentLevelPredictionsForDataset(modelControlIdString: String, datasetId: Int, documentIdToDocLevelPredictionStructure: [String: OutputPredictionType], moc: NSManagedObjectContext) async throws {
        let chunkSize = REConstants.Persistence.defaultCoreDataBatchSize
        let documentIds = Array(documentIdToDocLevelPredictionStructure.keys)
        for chunkIndex in stride(from: 0, to: documentIds.count, by: chunkSize) {
            if Task.isCancelled {
                throw KeyModelErrors.trainingWasCancelled
            }
            
            var dataChunk: [String: OutputPredictionType] = [:]
            
            let startIndex = chunkIndex
            let endIndex = min(startIndex + chunkSize, documentIds.count)
            let documentIdsChunkArray: [String] = Array(documentIds[startIndex..<endIndex])
            
            if documentIdsChunkArray.isEmpty {
                break
            }
            for documentId in documentIdsChunkArray {
                dataChunk[documentId] = documentIdToDocLevelPredictionStructure[documentId]
            }
            try await MainActor.run {
                try _addDocumentLevelPredictionsForDataset(modelControlIdString: modelControlIdString, datasetId: datasetId, documentIdToDocLevelPredictionStructure: documentIdToDocLevelPredictionStructure, moc: moc)
            }
        }
    }
    /// This assumes that the Document already exists in its associated Dataset in Core Data. This should be called from the main thread.
    func _addDocumentLevelPredictionsForDataset(modelControlIdString: String, datasetId: Int, documentIdToDocLevelPredictionStructure: [String: OutputPredictionType], moc: NSManagedObjectContext) throws {
        
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
                if let documentId = document.id, let documentLevelPrediction = documentIdToDocLevelPredictionStructure[documentId] {
                    if modelControlIdString == REConstants.ModelControl.indexModelId {  // in this case, only update the compressed exemplar vector
                        if let exemplarVector = documentLevelPrediction.exemplar {
                            // Exemplar object must already exist for this document, since it was used for training
                            document.exemplar?.exemplarCompressed = Data(fromArray: exemplarVector)
                        }
                        continue
                        // *** Remainder of loop skipped ***
                    }
                    document.prediction = documentLevelPrediction.predictedClass
                    // add Uncertainty and Exemplar structures
                    if document.uncertainty == nil {
                        let uncertainty = Uncertainty(context: moc)
                        uncertainty.softmax = Data(fromArray: documentLevelPrediction.softmax)
                        if DataController.isKnownValidLabel(label: documentLevelPrediction.predictedClass, numberOfClasses: numberOfClasses) && documentLevelPrediction.predictedClass < documentLevelPrediction.softmax.count {
                            // Save the softmax output separately for the predicted class to enable CoreData predicate-based search:
                            uncertainty.f = documentLevelPrediction.softmax[documentLevelPrediction.predictedClass]
                        }
                        document.uncertainty = uncertainty
                    } else {
                        document.uncertainty?.softmax = Data(fromArray: documentLevelPrediction.softmax)
                        if DataController.isKnownValidLabel(label: documentLevelPrediction.predictedClass, numberOfClasses: numberOfClasses) && documentLevelPrediction.predictedClass < documentLevelPrediction.softmax.count {
                            // Save the softmax output separately for the predicted class to enable CoreData predicate-based search:
                            document.uncertainty?.f = documentLevelPrediction.softmax[documentLevelPrediction.predictedClass]
                        }
                    }
                    
                    if let exemplarVector = documentLevelPrediction.exemplar {
                        if document.exemplar == nil {
                            let exemplar = Exemplar(context: moc)
                            exemplar.exemplar = Data(fromArray: exemplarVector)
                            document.exemplar = exemplar
                        } else {
                            document.exemplar?.exemplar = Data(fromArray: exemplarVector)
                        }
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


