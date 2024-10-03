//
//  DataController+Status.swift
//  Alpha1
//
//  Created by A on 7/29/23.
//

import Foundation

// Methods to check whether models and predictions are current.
extension DataController {
    
    func isPredictionCurrentBasedOnModelUUID(modelUUIDForDocument: String?) -> Bool {
        if let modelUUID = modelUUIDForDocument {
            if modelUUID == REConstants.ModelControl.defaultIndexModelUUID {
                return false
            } else {
                return modelUUID == inMemory_KeyModelGlobalControl.indexModelUUID
            }
        } else {
            return false
        }
    }
    func isModelTrainedandIndexed() -> Bool {
        if inMemory_KeyModelGlobalControl.keyModelUUID == REConstants.ModelControl.defaultIndexModelUUID || inMemory_KeyModelGlobalControl.indexModelUUID == REConstants.ModelControl.defaultIndexModelUUID {
            return false
        }
        return inMemory_KeyModelGlobalControl.keyModelUUID == inMemory_KeyModelGlobalControl.keyModelUUIDOwnedByIndexModel
    }
    
    func isPredictionUncertaintyCurrent(documentUncertaintyModelUUID: String) -> Bool {
//        guard let uncertaintyModelUUID = uncertaintyStatistics?.uncertaintyModelUUID, let indexModelUUIDOwnedByUnceraintyModel = uncertaintyStatistics?.indexModelUUID else {
//            return false
//        }
        
        guard let uncertaintyStatistics = uncertaintyStatistics else {
            return false
        }
        let uncertaintyModelUUID = uncertaintyStatistics.uncertaintyModelUUID
        return isUncertaintyModelCurrent() && documentUncertaintyModelUUID == uncertaintyModelUUID
        
        /*let indexModelUUIDOwnedByUnceraintyModel = uncertaintyStatistics.indexModelUUID
        let indexModelUUID = inMemory_KeyModelGlobalControl.indexModelUUID
        // at the document-level, uncertaintyStatistics.needsRefresh is redundant (but it is needed for global checks), but since it should neve be out-of-sync with the document UUID checks, we also consider it here
        // We also check that the index model, itself, is up to date: keyModel->indexModel->Uncertainty
        return documentUncertaintyModelUUID != REConstants.ModelControl.defaultUncertaintyModelUUID && documentUncertaintyModelUUID == uncertaintyModelUUID && indexModelUUIDOwnedByUnceraintyModel == indexModelUUID && !uncertaintyStatistics.needsRefresh*/
    }
    // Note that this checks the forward direction with the uuid: If index model changes, uncertainty needs update. And the reverse direction with needsRefresh: If train/calibration data changes, then know to update via needsRefresh. We also check that the index model, itself, is up to date: keyModel->indexModel->Uncertainty
    func isUncertaintyModelCurrent() -> Bool {
        guard let uncertaintyStatistics = uncertaintyStatistics else {
            return false
        }
        
        let uncertaintyModelUUID = uncertaintyStatistics.uncertaintyModelUUID
        let indexModelUUIDOwnedByUnceraintyModel = uncertaintyStatistics.indexModelUUID
        let indexModelUUID = inMemory_KeyModelGlobalControl.indexModelUUID
        
        return isModelTrainedandIndexed() && uncertaintyModelUUID != REConstants.ModelControl.defaultUncertaintyModelUUID && indexModelUUIDOwnedByUnceraintyModel == indexModelUUID && !uncertaintyStatistics.needsRefresh
    }
}
