//
//  CalibrationReliabilityToFrequencyChartView.swift
//  Alpha1
//
//  Created by A on 9/20/23.
//

import SwiftUI
import Charts

struct CalibrationReliabilityBarMark: ChartContent {
    var position: Float32
    var qdfCategoryReliability: UncertaintyStatistics.QDFCategoryReliability
    var categoryWidth: Float32
    var selectedCategory: UncertaintyStatistics.QDFCategoryReliability?
    var categoryProportion: Float32
    
    var reliabilityLabel: (reliabilityImageName: String, reliabilityTextCaption: String, reliabilityColorGradient: AnyShapeStyle, opacity: Double) {
        return UncertaintyStatistics.formatReliabilityLabelFromQDFCategoryReliability(qdfCategoryReliability: qdfCategoryReliability)
    }
    
    var body: some ChartContent {
        
        RectangleMark(
            xStart: .value("Rect Start Width", categoryWidth*position),
            xEnd: .value("Rect End Width", categoryWidth*(position+1)),
            yStart: .value("Rect Start Height", 0.0),
            yEnd: .value("Rect End Height", categoryProportion)
        )
        .foregroundStyle(
            reliabilityLabel.reliabilityColorGradient
                .opacity(
                    selectedCategory != nil ? (selectedCategory == qdfCategoryReliability ? reliabilityLabel.opacity : reliabilityLabel.opacity*0.5) : reliabilityLabel.opacity
                )
        )
        .annotation(position: .bottom) {
            VStack {
                Image(systemName: reliabilityLabel.reliabilityImageName)
                Text(reliabilityLabel.reliabilityTextCaption)
                    .modifier(CategoryLabelViewModifier())
            }
            .foregroundStyle(
                reliabilityLabel.reliabilityColorGradient
                    .opacity(
                        selectedCategory != nil ? (selectedCategory == qdfCategoryReliability ? reliabilityLabel.opacity : reliabilityLabel.opacity*0.5) : reliabilityLabel.opacity
                    )
            )
        }
    }
}
struct CalibrationReliabilityToFrequencyChartView: View {
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

    
    var selectionCategory2Total: [UncertaintyStatistics.QDFCategoryReliability: Int] {
        return dataController.uncertaintyStatistics?.uncertaintyGraphCoordinator?.datasetId_To_inMemoryDataCoordinator[datasetId]?.summaryStats.calibrationReliability2Total ?? [:]
    }
    var selectionCategory2Proportion: [UncertaintyStatistics.QDFCategoryReliability: Float32] {
        return dataController.uncertaintyStatistics?.uncertaintyGraphCoordinator?.datasetId_To_inMemoryDataCoordinator[datasetId]?.summaryStats.calibrationReliability2Proportion ?? [:]
    }
    var graphViewCategory2Total: [UncertaintyStatistics.QDFCategoryReliability: Int] {
        return dataController.uncertaintyStatistics?.uncertaintyGraphCoordinator?.datasetId_To_inMemoryDataCoordinator[datasetId]?.currentViewConstraintsStack.last?.summaryStats.calibrationReliability2Total ?? [:]
    }
    var graphViewCategory2Proportion: [UncertaintyStatistics.QDFCategoryReliability: Float32] {
        return dataController.uncertaintyStatistics?.uncertaintyGraphCoordinator?.datasetId_To_inMemoryDataCoordinator[datasetId]?.currentViewConstraintsStack.last?.summaryStats.calibrationReliability2Proportion ?? [:]
    }
    

    var category2Proportion: [UncertaintyStatistics.QDFCategoryReliability: Float32] {
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
    
    let categoryWidth: Float32 = 100.0/5.0
    
    var selectedCategory: UncertaintyStatistics.QDFCategoryReliability? {
        if let selectedWidth = rawSelectedWidth {
            if selectedWidth >= 0.0 && selectedWidth < categoryWidth {
                return .highestReliability
            } else if selectedWidth >= categoryWidth && selectedWidth < categoryWidth*2 {
                return .reliable
            } else if selectedWidth >= categoryWidth*2 && selectedWidth < categoryWidth*3 {
                return .lessReliable
            } else if selectedWidth >= categoryWidth*3 && selectedWidth < categoryWidth*4 {
                return .unreliable
            } else if selectedWidth >= categoryWidth*4 && selectedWidth < categoryWidth*5 {
                return .unavailable
            }
        }
        return nil
    }
 
    var body: some View {
        if dataLoaded, updateCounter >= 0 {
            VStack {
                
                Chart {
                    CalibrationReliabilityBarMark(position: 0, qdfCategoryReliability: .highestReliability, categoryWidth: categoryWidth, selectedCategory: selectedCategory, categoryProportion: category2Proportion[.highestReliability] ?? 0.0)

                    CalibrationReliabilityBarMark(position: 1, qdfCategoryReliability: .reliable, categoryWidth: categoryWidth, selectedCategory: selectedCategory, categoryProportion: category2Proportion[.reliable] ?? 0.0)
                    
                    CalibrationReliabilityBarMark(position: 2, qdfCategoryReliability: .lessReliable, categoryWidth: categoryWidth, selectedCategory: selectedCategory, categoryProportion: category2Proportion[.lessReliable] ?? 0.0)
                    
                    CalibrationReliabilityBarMark(position: 3, qdfCategoryReliability: .unreliable, categoryWidth: categoryWidth, selectedCategory: selectedCategory, categoryProportion: category2Proportion[.unreliable] ?? 0.0)
                    
                    CalibrationReliabilityBarMark(position: 4, qdfCategoryReliability: .unavailable, categoryWidth: categoryWidth, selectedCategory: selectedCategory, categoryProportion: category2Proportion[.unavailable] ?? 0.0)
       
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
                                        Text(REConstants.CategoryDisplayLabels.calibrationReliabilityFull+":")
                                        Text(UncertaintyStatistics.formatReliabilityLabelFromQDFCategoryReliability(qdfCategoryReliability: selectedCategory).reliabilityTextCaption)
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
                        Text(REConstants.CategoryDisplayLabels.calibrationReliabilityFull)
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

