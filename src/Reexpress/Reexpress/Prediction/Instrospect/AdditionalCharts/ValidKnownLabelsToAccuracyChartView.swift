//
//  ValidKnownLabelsToAccuracyChartView.swift
//  Alpha1
//
//  Created by A on 9/20/23.
//

import SwiftUI
import Charts

struct ValidKnownLabelsToAccuracyChartView: View {
    var datasetId: Int
    @EnvironmentObject var dataController: DataController
    @Binding var graphState: GraphState
    var dataLoaded: Bool {
        return graphState == .displayed
    }
    @AppStorage(REConstants.UserDefaults.showingGraphViewSummaryStatisticsStringKey) var showingGraphViewSummaryStatistics: Bool = REConstants.UserDefaults.showingGraphViewSummaryStatisticsStringKeyDefault // If true, we show the selection as it appears in the graph (which may be a sample). If false, we show the full selection.
    @AppStorage(REConstants.UserDefaults.statsFontSizeStringKey) var statsFontSize: Double = Double(REConstants.UserDefaults.defaultStatsFontSize)
    // isSample is only relevant when showingGraphViewSummaryStatistics
    var isSample: Bool {
        if let isSample = dataController.uncertaintyStatistics?.uncertaintyGraphCoordinator?.datasetId_To_inMemoryDataCoordinator[datasetId]?.currentViewIsSample() {
            return isSample
        } else {
            return false
        }
    }
    
    @State var rawSelectedStringLabel: String?
    
    @Binding var updateCounter: Int
    
    struct FPredictions { 
        let label: Int
        var labelAsString: String
        var frequency: Float32
    }
    
    var outputData: [FPredictions] {
        var data: [FPredictions] = []
        if showingGraphViewSummaryStatistics {
            for label in 0..<dataController.numberOfClasses {
                if label < graphViewFreqByClass.count {
                    data.append(.init(label: label, labelAsString: String(label), frequency: min(100*graphViewFreqByClass[label], 100)))
                } else {
                    data.append(.init(label: label, labelAsString: String(label), frequency: 0.0))
                }
            }
        } else {
            for label in 0..<dataController.numberOfClasses {
                if label < selectionFreqByClass.count {
                    data.append(.init(label: label, labelAsString: String(label), frequency: min(100*selectionFreqByClass[label], 100)))
                } else {
                    data.append(.init(label: label, labelAsString: String(label), frequency: 0.0))
                }
            }
        }
        return data
    }
        
    var graphViewTotalCorrectByClass: [Float32] {
        return dataController.uncertaintyStatistics?.uncertaintyGraphCoordinator?.datasetId_To_inMemoryDataCoordinator[datasetId]?.currentViewConstraintsStack.last?.summaryStats.totalCorrectByLabel ?? []
    }
    var graphViewTotalsByClass: [Float32] {
        return dataController.uncertaintyStatistics?.uncertaintyGraphCoordinator?.datasetId_To_inMemoryDataCoordinator[datasetId]?.currentViewConstraintsStack.last?.summaryStats.totalPredictedByLabel ?? []
    }
    var graphViewFreqByClass: [Float32] {
        return dataController.uncertaintyStatistics?.uncertaintyGraphCoordinator?.datasetId_To_inMemoryDataCoordinator[datasetId]?.currentViewConstraintsStack.last?.summaryStats.accuracyByLabel ?? []
    }
    var selectionTotalCorrectByClass: [Float32] {
        return dataController.uncertaintyStatistics?.uncertaintyGraphCoordinator?.datasetId_To_inMemoryDataCoordinator[datasetId]?.summaryStats.totalCorrectByLabel ?? []
    }
    var selectionTotalsByClass: [Float32] {
        return dataController.uncertaintyStatistics?.uncertaintyGraphCoordinator?.datasetId_To_inMemoryDataCoordinator[datasetId]?.summaryStats.totalPredictedByLabel ?? []
    }
    var selectionFreqByClass: [Float32] {
        return dataController.uncertaintyStatistics?.uncertaintyGraphCoordinator?.datasetId_To_inMemoryDataCoordinator[datasetId]?.summaryStats.accuracyByLabel ?? []
    }
    let barOpacity: Double = 0.5
    let chartHeight: CGFloat = 150
    let unavailableAccuracyString = "N/A"  // used when the denominator is 0
    var body: some View {
        if dataLoaded, updateCounter >= 0 {
            VStack {
                Chart(outputData, id:\.label) { f_element in
                    BarMark(
                        x: .value("Label", f_element.labelAsString),
                        y: .value("Frequency", f_element.frequency)
                    )
                    .foregroundStyle(
                        REConstants.REColors.reLabelMauve //reLabelUnlabeled //reLabelMauve
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
                            position: .top, spacing: 0,
                            overflowResolution: .init(
                                x: .fit(to: .chart),
                                y: .disabled
                            )
                        ) {
                            if rawSelectedStringLabel == f_element.labelAsString, f_element.label < graphViewTotalsByClass.count, f_element.label < graphViewFreqByClass.count, f_element.label < selectionTotalsByClass.count, f_element.label < selectionFreqByClass.count, f_element.label < graphViewTotalCorrectByClass.count, f_element.label < selectionTotalCorrectByClass.count {
                                let sampleTotalCorrect = graphViewTotalCorrectByClass[f_element.label]
                                let sampleTotal = graphViewTotalsByClass[f_element.label]
                                let sampleProportion = 100*graphViewFreqByClass[f_element.label]
                                let selectionTotalCorrect = selectionTotalCorrectByClass[f_element.label]
                                let selectionTotal = selectionTotalsByClass[f_element.label]
                                let selectionProportion = 100*selectionFreqByClass[f_element.label]
                                VStack {
                                    HStack {
                                        Text("Class-conditional Accuracy")
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
                                    Grid(verticalSpacing: REConstants.Visualization.popoverQuickViewGrid_VerticalSpacing) {
                                        GridRow {
                                            Text("")
                                                .gridColumnAlignment(.trailing)
                                            Text("Correct")
                                            Text("Total")
                                            Text(REConstants.CategoryDisplayLabels.accuracyLabel)
                                        }
                                        .foregroundStyle(.gray)
                                        if showingGraphViewSummaryStatistics {
                                            GridRow {
                                                Text(REConstants.CategoryDisplayLabels.currentSelectionLabel+":")
                                                    .foregroundStyle(.gray)
                                                Text(String(Int(selectionTotalCorrect)))
                                                    .monospaced()
                                                Text(String(Int(selectionTotal)))
                                                    .monospaced()
                                                Text(selectionTotal > 0 ? String(format: "%.2f", selectionProportion) : unavailableAccuracyString)
                                                    .monospaced()
                                            }
                                            .foregroundStyle(.gray)
                                            
                                            GridRow {
                                                Text(.init(isSample ? REConstants.CategoryDisplayLabels.currentViewSampleLabel+" (*displayed*):" : REConstants.CategoryDisplayLabels.currentViewLabel+" (*displayed*):"))
                                                    .foregroundStyle(isSample ? REConstants.Visualization.compareView_SampleIndicator : .primary)
 
                                                    Text(String(Int(sampleTotalCorrect)))
                                                        .monospaced()
                                                    Text(String(Int(sampleTotal)))
                                                        .monospaced()
                                                Text(sampleTotal > 0 ? String(format: "%.2f", sampleProportion) : unavailableAccuracyString)
                                                        .monospaced()
                                            }
                                        } else {
                                            GridRow {
                                                Text(REConstants.CategoryDisplayLabels.currentSelectionLabel+":")
                                                    .foregroundStyle(.gray)
                                                Text(String(Int(selectionTotalCorrect)))
                                                    .monospaced()
                                                Text(String(Int(selectionTotal)))
                                                    .monospaced()
                                                Text(selectionTotal > 0 ? String(format: "%.2f", selectionProportion) : unavailableAccuracyString)
                                                    .monospaced()
                                            }
                                        }
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
                    Text(REConstants.CategoryDisplayLabels.accuracyLabel)
                        .font(REConstants.Visualization.xAndYAxisFont)
                }
                .chartXAxisLabel(position: .bottom, alignment: .center) {
                    Text(REConstants.CategoryDisplayLabels.classLabelAxisLabel)
                        .font(REConstants.Visualization.xAndYAxisFont)
                }
                .chartYScale(domain: 0...100, range: .plotDimension(startPadding: 10, endPadding: 10))
                .frame(height: chartHeight)
                .padding()
            }
            .padding()
        }
    }
}

