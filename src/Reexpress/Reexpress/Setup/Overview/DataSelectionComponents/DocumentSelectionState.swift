//
//  DocumentSelectionState.swift
//  Alpha1
//
//  Created by A on 8/17/23.
//

import Foundation
import SwiftUI

struct SearchParameters {  // Keyword search
    var search: Bool = false
    var searchText = ""
    var searchField: String = "document"
    var caseSensitiveSearch: Bool = true
}
struct SemanticSearchParameters {
    var search: Bool = false
    var searchText = ""
    var retrievedDocumentIDs: [String] = []
    var retrievedDocumentIDs2HighlightRanges: [String: Range<String.Index>] = [:]
    // Note that we currently do not retain or display the intra-document distance.
    var retrievedDocumentIDs2DocumentLevelSearchDistances: [String: Float32] = [:]
    
    var searchPrompt: String = ""
    var searchAttributes: [Float32] = []
    
    var emphasizeSelectTokens: Bool = false
    var tokensToEmphasize = Set<String>()
    
    mutating func resetEmphasisStructures() {
        emphasizeSelectTokens = false
        tokensToEmphasize = Set<String>()
    }
    var rerankParameters = RerankParameters()
    mutating func updateSemanticSearchResultsStructures(rerankedRetrievedDocumentIDs: [String], createNewDocumentsViaCrossEncoding: Bool) {
        if createNewDocumentsViaCrossEncoding {
            retrievedDocumentIDs = rerankedRetrievedDocumentIDs
            // These are no longer relevant: For cross-encoding, we use the standard feature highlights, and the semantic distances do not apply since the text input has changed.
            retrievedDocumentIDs2HighlightRanges = [:]
            retrievedDocumentIDs2DocumentLevelSearchDistances = [:]
        } else {
            // Filter existing, with correspondence back to the original (non-cross-encoded) documents:
            var temp_retrievedDocumentIDs: [String] = []
            var temp_retrievedDocumentIDs2HighlightRanges: [String: Range<String.Index>] = [:]
            var temp_retrievedDocumentIDs2DocumentLevelSearchDistances: [String: Float32] = [:]
            
            for crossEncodedDocumentId in rerankedRetrievedDocumentIDs {
                if let documentId = rerankParameters.newDocumentIDs2RetrievedDocumentIDs[crossEncodedDocumentId] {
                    temp_retrievedDocumentIDs.append(documentId)
                    if let highlightRange = retrievedDocumentIDs2HighlightRanges[documentId] {
                        temp_retrievedDocumentIDs2HighlightRanges[documentId] = highlightRange
                    }
                    if let searchDistance = retrievedDocumentIDs2DocumentLevelSearchDistances[documentId] {
                        temp_retrievedDocumentIDs2DocumentLevelSearchDistances[documentId] = searchDistance
                    }
                }
            }
            
            retrievedDocumentIDs = temp_retrievedDocumentIDs
            retrievedDocumentIDs2HighlightRanges = temp_retrievedDocumentIDs2HighlightRanges
            retrievedDocumentIDs2DocumentLevelSearchDistances = temp_retrievedDocumentIDs2DocumentLevelSearchDistances
        }
    }
}

struct RerankParameters {
    var reranking: Bool = false
    
    var rerankTargetLabel: Int = 0
    var rerankPrompt: String = ""
    var rerankSearchText: String = ""  // typically same as searchText, but the user can change before running reranking
    var rerankAttributes: [Float32] = []  // only used if rerankAttributesMergeOption == RerankAttributesMergeOption.new
    var rerankAttributesMergeOption: RerankAttributesMergeOption = .document
    
    enum RerankAttributesMergeOption: Int, CaseIterable {
        case none = 0
        case search = 1
        case document = 2
        case average = 3
        case absDifference = 4
        case new = 5
    }
    var retrievedDocumentIDs2NewDocumentIDs: [String: String] = [:]
    var newDocumentIDs2RetrievedDocumentIDs: [String: String] = [:]
    
    var rerankDisplayOptions = RerankDisplayOptions()
    struct RerankDisplayOptions {
        var createNewDocumentInstance: Bool = true
        var onlyShowMatchesToTargetLabel: Bool = true
    }
}


struct InconsistentFeaturesParameters {
    var onlyShowDocumentsWithFeaturesInconsistentWithDocLevelPredictedClass: Bool = false
    var featureInconsistentWithDocLevelPredictedClasses: Set<Int> = Set<Int>()
}
struct ConsistentFeaturesParameters {
    var onlyShowDocumentsWithAFeatureConsistentWithDocLevelPredictedClass: Bool = false  // an inconsistent feature still allowed
}

struct SortParameters {
    var sortFields: Set<String> = Set<String>(["id"])
    var orderedSortFields: [String] = ["id"]
    var sortFieldToIsAscending: [String: Bool] = ["id": true]
    
    let availableSortFields: [String] = ["id", "info", "group", "distance", "q", "magnitude", "Last Modified", "Last Viewed", "Date Added"]
    
    mutating func selectAllSortFields() {
        sortFields = Set(availableSortFields)
        orderedSortFields = Array(sortFields)
        updateSortFieldToIsAscendingDictionary()
    }
    mutating func updateSortFieldSelection() {
        orderedSortFields = Array(sortFields)
        updateSortFieldToIsAscendingDictionary()
    }
    
    mutating func updateSortFieldToIsAscendingDictionary() {
        for sortField in sortFields {
            if sortField == "q" || sortField == "magnitude" {  // q and magnitude default to descending
                sortFieldToIsAscending[sortField] = false
            } else {
                sortFieldToIsAscending[sortField] = true
            }
        }
    }
    
    mutating func updatedSortFieldOrderDictionary(sortField: String) {
        if let sortAscending = sortFieldToIsAscending[sortField], sortAscending {
            sortFieldToIsAscending.updateValue(false, forKey: sortField)
        } else {
            sortFieldToIsAscending.updateValue(true, forKey: sortField)
        }
    }
    
    func sortFieldsAllSelected() -> Bool {
        return sortFields.count == availableSortFields.count
    }
}

struct ChangedDocumentsParameters {
    var onlyShowModifiedDocuments: Bool = false
    var onlyShowViewedDocuments: Bool = false
}
struct ProbabilityConstraint {
    // use int to avoid signficant digit display errors
    var lowerProbabilityInt: Int = REConstants.Uncertainty.minProbabilityPrecisionForDisplayAsInt
    var upperProbabilityInt: Int = REConstants.Uncertainty.maxProbabilityPrecisionForDisplayAsInt
    
    var lowerProbability: Float32 {
        return Float32(lowerProbabilityInt)/Float32(100.0)
    }
    var upperProbability: Float32 {
        return Float32(upperProbabilityInt)/Float32(100.0)
    }
    
    func getDisplayProbabilityStringWithSignificantDigits(probabilityInt: Int) -> String {
        let probabilityIntString = String(probabilityInt)
        if probabilityIntString.count == 1 {
            return "0.0\(probabilityInt)"
        } else {
            return "0.\(probabilityInt)"
        }
    }
}

struct DistanceConstraints {
    var minDistance: Float32? = nil
    var maxDistance: Float32? = nil
}
struct MagnitudeConstraints {
    var minF: Float32? = nil
    var maxF: Float32? = nil
}
struct PartitionSizeConstraints {
    var restrictPartitionSize: Bool = false // We have this additional Bool to avoid ambiguity with the main Partition size options that determine calibration reliability.
    var minPartitionSize: Int? = nil
    var maxPartitionSize: Int? = nil
}
struct DocumentSelectionState {
    enum LabelConstraint: Int, CaseIterable {
        case allPoints = 0
        case onlyCorrectPoints = 1
        case onlyWrongPoints = 2
    }
    
    var datasetId: Int
    var includeAllPartitions: Bool = true
    var predictedClasses: Set<Int> = Set<Int>()
    var numberOfClasses: Int
    var qCategories: Set<UncertaintyStatistics.QCategory>
    var distanceCategories: Set<UncertaintyStatistics.DistanceCategory>
    var compositionCategories: Set<UncertaintyStatistics.CompositionCategory>
    var qDFCategorySizeCharacterizations: Set<UncertaintyStatistics.QDFCategorySizeCharacterization>
    
//    var currentLabelConstraint: UncertaintyStatistics.DatasetUncertaintyCoordinator.LabelConstraint = .allPoints
    var currentLabelConstraint: LabelConstraint = .allPoints
    var lowerQConstraint: Int = 0
    var upperQConstraint: Int = REConstants.Uncertainty.maxQAvailableFromIndexer
    
    var distanceConstraints = DistanceConstraints()
    var magnitudeConstraints = MagnitudeConstraints()
    var partitionSizeConstraints = PartitionSizeConstraints()
    // Unlike predicted class, here the OOD and Unlabeled labels are also included:
    var displayedGroundTruthLabels: Set<Int> = Set<Int>()
    
    var probabilityConstraint = ProbabilityConstraint()
    var searchParameters = SearchParameters()
    var sortParameters = SortParameters()
    var changedDocumentsParameters = ChangedDocumentsParameters()
    
    var semanticSearchParameters = SemanticSearchParameters()
    
    var inconsistentFeaturesParameters = InconsistentFeaturesParameters()
    var consistentFeaturesParameters = ConsistentFeaturesParameters()
    
    var qdfCategoriesInSelection: Set<UncertaintyStatistics.QDFCategory> {
        var qdfCategories = Set<UncertaintyStatistics.QDFCategory>()
        for label in predictedClasses {
            for qCategory in qCategories {
                for distanceCategory in distanceCategories {
                    for compositionCategory in compositionCategories {
                        qdfCategories.insert(UncertaintyStatistics.QDFCategory(prediction: label, qCategory: qCategory, distanceCategory: distanceCategory, compositionCategory: compositionCategory))
                    }
                }
            }
        }
        return qdfCategories
    }
    var calibrationReliabilitiesOfSelection: Set<UncertaintyStatistics.QDFCategoryReliability> {
        var calibrationReliabilities = Set<UncertaintyStatistics.QDFCategoryReliability>()
        
        for qdfCategory in qdfCategoriesInSelection {
            for qDFCategorySizeCharacterization in qDFCategorySizeCharacterizations {
                let placeholderSizeOfCategory = UncertaintyStatistics.getPlaceholderCategorySizeFromQDFCategorySizeCharacterizationWithCaution(qDFCategorySizeCharacterization: qDFCategorySizeCharacterization)
                calibrationReliabilities.insert(UncertaintyStatistics.getRelativeCalibrationReliabilityForVennADMITCategory(vennADMITCategory: qdfCategory, sizeOfCategory: placeholderSizeOfCategory))
            }
        }
        return calibrationReliabilities
    }
    
    func getAllPossibleQDFCategoryIDs() -> Set<String> {
        var qdfCategoryIDs = Set<String>()
        for label in 0..<numberOfClasses {
            for qCategory in UncertaintyStatistics.QCategory.allCases {
                for distanceCategory in UncertaintyStatistics.DistanceCategory.allCases {
                    for compositionCategory in UncertaintyStatistics.CompositionCategory.allCases {
                        qdfCategoryIDs.insert(UncertaintyStatistics.QDFCategory(prediction: label, qCategory: qCategory, distanceCategory: distanceCategory, compositionCategory: compositionCategory).id)
                    }
                }
            }
        }
        return qdfCategoryIDs
    }
    
    init(numberOfClasses: Int) {
        self.numberOfClasses = numberOfClasses
        predictedClasses = Set(0..<numberOfClasses)
        datasetId = REConstants.DatasetsEnum.train.rawValue
        qCategories = Set(UncertaintyStatistics.QCategory.allCases)
        distanceCategories = Set(UncertaintyStatistics.DistanceCategory.allCases)
        compositionCategories = Set(UncertaintyStatistics.CompositionCategory.allCases)
        qDFCategorySizeCharacterizations = Set(UncertaintyStatistics.QDFCategorySizeCharacterization.allCases)
        
        displayedGroundTruthLabels = Set(0..<numberOfClasses)
        displayedGroundTruthLabels.insert(REConstants.DataValidator.oodLabel)
        displayedGroundTruthLabels.insert(REConstants.DataValidator.unlabeledLabel)
        
        inconsistentFeaturesParameters.featureInconsistentWithDocLevelPredictedClasses = Set(0..<numberOfClasses)
    }
    mutating func reset() {
        // alternatively, could just create a new instance, but in some cases, might not have numberOfClasses (since it's part of dataController), so can use this instead to reset all other fields.
        includeAllPartitions = true
        resetPredictedClasses()
        resetQCategories()
        resetDistanceCategories()
        resetCompositionCategories()
        resetQDFCategorySizeCharacterizations()
        datasetId = REConstants.DatasetsEnum.train.rawValue
        
        probabilityConstraint = ProbabilityConstraint()
        
        resetAdditionalConstraints()
        searchParameters = SearchParameters()
        sortParameters = SortParameters()
        changedDocumentsParameters = ChangedDocumentsParameters()
        
        semanticSearchParameters = SemanticSearchParameters()
    }
    
    mutating func resetPredictedClasses() {
        predictedClasses = Set(0..<numberOfClasses)
    }
    mutating func resetQCategories() {
        qCategories = Set(UncertaintyStatistics.QCategory.allCases)
    }
    mutating func resetDistanceCategories() {
        distanceCategories = Set(UncertaintyStatistics.DistanceCategory.allCases)
    }
    mutating func resetCompositionCategories() {
        compositionCategories = Set(UncertaintyStatistics.CompositionCategory.allCases)
    }
    mutating func resetQDFCategorySizeCharacterizations() {
        qDFCategorySizeCharacterizations = Set(UncertaintyStatistics.QDFCategorySizeCharacterization.allCases)
    }
    
    mutating func resetAdditionalConstraints() {
        currentLabelConstraint = .allPoints
        lowerQConstraint = 0
        upperQConstraint = REConstants.Uncertainty.maxQAvailableFromIndexer
        distanceConstraints = DistanceConstraints()
        magnitudeConstraints = MagnitudeConstraints()
        partitionSizeConstraints = PartitionSizeConstraints()
        resetDisplayedGroundTruthLabels()
        
        inconsistentFeaturesParameters = InconsistentFeaturesParameters()
        resetInconsistentFeaturesParametersClasses()
        
        consistentFeaturesParameters = ConsistentFeaturesParameters()
    }
    
    mutating func resetDisplayedGroundTruthLabels() {
        displayedGroundTruthLabels = Set(getAllPossibleGroundTruthLabels())
    }
    
    mutating func resetInconsistentFeaturesParametersClasses() {
        inconsistentFeaturesParameters.featureInconsistentWithDocLevelPredictedClasses = Set(0..<numberOfClasses)
    }
    
    func predictedClassesAllSelected() -> Bool {
        return predictedClasses.count == numberOfClasses
    }
    func qCategoryAllSelected() -> Bool {
        return qCategories.count == UncertaintyStatistics.QCategory.allCases.count
    }
    func distanceCategoryAllSelected() -> Bool {
        return distanceCategories.count == UncertaintyStatistics.DistanceCategory.allCases.count
    }
    func compositionCategoryAllSelected() -> Bool {
        return compositionCategories.count == UncertaintyStatistics.CompositionCategory.allCases.count
    }
    func qDFCategorySizeCharacterizationsAllSelected() -> Bool {
        return qDFCategorySizeCharacterizations.count == UncertaintyStatistics.QDFCategorySizeCharacterization.allCases.count
    }
    
    func getAllPossibleGroundTruthLabels() -> [Int] {
        var labels: [Int] = [REConstants.DataValidator.oodLabel, REConstants.DataValidator.unlabeledLabel]
        for label in 0..<numberOfClasses {
            labels.append(label)
        }
        return labels
    }
    func displayedGroundTruthLabelsAllSelected() -> Bool {
        return displayedGroundTruthLabels.count == numberOfClasses + 2 // OOD + unlabeled
    }
    
    func inconsistentFeaturesParametersAllSelected() -> Bool {
        return inconsistentFeaturesParameters.featureInconsistentWithDocLevelPredictedClasses.count == numberOfClasses
    }
}
