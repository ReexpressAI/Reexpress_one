//
//  DataController+CoreData+StateManagement.swift
//  Alpha1
//
//  Created by A on 8/14/23.
//

import Foundation
import CoreData

// NEED TO HANDLE DELETE OF DATASPLIT; ADD DOCUMENTS



/*
 Overview: modelControl.state exists to be able to record when documents in training or calibration have changed. The UUID strings, on the other hand, ensure that the models are consistent within themselves. That is, the training and/or calibration sets may change but the models can stay the same; it is a separate state issue when, for example, the index model has changed, but the uncertainty model has not been updated.
 
 If the label of a Document is changed:
 If in Training or Calibration:
 Primary model and Index model become stale
 Increment Uncertainty Model ID?
 
 If NOT in Training Nor Calibration:
 
 If the datasplit of a Document is changed:
 If was or now in Training or Calibration:
 
 If NOT in Training Nor Calibration (previously or now):
 */

extension DataController {
    
    enum StateChangeType: Int {
        //        case modelTrainingConditionsChanged = 0  // if training changed, then uncertainty also changes (so use 2)
        case onlyUncertaintyConditionsChanged = 1
        case modelTrainingAndUncertaintyConditionsChanged = 2
        case noStateChange = 3
    }
    // Called when uploading new document(s)
    // Marked as _Coarse since this takes a simpler approach than state management for existing documents. Here, we simply trigger a change if ANY documents are added to train or calibration, but do not consider the actual labels themselves.
    func updateStateForDataUpload_Coarse(datasetId: Int, moc: NSManagedObjectContext) throws {
        let stateChange = try getStateForDataUpload_Coarse(datasetId: datasetId)
        if stateChange != .noStateChange {
            try updateBasedOnState(stateChange: stateChange, moc: moc)
        }
    }
    func getStateForDataUpload_Coarse(datasetId: Int) throws -> StateChangeType {
        var stateChange: StateChangeType = .noStateChange
        
        if datasetId == REConstants.DatasetsEnum.calibration.rawValue {
            stateChange = .onlyUncertaintyConditionsChanged
        }
        if datasetId == REConstants.DatasetsEnum.train.rawValue {
            stateChange = .modelTrainingAndUncertaintyConditionsChanged
        }
        return stateChange
    }
    
    func updateStateForOneDocumentWithLabelChange(documentObject: Document, previousLabel: Int, newLabel: Int, moc: NSManagedObjectContext) throws {
        guard let datasetId = documentObject.dataset?.id else {
            // A Document must always be associated with a Dataset.
            throw CoreDataErrors.stateError
        }
        var stateChange: StateChangeType = .noStateChange
        
        if previousLabel != newLabel {
            if datasetId == REConstants.DatasetsEnum.train.rawValue {
                if DataController.isKnownValidLabel(label: previousLabel, numberOfClasses: numberOfClasses) || DataController.isKnownValidLabel(label: newLabel, numberOfClasses: numberOfClasses) {
                    stateChange = .modelTrainingAndUncertaintyConditionsChanged
                }
                /* else {
                 // In this case, labels used for training (i.e., excluding ood and unlabeled) didn't change, so only the uncertainty model is affected
                 stateChange = .onlyUncertaintyConditionsChanged
                 }*/
            } else if datasetId == REConstants.DatasetsEnum.calibration.rawValue {
                // A state change is triggered for calibration if ood/unlabeled change in Training (since it can affect indexing), but no state change is needed if ONLY ood/unlabeled changes in Calibration
                if DataController.isKnownValidLabel(label: previousLabel, numberOfClasses: numberOfClasses) || DataController.isKnownValidLabel(label: newLabel, numberOfClasses: numberOfClasses) {
                    stateChange = .onlyUncertaintyConditionsChanged
                }
            }
            
        }
        try updateBasedOnState(stateChange: stateChange, moc: moc)
    }
    
    func getStateForOneDocumentDeletion(documentObject: Document) throws -> StateChangeType {
        var stateChange: StateChangeType = .noStateChange
        let labelIsKnownValid = DataController.isKnownValidLabel(label: documentObject.label, numberOfClasses: numberOfClasses)
        
        guard let datasetId = documentObject.dataset?.id else {
            // A Document must always be associated with a Dataset.
            throw CoreDataErrors.stateError
        }
        
        if datasetId == REConstants.DatasetsEnum.calibration.rawValue {
            if labelIsKnownValid {
                stateChange = .onlyUncertaintyConditionsChanged
            }
        }
        
        if datasetId == REConstants.DatasetsEnum.train.rawValue {
            if labelIsKnownValid {
                stateChange = .modelTrainingAndUncertaintyConditionsChanged
            } else {  // in this case, indexing will change
                stateChange = .onlyUncertaintyConditionsChanged
            }
        }
        return stateChange
    }
    
    func updateStateForOneDocumentWithDatasplitTransfer(documentObject: Document, previousDatasplitId: Int, newDatasplitId: Int, moc: NSManagedObjectContext) throws {
        
        var stateChange: StateChangeType = .noStateChange
        
        if previousDatasplitId != newDatasplitId {
            let labelIsKnownValid = DataController.isKnownValidLabel(label: documentObject.label, numberOfClasses: numberOfClasses)
            
            if previousDatasplitId == REConstants.DatasetsEnum.calibration.rawValue || newDatasplitId == REConstants.DatasetsEnum.calibration.rawValue {
                if labelIsKnownValid {
                    stateChange = .onlyUncertaintyConditionsChanged
                }
            }
            
            if previousDatasplitId == REConstants.DatasetsEnum.train.rawValue || newDatasplitId == REConstants.DatasetsEnum.train.rawValue {
                if labelIsKnownValid {
                    stateChange = .modelTrainingAndUncertaintyConditionsChanged
                } else {  // in this case, indexing will change
                    stateChange = .onlyUncertaintyConditionsChanged
                }
                
                
            }
        }
        try updateBasedOnState(stateChange: stateChange, moc: moc)
    }
    func updateBasedOnState(stateChange: StateChangeType, moc: NSManagedObjectContext) throws {
        
        if stateChange == .modelTrainingAndUncertaintyConditionsChanged || stateChange == .onlyUncertaintyConditionsChanged {
            if stateChange == .modelTrainingAndUncertaintyConditionsChanged {
                // update Core Data Model state
                let fetchRequest = ModelControl.fetchRequest()
                let results = try moc.fetch(fetchRequest)
                for modelControl in results {
                    if modelControl.id == REConstants.ModelControl.keyModelId {
                        modelControl.state = InMemory_KeyModelGlobalControl.TrainingState.Stale.rawValue
                    } else if modelControl.id == REConstants.ModelControl.indexModelId {
                        modelControl.state = InMemory_KeyModelGlobalControl.IndexState.Stale.rawValue
                    }
                }
            }
            // Update Uncertainty
            let newUncertaintyModelUUID = UUID().uuidString
            
            let fetchRequestUncertainty = UncertaintyModelControl.fetchRequest()
            let resultsUncertainty = try moc.fetch(fetchRequestUncertainty)
            if let uncertaintyModelControl = resultsUncertainty.first {
                uncertaintyModelControl.uncertaintyModelUUID = newUncertaintyModelUUID
                uncertaintyModelControl.needsRefresh = true
            }
            //print("Update State: \(stateChange.rawValue)")
            do {
                if moc.hasChanges {
                    try moc.save()
                }
                // Update in-memory after successful save
                if stateChange == .modelTrainingAndUncertaintyConditionsChanged {
                    if inMemory_KeyModelGlobalControl.trainingState == .Trained {
                        inMemory_KeyModelGlobalControl.trainingState = .Stale
                    }
                    if inMemory_KeyModelGlobalControl.indexState == .Built {
                        inMemory_KeyModelGlobalControl.indexState = .Stale
                    }
                }
                uncertaintyStatistics?.uncertaintyModelUUID = newUncertaintyModelUUID
                uncertaintyStatistics?.needsRefresh = true
                
            } catch {
                // In this case, we need to rollback, because for some reason the save failed. Rollback is needed because this function is typically run when the managedObject is being displayed in the interface.
                moc.rollback()
                throw CoreDataErrors.saveError
            }
            
        }
    }
    // In this case, the index model is Stale and the recorded state needs to be updated
    func updateBasedOnStaleIndexModel(moc: NSManagedObjectContext) async throws {
        try await MainActor.run {
            
            // update Core Data Model state
            let fetchRequest = ModelControl.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", REConstants.ModelControl.indexModelId)
            let results = try moc.fetch(fetchRequest)
            for modelControl in results {
                if modelControl.id == REConstants.ModelControl.indexModelId {
                    modelControl.state = InMemory_KeyModelGlobalControl.IndexState.Stale.rawValue
                }
            }
            // Update Uncertainty
            let newUncertaintyModelUUID = UUID().uuidString
            
            let fetchRequestUncertainty = UncertaintyModelControl.fetchRequest()
            let resultsUncertainty = try moc.fetch(fetchRequestUncertainty)
            if let uncertaintyModelControl = resultsUncertainty.first {
                uncertaintyModelControl.uncertaintyModelUUID = newUncertaintyModelUUID
                uncertaintyModelControl.needsRefresh = true
            }
            
            if moc.hasChanges {
                try moc.save()
            }
            // Update in-memory after successful save
            if inMemory_KeyModelGlobalControl.indexState == .Built {
                inMemory_KeyModelGlobalControl.indexState = .Stale
            }
            
            uncertaintyStatistics?.uncertaintyModelUUID = newUncertaintyModelUUID
            uncertaintyStatistics?.needsRefresh = true
            
        }
    }
}
