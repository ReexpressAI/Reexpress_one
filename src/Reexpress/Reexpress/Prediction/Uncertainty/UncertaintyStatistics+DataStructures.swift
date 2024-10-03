//
//  UncertaintyStatistics+DataStructures.swift
//  Alpha1
//
//  Created by A on 4/23/23.
//

import Foundation
import CoreData
import CoreML
import Accelerate



extension UncertaintyStatistics {
 
    enum QCategory: Int, CaseIterable, Codable {
        case zero = 0
        case oneToQMax = 1
        case qMax = 2
    }
    
    func getQCategory(q: Int) -> QCategory? {
        switch q {
        case 0:
            return QCategory.zero
        case 1..<qMax:
            return QCategory.oneToQMax
        case qMax...:
            return QCategory.qMax
        default:
            return nil
        }
    }
        
    enum DistanceCategory: Int, CaseIterable {
        case lessThanOrEqualToMedian = 0
        case greaterThanMedianAndLessThanOrEqualToOOD = 1
        case greaterThanOOD = 2
    }
    
    
    enum CompositionCategory: Int, CaseIterable {
        case singleton = 0
        case multiple = 1
        case null = 2
        case mismatch = 3  // consider folding into null
    }
    
    
    /// See getPredictionSetCompositionId() for the raw id's used. In particular, note that the singleton sets are indexed by the respective predicted class Int.
    enum CompositionIdNonSingletonCases: Int, CaseIterable {
        case catchAll = 0
        case nullSet = 1
//        case predictionAndThresholdSingletonMismatch = 2
        case predictionAndPredictionSetMismatch = 2
    }
    /*
     Singleton set - the original model prediction is in the prediction set
     Null set - the prediction set is empty (=> output softmax is relatively low for all classes and falls below the thresholds)
     Mismatch - the non-null prediction set does not contain the original prediction
     Catchall - all other sets (i.e., non-singleton sets that also cover the original prediction): The prediction is confident enough to be included but there are one or more additional labels over which the model is comparatively uncertain.
     Order in confidence (in general) for the predicted class:
        1. Singleton set
        2. Catchall
        3. tied: {Mismatch, Null set}
     */
    func getPredictionSetCompositionId(numberOfClasses: Int, prediction: Int, predictionSet: Set<Int>) -> Int {
        switch predictionSet.count {
        case 1:  // singleton set (which can be any one, but only one, of the classes)
            let singletonPrediction = predictionSet.first!
            if singletonPrediction == prediction {
                return singletonPrediction  // values will be in 0..<numberOfClasses
            } else {
                // The following case should be relatively rare. It occurs when the thresholded singleton prediction does not match the argmax prediction from the model.
//                return numberOfClasses+CompositionIdNonSingletonCases.predictionAndThresholdSingletonMismatch.rawValue
                // These instances also get included with non-singleton counterparts below.
                return numberOfClasses+CompositionIdNonSingletonCases.predictionAndPredictionSetMismatch.rawValue
            }
        case 0:  // null set (i.e., the output softmax falls below the thresholds for all classes)
            return numberOfClasses+CompositionIdNonSingletonCases.nullSet.rawValue
        default:
            if predictionSet.contains(prediction) {  // catch-all for non-singleton, non-null sets in which the original prediction is in the set
                return numberOfClasses+CompositionIdNonSingletonCases.catchAll.rawValue
            } else {  // non-singleton, non-null sets in which the original prediction is *not* in the set
                return numberOfClasses+CompositionIdNonSingletonCases.predictionAndPredictionSetMismatch.rawValue
            }
        }
    }
    /// See getPredictionSetCompositionId() for the mapping from the composition of the set to the associated id.
    func getAllPredictionSetCompositionIds() -> Range<Int> {
        return 0..<(numberOfClasses+CompositionIdNonSingletonCases.allCases.count)
    }
    
    func getCompositionCategoryFromPredictionSetCompositionId(predictionSetCompositionId: Int) -> CompositionCategory {
        var compositionCategory: CompositionCategory
        if predictionSetCompositionId < numberOfClasses {
            compositionCategory = .singleton
        } else if predictionSetCompositionId == numberOfClasses+CompositionIdNonSingletonCases.catchAll.rawValue {
            compositionCategory = .multiple
        } else if predictionSetCompositionId == numberOfClasses+CompositionIdNonSingletonCases.predictionAndPredictionSetMismatch.rawValue {
            compositionCategory = .mismatch
        } else {
            compositionCategory = .null
        }
        return compositionCategory
    }
   
    struct DataPoint: Identifiable {
        let id: String
        let label: Int
        let prediction: Int
        let softmax: [Float32]
        let d0: Float32
        let q: Int
        let topKdistances: [Float32]  // into training/support
        let topKIndexesAsDocumentIds: [String]  // into training/support
        
        let qCategory: QCategory
        var calibratedOutput: CalibratedOutputType?
        var compositionCategory: CompositionCategory
        var distanceCategory: DistanceCategory
        
        var qdfCategory: QDFCategory?
        
        var document: String = ""
        
        // These are for convenience. Remaining attributes need to be queried directly from the database.
        var featureMatchesDocLevelSentenceRangeStart: Int
        var featureMatchesDocLevelSentenceRangeEnd: Int
        
    }
    
    
    // new
    typealias QDFCategory = VennADMITCategory
    struct VennADMITCategory: Identifiable, Hashable {
        typealias VennADMITCategoryIdType = String
        var id: VennADMITCategoryIdType {
            return "\(prediction)_\(qCategory.rawValue)_\(distanceCategory.rawValue)_\(compositionCategory.rawValue)" //_\(qMax)_\(alpha)"
        }
        let prediction: Int
        let qCategory: QCategory
        let distanceCategory: DistanceCategory
        let compositionCategory: CompositionCategory
        
        // hyper-parameters:
        //let qMax: Int
        //let alpha: Float32
        //let categoryIds = Set<String>()
        //        let predictionSetCompositionId: Int
        static func initQDFCategoryFromIdString(idString: String) -> QDFCategory? {
            let splitId = idString.split(separator: "_")
            if splitId.count == 4 {
                guard let prediction = Int(splitId[0]), let qCategoryRawValue = Int(splitId[1]), let distanceCategoryRawValue = Int(splitId[2]), let compositionCategoryRawValue = Int(splitId[3]), let qCategory = QCategory(rawValue: qCategoryRawValue), let distanceCategory = DistanceCategory(rawValue: distanceCategoryRawValue), let compositionCategory = CompositionCategory(rawValue: compositionCategoryRawValue) else {
                    return nil
                }
                return QDFCategory(prediction: prediction, qCategory: qCategory, distanceCategory: distanceCategory, compositionCategory: compositionCategory)
            }
            return nil
        }
    }
    typealias QDFCategoryReliability = VennADMITCategoryReliability
    enum VennADMITCategoryReliability: Int, CaseIterable {
        case highestReliability = 0
        case reliable = 1
        case lessReliable = 2
        case unreliable = 3
        // default case (e.g., for use when a selected partition is unavailable in a given dataset):
        case unavailable = 4
    }
    
    enum QDFCategorySizeCharacterization: Int, CaseIterable {
        case sufficient  // a relatively low bar
        case insufficient
        case zero
    }
    
    func getQDFCategorySizeCharacterization(sizeOfCategory: Int) -> QDFCategorySizeCharacterization {
        if sizeOfCategory == 0 {
            return .zero
        } else if sizeOfCategory > 0 && sizeOfCategory < REConstants.Uncertainty.minReliablePartitionSize {
            return .insufficient
        } else {
            return .sufficient
        }
    }
    
    // Use this with caution. This is just meant as a simple way to display labels from getRelativeCalibrationReliabilityForVennADMITCategory() when only the QDFCategorySizeCharacterization is available (such as when performing Core Data selections). It should be used with caution, since the returned Int does not necessarily reflect the actual size of the category (with the exception of .zero).
    static func getPlaceholderCategorySizeFromQDFCategorySizeCharacterizationWithCaution(qDFCategorySizeCharacterization: QDFCategorySizeCharacterization) -> Int {
        switch qDFCategorySizeCharacterization {
        case .sufficient:
            return REConstants.Uncertainty.minReliablePartitionSize
        case .insufficient:
            return 1
        case .zero:
            return 0
        }
    }
}

/* for each document we should save:
 reliability: VennADMITCategoryReliability ::  QDFCategoryReliability
 probability:
 sample size (of calibration) **at the time of calibration**
 some type of hash or uuid to identify the calibration details and calibration set at the time of calibration?
 
 OR could use hash and just always be on-demand:
 each document has:
 QDFCategory.id
 UncertaintyUUID
 
 Then an entity of:
 QDFCategory
    -sample size in calibration
    -UncertaintyUUID
 UncertaintyControl
    -index model UUID
    -UncertaintyUUID
    qMax: Int
    alpha: Float32
    -thresholds
    -other data structures
 
 */

/* In order to calibrate a new test point, the following are needed:
 d0Stats = trueClass_To_QToD0Statistics[prediction]?[qCategory] distance category
 
 // Note that the thresholds are currently not subdivided by distance
 var qCategory_To_Thresholds: [ QCategory: [Float32] ] = [:]
 qCategory_To_CompositionId_To_PredictedClass_To_DistanceCategory_To_CalibrationVennStructure[dataPoint.qCategory]?[predictionSetCompositionId]?[dataPoint.prediction]?[dataPoint.distanceCategory]
 */

/*
 Partitions: q (3) + d (3) + f (4). Note that the thresholds for determining f are only determined by partitioning q (not d).
 
 */


/*
 let encoder = JSONEncoder()
 let decoder = JSONDecoder()
 print("Original: \(uncertaintyStatistics.qCategory_To_Thresholds)")
 if let data = try? encoder.encode(uncertaintyStatistics.qCategory_To_Thresholds) {
     let string = String(data: data, encoding: .utf8)!
     print(string)
     let original_qCategory_To_Thresholds = try decoder.decode([ UncertaintyStatistics.QCategory: [Float32] ].self, from: data)
     print("Decoded: \(original_qCategory_To_Thresholds)")
 }
 
 
 */
