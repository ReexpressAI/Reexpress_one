//
//  ForwardWithInterpretability+Main.swift
//  Alpha1
//
//  Created by A on 8/3/23.
//

import SwiftUI
import CoreML

extension MainForwardAfterTrainingView {
    /* Progress:
     We first run the forward pass with interpretability on train and calibration.
     Then we forward index calibration.
     We construct the calibration object.
     We run a standard forward calibration step on the Calibration set.
     We forward index training (for reference, up to 99 matches, leaving out self).
     
     Then for all additional datasets selected by the user:
        -Run the forward pass with interpretability
        -Forward index
        -Calibrate
     */
    func mainForwardAfterTraining() async throws {
        if !dataController.isModelTrainedandIndexed() {
            if dataController.inMemory_KeyModelGlobalControl.modelWeights == nil {
                throw KeyModelErrors.keyModelWeightsMissing
            }
            if dataController.inMemory_KeyModelGlobalControl.indexModelWeights == nil {
                throw KeyModelErrors.indexModelWeightsMissing
            }
            // Make sure model state is marked out-of-date (discrepancy could arise due to a task cancel)
            try await dataController.updateBasedOnStaleIndexModel(moc: moc)
            throw KeyModelErrors.compressionNotCurrent
        }
        
        if !(inferenceDatasetIds.contains(REConstants.DatasetsEnum.train.rawValue) && inferenceDatasetIds.contains(REConstants.DatasetsEnum.calibration.rawValue)) {
            throw CoreDataErrors.datasetNotFound
        }
        
        //let start = Date.now
        
        //let batchSize = 100 //32 //1 //100  //250 // 100 //1000
        let batchSize = programModeController.batchSize
        let chunkSize = 1000
        try await forward_modelGroup(batchSize: batchSize, datasetId: REConstants.DatasetsEnum.train.rawValue)
        try await forward_modelGroup(batchSize: batchSize, datasetId: REConstants.DatasetsEnum.calibration.rawValue)
        
        let calibrationData = try await dataController.getExemplarDataFromDatabase(modelControlIdString: REConstants.ModelControl.keyModelId, datasetId: REConstants.DatasetsEnum.calibration.rawValue, moc: moc, returnAllData: false) // [String: (label: Int, prediction: Int, exemplar: [Float32], softmax: [Float32])]
        
        if Task.isCancelled {
            throw MLForwardErrors.forwardPassWasCancelled
        }
        let newCalibrationDocumentsArePresent: Bool = calibrationData.count != 0
        // runForwardIndex support should not be split across support, so we return all data
        let trainingData = try await dataController.getExemplarDataFromDatabase(modelControlIdString: REConstants.ModelControl.keyModelId, datasetId: REConstants.DatasetsEnum.train.rawValue, moc: moc, returnAllData: true)
        if Task.isCancelled {
            throw MLForwardErrors.forwardPassWasCancelled
        }
        // batch index and save calibrationData
        try await batchForwardIndex(datasetId: REConstants.DatasetsEnum.calibration.rawValue, chunkSize: chunkSize, query: calibrationData, support: trainingData)
        
        try await calculateUncertaintyForCalibration(newCalibrationDocumentsArePresent: newCalibrationDocumentsArePresent)
        
        try await calibrateNewData(datasetId: REConstants.DatasetsEnum.calibration.rawValue)
        
        
        await MainActor.run {
            // update progress
            let _ = inferenceDatasetIds2InferenceProgress.updateValue(
                InferenceProgress(datasetId: REConstants.DatasetsEnum.calibration.rawValue,
                                  totalDocuments: 0,
                                  currentDocumentProgress: 0,
                                  inferenceProgressStatus: .complete),
                forKey: REConstants.DatasetsEnum.calibration.rawValue)
        }
        
        // Note that training will be against itself here (up to 99 instances instead of 100 because of leave-one-out)
        try await batchForwardIndex(datasetId: REConstants.DatasetsEnum.train.rawValue, chunkSize: chunkSize, query: trainingData, support: trainingData)
        try await calibrateNewData(datasetId: REConstants.DatasetsEnum.train.rawValue)
        
        await MainActor.run {
            // update progress
            let _ = inferenceDatasetIds2InferenceProgress.updateValue(
                InferenceProgress(datasetId: REConstants.DatasetsEnum.train.rawValue,
                                  totalDocuments: 0,
                                  currentDocumentProgress: 0,
                                  inferenceProgressStatus: .complete),
                forKey: REConstants.DatasetsEnum.train.rawValue)
        }
        
        // Remaining selected datasets, if any:
        for evalDatasetId in inferenceDatasetIds.sorted() {
            if evalDatasetId != REConstants.DatasetsEnum.train.rawValue && evalDatasetId != REConstants.DatasetsEnum.calibration.rawValue {
                try await forward_modelGroup(batchSize: batchSize, datasetId: evalDatasetId)
                
                let evalData = try await dataController.getExemplarDataFromDatabase(modelControlIdString: REConstants.ModelControl.keyModelId, datasetId: evalDatasetId, moc: moc, returnAllData: false)
                // trainingData is the same as above
                try await batchForwardIndex(datasetId: evalDatasetId, chunkSize: chunkSize, query: evalData, support: trainingData)
                try await calibrateNewData(datasetId: evalDatasetId)
                
                await MainActor.run {
                    // update progress
                    let _ = inferenceDatasetIds2InferenceProgress.updateValue(
                        InferenceProgress(datasetId: evalDatasetId,
                                          totalDocuments: 0,
                                          currentDocumentProgress: 0,
                                          inferenceProgressStatus: .complete),
                        forKey: evalDatasetId)
                }
            }
        }
        await MainActor.run {
            allPredictionsComplete = true
        }
        
        //print("Duration of prediction: \(Date.now.timeIntervalSince(start))")
    }
}
