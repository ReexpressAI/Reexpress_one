//
//  QCategoryToFrequencyChartView.swift
//  Alpha1
//
//  Created by A on 9/18/23.
//

import SwiftUI
import Charts

struct QCategoryToFrequencyChartView: View {
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
    var selectionQCategory2Total: [UncertaintyStatistics.QCategory: Int] {
        return dataController.uncertaintyStatistics?.uncertaintyGraphCoordinator?.datasetId_To_inMemoryDataCoordinator[datasetId]?.summaryStats.qCategory2Total ?? [:]
    }
    var selectionQCategory2Proportion: [UncertaintyStatistics.QCategory: Float32] {
        return dataController.uncertaintyStatistics?.uncertaintyGraphCoordinator?.datasetId_To_inMemoryDataCoordinator[datasetId]?.summaryStats.qCategory2Proportion ?? [:]
    }
    var graphViewQCategory2Total: [UncertaintyStatistics.QCategory: Int] {
        return dataController.uncertaintyStatistics?.uncertaintyGraphCoordinator?.datasetId_To_inMemoryDataCoordinator[datasetId]?.currentViewConstraintsStack.last?.summaryStats.qCategory2Total ?? [:]
    }
    var graphViewQCategory2Proportion: [UncertaintyStatistics.QCategory: Float32] {
        return dataController.uncertaintyStatistics?.uncertaintyGraphCoordinator?.datasetId_To_inMemoryDataCoordinator[datasetId]?.currentViewConstraintsStack.last?.summaryStats.qCategory2Proportion ?? [:]
    }
    
//    var qCategory2Total: [UncertaintyStatistics.QCategory: Int] {
//        if showingGraphViewSummaryStatistics {
//            return graphViewQCategory2Total
//        } else {
//            return selectionQCategory2Total
//        }
//    }
    var qCategory2Proportion: [UncertaintyStatistics.QCategory: Float32] {
        if showingGraphViewSummaryStatistics {
            return graphViewQCategory2Proportion
        } else {
            return selectionQCategory2Proportion
        }
    }
    
    
    @State var rawSelectedWidth: Float32?
    @Binding var updateCounter: Int
    let distanceCategoryColorOpacity: Double = 0.5
    let categoryLabelColorOpacity: Double = 0.5
    
    let categoryWidth: Float32 = 100.0/3.0
    
    var selectedCategory: UncertaintyStatistics.QCategory? {
        if let selectedWidth = rawSelectedWidth {
            if selectedWidth >= 0.0 && selectedWidth < categoryWidth {
                return .qMax
            } else if selectedWidth >= categoryWidth && selectedWidth < categoryWidth*2 {
                return .oneToQMax
            } else if selectedWidth >= categoryWidth*2 && selectedWidth < categoryWidth*3 {
                return .zero
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
                        yEnd: .value("Rect End Height", qCategory2Proportion[.qMax] ?? 0.0)
                    )
                    .foregroundStyle(
                        REConstants.REColors.reLabelGreenLighter.gradient
                            .opacity(
                                selectedCategory != nil ? (selectedCategory == .qMax ? distanceCategoryColorOpacity : distanceCategoryColorOpacity*0.5) : distanceCategoryColorOpacity
                            )
                    )
                    .annotation(position: .bottom) {
                        VStack {
                            Text(UncertaintyStatistics.getQCategoryLabel(qCategory: .qMax))
                                .modifier(CategoryLabelViewModifier())
                            Text("q ∈ {\(REConstants.Uncertainty.defaultQMax),...,\(REConstants.Uncertainty.maxQAvailableFromIndexer)} ")
                                .monospaced()
                        }
                        .foregroundStyle(
                            REConstants.REColors.reLabelGreenLighter
                                .opacity(
                                    selectedCategory != nil ? (selectedCategory == .qMax ? distanceCategoryColorOpacity : distanceCategoryColorOpacity*0.5) : distanceCategoryColorOpacity
                                )
                        )
                    }
                    
                    RectangleMark(
                        xStart: .value("Rect Start Width", categoryWidth),
                        xEnd: .value("Rect End Width", categoryWidth*2),
                        yStart: .value("Rect Start Height", 0),
                        yEnd: .value("Rect End Height", qCategory2Proportion[.oneToQMax] ?? 0.0)
                    )
                    .foregroundStyle(
                        REConstants.Visualization.medianDistanceLineD0Color
                            .opacity(
                                selectedCategory != nil ? (selectedCategory == .oneToQMax ? categoryLabelColorOpacity : categoryLabelColorOpacity*0.5) : categoryLabelColorOpacity
                            )
                    )
                    .annotation(position: .bottom) {
                        VStack {
                            Text(UncertaintyStatistics.getQCategoryLabel(qCategory: .oneToQMax))
                                .modifier(CategoryLabelViewModifier())
                            Text("q ∈ {1,...,\(REConstants.Uncertainty.defaultQMax-1)}")
                                .monospaced()
                        }
                        .foregroundStyle(
                            REConstants.Visualization.medianDistanceLineD0Color
                                .opacity(
                                    selectedCategory != nil ? (selectedCategory == .oneToQMax ? categoryLabelColorOpacity : categoryLabelColorOpacity*0.5) : categoryLabelColorOpacity
                                )
                        )
                    }
                    RectangleMark(
                        xStart: .value("Rect Start Width", categoryWidth*2),
                        xEnd: .value("Rect End Width", categoryWidth*3),
                        yStart: .value("Rect Start Height", 0),
                        yEnd: .value("Rect End Height", qCategory2Proportion[.zero] ?? 0.0)
                    )
                    
                    .foregroundStyle(
                        .red.gradient
                            .opacity(
                                selectedCategory != nil ? (selectedCategory == .zero ? categoryLabelColorOpacity : categoryLabelColorOpacity*0.5) : categoryLabelColorOpacity
                            )
                    )
                    .annotation(position: .bottom) {
                        VStack {
                            Text(UncertaintyStatistics.getQCategoryLabel(qCategory: .zero))
                                .modifier(CategoryLabelViewModifier())
                            Text("q = 0")
                                .monospaced()
                        }
                        
                        .foregroundStyle(
                            .red
                                .opacity(
                                    selectedCategory != nil ? (selectedCategory == .zero ? categoryLabelColorOpacity : categoryLabelColorOpacity*0.5) : categoryLabelColorOpacity
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
                            if let selectedCategory = selectedCategory, let sampleTotal = graphViewQCategory2Total[selectedCategory], let sampleProportion = graphViewQCategory2Proportion[selectedCategory], let selectionTotal = selectionQCategory2Total[selectedCategory], let selectionProportion = selectionQCategory2Proportion[selectedCategory] {
                                VStack {
                                    HStack {
                                        Text(REConstants.CategoryDisplayLabels.qFull+":")
                                        Text(UncertaintyStatistics.getQCategoryLabel(qCategory: selectedCategory))
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
                        Text("")
                        Text(REConstants.CategoryDisplayLabels.qFull)
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
