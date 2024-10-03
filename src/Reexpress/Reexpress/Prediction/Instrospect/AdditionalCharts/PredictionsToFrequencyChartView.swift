//
//  PredictionsToFrequencyChartView.swift
//  Alpha1
//
//  Created by A on 9/19/23.
//

import SwiftUI
import Charts

struct PredictionsToFrequencyChartView: View {
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
    
    struct FPredictions { //}: Identifiable {
        //        let id: UUID = UUID()
        let label: Int
        var labelAsString: String
        var frequency: Float32
    }
    
    var outputData: [FPredictions] {
        var data: [FPredictions] = []
        if showingGraphViewSummaryStatistics {
            for label in 0..<dataController.numberOfClasses {
                if label < graphViewFreqByClass.count {
                    data.append(.init(label: label, labelAsString: String(label), frequency: graphViewFreqByClass[label]))
                } else {
                    data.append(.init(label: label, labelAsString: String(label), frequency: 0.0))
                }
            }
        } else {
            for label in 0..<dataController.numberOfClasses {
                if label < selectionFreqByClass.count {
                    data.append(.init(label: label, labelAsString: String(label), frequency: selectionFreqByClass[label]))
                } else {
                    data.append(.init(label: label, labelAsString: String(label), frequency: 0.0))
                }
            }
        }
        return data
    }
    
    var graphViewTotalsByClass: [Float32] {
        return dataController.uncertaintyStatistics?.uncertaintyGraphCoordinator?.datasetId_To_inMemoryDataCoordinator[datasetId]?.currentViewConstraintsStack.last?.summaryStats.predictionTotalsByClass ?? []
    }
    var graphViewFreqByClass: [Float32] {
        return dataController.uncertaintyStatistics?.uncertaintyGraphCoordinator?.datasetId_To_inMemoryDataCoordinator[datasetId]?.currentViewConstraintsStack.last?.summaryStats.predictionFreqByClass ?? []
    }
    var selectionTotalsByClass: [Float32] {
        return dataController.uncertaintyStatistics?.uncertaintyGraphCoordinator?.datasetId_To_inMemoryDataCoordinator[datasetId]?.summaryStats.predictionTotalsByClass ?? []
    }
    var selectionFreqByClass: [Float32] {
        return dataController.uncertaintyStatistics?.uncertaintyGraphCoordinator?.datasetId_To_inMemoryDataCoordinator[datasetId]?.summaryStats.predictionFreqByClass ?? []
    }
    let barOpacity: Double = 0.5
    let chartHeight: CGFloat = 150
    var body: some View {
        if dataLoaded, updateCounter >= 0 {
            VStack {
                Chart(outputData, id:\.label) { f_element in
                    BarMark(
                        x: .value("Label", f_element.labelAsString),
                        y: .value("Frequency", f_element.frequency)
                    )
                    .foregroundStyle(
                        Color.blue
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
                            if rawSelectedStringLabel == f_element.labelAsString, f_element.label < graphViewTotalsByClass.count, f_element.label < graphViewFreqByClass.count, f_element.label < selectionTotalsByClass.count, f_element.label < selectionFreqByClass.count {
                                
                                let sampleTotal = graphViewTotalsByClass[f_element.label]
                                let sampleProportion = graphViewFreqByClass[f_element.label]
                                let selectionTotal = selectionTotalsByClass[f_element.label]
                                let selectionProportion = selectionFreqByClass[f_element.label]
                                VStack {
                                    HStack {
                                        Text("Predicted label proportion")
                                            .foregroundStyle(.gray)
                                            .bold()
                                        Spacer()
                                    }
                                    HStack {
                                        Text(REConstants.CategoryDisplayLabels.predictedClassLabelAxisLabel+":")
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
                                            Text("Total")
                                            Text(REConstants.CategoryDisplayLabels.proportionLabel)
                                        }
                                        .foregroundStyle(.gray)
                                        if showingGraphViewSummaryStatistics {                                            
                                            GridRow {
                                                Text(.init(REConstants.CategoryDisplayLabels.currentSelectionLabel+":"))
                                                    .foregroundStyle(.gray)
                                                    Text(String(selectionTotal))
                                                        .monospaced()
                                                        .foregroundStyle(.gray)
                                                    Text(String(format: "%.2f", selectionProportion))
                                                        .monospaced()
                                                        .foregroundStyle(.gray)
                                            }
                                            GridRow {
                                                Text(.init(isSample ? REConstants.CategoryDisplayLabels.currentViewSampleLabel+" (*displayed*):" : REConstants.CategoryDisplayLabels.currentViewLabel+" (*displayed*):"))
                                                    .foregroundStyle(isSample ? REConstants.Visualization.compareView_SampleIndicator : .primary)
                                                    Text(String(sampleTotal))
                                                        .monospaced()
                                                    Text(String(format: "%.2f", sampleProportion))
                                                        .monospaced()
                                            }
                                        } else {
                                            GridRow {
                                                Text(REConstants.CategoryDisplayLabels.currentSelectionLabel+":")
                                                    .foregroundStyle(.gray)
                                                
                                                Text(String(Int(selectionTotal)))
                                                    .monospaced()
                                                Text(String(format: "%.2f", selectionProportion))
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
                    Text(REConstants.CategoryDisplayLabels.proportionLabel)
                        .font(REConstants.Visualization.xAndYAxisFont)
                }
                .chartXAxisLabel(position: .bottom, alignment: .center) {
                    Text(REConstants.CategoryDisplayLabels.predictedClassLabelAxisLabel)
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

