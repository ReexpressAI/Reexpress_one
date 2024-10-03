//
//  UncertaintychartStreamlinedPopoverView.swift
//  Alpha1
//
//  Created by A on 9/19/23.
//

import SwiftUI

struct UncertaintychartStreamlinedPopoverView: View {
    var dataController: DataController
    var dataPoint: UncertaintyStatistics.DataPoint?
    
    // We take in the font size via an argument rather than calling user defaults each time this view appears since it's potentially called many times in sucession.
    var statsFontSize: Double = Double(REConstants.UserDefaults.defaultStatsFontSize)
//    @AppStorage(REConstants.UserDefaults.statsFontSizeStringKey) var statsFontSize: Double = Double(REConstants.UserDefaults.defaultStatsFontSize)
    
    var f_of_x_argmax_formatted: String {
        if let dataPoint = dataPoint, dataPoint.prediction < dataPoint.softmax.count {
            return REConstants.floatProbToDisplaySignificantDigits(floatProb: dataPoint.softmax[dataPoint.prediction])
        } else {
            return ""
        }
    }
    var partitionSize: Int {
        if let dataPoint = dataPoint, let qdfCategory = dataPoint.qdfCategory, let calibratedOutput = dataController.uncertaintyStatistics?.vennADMITCategory_To_CalibratedOutput[qdfCategory], let sizeOfCategory = calibratedOutput?.sizeOfCategory, sizeOfCategory >= 0 {
            return Int(sizeOfCategory)
        }
        return 0
    }
    var partitionSizeString: String {
        if partitionSize < REConstants.Uncertainty.minReliablePartitionSize {
            return "Insufficient: " + String(partitionSize)
        } else {
            return String(partitionSize)
        }
    }
    var reliabilityLabel: (reliabilityImageName: String, reliabilityTextCaption: String, reliabilityColorGradient: AnyShapeStyle, opacity: Double) {
        if let dataPoint = dataPoint, let qdfCategory = dataPoint.qdfCategory {
            return UncertaintyStatistics.formatReliabilityLabel(dataPoint: nil, qdfCategory: qdfCategory, sizeOfCategory: partitionSize)
        }
        return UncertaintyStatistics.formatReliabilityLabel(dataPoint: nil, qdfCategory: nil, sizeOfCategory: partitionSize)
    }
    
    var calibratedProbabilityString: String {
        if let dataPoint = dataPoint, let qdfCategory = dataPoint.qdfCategory, let calibratedOutput = dataController.uncertaintyStatistics?.vennADMITCategory_To_CalibratedOutput[qdfCategory], let minDistribution = calibratedOutput?.minDistribution, dataPoint.prediction < minDistribution.count {
            return REConstants.floatProbToDisplaySignificantDigits(floatProb: minDistribution[dataPoint.prediction])
        }
        return "N/A"
    }
    var labelString: String {
        if let dataPoint = dataPoint, let labelDisplayName = dataController.labelToName[dataPoint.label] {
            return labelDisplayName
        } else {
            return "N/A"
        }
    }
    @ViewBuilder var predictionStringView: some View {
        HStack {
            if let dataPoint = dataPoint, dataPoint.prediction >= 0, let predictionDisplayName = dataController.labelToName[dataPoint.prediction] {
                if DataController.isKnownValidLabel(label: dataPoint.label, numberOfClasses: dataController.numberOfClasses) {
                    if dataPoint.prediction == dataPoint.label {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.green.gradient)
                            .opacity(0.5)
                    } else {
                        Image(systemName: "minus.diamond")
                            .foregroundStyle(.red.gradient)
                            .opacity(0.5)
                    }
                }
                Text(predictionDisplayName)
                    .monospaced()
            } else {
                Text("N/A")
                    .monospaced()
            }
        }
    }
    
    var body: some View {
        if let dataPoint = dataPoint, let qdfCategory = dataPoint.qdfCategory {
            VStack {
                Grid(verticalSpacing: REConstants.Visualization.popoverQuickViewGrid_VerticalSpacing) {
                    GridRow {
                        Text(REConstants.CategoryDisplayLabels.labelFull+":")
                            .foregroundStyle(.gray)
                            .gridColumnAlignment(.trailing)
                        Text(labelString)
                            .monospaced()
                            .gridColumnAlignment(.leading)
                    }
                    GridRow {
                        Text(REConstants.CategoryDisplayLabels.predictionFull+":")
                            .foregroundStyle(.gray)
                        predictionStringView
                    }
                    
                    GridRow {
                        Divider()
                            .gridCellUnsizedAxes([.horizontal, .vertical])
                            .gridCellColumns(2)
                    }
                    GridRow {
                        Text(REConstants.CategoryDisplayLabels.calibratedProbabilityFull+":")
                            .foregroundStyle(.gray)
                        Text(calibratedProbabilityString)
                            .monospaced()
                    }
                    
                    GridRow {
                        Text(REConstants.CategoryDisplayLabels.calibrationReliabilityFull+":")
                            .foregroundStyle(.gray)
                        HStack {
                            Image(systemName: reliabilityLabel.reliabilityImageName)
                                .font(.system(size: statsFontSize)) //.font(.system(size: 14))
                                .foregroundStyle(reliabilityLabel.reliabilityColorGradient)
                                .opacity(reliabilityLabel.opacity)
                            Text(reliabilityLabel.reliabilityTextCaption)
                        }
                    }
                    GridRow {
                        Text(REConstants.CategoryDisplayLabels.sizeFull+":")
                            .foregroundStyle(.gray)
                        Text(partitionSizeString)
                            .monospaced()
                    }

                    GridRow {
                        Divider()
                            .gridCellUnsizedAxes([.horizontal, .vertical])
                            .gridCellColumns(2)
                    }
                    GridRow {
                        Text(REConstants.CategoryDisplayLabels.fFull+":")
                            .foregroundStyle(.gray)
                        HStack {
                            Text(UncertaintyStatistics.getCompositionCategoryLabel(compositionCategory: qdfCategory.compositionCategory, abbreviated: true)+":")
//                                .font(.system(size: 14).smallCaps())
                                .font(.system(size: statsFontSize).smallCaps())
                                .monospaced()
                                .foregroundStyle(.gray)
                                .bold()
                            Text(f_of_x_argmax_formatted)
                                .monospaced()
                        }
                    }
                    GridRow {
                        Text(REConstants.CategoryDisplayLabels.dFull+":")
                            .foregroundStyle(.gray)
                        HStack {
                            Text(UncertaintyStatistics.getDistanceCategoryLabel(distanceCategory: qdfCategory.distanceCategory, abbreviated: true)+":")
//                                .font(.system(size: 14).smallCaps())
                                .font(.system(size: statsFontSize).smallCaps())
                                .monospaced()
                                .foregroundStyle(.gray)
                                .bold()
                            Text(String(dataPoint.d0))
                                .monospaced()
                        }
                    }
                    GridRow {
                        Text(REConstants.CategoryDisplayLabels.qFull+":")
                            .foregroundStyle(.gray)
                        HStack {
                            Text(UncertaintyStatistics.getQCategoryLabel(qCategory: qdfCategory.qCategory)+":")
//                                .font(.system(size: 14).smallCaps())
                                .font(.system(size: statsFontSize).smallCaps())
                                .monospaced()
                                .foregroundStyle(.gray)
                                .bold()
                            Text(String(dataPoint.q))
                                .monospaced()
                        }
                    }
                }
                .font(.system(size: statsFontSize))
            }
            .frame(minWidth: 350, maxWidth: 600)
            .padding()
            .modifier(SimpleBaseBorderModifierWithColorOption())
        }
    }
}


