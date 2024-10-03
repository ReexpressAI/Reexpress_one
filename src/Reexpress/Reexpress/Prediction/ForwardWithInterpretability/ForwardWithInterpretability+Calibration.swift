//
//  ForwardWithInterpretability+Calibration.swift
//  Alpha1
//
//  Created by A on 8/3/23.
//

import SwiftUI
import CoreML

extension MainForwardAfterTrainingView {
    // need separate methods for when the labels are not available
    func calculateUncertaintyForCalibration(newCalibrationDocumentsArePresent: Bool) async throws {

        // determine if UncertaintyStatistics is already up to date. If not, create a new Uncertainty Model.
        let uncertaintyStatisticsAreCurrent = !newCalibrationDocumentsArePresent && dataController.isUncertaintyModelCurrent()
        if !uncertaintyStatisticsAreCurrent {
            let calibrationUncertaintyStructureByTrueClass = try await dataController.getUncertaintyStructureForDatasetFromDatabaseOnlyKnownValidLabels(datasetId: REConstants.DatasetsEnum.calibration.rawValue, numberOfClasses: dataController.numberOfClasses, moc: moc)
            if calibrationUncertaintyStructureByTrueClass.isEmpty {
                return
            }
            let uncertaintyModelUUID = UUID().uuidString
            let uncertaintyStatistics = UncertaintyStatistics(uncertaintyModelUUID: uncertaintyModelUUID, indexModelUUID: dataController.inMemory_KeyModelGlobalControl.indexModelUUID, alpha: REConstants.Uncertainty.defaultConformalAlpha, qMax: REConstants.Uncertainty.defaultQMax, numberOfClasses: dataController.numberOfClasses)
            // next determine d0 splits per class
            await uncertaintyStatistics.calculateD0QuantileDivisions(numberOfClasses: dataController.numberOfClasses, uncertaintyStructureByTrueClass: calibrationUncertaintyStructureByTrueClass)
            if Task.isCancelled {
                throw MLForwardErrors.forwardPassWasCancelled
            }
            // now determine ADMIT sets for calibration
            await uncertaintyStatistics.calculateADMITSetsForCalibration(numberOfClasses: dataController.numberOfClasses, uncertaintyStructureByTrueClass: calibrationUncertaintyStructureByTrueClass)
            
            try await uncertaintyStatistics.constructVennPredictionForCalibration()
            if Task.isCancelled {
                throw MLForwardErrors.forwardPassWasCancelled
            }
            uncertaintyStatistics.needsRefresh = false
            // save to disk
            try await uncertaintyStatistics.save(moc: moc)
            // Update in-memory version:
            dataController.uncertaintyStatistics = uncertaintyStatistics
        }
    }
    
    // We run over calibration, as well. (This takes care of any unlabeled points in calibration, which are not considered in the above data structures.)
    func calibrateNewData(datasetId: Int) async throws {
        guard let uncertaintyStatistics = dataController.uncertaintyStatistics else {
            throw UncertaintyErrors.uncertaintyStatisticsIsUnexepctedlyMissing
        }
        let evalDataPoints = try await uncertaintyStatistics.getDataPointsForDatasetFromDatabase(datasetId: datasetId, numberOfClasses: dataController.numberOfClasses, moc: moc, returnAllData: false)
        if evalDataPoints.isEmpty {
            return
        }
        await MainActor.run {
            // update progress
            let _ = inferenceDatasetIds2InferenceProgress.updateValue(
                InferenceProgress(datasetId: datasetId,
                                  totalDocuments: evalDataPoints.count,
                                  currentDocumentProgress: 0,
                                  inferenceProgressStatus: .calibrating),
                forKey: datasetId)
        }
        let evalDataPointsCalibrated = await uncertaintyStatistics.calibrateTest(dataPoints: evalDataPoints)
        // save
        let chunkSize = 1000
        let documentIds = Array(evalDataPointsCalibrated.keys)
        for chunkIndex in stride(from: 0, to: documentIds.count, by: chunkSize) {
            await MainActor.run {
                // update progress -- Note that currently this just records the save step
                let _ = inferenceDatasetIds2InferenceProgress.updateValue(
                    InferenceProgress(datasetId: datasetId,
                                      totalDocuments: documentIds.count,
                                      currentDocumentProgress: chunkIndex,
                                      inferenceProgressStatus: .calibrating),
                    forKey: datasetId)
            }
            if Task.isCancelled {
                throw MLForwardErrors.forwardPassWasCancelled
            }

            var dataChunk: [ String: UncertaintyStatistics.DataPoint ] = [:]
            
            let startIndex = chunkIndex
            let endIndex = min(startIndex + chunkSize, documentIds.count)
            let documentIdsChunkArray: [String] = Array(documentIds[startIndex..<endIndex])
            
            if documentIdsChunkArray.isEmpty {
                break
            }
            for documentId in documentIdsChunkArray {
                dataChunk[documentId] = evalDataPointsCalibrated[documentId]
            }
            
            try await dataController.addCalibratedUncertaintyStructureForDataset(datasetId: datasetId, dataChunk: dataChunk, moc: moc)
        }
        await MainActor.run {
            // update progress
            let _ = inferenceDatasetIds2InferenceProgress.updateValue(
                InferenceProgress(datasetId: datasetId,
                                  totalDocuments: documentIds.count,
                                  currentDocumentProgress: documentIds.count,
                                  inferenceProgressStatus: .calibrating),
                forKey: datasetId)
        }
    }
}
