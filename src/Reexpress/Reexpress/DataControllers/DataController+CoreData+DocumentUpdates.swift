//
//  DataController+CoreData+DocumentUpdates.swift
//  Alpha1
//
//  Created by A on 8/14/23.
//

import Foundation
import CoreData

extension DataController {
    // It is assumed this is called from a UI that checks newInfoFieldText is valid and informs the user. Here, if no change is necesary or max length is exceeded, we return without throwing.
    func updateInfoForOneDocument(documentObject: Document?, newInfoFieldText: String, moc: NSManagedObjectContext) throws {
        // check for identity
        if let docObj = documentObject, let info = docObj.info, newInfoFieldText == info {
            return
        }
        // Note that info is an optional field, so it may not be present in the database. (However currently in practice, we set it to a blank string.)
        if let docObj = documentObject, newInfoFieldText.count <= REConstants.DataValidator.maxInfoRawCharacterLength {
            docObj.info = newInfoFieldText
            
            do {
                if moc.hasChanges {
                    try moc.save()
                }
                
            } catch {
                // In this case, we need to rollback, because for some reason the save failed. Rollback is needed because this function is typically run when the managedObject is being displayed in the interface.
                moc.rollback()
                throw CoreDataErrors.saveError
            }
        }
    }
    // It is assumed this is called from a UI that checks newGroupFieldText is valid and informs the user. Here, if no change is necesary or max length is exceeded, we return without throwing.
    func updateGroupForOneDocument(documentObject: Document?, newGroupFieldText: String, moc: NSManagedObjectContext) throws {
        // check for identity
        if let docObj = documentObject, let group = docObj.group, newGroupFieldText == group {
            return
        }
        // Note that group is an optional field, so it may not be present in the database. (However currently in practice, we set it to a blank string.)
        if let docObj = documentObject, newGroupFieldText.count <= REConstants.DataValidator.maxGroupRawCharacterLength {
            docObj.group = newGroupFieldText
            
            do {
                if moc.hasChanges {
                    try moc.save()
                }
                
            } catch {
                // In this case, we need to rollback, because for some reason the save failed. Rollback is needed because this function is typically run when the managedObject is being displayed in the interface.
                moc.rollback()
                throw CoreDataErrors.saveError
            }
        }
    }
    
    func toggleViewPropertyForOneDocument(documentObject: Document?, moc: NSManagedObjectContext) throws {
        if let docObj = documentObject {
            if docObj.viewed {
                docObj.viewed = false
                docObj.lastViewed = nil
            } else {
                docObj.viewed = true
                docObj.lastViewed = Date()
            }
            
            do {
                if moc.hasChanges {
                    try moc.save()
                }
            } catch {
                // In this case, we need to rollback, because for some reason the save failed. Rollback is needed because this function is typically run when the managedObject is being displayed in the interface.
                moc.rollback()
                throw CoreDataErrors.saveError
            }
        }
    }
    
    func updateLabelForOneDocument(documentObject: Document?, newLabel: Int, moc: NSManagedObjectContext) throws {
        if let docObj = documentObject, DataController.isValidLabel(label: newLabel, numberOfClasses: numberOfClasses), newLabel != docObj.label {
            let previousLabel = docObj.label
            docObj.label = newLabel
            // modified records that a label was changed
            docObj.modified = true
            docObj.lastModified = Date()
            
            // Update state; note that a label can be changed before prediction has occurred, so models may not yet exist
            // If the document belongs to training or calibration, increment the models
            
            do {
                try updateStateForOneDocumentWithLabelChange(documentObject: docObj, previousLabel: previousLabel, newLabel: newLabel, moc: moc)
                if moc.hasChanges {
                    try moc.save()
                }
                
            } catch {
                // In this case, we need to rollback, because for some reason the save failed. Rollback is needed because this function is typically run when the managedObject is being displayed in the interface.
                moc.rollback()
                throw CoreDataErrors.saveError
            }
        }
    }
    
    // Important: Remember to run try await updateInMemoryDatasetStats(moc: moc, dataController: dataController)
    // It should already be checked that the new datasplit has sufficient space
    func transferOneDocument(documentObject: Document?, newDatasplitId: Int, moc: NSManagedObjectContext) throws {
        if let docObj = documentObject, let oldDatasplitId = docObj.dataset?.id, oldDatasplitId != newDatasplitId {
            
            do {
                let fetchRequest = Dataset.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", NSNumber(value: oldDatasplitId))
                let datasetRequest = try moc.fetch(fetchRequest) //as [Dataset]
                
                if datasetRequest.isEmpty {
                    throw CoreDataErrors.saveError
                }
                let dataset = datasetRequest[0]
//                dataset.removeFromDocuments(docObj)
                
                
                let newfetchRequest = Dataset.fetchRequest()
                newfetchRequest.predicate = NSPredicate(format: "id == %@", NSNumber(value: newDatasplitId))
                let newdatasetRequest = try moc.fetch(newfetchRequest) //as [Dataset]
                
                if newdatasetRequest.isEmpty {
                    throw CoreDataErrors.saveError
                }
                
                let newDataset = newdatasetRequest[0]
                if let datasetDocuments = newDataset.documents, datasetDocuments.count + 1 <= REConstants.DatasetsConstraints.maxTotalLines {
                    dataset.removeFromDocuments(docObj)
                    newDataset.addToDocuments(docObj)
                } else {  // unexpectedly, the new dataset does not have space, so throw
                    throw CoreDataErrors.saveError
                }
                
                // Update state; note that a label can be changed before prediction has occurred, so models may not yet exist
                try updateStateForOneDocumentWithDatasplitTransfer(documentObject: docObj, previousDatasplitId: oldDatasplitId, newDatasplitId: newDatasplitId, moc: moc)
                //                try updateStateForOneDocumentWithLabelChange(placeholderDatasetId: placeholderDatasetId, documentObject: docObj, previousLabel: labelPlaceholder, newLabel: newLabelPlaceholder, moc: moc)
                if moc.hasChanges {
                    try moc.save()
                }
                
            } catch {
                // In this case, we need to rollback, because for some reason the save failed. Rollback is needed because this function is typically run when the managedObject is being displayed in the interface.
                moc.rollback()
                throw CoreDataErrors.saveError
            }
        }
    }
    
    func deleteOneDocument(documentObject: Document?, moc: NSManagedObjectContext) throws {
        if let docObj = documentObject {
            
            do {
                // Record model state before deleting
                let stateChange: StateChangeType = try getStateForOneDocumentDeletion(documentObject: docObj)

                moc.delete(docObj)
                
                try updateBasedOnState(stateChange: stateChange, moc: moc)
                
                if moc.hasChanges {
                    try moc.save()
                }
                
            } catch {
                // In this case, we need to rollback, because for some reason the save failed. Rollback is needed because this function is typically run when the managedObject is being displayed in the interface.
                moc.rollback()
                throw CoreDataErrors.saveError
            }
        }
    }
}

