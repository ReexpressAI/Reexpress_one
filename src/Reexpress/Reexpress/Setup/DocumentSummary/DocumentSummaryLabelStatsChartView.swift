//
//  DocumentSummaryLabelStatsChartView.swift
//  Alpha1
//
//  Created by A on 9/20/23.
//

import SwiftUI
import Charts

struct DocumentSummaryLabelStatsChartView: View {
    @EnvironmentObject var dataController: DataController

    @Binding var dataLoaded: Bool
    @State var rawSelectedStringLabel: String?
    @AppStorage(REConstants.UserDefaults.statsFontSizeStringKey) var statsFontSize: Double = Double(REConstants.UserDefaults.defaultStatsFontSize)
    var labelSummaryStatistics: (labelTotalsByClass: [Int: Float32], labelFreqByClass: [Int: Float32], totalDocuments: Int)
    
    struct FPredictions: Identifiable {
        let id: UUID = UUID()
        let label: Int
        var labelAsString: String
        var frequency: Float32
    }
    
    var outputData: [FPredictions] {
        var data: [FPredictions] = []
        let allValidLabels = DataController.allValidLabelsAsArray(numberOfClasses: dataController.numberOfClasses)
            for label in allValidLabels {
                if let value = selectionFreqByClass[label] {
                    if (label == REConstants.DataValidator.oodLabel || label == REConstants.DataValidator.unlabeledLabel) {
                        let labelDisplayName = REConstants.DataValidator.getDefaultLabelName(label: label, abbreviated: true)
                        data.append(.init(label: label, labelAsString: labelDisplayName, frequency: value))
                    } else {
                        data.append(.init(label: label, labelAsString: String(label), frequency: value))
                    }
                } else {
                    data.append(.init(label: label, labelAsString: String(label), frequency: 0.0))
                }
            }
        return data
    }
    
    var selectionTotalsByClass: [Int: Float32] {
        return labelSummaryStatistics.labelTotalsByClass
    }
    var selectionFreqByClass: [Int: Float32] {
        return labelSummaryStatistics.labelFreqByClass
    }
    let barOpacity: Double = 0.5
    let chartHeight: CGFloat = 150
    var body: some View {
        if dataLoaded {
            VStack {
                Chart(outputData, id:\.label) { f_element in
                    BarMark(
                        x: .value("Label", f_element.labelAsString),
                        y: .value("Frequency", f_element.frequency)
                    )
                    .foregroundStyle(
                        Color.orange
                            .opacity(
                                rawSelectedStringLabel != nil ? (rawSelectedStringLabel == f_element.labelAsString ? barOpacity : barOpacity*0.5) : barOpacity
                            )
                    )
                    
                    if let rawSelectedStringLabel = rawSelectedStringLabel, rawSelectedStringLabel == f_element.labelAsString {
                        RuleMark(
                            x: .value("Label", rawSelectedStringLabel)
                        )
                        .foregroundStyle(Color.gray.opacity(0.0))
                        .offset(yStart: 0)
                        .zIndex(-1)
                        .annotation(
                            position: .bottom, spacing: 0,
                            overflowResolution: .init(
                                x: .fit(to: .chart),
                                y: .disabled
                            )
                        ) {
                            if rawSelectedStringLabel == f_element.labelAsString, let selectionTotal = selectionTotalsByClass[f_element.label], let selectionProportion = selectionFreqByClass[f_element.label] {
                                VStack {
                                    HStack {
                                        Text("True label proportion")
                                            .foregroundStyle(.gray)
                                            .bold()
                                        Spacer()
                                    }
                                    HStack {
                                        Text(REConstants.CategoryDisplayLabels.classLabelAxisLabel+":")
                                            .foregroundStyle(.gray)
                                        if let predictionDisplayName = dataController.labelToName[f_element.label] {
                                            Text(predictionDisplayName.truncateUpToMaxWithEllipsis(maxLength: 25))
                                                .monospaced()
                                        } else {
                                            Text(String(f_element.label))
                                                .monospaced()
                                        }
                                        
                                        Spacer()
                                    }
                                    
                                    Divider()
                                    HStack {
                                        Grid(verticalSpacing: REConstants.Visualization.popoverQuickViewGrid_VerticalSpacing) {
                                            GridRow {
                                                Text("Total")
                                                Text(REConstants.CategoryDisplayLabels.proportionLabel)
                                            }
                                            .foregroundStyle(.gray)
                                            GridRow {
                                                Text(String(Int(selectionTotal)))
                                                    .monospaced()
                                                Text(String(format: "%.2f", selectionProportion))
                                                    .monospaced()
                                            }
                                        }
                                        Spacer()
                                    }
                                }
                                .font(.system(size: statsFontSize))
                                .padding()
                                .modifier(SimpleBaseBorderModifierWithColorOption())
                            }
                        }
                    }
                     
                }
                .chartXSelection(value: $rawSelectedStringLabel)
                .chartYAxisLabel(position: .trailing, alignment: .center) {
                    Text(REConstants.CategoryDisplayLabels.proportionLabel)
                        .font(REConstants.Visualization.xAndYAxisFont)
                }
                .chartXAxisLabel(position: .bottom, alignment: .center) {
                    Text(REConstants.CategoryDisplayLabels.classLabelAxisLabel)
                        .font(REConstants.Visualization.xAndYAxisFont)
                }
                .chartYScale(domain: 0...1, range: .plotDimension(startPadding: 10, endPadding: 10))
                .frame(height: chartHeight)
                .padding()
            }
            .padding()
        }
    }
    
}
