//
//  UncertaintyStatistics+AnalysisTests.swift
//  Alpha1
//
//  Created by A on 4/24/23.
//

import Foundation
import CoreData
import CoreML
import Accelerate

/*extension UncertaintyStatistics {
    func analyzeCalibration(dataPoints: [ String: DataPoint ]) {
        var psSizes: [Int] = Array<Int>(repeating: 0, count: getAllPredictionSetCompositionIds().count)
        var covered = Array<Float32>(repeating: 0.0, count: numberOfClasses)
        var total = Array<Float32>(repeating: 0.0, count: numberOfClasses)
        var coveredSingleton = Array<Float32>(repeating: 0.0, count: numberOfClasses)
        var totalSingleton = Array<Float32>(repeating: 0.0, count: numberOfClasses)
        
        var calibratedAtAlpha = Array<Float32>(repeating: 0.0, count: numberOfClasses)
        var totalCalibratedAtAlpha = Array<Float32>(repeating: 0.0, count: numberOfClasses)
        
        var calibratedAtAlpha_D0Restricted = Array<Float32>(repeating: 0.0, count: numberOfClasses)
        var totalCalibratedAtAlpha_D0Restricted = Array<Float32>(repeating: 0.0, count: numberOfClasses)
        
        var calibratedAtAlpha_D0Restricted_QRestricted = Array<Float32>(repeating: 0.0, count: numberOfClasses)
        var totalCalibratedAtAlpha_D0Restricted_QRestricted = Array<Float32>(repeating: 0.0, count: numberOfClasses)
        
        var calibratedAtAlpha_D0Restricted_QRestricted_SingletonADMITRestricted = Array<Float32>(repeating: 0.0, count: numberOfClasses)
        var totalCalibratedAtAlpha_D0Restricted_QRestricted_SingletonADMITRestricted = Array<Float32>(repeating: 0.0, count: numberOfClasses)
        
        var countForQMaxByTrueLabel = Array<Float32>(repeating: 0.0, count: numberOfClasses)
        
        
        
//        qCategory_To_CompositionId_To_PredictedClass_To_DistanceCategory_To_CalibrationVennStructure[dataPoint.qCategory]?[predictionSetCompositionId]?[dataPoint.prediction]?[dataPoint.distanceCategory]
        
        //trueClass_To_QToD0Radius[trueLabel]?[qCategory] = (radius: radius, max: maxD0)
        for (dataPointId, dataPoint) in dataPoints {
            psSizes[dataPoint.predictionSetCompositionId] += 1
            if dataPoint.qCategory == QCategory.qMax {
                countForQMaxByTrueLabel[dataPoint.label] += 1
            }
            total[dataPoint.label] += 1
            if dataPoint.predictionSetCompositionId == dataPoint.label || dataPoint.predictionSetCompositionId == numberOfClasses { //}|| dataPoint.predictionSetCompositionId == numberOfClasses + 1 {
                covered[dataPoint.label] += 1
            }
            if dataPoint.predictionSetCompositionId < numberOfClasses {
                totalSingleton[dataPoint.label] += 1
                if dataPoint.predictionSetCompositionId == dataPoint.label {
                    coveredSingleton[dataPoint.label] += 1
                }
            }
            if let calibratedOutput = dataPoint.calibratedOutput {
//                if calibratedOutput.sizeOfCategory
                let (predicationCalibratedUInt, calibratedVal) = vDSP.indexOfMaximum(calibratedOutput.minDistribution)
                if calibratedVal >= alpha { //alpha {
                    let predicationCalibrated = Int(predicationCalibratedUInt)
                    totalCalibratedAtAlpha[predicationCalibrated] += 1
                    if predicationCalibrated == dataPoint.label {
                        calibratedAtAlpha[predicationCalibrated] += 1
                    }
                    // restricted to d0
//                    if let maxD0 = trueClass_To_QToD0Radius[dataPoint.prediction]?[dataPoint.qCategory]?.max, dataPoint.d0 <= maxD0 {
                    if dataPoint.distanceCategory == DistanceCategory.lessThanOrEqualToMedian {//} DistanceCategory.lessThanOrEqualToMedian {
                        totalCalibratedAtAlpha_D0Restricted[predicationCalibrated] += 1
                        if predicationCalibrated == dataPoint.label {
                            calibratedAtAlpha_D0Restricted[predicationCalibrated] += 1
                        }
                        // additional q restriction
                        if dataPoint.qCategory == QCategory.qMax { //} qMax {
                            totalCalibratedAtAlpha_D0Restricted_QRestricted[predicationCalibrated] += 1
                            if predicationCalibrated == dataPoint.label {
                                calibratedAtAlpha_D0Restricted_QRestricted[predicationCalibrated] += 1
                            }
                            
                            if dataPoint.predictionSetCompositionId < numberOfClasses {
                                totalCalibratedAtAlpha_D0Restricted_QRestricted_SingletonADMITRestricted[predicationCalibrated] += 1
                                if predicationCalibrated == dataPoint.label {
                                    calibratedAtAlpha_D0Restricted_QRestricted_SingletonADMITRestricted[predicationCalibrated] += 1
                                }
                                print("Softmax: \(dataPoint.softmax); calibrated: \(calibratedOutput.minDistribution); size of category: \(calibratedOutput.sizeOfCategory)")
                            }

                        }
                    }
                }
            }
        }
        print(psSizes)
        for label in 0..<numberOfClasses {
            print("Label: \(label); coverage: \(covered[label] / max(1, total[label]))")
            print("Label: \(label); coverage (singleton): \(coveredSingleton[label] / max(1, totalSingleton[label]))")
            
            print("Label: \(label); calibrated > alpha: \(calibratedAtAlpha[label] / max(1, totalCalibratedAtAlpha[label])), total: \(totalCalibratedAtAlpha[label])")
            
            print("Label: \(label); calibrated > alpha, restricted to d0 max for category: \(calibratedAtAlpha_D0Restricted[label] / max(1, totalCalibratedAtAlpha_D0Restricted[label])), total: \(totalCalibratedAtAlpha_D0Restricted[label])")
            
            print("Label: \(label); calibrated > alpha, restricted to d0 max for category, restricted to QCategory.qMax: \(calibratedAtAlpha_D0Restricted_QRestricted[label] / max(1, totalCalibratedAtAlpha_D0Restricted_QRestricted[label])), total: \(totalCalibratedAtAlpha_D0Restricted_QRestricted[label])")
            
            print("Label: \(label); calibrated > alpha, restricted to d0 max for category, restricted to QCategory.qMax, restricted to singleton: \(calibratedAtAlpha_D0Restricted_QRestricted_SingletonADMITRestricted[label] / max(1, totalCalibratedAtAlpha_D0Restricted_QRestricted_SingletonADMITRestricted[label])), total: \(totalCalibratedAtAlpha_D0Restricted_QRestricted_SingletonADMITRestricted[label])")
            print("Label: \(label): Points in Q Max Category \(qMax) (unrestricted) by true class: \(countForQMaxByTrueLabel[label])")
        }
        
    }
}
*/
