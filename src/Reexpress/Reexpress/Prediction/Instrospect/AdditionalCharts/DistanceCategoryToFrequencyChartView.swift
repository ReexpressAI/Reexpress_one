//
//  DistanceCategoryToFrequencyChartView.swift
//  Alpha1
//
//  Created by A on 9/20/23.
//

import SwiftUI
import Charts

struct DistanceCategoryToFrequencyChartView: View {
    var datasetId: Int
    @EnvironmentObject var dataController: DataController
    @Binding var graphState: GraphState
    var dataLoaded: Bool {
        return graphState == .displayed
    }
       
    @AppStorage(REConstants.UserDefaults.showingGraphViewSummaryStatisticsStringKey) var showingGraphViewSummaryStatistics: Bool = REConstants.UserDefaults.showingGraphViewSummaryStatisticsStringKeyDefault // If true, we show the selection as it appears in the graph (which may be a sample). If false, we show the full selection.
    @AppStorage(REConstants.UserDefaults.statsFontSizeStringKey) var statsFontSize: Double = Double(REConstants.UserDefaults.defaultStatsFontSize)
    var isSample: Bool {
        if let isSample = dataController.uncertaintyStatistics?.uncertaintyGraphCoordinator?.datasetId_To_inMemoryDataCoordinator[datasetId]?.currentViewIsSample() {
            return isSample
        } else {
            return false
        }
    }
    var selectionCategory2Total: [UncertaintyStatistics.DistanceCategory: Int] {
        return dataController.uncertaintyStatistics?.uncertaintyGraphCoordinator?.datasetId_To_inMemoryDataCoordinator[datasetId]?.summaryStats.distanceCategory2Total ?? [:]
    }
    var selectionCategory2Proportion: [UncertaintyStatistics.DistanceCategory: Float32] {
        return dataController.uncertaintyStatistics?.uncertaintyGraphCoordinator?.datasetId_To_inMemoryDataCoordinator[datasetId]?.summaryStats.distanceCategory2Proportion ?? [:]
    }
    var graphViewCategory2Total: [UncertaintyStatistics.DistanceCategory: Int] {
        return dataController.uncertaintyStatistics?.uncertaintyGraphCoordinator?.datasetId_To_inMemoryDataCoordinator[datasetId]?.currentViewConstraintsStack.last?.summaryStats.distanceCategory2Total ?? [:]
    }
    var graphViewCategory2Proportion: [UncertaintyStatistics.DistanceCategory: Float32] {
        return dataController.uncertaintyStatistics?.uncertaintyGraphCoordinator?.datasetId_To_inMemoryDataCoordinator[datasetId]?.currentViewConstraintsStack.last?.summaryStats.distanceCategory2Proportion ?? [:]
    }
    

    var category2Proportion: [UncertaintyStatistics.DistanceCategory: Float32] {
        if showingGraphViewSummaryStatistics {
            return graphViewCategory2Proportion
        } else {
            return selectionCategory2Proportion
        }
    }
    
    
    @State var rawSelectedWidth: Float32?
    @Binding var updateCounter: Int
    let distanceCategoryColorOpacity: Double = 0.5
    let categoryLabelColorOpacity: Double = 0.5
    
    let categoryWidth: Float32 = 100.0/3.0
    
    var selectedCategory: UncertaintyStatistics.DistanceCategory? {
        if let selectedWidth = rawSelectedWidth {
            if selectedWidth >= 0.0 && selectedWidth < categoryWidth {
                return .lessThanOrEqualToMedian
            } else if selectedWidth >= categoryWidth && selectedWidth < categoryWidth*2 {
                return .greaterThanMedianAndLessThanOrEqualToOOD
            } else if selectedWidth >= categoryWidth*2 && selectedWidth < categoryWidth*3 {
                return .greaterThanOOD
            }
        }
        return nil
    }
 
    var body: some View {
        if dataLoaded, updateCounter >= 0 {
            VStack {
                
                Chart {
                    RectangleMark(
                        xStart: .value("Rect Start Width", 0.0),
                        xEnd: .value("Rect End Width", categoryWidth),
                        yStart: .value("Rect Start Height", 0.0),
                        yEnd: .value("Rect End Height", category2Proportion[.lessThanOrEqualToMedian] ?? 0.0)
                    )
                    .foregroundStyle(
                        REConstants.REColors.reLabelGreenLighter.gradient
                            .opacity(
                                selectedCategory != nil ? (selectedCategory == .lessThanOrEqualToMedian ? distanceCategoryColorOpacity : distanceCategoryColorOpacity*0.5) : distanceCategoryColorOpacity
                            )
                    )
                    .annotation(position: .bottom) {
                        Text(UncertaintyStatistics.getDistanceCategoryLabel(distanceCategory: .lessThanOrEqualToMedian, abbreviated: true))
                            .modifier(CategoryLabelViewModifier())
                        .foregroundStyle(
                            REConstants.REColors.reLabelGreenLighter
                                .opacity(
                                    selectedCategory != nil ? (selectedCategory == .lessThanOrEqualToMedian ? distanceCategoryColorOpacity : distanceCategoryColorOpacity*0.5) : distanceCategoryColorOpacity
                                )
                        )
                    }
                    
                    RectangleMark(
                        xStart: .value("Rect Start Width", categoryWidth),
                        xEnd: .value("Rect End Width", categoryWidth*2),
                        yStart: .value("Rect Start Height", 0),
                        yEnd: .value("Rect End Height", category2Proportion[.greaterThanMedianAndLessThanOrEqualToOOD] ?? 0.0)
                    )
                    .foregroundStyle(
                        REConstants.Visualization.medianDistanceLineD0Color
                            .opacity(
                                selectedCategory != nil ? (selectedCategory == .greaterThanMedianAndLessThanOrEqualToOOD ? categoryLabelColorOpacity : categoryLabelColorOpacity*0.5) : categoryLabelColorOpacity
                            )
                    )
                    .annotation(position: .bottom) {
                        Text(UncertaintyStatistics.getDistanceCategoryLabel(distanceCategory: .greaterThanMedianAndLessThanOrEqualToOOD, abbreviated: true))
                            .modifier(CategoryLabelViewModifier())
                        .foregroundStyle(
                            REConstants.Visualization.medianDistanceLineD0Color
                                .opacity(
                                    selectedCategory != nil ? (selectedCategory == .greaterThanMedianAndLessThanOrEqualToOOD ? categoryLabelColorOpacity : categoryLabelColorOpacity*0.5) : categoryLabelColorOpacity
                                )
                        )
                    }
                    RectangleMark(
                        xStart: .value("Rect Start Width", categoryWidth*2),
                        xEnd: .value("Rect End Width", categoryWidth*3),
                        yStart: .value("Rect Start Height", 0),
                        yEnd: .value("Rect End Height", category2Proportion[.greaterThanOOD] ?? 0.0)
                    )
                    
                    .foregroundStyle(
                        REConstants.Visualization.oodDistanceLineD0Color
                            .opacity(
                                selectedCategory != nil ? (selectedCategory == .greaterThanOOD ? categoryLabelColorOpacity : categoryLabelColorOpacity*0.5) : categoryLabelColorOpacity
                            )
                    )
                    .annotation(position: .bottom) {
                        Text(UncertaintyStatistics.getDistanceCategoryLabel(distanceCategory: .greaterThanOOD, abbreviated: true))
                            .modifier(CategoryLabelViewModifier())
                        .foregroundStyle(
                            REConstants.Visualization.oodDistanceLineD0Color
                                .opacity(
                                    selectedCategory != nil ? (selectedCategory == .greaterThanOOD ? categoryLabelColorOpacity : categoryLabelColorOpacity*0.5) : categoryLabelColorOpacity
                                )
                        )
                    }
                    if let rawSelectedWidth = rawSelectedWidth {
                        RuleMark(
                            x: .value("Selected", rawSelectedWidth)
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
                            if let selectedCategory = selectedCategory, let sampleTotal = graphViewCategory2Total[selectedCategory], let sampleProportion = graphViewCategory2Proportion[selectedCategory], let selectionTotal = selectionCategory2Total[selectedCategory], let selectionProportion = selectionCategory2Proportion[selectedCategory] {
                                VStack {
                                    HStack {
                                        Text(REConstants.CategoryDisplayLabels.dFull+":")
                                        Text(UncertaintyStatistics.getDistanceCategoryLabel(distanceCategory: selectedCategory, abbreviated: true))
//                                            .font(.system(size: 14).smallCaps())
                                            .font(.system(size: statsFontSize).smallCaps())
                                            .monospaced()
                                        Spacer()
                                    }
                                    .foregroundStyle(.gray)
                                    .bold()
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
                                                Text(REConstants.CategoryDisplayLabels.currentSelectionLabel+":")
                                                    .foregroundStyle(.gray)
                                                if isSample {
                                                    Text(String(selectionTotal))
                                                        .monospaced()
                                                    Text(String(format: "%.2f", selectionProportion))
                                                        .monospaced()
                                                } else {
                                                    Text(String(sampleTotal))
                                                        .monospaced()
                                                    Text(String(format: "%.2f", sampleProportion))
                                                        .monospaced()
                                                }
                                            }
                                            GridRow {
                                                Text(REConstants.CategoryDisplayLabels.currentViewSampleLabel+":")
                                                    .foregroundStyle(.gray)
                                                if isSample {
                                                    Text(String(sampleTotal))
                                                        .monospaced()
                                                    Text(String(format: "%.2f", sampleProportion))
                                                        .monospaced()
                                                } else {
                                                    Text("N/A")
                                                    Text("N/A")
                                                }
                                            }
                                        } else {
                                            GridRow {
                                                Text(REConstants.CategoryDisplayLabels.currentSelectionLabel+":")
                                                    .foregroundStyle(.gray)

                                                    Text(String(selectionTotal))
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
                .chartXSelection(value: $rawSelectedWidth)
                
                .chartYAxisLabel(position: .trailing, alignment: .center) {
                    Text(REConstants.CategoryDisplayLabels.proportionLabel)
                        .font(REConstants.Visualization.xAndYAxisFont)
                }
                .chartXAxisLabel(position: .bottom, alignment: .center) {
                    VStack {
                        Text("")
                        Text(REConstants.CategoryDisplayLabels.dFull)
                    }
                    .font(REConstants.Visualization.xAndYAxisFont)
                }
                .chartXAxis(.hidden)
                .chartXScale(domain: 0...100, range: .plotDimension(startPadding: 10, endPadding: 10))
                .chartYScale(domain: 0...1, range: .plotDimension(startPadding: 10, endPadding: 10))
                .frame(height: 150)
                .padding()
            }
            .padding()
        }
    }
}
