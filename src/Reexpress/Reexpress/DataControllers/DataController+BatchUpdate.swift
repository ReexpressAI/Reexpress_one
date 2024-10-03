//
//  DataController+BatchUpdate.swift
//  Alpha1
//
//  Created by A on 8/28/23.
//

import Foundation
import CoreData
import NaturalLanguage
import Accelerate

/*
 enum DocumentViewedState: Int, CaseIterable, Hashable {
     case viewed
     case unviewed
 }
 struct DocumentBatchChangeState {
     var deleteAllDocuments: Bool = false
     var changeLabel: Bool = false
     var transferDatasplit: Bool = false
     var changeViewedState: Bool = false
     
     var newDocumentViewedState: DocumentViewedState = .viewed
     var newLabelID: Int? //= REConstants.DataValidator.oodLabel
     var newDatasplitID: Int? // = REConstants.DatasetsEnum.train.rawValue
     
     var atLeastOneChangeOperationSelected: Bool {
         return deleteAllDocuments || changeLabel || transferDatasplit || changeViewedState
     }
 }
 */

extension DataController {
    func deleteBatchDocuments(documentIDArray: [String], moc: NSManagedObjectContext) async throws {
        // It is assumed that the number of deletions are <= total rows in view at any given time, so we just keep this on the main thread to keep state updates simple
        /*let taskContext = newTaskContext()
        try taskContext.performAndWait {  // be careful with control flow with .perform since it immediately returns (asynchronous)
        //try await taskContext.perform {
            
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Document")
            
            request.predicate = NSPredicate(format: "id in %@", documentIDArray)
            
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: request)
            batchDeleteRequest.resultType = .resultTypeCount

            let _ = try taskContext.execute(batchDeleteRequest) as? NSBatchDeleteResult
        }*/
        try await MainActor.run {
            let fetchRequest = Document.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id in %@", documentIDArray)
            let documentRequest = try moc.fetch(fetchRequest) as [Document]
            
            if documentRequest.isEmpty {
                throw CoreDataErrors.noDocumentsFound
            }
            for documentObject in documentRequest {
                moc.delete(documentObject)
            }
            if moc.hasChanges {
                try moc.save()
            }
            
        }
    }
    func batchUpdateNonDelete(documentIDArray: [String], existingDatasplitId: Int, documentBatchChangeState: DocumentBatchChangeState, moc: NSManagedObjectContext) async throws {
        
        try await MainActor.run {

            let fetchRequest = Document.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id in %@", documentIDArray)
            let documentRequest = try moc.fetch(fetchRequest) as [Document]
            
            if documentRequest.isEmpty {
                throw CoreDataErrors.noDocumentsFound
            }
            let updateDate = Date()
            var existingDatasplitObject: Dataset? = nil
            var newDatasplitObject: Dataset? = nil
            if documentBatchChangeState.transferDatasplit, let newDatasplitId = documentBatchChangeState.newDatasplitID {
                if existingDatasplitId == newDatasplitId {
                    throw BatchUpdateErrors.batchUpdateFailed
                }
                let fetchRequest = Dataset.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", NSNumber(value: existingDatasplitId))
                let datasetRequest = try moc.fetch(fetchRequest) //as [Dataset]
                
                if datasetRequest.isEmpty {
                    throw CoreDataErrors.datasetNotFound
                }
                existingDatasplitObject = datasetRequest[0]
                
                let newfetchRequest = Dataset.fetchRequest()
                newfetchRequest.predicate = NSPredicate(format: "id == %@", NSNumber(value: newDatasplitId))
                let newdatasetRequest = try moc.fetch(newfetchRequest) //as [Dataset]
                
                if newdatasetRequest.isEmpty {
                    throw CoreDataErrors.datasetNotFound
                }
                newDatasplitObject = newdatasetRequest[0]
                if let newDatasetDocuments = newDatasplitObject?.documents, newDatasetDocuments.count + documentRequest.count > REConstants.DatasetsConstraints.maxTotalLines {
                    // The new datasplit unexpectedly has insufficient space, so throw
                    throw BatchUpdateErrors.batchUpdateFailed
                }
            }
            for documentObject in documentRequest {
                if documentBatchChangeState.changeLabel, let newLabel = documentBatchChangeState.newLabelID {
                    if newLabel != documentObject.label {  // only update if different from existing
                        documentObject.label = newLabel
                        documentObject.lastModified = updateDate
                    }
                }
                if documentBatchChangeState.changeViewedState {
                    switch documentBatchChangeState.newDocumentViewedState {
                    case .viewed:
                        documentObject.viewed = true
                        documentObject.lastViewed = updateDate
                    case .unviewed:
                        documentObject.viewed = false
                        documentObject.lastViewed = nil
                    }
                    
                }
                if documentBatchChangeState.changeGroupField {
                    if documentBatchChangeState.groupFieldText.count <= REConstants.DataValidator.maxGroupRawCharacterLength {
                        documentObject.group = documentBatchChangeState.groupFieldText
                    } else {
                        throw BatchUpdateErrors.batchUpdateFailed
                    }
                }
                if documentBatchChangeState.changeInfoField {
                    if documentBatchChangeState.infoFieldText.count <= REConstants.DataValidator.maxInfoRawCharacterLength {
                        documentObject.info = documentBatchChangeState.infoFieldText
                    } else {
                        throw BatchUpdateErrors.batchUpdateFailed
                    }
                }
                if documentBatchChangeState.transferDatasplit, let newDatasplitId = documentBatchChangeState.newDatasplitID, let existingDatasetIDfromObject = documentObject.dataset?.id, newDatasplitId != existingDatasplitId {
                    if existingDatasplitId != existingDatasetIDfromObject {
                        throw BatchUpdateErrors.batchUpdateFailed
                    }
                    if let prevDataset = existingDatasplitObject, let newDataset = newDatasplitObject {
                        prevDataset.removeFromDocuments(documentObject)
                        newDataset.addToDocuments(documentObject)
                    }
                }
            }
            
            if moc.hasChanges {
                try moc.save()
            }
        }
    }
    
    func processBatchUpdate(datasetId: Int, documentBatchChangeState: DocumentBatchChangeState, multipleSelectedDocuments: Set<TableDataPoint.ID>, moc: NSManagedObjectContext, documentSelectionState: DocumentSelectionState, expectedSizeOfUpdate: Int) async throws {
        if documentBatchChangeState.atLeastOneChangeOperationSelected, (!multipleSelectedDocuments.isEmpty || documentBatchChangeState.applyChangesToAllDocumentsAndRowsInSelection) {
            var documentIDArray: [String] = [] // = Array(multipleSelectedDocuments)
            if !documentBatchChangeState.applyChangesToAllDocumentsAndRowsInSelection {
                documentIDArray = Array(multipleSelectedDocuments)
            } else {
                if documentSelectionState.semanticSearchParameters.search {
                    if documentSelectionState.semanticSearchParameters.retrievedDocumentIDs.isEmpty {
                        throw BatchUpdateErrors.batchUpdateFailed
                    } else {
                        // In this case, the document IDs are already retrieved from a semantic search, so can proceed as if the users has selected documents in the table
                        documentIDArray = documentSelectionState.semanticSearchParameters.retrievedDocumentIDs
                    }
                } else {
                    // This case is more complicated, since we first need to retrieve all ids, and then process in batches since the selection could include all documents in the datasplit. Delete, in particular, can be expensive.
                    let supportDocumentIds = try await semanticSearchGetSupportIds(documentSelectionState: documentSelectionState, moc: moc)
                    documentIDArray = Array(supportDocumentIds)
                    
                    if Task.isCancelled {
                        throw BatchUpdateErrors.batchUpdateFailed
                    }
                    
                }
            }
            if documentIDArray.count != expectedSizeOfUpdate || documentIDArray.isEmpty {
                throw BatchUpdateErrors.batchUpdateFailed
            }
            
            let chunkSize = REConstants.ModelControl.batchUpdateCoreDataChunkSize
            for chunkIndex in stride(from: 0, to: documentIDArray.count, by: chunkSize) {
                                
                if Task.isCancelled {
                    throw BatchUpdateErrors.batchUpdateFailed
                }
                
                let startIndex = chunkIndex
                let endIndex = min(startIndex + chunkSize, documentIDArray.count)
                let documentIDArrayChunk = Array(documentIDArray[startIndex..<endIndex])
                if !documentIDArrayChunk.isEmpty {
                    try await processBatchUpdateOnePass(datasetId: datasetId, documentBatchChangeState: documentBatchChangeState, documentIDArray: documentIDArrayChunk, moc: moc)
                }
            }
            
        } else {
            throw BatchUpdateErrors.batchUpdateFailed
        }
    }
    
    func processBatchUpdateOnePass(datasetId: Int, documentBatchChangeState: DocumentBatchChangeState, documentIDArray: [String], moc: NSManagedObjectContext) async throws {
        if documentBatchChangeState.atLeastOneChangeOperationSelected, !documentIDArray.isEmpty {
            do {
                if documentBatchChangeState.deleteAllDocuments {  // Deletion, of course, is exclusive. If deleted, then we skip making any additional changes. However, importantly, we need to update state changes below whether deletion or not.
                    try await deleteBatchDocuments(documentIDArray: documentIDArray, moc: moc)
                } else {
                    try await batchUpdateNonDelete(documentIDArray: documentIDArray, existingDatasplitId: datasetId, documentBatchChangeState: documentBatchChangeState, moc: moc)
                }
                // Keep state changes simple:
                var stateChange: StateChangeType = .noStateChange
                if datasetId == REConstants.DatasetsEnum.train.rawValue {
                    stateChange = .modelTrainingAndUncertaintyConditionsChanged
                } else if datasetId == REConstants.DatasetsEnum.calibration.rawValue {
                    stateChange = .onlyUncertaintyConditionsChanged
                }
                if !documentBatchChangeState.deleteAllDocuments, documentBatchChangeState.transferDatasplit, let newDatasplitId = documentBatchChangeState.newDatasplitID {
                    if newDatasplitId == REConstants.DatasetsEnum.train.rawValue {
                        stateChange = .modelTrainingAndUncertaintyConditionsChanged
                    } else if newDatasplitId == REConstants.DatasetsEnum.calibration.rawValue {
                        if stateChange == .noStateChange {
                            stateChange = .onlyUncertaintyConditionsChanged
                        } // otherwise, at least .onlyUncertaintyConditionsChanged has already been selected
                    }
                }
                let stateChangeConstant = stateChange
                try await MainActor.run {
                    try updateBasedOnState(stateChange: stateChangeConstant, moc: moc)
                }
            } catch {
                await MainActor.run {
                    moc.rollback()
                }
                throw BatchUpdateErrors.batchUpdateFailed
            }
            
        } else {
            throw BatchUpdateErrors.batchUpdateFailed
        }
    }
}
