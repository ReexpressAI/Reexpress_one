//
//  UncertaintyStatistics+CategoryStringLabels.swift
//  Alpha1
//
//  Created by A on 8/11/23.
//

import Foundation

extension UncertaintyStatistics {
 
    static func getCompositionCategoryLabel(compositionCategory: CompositionCategory, abbreviated: Bool) -> String {
        switch compositionCategory {
        case .singleton:
            if abbreviated {
                return "High"
            } else {
                return "High (Singleton)"
            }
        case .multiple:
            return "Low (Multiple)"
        case .null:
            return "Low (Null)"
        case .mismatch:
            return "Low (Mismatch)"
        }
    }
    static func getCompositionCategoryLabel_abbreviationAndDescription(compositionCategory: CompositionCategory) -> (abbreviation: String, description: String) {
        var abbreviation: String = ""
        var description: String = ""
        switch compositionCategory {
        case .singleton:
            abbreviation = "High"
            description = "(Singleton)"
        case .multiple:
            abbreviation = "Low"
            description = "(Multiple)"
        case .null:
            abbreviation = "Low"
            description = "(Null)"
        case .mismatch:
            abbreviation = "Low"
            description = "(Mismatch)"
        }
        return (abbreviation: abbreviation, description: description)
    }
    static func getQCategoryLabel(qCategory: QCategory) -> String {
        switch qCategory {
        case .zero:
            return "Low"
        case .oneToQMax:
            return "Medium"
        case .qMax:
            return "High"
        }
    }
    
    static func getDistanceCategoryLabel(distanceCategory: DistanceCategory, abbreviated: Bool) -> String {
        switch distanceCategory {
        case .lessThanOrEqualToMedian:
            return "Near"
        case .greaterThanMedianAndLessThanOrEqualToOOD:
            return "Far"
        case .greaterThanOOD:
            if abbreviated {
                return "OOD"
            } else {
                return "Out-of-distribution"
            }
        }
    }
    
    
    static func getQDFCategorySizeCharacterizationLabel(qDFCategorySizeCharacterization: QDFCategorySizeCharacterization) -> String {
        switch qDFCategorySizeCharacterization {
        case .sufficient:
            return "≥\(REConstants.Uncertainty.minReliablePartitionSize)"
        case .insufficient:
            return "0 > and < \(REConstants.Uncertainty.minReliablePartitionSize)"
        case .zero:
            return "0"
        }
    }
    
}
