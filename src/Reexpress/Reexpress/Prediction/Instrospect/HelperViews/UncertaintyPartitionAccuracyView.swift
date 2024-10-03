//
//  UncertaintyPartitionAccuracyView.swift
//  Alpha1
//
//  Created by A on 9/20/23.
//

import SwiftUI

/*
 balancedAccuracy = vDSP.mean(accuracyByNonZeroLabel)
 balancedAccuracy_NonzeroClasses = accuracyByNonZeroLabel.count
 totalCorrect = vDSP.sum(totalCorrectByLabel)
 totalPredicted = vDSP.sum(totalPredictedByLabel)
 if totalPredicted > 0 {
 accuracy = totalCorrect / totalPredicted
 }
 */
struct UncertaintyPartitionAccuracyView: View {
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
    
    
    var graphViewBalancedAccuracy: Float32 {
        return 100.0 * (dataController.uncertaintyStatistics?.uncertaintyGraphCoordinator?.datasetId_To_inMemoryDataCoordinator[datasetId]?.currentViewConstraintsStack.last?.summaryStats.balancedAccuracy ?? 0.0)
    }
    var graphViewBalancedAccuracy_NonzeroClasses: Int {
        return dataController.uncertaintyStatistics?.uncertaintyGraphCoordinator?.datasetId_To_inMemoryDataCoordinator[datasetId]?.currentViewConstraintsStack.last?.summaryStats.balancedAccuracy_NonzeroClasses ?? 0
    }
    var selectionBalancedAccuracy: Float32 {
        return 100.0 * (dataController.uncertaintyStatistics?.uncertaintyGraphCoordinator?.datasetId_To_inMemoryDataCoordinator[datasetId]?.summaryStats.balancedAccuracy ?? 0.0)
    }
    var selectionBalancedAccuracy_NonzeroClasses: Int {
        return dataController.uncertaintyStatistics?.uncertaintyGraphCoordinator?.datasetId_To_inMemoryDataCoordinator[datasetId]?.summaryStats.balancedAccuracy_NonzeroClasses ?? 0
    }
    
    var graphViewAccuracy: Float32 {
        return 100.0 * (dataController.uncertaintyStatistics?.uncertaintyGraphCoordinator?.datasetId_To_inMemoryDataCoordinator[datasetId]?.currentViewConstraintsStack.last?.summaryStats.accuracy ?? 0.0)
    }
    var graphViewTotalCorrect: Int {
        return Int(dataController.uncertaintyStatistics?.uncertaintyGraphCoordinator?.datasetId_To_inMemoryDataCoordinator[datasetId]?.currentViewConstraintsStack.last?.summaryStats.totalCorrect ?? 0)
    }
    var graphViewTotalPredicted: Int {
        return Int(dataController.uncertaintyStatistics?.uncertaintyGraphCoordinator?.datasetId_To_inMemoryDataCoordinator[datasetId]?.currentViewConstraintsStack.last?.summaryStats.totalPredicted ?? 0)
    }
    var selectionAccuracy: Float32 {
        return 100.0 * (dataController.uncertaintyStatistics?.uncertaintyGraphCoordinator?.datasetId_To_inMemoryDataCoordinator[datasetId]?.summaryStats.accuracy ?? 0.0)
    }
    var selectionTotalCorrect: Int {
        return Int(dataController.uncertaintyStatistics?.uncertaintyGraphCoordinator?.datasetId_To_inMemoryDataCoordinator[datasetId]?.summaryStats.totalCorrect ?? 0)
    }
    var selectionTotalPredicted: Int {
        return Int(dataController.uncertaintyStatistics?.uncertaintyGraphCoordinator?.datasetId_To_inMemoryDataCoordinator[datasetId]?.summaryStats.totalPredicted ?? 0)
    }
    
    let unavailableAccuracyString = "N/A"  // used when the denominator is 0
    var body: some View {
        if dataLoaded, updateCounter >= 0 {
            VStack {
                Grid(horizontalSpacing: 20) {
                        GridRow {
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(REConstants.CategoryDisplayLabels.currentSelectionLabel)
                                        .bold()
                                }
                            }
                            .gridCellColumns(4)
                        }
                        .foregroundStyle(showingGraphViewSummaryStatistics ? .gray : .primary)
                        GridRow {
                            HStack {
                                PopoverViewWithButtonLocalState(popoverViewText: REConstants.Uncertainty.balancedAccuracyDescription)
                                    .foregroundStyle(.gray)
                                Text("Balanced Accuracy:")
                                    .foregroundStyle(.gray)
                                    .bold()
                            }
                            .gridColumnAlignment(.trailing)

                            Text(selectionBalancedAccuracy_NonzeroClasses > 0 ? String(format: "%.2f", selectionBalancedAccuracy) : unavailableAccuracyString)
                                .textSelection(.enabled)
                                .monospaced()
                            HStack(spacing: 0) {
                                Text("Out of ")
                                    .foregroundStyle(.gray)
                                Text(String(selectionBalancedAccuracy_NonzeroClasses))
                                    .monospaced()
                                Text(" \(selectionBalancedAccuracy_NonzeroClasses != 1 ? "classes" : "class") with > 0 labels")
                                    .foregroundStyle(.gray)
                            }
                            .gridCellColumns(2)
                        }
                        .foregroundStyle(showingGraphViewSummaryStatistics ? .gray : .primary)
                        GridRow {
                            Text("")
                            Text("")
                            Text("Correct")
                                .foregroundStyle(.gray)
                            Text("Total")
                                .foregroundStyle(.gray)
//                            Text(REConstants.CategoryDisplayLabels.accuracyLabel)
//                                .foregroundStyle(.gray)
                        }
                        .padding(.top, 5)
                        .foregroundStyle(showingGraphViewSummaryStatistics ? .gray : .primary)
                        GridRow {
                            Text("\(REConstants.CategoryDisplayLabels.accuracyLabel):")
                                .foregroundStyle(.gray)
                                .bold()
                            Text(selectionTotalPredicted > 0 ? String(format: "%.2f", selectionAccuracy) : unavailableAccuracyString)
                                .textSelection(.enabled)
                                .monospaced()
                            Text(String(selectionTotalCorrect))
                                .textSelection(.enabled)
                            Text(String(selectionTotalPredicted))
                                .textSelection(.enabled)
                        }
                        .foregroundStyle(showingGraphViewSummaryStatistics ? .gray : .primary)
                    if showingGraphViewSummaryStatistics { //}&& isSample {
                        GridRow {
                            VStack(alignment: .leading) {
                                HStack {
//                                    Text(REConstants.CategoryDisplayLabels.currentViewSampleLabel)
                                    Text(.init(isSample ? REConstants.CategoryDisplayLabels.currentViewSampleLabel+" (*displayed*)" : REConstants.CategoryDisplayLabels.currentViewLabel+" (*displayed*)"))
                                        .bold()
                                        .foregroundStyle(isSample ? REConstants.Visualization.compareView_SampleIndicator : .primary)
                                }
                                .padding([.top, .bottom], 5)
                            }
                            .gridCellColumns(4)
                        }
                        GridRow {
                            HStack {
                                Text("Balanced Accuracy:")
                                    .foregroundStyle(.gray)
                                    .bold()
                            }
                            Text(graphViewBalancedAccuracy_NonzeroClasses > 0 ? String(format: "%.2f", graphViewBalancedAccuracy) : unavailableAccuracyString)
                                .textSelection(.enabled)
                                .monospaced()
                            HStack(spacing: 0) {
                                Text("Out of ")
                                    .foregroundStyle(.gray)
                                Text(String(graphViewBalancedAccuracy_NonzeroClasses))
                                    .monospaced()
                                Text(" \(graphViewBalancedAccuracy_NonzeroClasses != 1 ? "classes" : "class") with > 0 labels")
                                    .foregroundStyle(.gray)
                            }
                            .gridCellColumns(2)
                        }
                        
                        GridRow {
                            Text("")
                            Text("")
                            Text("Correct")
                                .foregroundStyle(.gray)
                            Text("Total")
                                .foregroundStyle(.gray)
                        }
                        .padding(.top, 5)
                        GridRow {
                            Text("\(REConstants.CategoryDisplayLabels.accuracyLabel):")
                                .foregroundStyle(.gray)
                                .bold()
                            Text(graphViewTotalPredicted > 0 ? String(format: "%.2f", graphViewAccuracy) : unavailableAccuracyString)
                                .textSelection(.enabled)
                                .monospaced()
                            Text(String(graphViewTotalCorrect))
                                .textSelection(.enabled)
                            Text(String(graphViewTotalPredicted))
                                .textSelection(.enabled)
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

