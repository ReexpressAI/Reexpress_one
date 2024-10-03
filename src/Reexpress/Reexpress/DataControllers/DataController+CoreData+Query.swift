//
//  DataController+CoreData+Query.swift
//  Alpha1
//
//  Created by A on 6/22/23.
//

import Foundation

import CoreData

extension DataController {
    /// Just return the text data. Used when cacheing states. Considering changing to Datapoints.
    //    func getJSONDocumentArrayFromDatabase(datasetId: Int, moc: NSManagedObjectContext) async throws -> [JSONDocument] {
    //
    //        // retrieve labels and embeddings from the database
    //        let jsonDocumentArray = try await MainActor.run {
    //            var jsonDocumentArray: [JSONDocument] = []
    //            let fetchRequest = Dataset.fetchRequest()
    //            fetchRequest.predicate = NSPredicate(format: "id == %@", NSNumber(value: datasetId))
    //            let datasetRequest = try moc.fetch(fetchRequest) //as [Dataset]
    //
    //            if datasetRequest.isEmpty {
    //                throw CoreDataErrors.retrievalError
    //            }
    //            let dataset = datasetRequest[0]
    //
    //            if let documents = dataset.documents {
    //                for document in documents {
    //                    let jsonDocument = JSONDocument(id: document.id ?? "", label: document.label, document: document.document ?? "", info: document.info ?? "", attributes: [], group: document.group ?? "", prediction: document.prediction, modified: document.modified)
    //                    jsonDocumentArray.append(jsonDocument)
    //                }
    //            } else {
    //                throw CoreDataErrors.retrievalError
    //            }
    //
    //            return jsonDocumentArray
    //        }
    //        return jsonDocumentArray
    //    }
    
    /// This returns a list of tuples of strings to avoid passing managedobjects across threads, which can lead to some subtle bugs.
    /// onlyLabeled should be true for training loops
    func getJSONDocumentArrayFromDatabaseOnlyUncached(datasetId: Int, moc: NSManagedObjectContext, onlyLabeled: Bool) async throws -> [(id: String, document: String, prompt: String)] {
        
        // retrieve labels and embeddings from the database
        let jsonDocumentArray = try await MainActor.run {
            //            var jsonDocumentArray: [Document] = []
            let fetchRequest = Document.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "dataset.id == %@", NSNumber(value: datasetId))
            let datasetRequest = try moc.fetch(fetchRequest) as [Document]
            
            if datasetRequest.isEmpty {
                throw CoreDataErrors.noDocumentsFound
            }
            
            var jsonDocumentArray: [(id: String, document: String, prompt: String)] = []
            for documentObj in datasetRequest {
                if documentObj.embedding == nil {
                    if !onlyLabeled || (onlyLabeled && DataController.isKnownValidLabel(label: documentObj.label, numberOfClasses: numberOfClasses)) {
                        jsonDocumentArray.append((id: documentObj.id ?? "", document: documentObj.document ?? "", prompt: documentObj.prompt ?? ""))
                    }
                }
            }
            return jsonDocumentArray
        }
        return jsonDocumentArray
    }
    
    /// Returns instances that have not been through full (current) prediction.
    /// isPredictionCurrentBasedOnModelUUID(modelUUIDForDocument: documentObj.modelUUID) == false means a prediction is not up-to-date
    func getJSONDocumentArrayFromDatabaseOnlyUnpredicted(datasetId: Int, moc: NSManagedObjectContext) async throws -> [(id: String, document: String, prompt: String, attributes: [Float32])] {
        
        // retrieve labels and embeddings from the database
        let jsonDocumentArray = try await MainActor.run {
            //            var jsonDocumentArray: [Document] = []
            let fetchRequest = Document.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "dataset.id == %@", NSNumber(value: datasetId))
            let datasetRequest = try moc.fetch(fetchRequest) as [Document]
            
            if datasetRequest.isEmpty {
                throw CoreDataErrors.noDocumentsFound
            }
            
            var jsonDocumentArray: [(id: String, document: String, prompt: String, attributes: [Float32])] = []
            for documentObj in datasetRequest {
                // MARK: TODO also add check for uncertainty uuid
                // We return if the index model UUID is missing or out-of-date, and/or the uncertainty UUID is missing or out-of-date
                if !isPredictionCurrentBasedOnModelUUID(modelUUIDForDocument: documentObj.modelUUID) {
                //if !documentObj.modified {  // This should probably be changed to some other check.
                    
                    // Get attributes, if any. Note that the stored attributes may be less than the full size, so fill with 0's, as applicable.
                    var attributesVector: [Float32] = []
                    if var attributes = documentObj.attributes?.vector?.toArray(type: Float32.self) {
                        if attributes.count > REConstants.KeyModelConstraints.attributesSize {
                            throw GeneralFileErrors.attributeMaxSizeError
                        }
                        // expand attributes to full size:
                        attributes.append(contentsOf: [Float32](repeating: Float32(0.0), count: REConstants.KeyModelConstraints.attributesSize-attributes.count))
                        // append attributes to the input embedding
                        attributesVector = attributes
                    } else { // no attributes, so fill with empty mask
                        attributesVector = [Float32](repeating: Float32(0.0), count: REConstants.KeyModelConstraints.attributesSize)
                    }
                    
                    jsonDocumentArray.append((id: documentObj.id ?? "", document: documentObj.document ?? "", prompt: documentObj.prompt ?? "", attributes: attributesVector))
                }
            }
            return jsonDocumentArray
        }
        return jsonDocumentArray
    }
}
