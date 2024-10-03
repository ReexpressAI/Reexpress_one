//
//  UncertaintyStatistics.swift
//  Alpha1
//
//  Created by A on 4/23/23.
//

import Foundation
import CoreData
import CoreML
import Accelerate



// for graphing:
// q, predicted class, d0, true class

class UncertaintyStatistics {
    
    typealias CalibratedOutputType = (minDistribution: [Float32], sizeOfCategory: Float32)
    
    var uncertaintyModelUUID: String
    var indexModelUUID: String
    var needsRefresh: Bool = false
    
    var alpha: Float32 = REConstants.Uncertainty.defaultConformalAlpha
    var conformalThresholdTolerance: Float32 = REConstants.Uncertainty.defaultConformalThresholdTolerance
    var qMax: Int = REConstants.Uncertainty.defaultQMax
    var numberOfClasses: Int
    
    var trueClass_To_QToD0Statistics: [ Int: [QCategory: (median: Float32, max: Float32)] ] = [:]
    var qCategory_To_Thresholds: [ QCategory: [Float32] ] = [:]
    
    var vennADMITCategory_To_CalibratedOutput: [VennADMITCategory: CalibratedOutputType?] = [:]
    
    var validKnownLabelsMinD0: Float32 = Float32.infinity
    var validKnownLabelsMaxD0: Float32 = -Float32.infinity

    var uncertaintyGraphCoordinator: UncertaintyGraphCoordinator?
    private var calibrationIdToDataPointsValidKnown: [ String: DataPoint ] = [:]  // only points with valid known labels
    private var vennADMITCategory_To_CalibrationIds: [VennADMITCategory: Set<String>] = [:]
    
    init(uncertaintyModelUUID: String, indexModelUUID: String, alpha: Float32 = REConstants.Uncertainty.defaultConformalAlpha, conformalThresholdTolerance: Float32 = REConstants.Uncertainty.defaultConformalThresholdTolerance, qMax: Int = REConstants.Uncertainty.defaultQMax, numberOfClasses: Int) {

        self.uncertaintyModelUUID = uncertaintyModelUUID
        self.indexModelUUID = indexModelUUID
        self.alpha = alpha
        self.conformalThresholdTolerance = conformalThresholdTolerance
        self.qMax = qMax
        self.numberOfClasses = numberOfClasses

        // Initialize
        for trueLabel in 0..<numberOfClasses {
            trueClass_To_QToD0Statistics[trueLabel] = [:]
        }
    }
    

    
    func getDistanceCategory(prediction: Int, qCategory: QCategory, d0: Float32) -> DistanceCategory {
        if let d0Stats = trueClass_To_QToD0Statistics[prediction]?[qCategory] {
            switch d0 {
            case 0...d0Stats.median:
                return DistanceCategory.lessThanOrEqualToMedian
            case d0Stats.median...d0Stats.max:
                return DistanceCategory.greaterThanMedianAndLessThanOrEqualToOOD
            default:
                return DistanceCategory.greaterThanOOD
            }
        }
        return DistanceCategory.greaterThanOOD
    }
    

    
    /// This should typically only be run on the calibration set, as the ground-truth labels are used.
    func calculateD0QuantileDivisions(numberOfClasses: Int, uncertaintyStructureByTrueClass: [Int: [(documentId: String, prediction: Int, softmax: [Float32], d0: Float32, q: Int)]]) async {

        // Initialize
        var trueClass_To_QToD0TP: [ Int: [QCategory: [Float32]] ] = [:]  // { true label->{ q -> d0's} }
        for trueLabel in 0..<numberOfClasses {
            trueClass_To_QToD0TP[trueLabel] = [:]
            for qCategory in QCategory.allCases {
                trueClass_To_QToD0TP[trueLabel]?[qCategory] = []
            }
        }
        
        for trueLabel in 0..<numberOfClasses {
            if let uncertaintyStructureForLabel = uncertaintyStructureByTrueClass[trueLabel] {
                for uncertaintyStructure in uncertaintyStructureForLabel {
                    if uncertaintyStructure.d0 < validKnownLabelsMinD0 {
                        validKnownLabelsMinD0 = uncertaintyStructure.d0
                    }
                    if uncertaintyStructure.d0 > validKnownLabelsMaxD0 {
                        validKnownLabelsMaxD0 = uncertaintyStructure.d0
                    }
                    if uncertaintyStructure.prediction == trueLabel && DataController.isKnownValidLabel(label: trueLabel, numberOfClasses: numberOfClasses) {
                        switch uncertaintyStructure.q {
                        case 0:
                            trueClass_To_QToD0TP[trueLabel]?[QCategory.zero]?.append(uncertaintyStructure.d0)
                        case 1..<qMax:
                            trueClass_To_QToD0TP[trueLabel]?[QCategory.oneToQMax]?.append(uncertaintyStructure.d0)
                        case qMax...:
                            trueClass_To_QToD0TP[trueLabel]?[QCategory.qMax]?.append(uncertaintyStructure.d0)
                        default:
                            continue
                        }
                    }
                }
            }
        }
        
        for trueLabel in 0..<numberOfClasses {
            for qCategory in QCategory.allCases {
                if let quantiles = trueClass_To_QToD0TP[trueLabel]?[qCategory]?.quantiles(at: [0.5, 1.0]), let medianTPD0 = quantiles.first, let maxTPD0 = quantiles.last { 
                    trueClass_To_QToD0Statistics[trueLabel]?[qCategory] = (median: medianTPD0, max: maxTPD0)
                }
            }
        }
    }
    

        
    /// Calculated for calibration. Note that leave-one-out is statistically unnecessary, since we are setting 100 as our sample size min and our resolution is 0.01.
    ///  Note that thresholds are calculated without regard to the distance category.
    func calculateADMITSetsForCalibration(numberOfClasses: Int, uncertaintyStructureByTrueClass: [Int: [(documentId: String, prediction: Int, softmax: [Float32], d0: Float32, q: Int)]]) async { 

        var qCategory_To_CalibrationIds: [ QCategory: [String] ] = [:]
        var qCategory_To_TrueClass_To_TrueSoftmaxOutputs: [ QCategory: [Int: [Float32]] ] = [:]
        for qCategory in QCategory.allCases {
            qCategory_To_CalibrationIds[qCategory] = []
            qCategory_To_TrueClass_To_TrueSoftmaxOutputs[qCategory] = [:]
            for trueLabel in 0..<numberOfClasses {
                qCategory_To_TrueClass_To_TrueSoftmaxOutputs[qCategory]?[trueLabel] = []
            }
        }
        for trueLabel in 0..<numberOfClasses {
            if let uncertaintyStructureForLabel = uncertaintyStructureByTrueClass[trueLabel] {
                for uncertaintyStructure in uncertaintyStructureForLabel {
                    
                    if let qCategory = getQCategory(q: uncertaintyStructure.q) {
                        let distanceCategory = getDistanceCategory(prediction: uncertaintyStructure.prediction, qCategory: qCategory, d0: uncertaintyStructure.d0)
                        // Note that some of the fields are set to holder defaults (e.g., topKdistances are available at this point but are not needed here, so we save the storage space):
                        let dataPoint = DataPoint(id: uncertaintyStructure.documentId, label: trueLabel, prediction: uncertaintyStructure.prediction, softmax: uncertaintyStructure.softmax, d0: uncertaintyStructure.d0, q: uncertaintyStructure.q, topKdistances: [], topKIndexesAsDocumentIds: [], qCategory: qCategory, calibratedOutput: nil, compositionCategory: .null, distanceCategory: distanceCategory,featureMatchesDocLevelSentenceRangeStart: -1, featureMatchesDocLevelSentenceRangeEnd: -1
                        )
                        calibrationIdToDataPointsValidKnown[dataPoint.id] = dataPoint
                        qCategory_To_CalibrationIds[qCategory]?.append(dataPoint.id)
                        qCategory_To_TrueClass_To_TrueSoftmaxOutputs[qCategory]?[trueLabel]?.append(dataPoint.softmax[dataPoint.label])
                    }
                }
            }
        }
        
        // ADMIT sets
        /*var psSizes: [Int] = Array<Int>(repeating: 0, count: getAllPredictionSetCompositionIds().count)
        var covered = Array<Float32>(repeating: 0.0, count: numberOfClasses)
        var total = Array<Float32>(repeating: 0.0, count: numberOfClasses)
        var coveredSingleton = Array<Float32>(repeating: 0.0, count: numberOfClasses)
        var totalSingleton = Array<Float32>(repeating: 0.0, count: numberOfClasses)
        */
        for qCategory in QCategory.allCases {
            
            // calculate the thresholds once for all points in the category
            var thresholds = Array<Float32>(repeating: 0.0, count: numberOfClasses)
            for trueLabel in 0..<numberOfClasses {
                if let softmaxOutputs = qCategory_To_TrueClass_To_TrueSoftmaxOutputs[qCategory]?[trueLabel] {
                    if let threshold = getConformalThresholdForClass(softmaxOutputForTrueClass: softmaxOutputs, alpha: alpha, tolerance: conformalThresholdTolerance) {
                        thresholds[trueLabel] = threshold
                    }
                }
            }
            qCategory_To_Thresholds[qCategory] = thresholds
            if let dataPointIds = qCategory_To_CalibrationIds[qCategory] {
                for dataPointId in dataPointIds {
                    guard let dataPoint = calibrationIdToDataPointsValidKnown[dataPointId] else {
                        continue
                    }

                    if let predictionSet = try? await constructPredictionSetFromThresholds(numberOfClasses: numberOfClasses, prediction: dataPoint.prediction, softmax: dataPoint.softmax, thresholds: thresholds) {

                        let predictionSetCompositionId = getPredictionSetCompositionId(numberOfClasses: numberOfClasses, prediction: dataPoint.prediction, predictionSet: predictionSet)
                        
                        calibrationIdToDataPointsValidKnown[dataPoint.id]?.compositionCategory = getCompositionCategoryFromPredictionSetCompositionId(predictionSetCompositionId: predictionSetCompositionId)
                        
                        //qCategory_To_CompositionId_To_PredictedClass_To_CalibrationIds[qCategory]?[predictionSetCompositionId]?[dataPoint.prediction]?.insert(dataPoint.id)
        
                        let qdfCategory = VennADMITCategory(prediction: dataPoint.prediction, qCategory: qCategory, distanceCategory: dataPoint.distanceCategory, compositionCategory: getCompositionCategoryFromPredictionSetCompositionId(predictionSetCompositionId: predictionSetCompositionId))
                        if let _  = vennADMITCategory_To_CalibrationIds[qdfCategory] {
                            vennADMITCategory_To_CalibrationIds[qdfCategory]?.insert(dataPoint.id)
                        } else {
                            vennADMITCategory_To_CalibrationIds[qdfCategory] = Set([dataPoint.id])
                        }
//                        qCategory_To_CompositionId_To_PredictedClass_To_DistanceCategory_To_CalibrationIds[qCategory]?[predictionSetCompositionId]?[dataPoint.prediction]?[dataPoint.distanceCategory]?.insert(dataPoint.id)

                        /*psSizes[predictionSetCompositionId] += 1
                        
                        total[dataPoint.label] += 1
                        if predictionSet.contains(dataPoint.label) {
                            covered[dataPoint.label] += 1
                        }
                        if predictionSetCompositionId < numberOfClasses {
                            totalSingleton[dataPoint.label] += 1
                            if predictionSet.contains(dataPoint.label) {
                                coveredSingleton[dataPoint.label] += 1
                            }
                        }
                         */
                    }
                }
            }
        }
        
//        print(vennADMITCategory_To_CalibrationIds.count)
//        print(psSizes)
//        for label in 0..<numberOfClasses {
//            print("Label: \(label); coverage: \(covered[label] / max(1, total[label]))")
//            print("Label: \(label); coverage (singleton): \(coveredSingleton[label] / max(1, totalSingleton[label]))")
//        }
        
    }
    
    func getConformalThresholdForClass(softmaxOutputForTrueClass: [Float32], alpha: Float32 = REConstants.Uncertainty.defaultConformalAlpha, tolerance: Float32 = REConstants.Uncertainty.defaultConformalThresholdTolerance) -> Float32? {
        var softmaxOutputForTrueClass = softmaxOutputForTrueClass
        vDSP.sort(&softmaxOutputForTrueClass, sortOrder: .ascending)
        if let quantile = softmaxOutputForTrueClass.quantile(at: 1-alpha, sort: false) {
            return max( quantile - tolerance, 0.0)
        }
        return nil
    }
    
    func constructPredictionSetFromThresholds(numberOfClasses: Int, prediction: Int, softmax: [Float32], thresholds: [Float32]) async throws -> Set<Int> {
        if !(softmax.count == thresholds.count && numberOfClasses == softmax.count) {
            throw UncertaintyErrors.thresholdDimensionError
        }
        var predictionSet = Set<Int>()
        for label in 0..<numberOfClasses {
            if softmax[label] >= thresholds[label] {
                predictionSet.insert(label)
            }
        }
        return predictionSet
    }


    
    /// Note that we are including all points together, rather than leave-one-out.
    func constructVennPredictionForCalibration() async throws {
        // One pass over all q categories, prediction set composition ids, and predictions for calibration
        for qCategory in QCategory.allCases {
            
            for predictionSetCompositionId in getAllPredictionSetCompositionIds() {

                for prediction in 0..<numberOfClasses {

                    for distanceCategory in DistanceCategory.allCases {
                        let qdfCategory = VennADMITCategory(prediction: prediction, qCategory: qCategory, distanceCategory: distanceCategory, compositionCategory: getCompositionCategoryFromPredictionSetCompositionId(predictionSetCompositionId: predictionSetCompositionId))
                        
                        guard let categoryDataPointIds = vennADMITCategory_To_CalibrationIds[qdfCategory], categoryDataPointIds.count > 0 else {  // Calculate for only single point categories, but typically small categories should be used with caution.
                            continue
                        }

                        // Note the +1, as these pre-calculated values are intended for use with a separate test point. This has the effect of adding a degree of slack, but in practice, since our min sample size for display is 100 and we set a resolution of 0.01, it tends not to make a difference in practice.
                        let sizeOfCategory: Float32 = Float32(categoryDataPointIds.count) + 1.0
                        
                        var minUnnormalizedDistribution = Array<Float32>(repeating: 0.0, count: numberOfClasses)
                        
                        for trueClass in 0..<numberOfClasses {
                            
                            minUnnormalizedDistribution[trueClass] = vDSP.sum( categoryDataPointIds.map { calibrationIdToDataPointsValidKnown[$0]?.label == trueClass ? Float32(1.0) : Float32(0.0) } )
                            
                        }
                        let minDistribution = vDSP.divide(minUnnormalizedDistribution, sizeOfCategory)
                        
                        // We reduce sizeOfCategory by 1. The client is then responsible for how to convey the normalization to the end-user.
                        vennADMITCategory_To_CalibratedOutput[qdfCategory] = (minDistribution: minDistribution, sizeOfCategory: sizeOfCategory-1.0)
                        
                        // MARK: We do not update calibration datapoints here, because any unlabeled datapoints in the calibration set would not be included. Instead, we run another pass in the same manner as with all other datasplits.
                    }
                }
            }
        }
    }
    
}
