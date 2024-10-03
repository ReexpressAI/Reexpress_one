//
//  UncertaintyStatistics+CoreData.swift
//  Alpha1
//
//  Created by A on 7/31/23.
//

import Foundation
import CoreData
import CoreML
import Accelerate

extension UncertaintyStatistics {
    func restoreFromDisk(moc: NSManagedObjectContext) async throws {
        // also update datacontroller?
        
        try await MainActor.run {
            // Reconstitute from disk
            // Note that currently the saved versions of alpha, conformalThresholdTolerance, and qMax are always ignored.
            alpha = REConstants.Uncertainty.defaultConformalAlpha
            conformalThresholdTolerance = REConstants.Uncertainty.defaultConformalThresholdTolerance
            qMax = REConstants.Uncertainty.defaultQMax
            
            let fetchRequest = UncertaintyModelControl.fetchRequest()
            let request = try moc.fetch(fetchRequest)
            if let uncertaintyModelControl = request.first {
                /* see note above
                alpha = uncertaintyModelControl.alpha
                conformalThresholdTolerance = uncertaintyModelControl.conformalThresholdTolerance
                qMax = uncertaintyModelControl.qMax
                */
                indexModelUUID = uncertaintyModelControl.indexModelUUID ?? ""
                uncertaintyModelUUID = uncertaintyModelControl.uncertaintyModelUUID ?? ""
                needsRefresh = uncertaintyModelControl.needsRefresh
                validKnownLabelsMinD0 = uncertaintyModelControl.validKnownLabelsMinD0
                validKnownLabelsMaxD0 = uncertaintyModelControl.validKnownLabelsMaxD0
                
                // Rebuild dictionaries
                if let qCategoriesCD = uncertaintyModelControl.qCategories {
                    for qCategoryCD in qCategoriesCD {
                        guard let qCategory = QCategory(rawValue: qCategoryCD.qCategory) else {
                            throw UncertaintyErrors.unexpectedDataStructureInCoreData
                        }
                        if let thresholds: [Float32] = qCategoryCD.thresholds?.toArray(type: Float32.self) {
                            if thresholds.count != numberOfClasses {
                                throw UncertaintyErrors.thresholdDimensionError
                            }
                            qCategory_To_Thresholds[qCategory] = thresholds
                        }
                        guard let tpD0MedianByClass = qCategoryCD.tpD0MedianByClass?.toArray(type: Float32.self), let tpD0MaxByClass = qCategoryCD.tpD0MaxByClass?.toArray(type: Float32.self), tpD0MedianByClass.count == numberOfClasses, tpD0MaxByClass.count == numberOfClasses else {
                            throw UncertaintyErrors.unexpectedDataStructureInCoreData
                        }
                        for trueLabel in 0..<numberOfClasses {
                            trueClass_To_QToD0Statistics[trueLabel]?[qCategory] = (median: tpD0MedianByClass[trueLabel], max: tpD0MaxByClass[trueLabel])
                        }
                    }
                }
                
                if let qdfCategoriesCD = uncertaintyModelControl.qdfCategories {
                    for qdfCategoryCD in qdfCategoriesCD {
                        guard let qCategory = QCategory(rawValue: qdfCategoryCD.qCategory), let distanceCategory = DistanceCategory(rawValue: qdfCategoryCD.distanceCategory), let compositionCategory = CompositionCategory(rawValue: qdfCategoryCD.compositionCategory), let minDistribution = qdfCategoryCD.minDistribution?.toArray(type: Float32.self), minDistribution.count == numberOfClasses else {
                            throw UncertaintyErrors.unexpectedDataStructureInCoreData
                        }
                        let prediction = qdfCategoryCD.prediction
                        let sizeOfCategory = Float32(qdfCategoryCD.sizeOfCategory)
                                              
                        let qdfCategory = VennADMITCategory(prediction: prediction, qCategory: qCategory, distanceCategory: distanceCategory, compositionCategory: compositionCategory)
                        
                        vennADMITCategory_To_CalibratedOutput[qdfCategory] = (minDistribution: minDistribution, sizeOfCategory: sizeOfCategory)
                    }
                }
            }
            

        }
    }
    
    func deleteExistingUncertaintyModel(moc: NSManagedObjectContext) async throws {
        try await MainActor.run {
            let fetchRequest = UncertaintyModelControl.fetchRequest()
            let request = try moc.fetch(fetchRequest)
            
            for modelControl in request {
                moc.delete(modelControl)
            }
            do {
                if moc.hasChanges {
                    try moc.save()
                }
            } catch {
                throw CoreDataErrors.saveError
            }
        }
    }
    func save(moc: NSManagedObjectContext) async throws {
        // We always first perform a delete. We only save the Categories that are present in the current data, so this helps to ensure that inconsistencies do not arise.
        try await deleteExistingUncertaintyModel(moc: moc)
        // retrieve uncertainty structure for points with valid known labels (only 0..<numberOfClasses) from the database
        try await MainActor.run {
            let fetchRequest = UncertaintyModelControl.fetchRequest()
            let request = try moc.fetch(fetchRequest)
            if !request.isEmpty {  // Any existing UncertaintyModelControl should already be deleted.
                throw CoreDataErrors.deletionError
            }
            let uncertaintyModelControl = UncertaintyModelControl(context: moc)
                        
            uncertaintyModelControl.indexModelUUID = indexModelUUID
            uncertaintyModelControl.uncertaintyModelUUID = uncertaintyModelUUID
            uncertaintyModelControl.needsRefresh = false
            uncertaintyModelControl.qMax = qMax
            uncertaintyModelControl.alpha = alpha
            uncertaintyModelControl.validKnownLabelsMinD0 = validKnownLabelsMinD0
            uncertaintyModelControl.validKnownLabelsMaxD0 = validKnownLabelsMaxD0
            uncertaintyModelControl.conformalThresholdTolerance = conformalThresholdTolerance
            
            // We create categories for those present in the data
            for qCategory in QCategory.allCases {
                if let thresholds = qCategory_To_Thresholds[qCategory] {
                    let qCategoryCD = QCategoryCD(context: moc)
                    qCategoryCD.qCategory = qCategory.rawValue
                    qCategoryCD.thresholds = Data(fromArray: thresholds)
                    var tpD0MedianByClass = [Float32](repeating: 0.0, count: numberOfClasses)
                    var tpD0MaxByClass = [Float32](repeating: 0.0, count: numberOfClasses)
                    for label in 0..<numberOfClasses {
                        if let d0Stats = trueClass_To_QToD0Statistics[label]?[qCategory] {
                            tpD0MedianByClass[label] = d0Stats.median
                            tpD0MaxByClass[label] = d0Stats.max
                        }
                    }
                    qCategoryCD.tpD0MedianByClass = Data(fromArray: tpD0MedianByClass)
                    qCategoryCD.tpD0MaxByClass = Data(fromArray: tpD0MaxByClass)
                    uncertaintyModelControl.addToQCategories(qCategoryCD)
                }
                
                for predictionSetCompositionId in getAllPredictionSetCompositionIds() {
                    for prediction in 0..<numberOfClasses {
                        for distanceCategory in DistanceCategory.allCases {
                            let qdfCategory = VennADMITCategory(prediction: prediction, qCategory: qCategory, distanceCategory: distanceCategory, compositionCategory: getCompositionCategoryFromPredictionSetCompositionId(predictionSetCompositionId: predictionSetCompositionId))
                            
                            guard let calibratedOutputOptional = vennADMITCategory_To_CalibratedOutput[qdfCategory], let calibratedOutput = calibratedOutputOptional else {
                                continue
                            }
                            let qdfCategoryCD = QDFCategoryCD(context: moc)
                            qdfCategoryCD.id = qdfCategory.id
                            
                            qdfCategoryCD.prediction = qdfCategory.prediction
                            qdfCategoryCD.qCategory = qdfCategory.qCategory.rawValue
                            qdfCategoryCD.distanceCategory = qdfCategory.distanceCategory.rawValue
                            qdfCategoryCD.compositionCategory = qdfCategory.compositionCategory.rawValue
                            qdfCategoryCD.sizeOfCategory = Int(calibratedOutput.sizeOfCategory)
                            // We also save the probability for the predicted class separately from the minDistribution array to enable fast CoreData queries. (Reason: It is not possible to directly query Data fields via fetch request predicates.) This is currently only used as a CoreData field, and it is not re-loaded from disk into memory, since we just use minDistribution.
                            if qdfCategory.prediction >= 0 && qdfCategory.prediction < calibratedOutput.minDistribution.count {
                                // Note that this is not necessarily the argmax of calibratedOutput.minDistribution, since qdfCategory.prediction is the argmax of the original model's softmax output distribution.
                                // This is the rounded version.
                                if let roundedMaxProbability = Float32(REConstants.floatProbToDisplaySignificantDigits(floatProb: calibratedOutput.minDistribution[qdfCategory.prediction])) {
                                    qdfCategoryCD.predictionProbability = roundedMaxProbability
                                }
                                // We instead save the rounded version to avoid numerical inconsistencies when searching:
                                //qdfCategoryCD.predictionProbability = calibratedOutput.minDistribution[qdfCategory.prediction]
                            }
                            qdfCategoryCD.minDistribution = Data(fromArray: calibratedOutput.minDistribution)
                            uncertaintyModelControl.addToQdfCategories(qdfCategoryCD)
                        }
                    }
                }
            }
            do {
                if moc.hasChanges {
                    try moc.save()
                }
            } catch {
                throw CoreDataErrors.saveError
            }
        }
        
    }
}
