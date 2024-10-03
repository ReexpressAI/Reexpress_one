//
//  UncertaintyStatistics+CalibrationReliability.swift
//  Alpha1
//
//  Created by A on 5/9/23.
//

import Foundation
import SwiftUI

extension UncertaintyStatistics {
    /// This does  take into consideration the sample size.
    /// Note that OOD is synonomous with the unavailable category.
    static func getRelativeCalibrationReliabilityForVennADMITCategory(vennADMITCategory: UncertaintyStatistics.VennADMITCategory, sizeOfCategory: Int) -> UncertaintyStatistics.VennADMITCategoryReliability {
        // Note that OOD includes any category that does not appear in Calibration:
        if vennADMITCategory.distanceCategory == .greaterThanOOD || sizeOfCategory == 0 {
            return UncertaintyStatistics.VennADMITCategoryReliability.unavailable
        }
        if vennADMITCategory.qCategory == .qMax && vennADMITCategory.compositionCategory == .singleton {
            switch vennADMITCategory.distanceCategory {
            case .lessThanOrEqualToMedian:
                if sizeOfCategory < REConstants.Uncertainty.minReliablePartitionSize {
                    return UncertaintyStatistics.VennADMITCategoryReliability.unreliable
                }
                return UncertaintyStatistics.VennADMITCategoryReliability.highestReliability
            case .greaterThanMedianAndLessThanOrEqualToOOD:
                if sizeOfCategory < REConstants.Uncertainty.minReliablePartitionSize {
                    return UncertaintyStatistics.VennADMITCategoryReliability.unreliable
                }
                return UncertaintyStatistics.VennADMITCategoryReliability.reliable
            case .greaterThanOOD:
                return UncertaintyStatistics.VennADMITCategoryReliability.unavailable // OOD (also caught above in first check)
            }
        } else if vennADMITCategory.qCategory == .oneToQMax && vennADMITCategory.compositionCategory == .singleton && vennADMITCategory.distanceCategory == .lessThanOrEqualToMedian {
            if sizeOfCategory < REConstants.Uncertainty.minReliablePartitionSize {
                return UncertaintyStatistics.VennADMITCategoryReliability.unreliable
            }
            return UncertaintyStatistics.VennADMITCategoryReliability.lessReliable
        }
                
        return UncertaintyStatistics.VennADMITCategoryReliability.unreliable
    }
    
    static func formatReliabilityLabel(dataPoint: UncertaintyStatistics.DataPoint? = nil, qdfCategory: UncertaintyStatistics.QDFCategory? = nil, sizeOfCategory: Int) -> (reliabilityImageName: String, reliabilityTextCaption: String, reliabilityColorGradient: AnyShapeStyle, opacity: Double) {
        let defaultOpacity: Double = 0.5
        let vennADMITCategory: VennADMITCategory
        if let qdfCategory = qdfCategory {
            vennADMITCategory = qdfCategory
        } else {  // If the QDF category is not provided as an argument, we need to construct it from the dataPoint structure:
            guard let dataPoint = dataPoint else {
                return (reliabilityImageName: "questionmark.square.dashed", reliabilityTextCaption: "OOD", reliabilityColorGradient: AnyShapeStyle(Color.purple.gradient), opacity: defaultOpacity)
            }
            vennADMITCategory = UncertaintyStatistics.VennADMITCategory(prediction: dataPoint.prediction, qCategory: dataPoint.qCategory, distanceCategory: dataPoint.distanceCategory, compositionCategory: dataPoint.compositionCategory)
        }
        
        let vennADMITCategoryMinReliability = UncertaintyStatistics.getRelativeCalibrationReliabilityForVennADMITCategory(vennADMITCategory: vennADMITCategory, sizeOfCategory: sizeOfCategory)
        return UncertaintyStatistics.formatReliabilityLabelFromQDFCategoryReliability(qdfCategoryReliability: vennADMITCategoryMinReliability, defaultOpacity: defaultOpacity)

    }
    static func formatReliabilityLabelFromQDFCategoryReliability(qdfCategoryReliability: UncertaintyStatistics.QDFCategoryReliability, defaultOpacity: Double = 0.5) -> (reliabilityImageName: String, reliabilityTextCaption: String, reliabilityColorGradient: AnyShapeStyle, opacity: Double) {
        switch qdfCategoryReliability {
        case .highestReliability:
            return (reliabilityImageName: "checkmark.shield.fill", reliabilityTextCaption: "Highest", reliabilityColorGradient: AnyShapeStyle(Color.green.gradient), opacity: defaultOpacity)
        case .reliable:
            return (reliabilityImageName: "shield.righthalf.filled", reliabilityTextCaption: "High", reliabilityColorGradient: AnyShapeStyle(Color.green.gradient), opacity: defaultOpacity)
        case .lessReliable:
            return (reliabilityImageName: "exclamationmark.triangle", reliabilityTextCaption: "Low", reliabilityColorGradient: AnyShapeStyle(Color.yellow.gradient), opacity: defaultOpacity)
        case .unreliable:
            return (reliabilityImageName: "exclamationmark.octagon.fill", reliabilityTextCaption: "Lowest", reliabilityColorGradient: AnyShapeStyle(Color.red.gradient), opacity: defaultOpacity)
        case .unavailable:
            return (reliabilityImageName: "questionmark.square.dashed", reliabilityTextCaption: "OOD", reliabilityColorGradient: AnyShapeStyle(Color.purple.gradient), opacity: defaultOpacity)
        }
    }
}
