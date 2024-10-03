//
//  DataOverviewView+RetrievalMethods.swift
//  Alpha1
//
//  Created by A on 8/27/23.
//

import SwiftUI

extension DataOverviewView {
    func getDataPointsForDatasetFromDatabase(documentSelectionState: DocumentSelectionState, moc: NSManagedObjectContext, fetchOffset: Int, batchSize: Int) async throws -> (documentRequest: [ Document ], documentIdToIndex: [String: Int], count: Int) {
        //try await getCountResult(datasetId: datasetId, moc: moc)
        let documentRequestResult = try await MainActor.run {
            var documentIdToIndex: [String: Int] = [:]
            
            // Another fecth to update the documents count. We re-fetch, because it is possible the user has uploaded duplicates.
            let fetchRequest = Document.fetchRequest()
            let compoundPredicate = try dataController.getFetchPredicateBasedOnDocumentSelectionState(documentSelectionState: documentSelectionState, moc: moc)
            
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: compoundPredicate)
            
            let sortDescriptors = dataController.getSortDescriptorsBasedOnDocumentSelectionState(documentSelectionState: documentSelectionState, moc: moc)
            
            fetchRequest.sortDescriptors = sortDescriptors
            
            let count = try moc.count(for: fetchRequest)  // This is used to determine the total rows. Note that fetchBatchSize (and related) has not yet been applied.
            fetchRequest.fetchOffset = fetchOffset
            fetchRequest.fetchBatchSize = batchSize
            fetchRequest.fetchLimit = batchSize
            
            let documentRequest = try moc.fetch(fetchRequest)
            
            if documentRequest.isEmpty {
                throw CoreDataErrors.retrievalError
            }
            //let count = documentRequest.count
            for i in 0..<documentRequest.count {
                let dataPoint = documentRequest[i]
                if let id = dataPoint.id {
                    documentIdToIndex[id] = i
                }
            }
            
            return (documentRequest: documentRequest, documentIdToIndex: documentIdToIndex, count: count)
        }
        return documentRequestResult
    }
    func getDataPointsForDatasetFromDatabaseFromDocumentIDs(retrievedDocumentIDs: [String], moc: NSManagedObjectContext) async throws -> (documentRequest: [ Document ], documentIdToIndex: [String: Int], count: Int) {
        //try await getCountResult(datasetId: datasetId, moc: moc)
        let documentRequestResult = try await MainActor.run {
            var documentIdToIndex: [String: Int] = [:]
            
            let fetchRequest = Document.fetchRequest()
            
            fetchRequest.predicate = NSPredicate(format: "id in %@", retrievedDocumentIDs)
            
            let documentRequest = try moc.fetch(fetchRequest)
            
            if documentRequest.isEmpty {
                throw CoreDataErrors.retrievalError
            }
            //let count = documentRequest.count
            for i in 0..<documentRequest.count {
                let dataPoint = documentRequest[i]
                if let id = dataPoint.id {
                    documentIdToIndex[id] = i
                }
            }
            
            // The IDs may not be ordered in the top-k order, and an document could have been deleted in another view, so we filter and re-order
            var orderedDocumentRequest: [Document] = []
            var orderedDocumentIdToIndex: [String: Int] = [:]
            var orderedI: Int = 0
            for docID in retrievedDocumentIDs {
                if let i = documentIdToIndex[docID] {
                    orderedDocumentRequest.append(documentRequest[i])
                    orderedDocumentIdToIndex[docID] = orderedI
                    orderedI += 1
                }
            }
            // In this case, count is just orderedDocumentRequest.count, because we assume the total count from retrieval (currently 100), is less than the batch size (i.e., the total number of rows viewable in the table at a time).
            return (documentRequest: orderedDocumentRequest, documentIdToIndex: orderedDocumentIdToIndex, count: orderedDocumentRequest.count)
        }
        return documentRequestResult
    }
    func resetTable() {
        sortedDataPoints = []
        documentIdToIndex = [:]
        databaseRetrievalRows = []
        selectedDBRow = nil
        selectedDocument = nil
        documentObject = nil
        multipleSelectedDocuments.removeAll()
        dataController.selectedDBRow_DocumentsOverview = nil  // stored db row when returning to view
        //        datasetId = nil
    }
    func retrieve(documentSelectionState: DocumentSelectionState?, fetchOffset: Int, batchSize: Int, initiateRows: Bool, existingDBRow: DatabaseRetrievalRow?=nil) {
        guard let documentSelectionState = documentSelectionState else {
            resetTable()
            return
        }
        Task {
            do {
                //                await MainActor.run {
                //                    documentRetrievalInProgress = true
                ////                    sortedDataPoints = []
                ////                    documentIdToIndex = [:]
                //                }
                var dataPointsResultOptional: (documentRequest: [ Document ], documentIdToIndex: [String: Int], count: Int)? = nil
                if documentSelectionState.semanticSearchParameters.search, !documentSelectionState.semanticSearchParameters.retrievedDocumentIDs.isEmpty {
                    dataPointsResultOptional = try await getDataPointsForDatasetFromDatabaseFromDocumentIDs(retrievedDocumentIDs: documentSelectionState.semanticSearchParameters.retrievedDocumentIDs, moc: moc)
                } else {
                    dataPointsResultOptional = try await getDataPointsForDatasetFromDatabase(documentSelectionState: documentSelectionState, moc: moc, fetchOffset: fetchOffset, batchSize: batchSize)
                }
                guard let dataPointsResult = dataPointsResultOptional else {
                    await MainActor.run {
                        resetTable()
                    }
                    return
                }
                await MainActor.run {
                    if initiateRows {
                        var newRows: [DatabaseRetrievalRow] = []
                        // Note that dataPointsResult.count is the count of all documents returnable and can differ from dataPointsResult.documentRequest.count
                        for batchIndex in stride(from: 0, to: dataPointsResult.count, by: batchSize) {
                            // -1 since indexed by 0.
                            let endRow = min(batchIndex+batchSize, dataPointsResult.count)-1
                            newRows.append(.init(startRow: batchIndex, endRow: endRow))
                        }
                        /*for batchIndex in 0..<dataPointsResult.count/batchSize {
                            let startRow = batchIndex * batchSize
                            let endRow = startRow + batchSize
                            newRows.append(.init(startRow: startRow, endRow: min(endRow, dataPointsResult.count)))
                        }*/
                        // this shouldn't occur when using stride:
                        /*if newRows.isEmpty && dataPointsResult.count != 0 {
                            newRows.append(.init(startRow: 0, endRow: dataPointsResult.count))
                        }*/
                        databaseRetrievalRows = newRows
                        selectedDBRow = databaseRetrievalRows.first
                    }
                    sortedDataPoints = dataPointsResult.documentRequest
                    documentIdToIndex = dataPointsResult.documentIdToIndex
                    documentRetrievalInProgress = false
                    documentObject = nil
                    selectedDocument = nil
                    multipleSelectedDocuments.removeAll()
                    // This jumps back to the row in case returning from a previous view. We always re-fetch and re-init in case the underlying data has changed in the interim.
                    if let existingRow = existingDBRow {
                        jumpToExistingRow(existingDBRow: existingRow)
                    }
                }
            } catch {
                await MainActor.run {
                    documentRetrievalInProgress = false
                    documentRetrievalError = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    documentRetrievalError = false
                }
                await MainActor.run {
                    resetTable()
                }
                /*sortedDataPoints = []
                 documentIdToIndex = [:]
                 databaseRetrievalRows = []
                 selectedDBRow = nil
                 documentObject = nil
                 selectedDocument = nil
                 datasetId = nil*/
                
            }
        }
    }
    
    func jumpToExistingRow(existingDBRow: DatabaseRetrievalRow) {
        // Check if existing row selection is present. If so, switch to that row. (This gets overwritten on resets and new retrievial, so existingDBRow is a temporary copy).
        var existingDBRowWasFound: Bool = false
        // Need to search for match, since UUID has changed. O(n), but we're assuming the number of rows is relatively small.
        for dbRow in databaseRetrievalRows {
            if dbRow.startRow == existingDBRow.startRow && dbRow.endRow == existingDBRow.endRow {
                selectedDBRow = dbRow
                existingDBRowWasFound = true
                break
            }
        }
        if !existingDBRowWasFound {
            dataController.selectedDBRow_DocumentsOverview = nil
        }
        existingDBRow_TempCopy = nil
    }
    
    func initiateRetrieval() {
        guard let startNewRetrieval = initiateFullRetrieval else {
            resetTable()
            return
        }
        if startNewRetrieval {
            resetTable()
            documentRetrievalInProgress = true
            dataController.documentSelectionState_DocumentsOverview = documentSelectionState_proposal
//            print("search text: \(dataController.documentSelectionState_DocumentsOverview?.semanticSearchParameters.searchText)")
//            print("search prompt: \(dataController.documentSelectionState_DocumentsOverview?.semanticSearchParameters.searchPrompt)")
            retrieve(documentSelectionState: dataController.documentSelectionState_DocumentsOverview, fetchOffset: 0, batchSize: batchSize, initiateRows: true, existingDBRow: existingDBRow_TempCopy)
            shouldScrollToTop = true
        } else {
            // must be a cancel from the Selection view, so take no action (i.e., any existing selection results remain) other than re-setting the proposal state
            if let documentSelectionState = dataController.documentSelectionState_DocumentsOverview {
                documentSelectionState_proposal = documentSelectionState
            } else { // this case shouldn't occur in the current convention, since dataController should maintain an instance of the state
                documentSelectionState_proposal = DocumentSelectionState(numberOfClasses: dataController.numberOfClasses)
            }
        }
    }
}


