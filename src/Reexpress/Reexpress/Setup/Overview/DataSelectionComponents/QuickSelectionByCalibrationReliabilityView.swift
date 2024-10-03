//
//  QuickSelectionByCalibrationReliabilityView.swift
//  Alpha1
//
//  Created by A on 8/20/23.
//

import SwiftUI

struct QuickSelectionByCalibrationReliabilityView: View {
//    var qdfCategoriesInSelection: Set<UncertaintyStatistics.QDFCategory> {
//        var qdfCategories = Set<UncertaintyStatistics.QDFCategory>()
//        for label in predictedClasses {
//            for qCategory in qCategories {
//                for distanceCategory in distanceCategories {
//                    for compositionCategory in compositionCategories {
//                        qdfCategories.insert(UncertaintyStatistics.QDFCategory(prediction: label, qCategory: qCategory, distanceCategory: distanceCategory, compositionCategory: compositionCategory))
//                    }
//                }
//            }
//        }
//        return qdfCategories
//    }
//    var calibrationReliabilitiesOfSelection: Set<UncertaintyStatistics.QDFCategoryReliability> {
//        var calibrationReliabilities = Set<UncertaintyStatistics.QDFCategoryReliability>()
//
//        for qdfCategory in qdfCategoriesInSelection {
//            for qDFCategorySizeCharacterization in qDFCategorySizeCharacterizations {
//                let placeholderSizeOfCategory = UncertaintyStatistics.getPlaceholderCategorySizeFromQDFCategorySizeCharacterizationWithCaution(qDFCategorySizeCharacterization: qDFCategorySizeCharacterization)
//                calibrationReliabilities.insert(UncertaintyStatistics.getRelativeCalibrationReliabilityForVennADMITCategory(vennADMITCategory: qdfCategory, sizeOfCategory: placeholderSizeOfCategory))
//            }
//        }
//        return calibrationReliabilities
//    }
    
    func addQDFCategoriesBasedOnReliability(qDFCategoryReliability: UncertaintyStatistics.QDFCategoryReliability) {
        documentSelectionState.qDFCategorySizeCharacterizations.removeAll() // = Set<UncertaintyStatistics.QDFCategorySizeCharacterization>()
        // we do not reset predicted labels
        documentSelectionState.qCategories.removeAll()
        documentSelectionState.distanceCategories.removeAll()
        documentSelectionState.compositionCategories.removeAll()
        
        switch qDFCategoryReliability {
        case .highestReliability:
            documentSelectionState.qDFCategorySizeCharacterizations.insert(.sufficient)
            
            documentSelectionState.qCategories.insert(.qMax)
            documentSelectionState.distanceCategories.insert(.lessThanOrEqualToMedian)
            documentSelectionState.compositionCategories.insert(.singleton)
                        
        case .reliable:
            documentSelectionState.qDFCategorySizeCharacterizations.insert(.sufficient)
            documentSelectionState.qCategories.insert(.qMax)
            documentSelectionState.distanceCategories.insert(.greaterThanMedianAndLessThanOrEqualToOOD)
            documentSelectionState.compositionCategories.insert(.singleton)
        case .lessReliable:
            documentSelectionState.qDFCategorySizeCharacterizations.insert(.sufficient)
            documentSelectionState.qCategories.insert(.oneToQMax)
            documentSelectionState.distanceCategories.insert(.lessThanOrEqualToMedian)
            documentSelectionState.compositionCategories.insert(.singleton)
        case .unreliable:
            documentSelectionState.qDFCategorySizeCharacterizations.insert(.insufficient)
            
            documentSelectionState.resetQCategories()
            documentSelectionState.resetDistanceCategories()
            documentSelectionState.distanceCategories.remove(.greaterThanOOD)
            documentSelectionState.resetCompositionCategories()
        case .unavailable:
            documentSelectionState.qDFCategorySizeCharacterizations.insert(.zero)
            
            documentSelectionState.resetQCategories()
            documentSelectionState.resetDistanceCategories()
            documentSelectionState.resetCompositionCategories()
        }
    }
    @Binding var documentSelectionState: DocumentSelectionState
    @State private var isShowingInfoForCalibrationReliability: Bool = false
    var buttonFrameWidth: CGFloat = 60
    var buttonFrameHeight: CGFloat = 60
    //@State var currentSelection: UncertaintyStatistics.QDFCategoryReliability? = nil
    
    let labelPlaceholder: Int = 0  // just a temporary value to get a reliability label (which does not depend on the actual class value)
    var body: some View {
        // MARK: Reliability control buttons:
        VStack(alignment: .center) {
            HStack {
                Text("Calibration reliability")
                    .foregroundStyle(.secondary)
                Button {
                    isShowingInfoForCalibrationReliability.toggle()
                } label: {
                    Image(systemName: "info.circle.fill")
                }
                .buttonStyle(.borderless)
                .popover(isPresented: $isShowingInfoForCalibrationReliability) {
                    CalibrationReliabilityView()
                        .frame(width: 800)
                }
            }
            HStack(alignment: .lastTextBaseline) {
                Button {
                    addQDFCategoriesBasedOnReliability(qDFCategoryReliability: .highestReliability)
                } label: {
                    VStack {
                        let reliabilityLabel = UncertaintyStatistics.formatReliabilityLabel(dataPoint: nil, qdfCategory: UncertaintyStatistics.QDFCategory(prediction: labelPlaceholder, qCategory: .qMax, distanceCategory: .lessThanOrEqualToMedian, compositionCategory: .singleton), sizeOfCategory: REConstants.Uncertainty.minReliablePartitionSize)
                        Image(systemName: reliabilityLabel.reliabilityImageName)
                            .font(.title)
                            .foregroundStyle(reliabilityLabel.reliabilityColorGradient)
                            .opacity(reliabilityLabel.opacity)
                        Text(reliabilityLabel.reliabilityTextCaption)
                            .foregroundStyle(.gray)
                            .font(.title3)
                    }
                    .frame(width: buttonFrameWidth, height: buttonFrameHeight)
                    .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(.secondary)
                            .opacity(documentSelectionState.calibrationReliabilitiesOfSelection.contains(.highestReliability) ? 1.0 : 0.0)
                    )
                }
                .buttonStyle(.borderless)

                Button {
                    addQDFCategoriesBasedOnReliability(qDFCategoryReliability: .reliable)
                } label: {
                    VStack {
                        let reliabilityLabel = UncertaintyStatistics.formatReliabilityLabel(dataPoint: nil, qdfCategory: UncertaintyStatistics.QDFCategory(prediction: labelPlaceholder, qCategory: .qMax, distanceCategory: .greaterThanMedianAndLessThanOrEqualToOOD, compositionCategory: .singleton), sizeOfCategory: REConstants.Uncertainty.minReliablePartitionSize)
                        Image(systemName: reliabilityLabel.reliabilityImageName)
                            .font(.title)
                            .foregroundStyle(reliabilityLabel.reliabilityColorGradient)
                            .opacity(reliabilityLabel.opacity)
                        Text(reliabilityLabel.reliabilityTextCaption)
                            .foregroundStyle(.gray)
                            .font(.title3)
                    }
                    .frame(width: buttonFrameWidth, height: buttonFrameHeight)
                    .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(.secondary)
                            .opacity(documentSelectionState.calibrationReliabilitiesOfSelection.contains(.reliable) ? 1.0 : 0.0)
                    )
                }
                .buttonStyle(.borderless)
                Button {
                    addQDFCategoriesBasedOnReliability(qDFCategoryReliability: .lessReliable)
                } label: {
                    VStack {
                        let reliabilityLabel = UncertaintyStatistics.formatReliabilityLabel(dataPoint: nil, qdfCategory: UncertaintyStatistics.QDFCategory(prediction: labelPlaceholder, qCategory: .oneToQMax, distanceCategory: .lessThanOrEqualToMedian, compositionCategory: .singleton), sizeOfCategory: REConstants.Uncertainty.minReliablePartitionSize)
                        Image(systemName: reliabilityLabel.reliabilityImageName)
                            .font(.title)
                            .foregroundStyle(reliabilityLabel.reliabilityColorGradient)
                            .opacity(reliabilityLabel.opacity)
                        Text(reliabilityLabel.reliabilityTextCaption)
                            .foregroundStyle(.gray)
                            .font(.title3)
                    }
                    .frame(width: buttonFrameWidth, height: buttonFrameHeight)
                    .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(.secondary)
                            .opacity(documentSelectionState.calibrationReliabilitiesOfSelection.contains(.lessReliable) ? 1.0 : 0.0)
                    )
                }
                .buttonStyle(.borderless)
                
                Button {
                    addQDFCategoriesBasedOnReliability(qDFCategoryReliability: .unreliable)
                } label: {
                    VStack {
                        let reliabilityLabel = UncertaintyStatistics.formatReliabilityLabel(dataPoint: nil, qdfCategory: UncertaintyStatistics.QDFCategory(prediction: labelPlaceholder, qCategory: .zero, distanceCategory: .lessThanOrEqualToMedian, compositionCategory: .mismatch), sizeOfCategory: REConstants.Uncertainty.minReliablePartitionSize)
                        Image(systemName: reliabilityLabel.reliabilityImageName)
                            .font(.title)
                            .foregroundStyle(reliabilityLabel.reliabilityColorGradient)
                            .opacity(reliabilityLabel.opacity)
                        Text(reliabilityLabel.reliabilityTextCaption)
                            .foregroundStyle(.gray)
                            .font(.title3)
                    }
                    .frame(width: buttonFrameWidth, height: buttonFrameHeight)
                    .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(.secondary)
                            .opacity(documentSelectionState.calibrationReliabilitiesOfSelection.contains(.unreliable) ? 1.0 : 0.0)
                    )
                }
                .buttonStyle(.borderless)
                
                Button {
                    addQDFCategoriesBasedOnReliability(qDFCategoryReliability: .unavailable)
                } label: {
                    VStack {
                        let reliabilityLabel = UncertaintyStatistics.formatReliabilityLabel(dataPoint: nil, qdfCategory: UncertaintyStatistics.QDFCategory(prediction: labelPlaceholder, qCategory: .oneToQMax, distanceCategory: .greaterThanOOD, compositionCategory: .singleton), sizeOfCategory: REConstants.Uncertainty.minReliablePartitionSize)
                        Image(systemName: reliabilityLabel.reliabilityImageName)
                            .font(.title)
                            .foregroundStyle(reliabilityLabel.reliabilityColorGradient)
                            .opacity(reliabilityLabel.opacity)
                        Text(reliabilityLabel.reliabilityTextCaption)
                            .foregroundStyle(.gray)
                            .font(.title3)
                    }
                    .frame(width: buttonFrameWidth, height: buttonFrameHeight)
                    .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(.secondary)
                            .opacity(documentSelectionState.calibrationReliabilitiesOfSelection.contains(.unavailable) ? 1.0 : 0.0)
                    )
                }
                .buttonStyle(.borderless)
            }
        }
        //.padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 60))
    }
}

//struct QuickSelectionByCalibrationReliabilityView_Previews: PreviewProvider {
//    static var previews: some View {
//        QuickSelectionByCalibrationReliabilityView()
//    }
//}
