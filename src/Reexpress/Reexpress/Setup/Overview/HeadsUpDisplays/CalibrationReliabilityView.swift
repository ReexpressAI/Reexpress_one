//
//  CalibrationReliabilityView.swift
//  Alpha1
//
//  Created by A on 8/13/23.
//

import SwiftUI

struct CalibrationReliabilityView: View {
    
//    var reliabilityLabel: (reliabilityImageName: String, reliabilityTextCaption: String, reliabilityColorGradient: AnyShapeStyle, opacity: Double) {
//        if documentObject != nil, let qdfCategory = documentQDFCategory {
//            return UncertaintyStatistics.formatReliabilityLabel(dataPoint: nil, qdfCategory: qdfCategory, sizeOfCategory: partitionSize)
//        }
//        return UncertaintyStatistics.formatReliabilityLabel(dataPoint: nil, qdfCategory: nil, sizeOfCategory: partitionSize)
//    }
    
    
    var body: some View {
        
        ScrollView {
            VStack {
                HStack {
                    Text(REConstants.CategoryDisplayLabels.calibrationReliabilityFull + " Guide")
//                    Text("Calibration Reliability Guide")
                        .font(.title2)
                        .foregroundStyle(.gray)
                    Spacer()
                    SimpleCloseButton()
                }
                Text("The overall reliability of the calibration process (separate from the probability itself) is determined by \(REConstants.CategoryDisplayLabels.qdfPartitionLabel_TextStruct) partition membership and the associated partition size in the Calibration Set. The divisions are as follows:")
                    .padding()
            
                // Highest
                Group {
                    HStack {
                        let reliabilityLabel = UncertaintyStatistics.formatReliabilityLabel(dataPoint: nil, qdfCategory: UncertaintyStatistics.QDFCategory(prediction: 0, qCategory: .qMax, distanceCategory: .lessThanOrEqualToMedian, compositionCategory: .singleton), sizeOfCategory: REConstants.Uncertainty.minReliablePartitionSize)
                        Image(systemName: reliabilityLabel.reliabilityImageName)
                            .font(.title)
                            .foregroundStyle(reliabilityLabel.reliabilityColorGradient)
                            .opacity(reliabilityLabel.opacity)
                        Text(reliabilityLabel.reliabilityTextCaption)
                            .foregroundStyle(.gray)
                            .font(.title3)
                    }
                    
                    Grid(horizontalSpacing: 20, verticalSpacing: 20) {
                        GridRow(alignment: .top) {
                            Text(REConstants.CategoryDisplayLabels.qFull)
                                .foregroundStyle(.gray)
                                .gridColumnAlignment(.trailing)
                            Text(UncertaintyStatistics.getQCategoryLabel(qCategory: .qMax))
                                .modifier(CategoryLabelViewModifier())
                                .gridColumnAlignment(.leading)
                        }
                        GridRow(alignment: .top) {
                            Text(REConstants.CategoryDisplayLabels.dFull)
                                .foregroundStyle(.gray)
                            Text(UncertaintyStatistics.getDistanceCategoryLabel(distanceCategory: .lessThanOrEqualToMedian, abbreviated: true))
                                .modifier(CategoryLabelViewModifier())
                            
                        }
                        GridRow(alignment: .top) {
                            Text(REConstants.CategoryDisplayLabels.fFull)
                                .foregroundStyle(.gray)
                            Text(UncertaintyStatistics.getCompositionCategoryLabel(compositionCategory: .singleton, abbreviated: true))
                                .modifier(CategoryLabelViewModifier())
                            
                        }
                        GridRow(alignment: .top) {
                            Text(REConstants.CategoryDisplayLabels.sizeFull)
                                .foregroundStyle(.gray)
                            Text(UncertaintyStatistics.getQDFCategorySizeCharacterizationLabel(qDFCategorySizeCharacterization: .sufficient))
                                .modifier(CategoryLabelViewModifier())
                        }
                    }
                    .padding()
                    .modifier(SimpleBaseBorderModifier())
                    .padding()
                }
                // High
                Group {
                    HStack {
                        let reliabilityLabel = UncertaintyStatistics.formatReliabilityLabel(dataPoint: nil, qdfCategory: UncertaintyStatistics.QDFCategory(prediction: 0, qCategory: .qMax, distanceCategory: .greaterThanMedianAndLessThanOrEqualToOOD, compositionCategory: .singleton), sizeOfCategory: REConstants.Uncertainty.minReliablePartitionSize)
                        Image(systemName: reliabilityLabel.reliabilityImageName)
                            .font(.title)
                            .foregroundStyle(reliabilityLabel.reliabilityColorGradient)
                            .opacity(reliabilityLabel.opacity)
                        Text(reliabilityLabel.reliabilityTextCaption)
                            .foregroundStyle(.gray)
                            .font(.title3)
                    }
                    
                    Grid(horizontalSpacing: 20, verticalSpacing: 20) {
                        GridRow(alignment: .top) {
                            Text(REConstants.CategoryDisplayLabels.qFull)
                                .foregroundStyle(.gray)
                                .gridColumnAlignment(.trailing)
                            Text(UncertaintyStatistics.getQCategoryLabel(qCategory: .qMax))
                                .modifier(CategoryLabelViewModifier())
                                .gridColumnAlignment(.leading)
                        }
                        GridRow(alignment: .top) {
                            Text(REConstants.CategoryDisplayLabels.dFull)
                                .foregroundStyle(.gray)
                            Text(UncertaintyStatistics.getDistanceCategoryLabel(distanceCategory: .greaterThanMedianAndLessThanOrEqualToOOD, abbreviated: true))
                                .modifier(CategoryLabelViewModifier())
                            
                        }
                        GridRow(alignment: .top) {
                            Text(REConstants.CategoryDisplayLabels.fFull)
                                .foregroundStyle(.gray)
                            Text(UncertaintyStatistics.getCompositionCategoryLabel(compositionCategory: .singleton, abbreviated: true))
                                .modifier(CategoryLabelViewModifier())
                            
                        }
                        GridRow(alignment: .top) {
                            Text(REConstants.CategoryDisplayLabels.sizeFull)
                                .foregroundStyle(.gray)
                            Text(UncertaintyStatistics.getQDFCategorySizeCharacterizationLabel(qDFCategorySizeCharacterization: .sufficient))
                                .modifier(CategoryLabelViewModifier())
                        }
                    }
                    .padding()
                    .modifier(SimpleBaseBorderModifier())
                    .padding()
                }
                
                // Low
                Group {
                    HStack {
                        let reliabilityLabel = UncertaintyStatistics.formatReliabilityLabel(dataPoint: nil, qdfCategory: UncertaintyStatistics.QDFCategory(prediction: 0, qCategory: .oneToQMax, distanceCategory: .lessThanOrEqualToMedian, compositionCategory: .singleton), sizeOfCategory: REConstants.Uncertainty.minReliablePartitionSize)
                        Image(systemName: reliabilityLabel.reliabilityImageName)
                            .font(.title)
                            .foregroundStyle(reliabilityLabel.reliabilityColorGradient)
                            .opacity(reliabilityLabel.opacity)
                        Text(reliabilityLabel.reliabilityTextCaption)
                            .foregroundStyle(.gray)
                            .font(.title3)
                    }
                    
                    Grid(horizontalSpacing: 20, verticalSpacing: 20) {
                        GridRow(alignment: .top) {
                            Text(REConstants.CategoryDisplayLabels.qFull)
                                .foregroundStyle(.gray)
                                .gridColumnAlignment(.trailing)
                            Text(UncertaintyStatistics.getQCategoryLabel(qCategory: .oneToQMax))
                                .modifier(CategoryLabelViewModifier())
                                .gridColumnAlignment(.leading)
                        }
                        GridRow(alignment: .top) {
                            Text(REConstants.CategoryDisplayLabels.dFull)
                                .foregroundStyle(.gray)
                            Text(UncertaintyStatistics.getDistanceCategoryLabel(distanceCategory: .lessThanOrEqualToMedian, abbreviated: true))
                                .modifier(CategoryLabelViewModifier())
                            
                        }
                        GridRow(alignment: .top) {
                            Text(REConstants.CategoryDisplayLabels.fFull)
                                .foregroundStyle(.gray)
                            Text(UncertaintyStatistics.getCompositionCategoryLabel(compositionCategory: .singleton, abbreviated: true))
                                .modifier(CategoryLabelViewModifier())
                            
                        }
                        GridRow(alignment: .top) {
                            Text(REConstants.CategoryDisplayLabels.sizeFull)
                                .foregroundStyle(.gray)
                            Text(UncertaintyStatistics.getQDFCategorySizeCharacterizationLabel(qDFCategorySizeCharacterization: .sufficient))
                                .modifier(CategoryLabelViewModifier())
                        }
                    }
                    .padding()
                    .modifier(SimpleBaseBorderModifier())
                    .padding()
                }
                // OOD
                Group {
                    HStack {
                        let reliabilityLabel = UncertaintyStatistics.formatReliabilityLabel(dataPoint: nil, qdfCategory: UncertaintyStatistics.QDFCategory(prediction: 0, qCategory: .oneToQMax, distanceCategory: .greaterThanOOD, compositionCategory: .singleton), sizeOfCategory: REConstants.Uncertainty.minReliablePartitionSize)
                        Image(systemName: reliabilityLabel.reliabilityImageName)
                            .font(.title)
                            .foregroundStyle(reliabilityLabel.reliabilityColorGradient)
                            .opacity(reliabilityLabel.opacity)
                        Text(reliabilityLabel.reliabilityTextCaption)
                            .foregroundStyle(.gray)
                            .font(.title3)
                    }
                    
                    Grid(horizontalSpacing: 20, verticalSpacing: 20) {
                        GridRow(alignment: .top) {
                            Text(REConstants.CategoryDisplayLabels.dFull)
                                .foregroundStyle(.gray)
                            Text(UncertaintyStatistics.getDistanceCategoryLabel(distanceCategory: .greaterThanOOD, abbreviated: true))
                                .modifier(CategoryLabelViewModifier())
                            
                        }
                    }
                    .padding()
                    .modifier(SimpleBaseBorderModifier())
                    .padding()
                    Text("and/or")
                        .monospaced()
                        .italic()
                        .foregroundStyle(.gray)
                                
                    Grid(horizontalSpacing: 20, verticalSpacing: 20) {
                        GridRow(alignment: .top) {
                            Text(REConstants.CategoryDisplayLabels.sizeFull)
                                .foregroundStyle(.gray)
                            Text("0")
                                .modifier(CategoryLabelViewModifier())
                        }
                    }
                    .padding()
                    .modifier(SimpleBaseBorderModifier())
                    .padding()
                }
                // Lowest
                HStack {
                    let reliabilityLabel = UncertaintyStatistics.formatReliabilityLabel(dataPoint: nil, qdfCategory: UncertaintyStatistics.QDFCategory(prediction: 0, qCategory: .zero, distanceCategory: .lessThanOrEqualToMedian, compositionCategory: .mismatch), sizeOfCategory: REConstants.Uncertainty.minReliablePartitionSize)
//                    let reliabilityLabel = UncertaintyStatistics.formatReliabilityLabel(dataPoint: nil, qdfCategory: UncertaintyStatistics.QDFCategory(prediction: 0, qCategory: .oneToQMax, distanceCategory: .lessThanOrEqualToMedian, compositionCategory: .singleton), sizeOfCategory: 0)
                    Image(systemName: reliabilityLabel.reliabilityImageName)
                        .font(.title)
                        .foregroundStyle(reliabilityLabel.reliabilityColorGradient)
                        .opacity(reliabilityLabel.opacity)
                    Text(reliabilityLabel.reliabilityTextCaption)
                        .foregroundStyle(.gray)
                        .font(.title3)
                }
                
                Grid(horizontalSpacing: 20, verticalSpacing: 20) {
                    GridRow(alignment: .top) {
                        Text("All remaining partitions and partition sizes")
                            .monospaced()
                            .italic()
                            .foregroundStyle(.gray)
                    }
                }
                .padding()
                .modifier(SimpleBaseBorderModifier())
                .padding()
            }
            .font(REConstants.Fonts.baseFont)
            .padding()
            .modifier(SimpleBaseBorderModifier())
            .padding()
            CalibrationReliabilityDisclaimerView()
//            VStack {
//                Text("\(REConstants.ProgramIdentifiers.mainProgramName) can only estimate a minimum probability of 0.01 and a maximum probability of 0.99, so it is neither intended nor suitable for high-risk applications.")
////                Text("The displayed calibrated probability is In the event the argmax between calibrated and uncalibrated differ...")
//            }
//            .foregroundStyle(.gray)
//            .italic()
//            .font(REConstants.Fonts.baseFont)
//            .frame(maxWidth: .infinity)
//            .padding()
//            .modifier(PrimaryComponentsViewModifier(useReBackgroundDarker: true, viewBoxScaling: 8))
////            .modifier(SimpleBaseBorderModifier())
//            .padding()
        }
        .scrollBounceBehavior(.basedOnSize)
        .padding()
        .modifier(SimpleBaseBorderModifier())
        .padding()
    }
}

struct CalibrationReliabilityView_Previews: PreviewProvider {
    static var previews: some View {
        CalibrationReliabilityView()
    }
}
