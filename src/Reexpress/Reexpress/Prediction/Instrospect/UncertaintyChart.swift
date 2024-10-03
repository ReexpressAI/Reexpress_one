//
//  UncertaintyChart.swift
//  Alpha1
//
//  Created by A on 5/2/23.
//

import SwiftUI
import Charts

struct UncertaintyChart: View {
    var datasetId: Int
    @EnvironmentObject var dataController: DataController
    @Binding var graphState: GraphState
    var dataLoaded: Bool {
        return graphState == .displayed
    }
    
    //@Binding var userDidScroll: Bool
    @ObservedObject var searchViewModel: IntrospectionMainViewGrid.ViewModel
    @Binding var existingXRange: ClosedRange<Float32>?
    
    @StateObject var viewModel = ViewModel()
    @State var infoPopoverShowing: Bool = false  // currently this cannot be in the view model without a warning: [SwiftUI] Publishing changes from within view updates is not allowed, this will cause undefined behavior.
    @State var partitionPopoverShowing: Bool = false
    @State var newPartitioningRequested: Bool = false
    
    @State var distanceRangeForZoom: (Float32, Float32)?
    
    var isComparisonDatasplit: Bool = false
    @State var chartView_counter: Int = 0
    
    @AppStorage(REConstants.UserDefaults.compareChartHeightStringKey) var chartHeight: Double = REConstants.UserDefaults.compareChartDefaultHeight

    func toggleChartHeight() {
        if chartHeight == REConstants.UserDefaults.compareChartDefaultHeight {
            chartHeight = REConstants.UserDefaults.compareChartExpandedHeight
        } else {
            chartHeight = REConstants.UserDefaults.compareChartDefaultHeight
        }
    }
    @AppStorage(REConstants.UserDefaults.showingGraphViewSummaryStatisticsStringKey) var showingGraphViewSummaryStatistics: Bool = REConstants.UserDefaults.showingGraphViewSummaryStatisticsStringKeyDefault
    @AppStorage(REConstants.UserDefaults.statsFontSizeStringKey) var statsFontSize: Double = Double(REConstants.UserDefaults.defaultStatsFontSize)
    @State private var isShowingInfoForCalibrationReliability: Bool = false
    @State private var showingDisplayOptionsPopover: Bool = false
    var displayData: [String] {
        return dataController.uncertaintyStatistics?.uncertaintyGraphCoordinator?.datasetId_To_inMemoryDataCoordinator[datasetId]?.currentViewConstraintsStack.last?.sortedSampledDocumentIdsForDisplay ?? []
        
    }
    var displayDocumentIdsToDataPoints: [String: UncertaintyStatistics.DataPoint] {
        dataController.uncertaintyStatistics?.uncertaintyGraphCoordinator?.datasetId_To_inMemoryDataCoordinator[datasetId]?.documentIdsToDataPoints ?? [:]
    }
    
    var historyIsAvailable: Bool {
        if let historyAvailable = dataController.uncertaintyStatistics?.uncertaintyGraphCoordinator?.datasetId_To_inMemoryDataCoordinator[datasetId]?.viewHistoryIsAvailable() {
            return historyAvailable
        } else {
            return false
        }
    }
    
    
    func getDistanceBoundariesForPredictionQCategory(prediction: Int, qCategory: UncertaintyStatistics.QCategory) -> (median: Float32, max: Float32)? {
        return dataController.uncertaintyStatistics?.trueClass_To_QToD0Statistics[prediction]?[qCategory]
    }
    
    var isSample: Bool {
        if let isSample = dataController.uncertaintyStatistics?.uncertaintyGraphCoordinator?.datasetId_To_inMemoryDataCoordinator[datasetId]?.currentViewIsSample() {
            return isSample
        } else {
            return false
        }
    }
    
    var selectedQDFCategory: UncertaintyStatistics.QDFCategory? {
        if let selectedDocumentId = viewModel.selectedElement, let dataPoint = dataController.uncertaintyStatistics?.uncertaintyGraphCoordinator?.datasetId_To_inMemoryDataCoordinator[datasetId]?.documentIdsToDataPoints[selectedDocumentId] {
            return dataPoint.qdfCategory //UncertaintyStatistics.VennADMITCategory(prediction: dataPoint.prediction, qCategory: dataPoint.qCategory, distanceCategory: dataPoint.distanceCategory, compositionCategory: dataPoint.compositionCategory)
        } else {
            return nil
        }
    }

    enum CategoryMatchStates: Int, CaseIterable {
        case match = 0
        case mimsatch = 1
        case noCurrentSelection = 2
    }

    func isQDFCategoryMatch(dataPoint: UncertaintyStatistics.DataPoint) -> CategoryMatchStates {
        if let selectedQDFCategory = selectedQDFCategory {
            if selectedQDFCategory == dataPoint.qdfCategory {  // if dataPoint.qdfCategory == nil, then we treat as mismatch
                return CategoryMatchStates.match
            } else {
                return CategoryMatchStates.mimsatch
            }
        } else {
            return CategoryMatchStates.noCurrentSelection
        }
    }
    
    func resamplePoints() {
        let updatedRequiredDataPointId = dataController.uncertaintyStatistics?.uncertaintyGraphCoordinator?.datasetId_To_inMemoryDataCoordinator[datasetId]?.resampleCurrentView(requiredDataPointId: viewModel.selectedTappedElement, sampleSize: REConstants.Uncertainty.defaultDisplaySampleSize)
        
        viewModel.selectedTappedElement = updatedRequiredDataPointId
        updateSiblingGraphs()
    }
    
    func zoom(lowerD0: Float32?, upperD0: Float32?) {
        if let lowerD0 = lowerD0, let upperD0 = upperD0 {
            if let _ = dataController.uncertaintyStatistics?.uncertaintyGraphCoordinator?.datasetId_To_inMemoryDataCoordinator[datasetId]?.currentViewConstraintsStack.last {
                
                // after zoom, axes are no longer aligned (if applicable)
                //existingXRange = nil
                let updatedRequiredDataPointId = try? dataController.uncertaintyStatistics?.uncertaintyGraphCoordinator?.datasetId_To_inMemoryDataCoordinator[datasetId]?.resampleDocumentIdsFilteredByConstraint(lowerD0: lowerD0, upperD0: upperD0, requiredDataPointId: viewModel.selectedTappedElement, sampleSize: REConstants.Uncertainty.defaultDisplaySampleSize)
                
                viewModel.selectedTappedElement = updatedRequiredDataPointId
                updateSiblingGraphs()
            }
        }
    }

    func updateSiblingGraphs() {
        chartView_counter += 1
    }
    @State private var isShowingInitializedAlert: Bool = false
    
    var body: some View {
            VStack {
                HStack {
                    
                    SingleDatasplitView(datasetId: datasetId)
                        .font(REConstants.Fonts.baseFont)
                        .monospaced()
                        .foregroundStyle(isComparisonDatasplit ? REConstants.REColors.reLabelBeige : .gray)
                        .opacity(isComparisonDatasplit ? 0.75 : 1.0)
                        .padding(.leading)
                    Spacer()
                    
                    Button {
                        showingDisplayOptionsPopover.toggle()
                    } label: {
                        Image(systemName: "gear")
                            .foregroundStyle(.blue.gradient)
                            .font(REConstants.Fonts.baseFont)
                            //.padding(.trailing)
                    }
                    .buttonStyle(.borderless)
                    .popover(isPresented: $showingDisplayOptionsPopover, arrowEdge: .top) {
                        StatsTextDisplayOptionsView()
                    }
                    //.padding(.trailing)
                }
                if showingGraphViewSummaryStatistics {
                    HStack {
                        Spacer()
                        HStack(alignment: .lastTextBaseline) {
                            Spacer()
                            
                            Group {
                                
                                Button {
                                    resamplePoints()
                                } label: {
                                    UncertaintyGraphControlButtonLabelWithCaptionVStack(buttonImageName: "dice", buttonTextCaption: "Resample")
                                }
                                .buttonStyle(.borderless)
                                .opacity(isSample ? 1.0 : 0.5)
                                .disabled(!isSample)
                                .onChange(of: existingXRange) { oldValue, newValue in
                                    if newValue != nil {
                                        if let minMaxD0DataPoints =  dataController.uncertaintyStatistics?.uncertaintyGraphCoordinator?.datasetId_To_inMemoryDataCoordinator[datasetId]?.getCurrentMinMaxD0DataPoints() {
                                            var lowerD0 = minMaxD0DataPoints.minD0DataPoint.d0
                                            var upperD0 = minMaxD0DataPoints.maxD0DataPoint.d0
                                            if let existingXRange = existingXRange {
                                                if existingXRange.lowerBound < lowerD0 {
                                                    lowerD0 = existingXRange.lowerBound
                                                }
                                                if existingXRange.upperBound > upperD0 {
                                                    upperD0 = existingXRange.upperBound
                                                }
                                            }
                                            zoom(lowerD0: lowerD0, upperD0: upperD0)
                                            
                                        }
                                    }
                                }
                                Button {
                                    dataController.uncertaintyStatistics?.uncertaintyGraphCoordinator?.datasetId_To_inMemoryDataCoordinator[datasetId]?.goBackInViewHistory()
                                    viewModel.selectedTappedElement = nil
                                    viewModel.selectedElement = nil // necessary also for refreshing the view
                                    existingXRange = nil  // no longer aligned
                                    updateSiblingGraphs()
                                } label: {
                                    UncertaintyGraphControlButtonLabelWithCaptionVStack(buttonImageName: "minus.magnifyingglass", buttonTextCaption: "Zoom out") //"minus.magnifyingglass"
                                }
                                .buttonStyle(.borderless)
                                .opacity(historyIsAvailable ? 1.0 : 0.5)
                                .disabled(!historyIsAvailable)
                                
                                Button {
                                    dataController.uncertaintyStatistics?.uncertaintyGraphCoordinator?.datasetId_To_inMemoryDataCoordinator[datasetId]?.resetView()
                                    viewModel.selectedTappedElement = nil
                                    viewModel.selectedElement = nil // necessary also for refreshing the view
                                    existingXRange = nil  // no longer aligned
                                    updateSiblingGraphs()
                                } label: {
                                    UncertaintyGraphControlButtonLabelWithCaptionVStack(buttonImageName: "arrow.clockwise", buttonTextCaption: "Reset Zoom", buttonFrameWidth: 80)
                                }
                                .buttonStyle(.borderless)
                                .opacity(historyIsAvailable ? 1.0 : 0.5)
                                .disabled(!historyIsAvailable)
                            }
                            Group {
                                Button {
                                    toggleChartHeight()
                                } label: {
                                    UncertaintyGraphControlButtonLabelWithCaptionVStack(buttonImageName: "arrow.up.left.and.down.right.and.arrow.up.right.and.down.left", buttonTextCaption: "Resize")
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                        .frame(width: 650)
                        .padding([.trailing])
                    }
                    
                    
                    
                    // MARK: Document, Selection, and Sample Size quick view
                    HStack {
                        if let documentId = viewModel.selectedTappedElement {
                            UncertaintyGraphDatapointFocusView(documentId: documentId)
                        }
                        Spacer()
                        UncertaintyPartitionQuickView(sampleSizeSummary: dataController.uncertaintyStatistics?.uncertaintyGraphCoordinator?.datasetId_To_inMemoryDataCoordinator[datasetId]?.getSampleSizeSummary(), datasetSize: dataController.inMemory_Datasets[datasetId]?.count)
                            .padding(EdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 20))
                    }
                    
                    Chart {
                        ForEach(displayData, id: \.self) { documentId in
                            if dataLoaded, let dataPoint = displayDocumentIdsToDataPoints[documentId] {
                                let categoryMatchState = isQDFCategoryMatch(dataPoint: dataPoint)
                                if categoryMatchState == .noCurrentSelection {
                                    
                                    PointMark(
                                        x: .value("Distance to training", dataPoint.d0),
                                        y: .value("Softmax", dataPoint.softmax[dataPoint.prediction])
                                    )
                                    // If true labels are available, we indicate correct/incorrect predictions; else .blue if unlabeled, ood color otherwise
                                    .foregroundStyle(DataController.isKnownValidLabel(label: dataPoint.label, numberOfClasses: dataController.numberOfClasses) ? (dataPoint.label == dataPoint.prediction ? Color.green.gradient : Color.red.gradient) : (dataPoint.label == REConstants.DataValidator.unlabeledLabel ? Color.blue.gradient : REConstants.Visualization.oodDistanceLineD0Color))
                                    .opacity(0.85)
                                    
                                } else {
                                    PointMark(
                                        x: .value("Distance to training", dataPoint.d0),
                                        y: .value("Softmax", dataPoint.softmax[dataPoint.prediction])
                                    )
                                    // If true labels are available, we indicate correct/incorrect predictions; else .blue
                                    .foregroundStyle(DataController.isKnownValidLabel(label: dataPoint.label, numberOfClasses: dataController.numberOfClasses) ? (dataPoint.label == dataPoint.prediction ? Color.green.gradient : Color.red.gradient) : (dataPoint.label == REConstants.DataValidator.unlabeledLabel ? Color.blue.gradient : REConstants.Visualization.oodDistanceLineD0Color)) //Color.blue.gradient)
                                    .opacity(categoryMatchState == .match ? 1.0 : 0.2)
                                    
                                    
                                    
                                    
                                    if let dataPointID = viewModel.selectedElement, displayDocumentIdsToDataPoints[dataPointID]?.id == dataPoint.id, distanceRangeForZoom == nil {
                                        RuleMark(
                                            x: .value("Distance to training", dataPoint.d0)
                                        )
                                        .lineStyle(StrokeStyle(lineWidth: 2))
                                        .foregroundStyle(.gray.opacity(0.5))
                                        .offset(yStart: 0)
                                        .zIndex(-1)
                                        .annotation(
                                            position: .top, spacing: 0,
                                            overflowResolution: .init(
                                                x: .fit(to: .chart),
                                                y: .disabled
                                            )
                                        ) {
                                            if infoPopoverShowing {
                                                UncertaintychartStreamlinedPopoverView(dataController: dataController, dataPoint: dataPoint, statsFontSize: statsFontSize)
                                            }
                                        }
                                    }
                                    
                                    if distanceRangeForZoom == nil && viewModel.selectedElement != nil && displayDocumentIdsToDataPoints[viewModel.selectedElement ?? ""]?.id == dataPoint.id {
                                        if let softmaxThresholds = dataController.uncertaintyStatistics?.qCategory_To_Thresholds[dataPoint.qCategory] {
                                            let softmaxThresholdForPredictedClass = softmaxThresholds[dataPoint.prediction]
                                            RuleMark(
                                                y: .value("Softmax", softmaxThresholdForPredictedClass)
                                            )
                                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 10]))
                                            .foregroundStyle(
                                                REConstants.Visualization.compositionThresholdLineColor
                                            )
                                        }
                                        if let distanceBoundaries = getDistanceBoundariesForPredictionQCategory(prediction: dataPoint.prediction, qCategory: dataPoint.qCategory) {
                                            if let d0Check = dataController.uncertaintyStatistics?.uncertaintyGraphCoordinator?.datasetId_To_inMemoryDataCoordinator[datasetId]?.d0InXRange(d0: distanceBoundaries.median), d0Check {
                                                RuleMark(
                                                    x: .value("Distance to training", distanceBoundaries.median)
                                                )
                                                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 10]))
                                                .foregroundStyle(
                                                    REConstants.Visualization.medianDistanceLineD0Color
                                                )
                                            }
                                            if let d0Check = dataController.uncertaintyStatistics?.uncertaintyGraphCoordinator?.datasetId_To_inMemoryDataCoordinator[datasetId]?.d0InXRange(d0: distanceBoundaries.max), d0Check {
                                                RuleMark(
                                                    x: .value("Distance to training", distanceBoundaries.max)
                                                )
                                                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 10]))
                                                .foregroundStyle(
                                                    REConstants.Visualization.oodDistanceLineD0Color
                                                )
                                            }
                                        }
                                        
                                    }
                                    
                                }
                                
                                PointMark(
                                    x: .value("Distance to training", dataPoint.d0),
                                    y: .value("Softmax", dataPoint.softmax[dataPoint.prediction])
                                )
                                .opacity(distanceRangeForZoom == nil && viewModel.selectedElement != nil && displayDocumentIdsToDataPoints[viewModel.selectedElement ?? ""]?.id == dataPoint.id ? 1.0 : 0.0)
                                .annotation(position: .overlay, alignment: .center) {
                                    VStack {
                                        Image(systemName: "circle.fill")
                                        
                                    }
                                    .foregroundStyle(
                                        .orange.gradient
                                    )
                                    .font(.system(size: 10))
                                    .opacity(distanceRangeForZoom == nil && viewModel.selectedElement != nil && displayDocumentIdsToDataPoints[viewModel.selectedElement ?? ""]?.id == dataPoint.id ? 0.5 : 0.0)
                                }
                                
                                .symbolSize(0) // do not show the default shape symbol
                                
                                /// The following is for the tapped element (if any), which becomes pinned after tapping. Unlike the normal highlight, this highlight is retained even when zooming (provided point is still in view).
                                PointMark(
                                    x: .value("Distance to training", dataPoint.d0),
                                    y: .value("Softmax", dataPoint.softmax[dataPoint.prediction])
                                )
                                .opacity(viewModel.selectedTappedElement != nil && displayDocumentIdsToDataPoints[ viewModel.selectedTappedElement ?? ""]?.id == dataPoint.id ? 1.0 : 0.0)
                                .annotation(position: .overlay, alignment: .center) {
                                    VStack {
                                        Image(systemName: "scope")
                                    }
                                    .foregroundStyle(
                                        .orange.gradient //.blue //.gradient // .yellow
                                    )
                                    .font(.system(size: 20))
                                    .opacity(viewModel.selectedTappedElement != nil && displayDocumentIdsToDataPoints[viewModel.selectedTappedElement ?? ""]?.id == dataPoint.id ? 0.5 : 0.0)
                                }
                                
                                .symbolSize(0) // do not show the default shape symbol
                                
                                
                            }
                            // Zoom
                            if let (start, end) = distanceRangeForZoom {
                                RectangleMark(
                                    xStart: .value("Selection Start", start),
                                    xEnd: .value("Selection End", end)
                                )
                                .foregroundStyle(.gray.opacity(0.005))
                            }
                            
                            // show *population* min/max d0 for samples
                            if let minMaxD0DataPoints = dataController.uncertaintyStatistics?.uncertaintyGraphCoordinator?.datasetId_To_inMemoryDataCoordinator[datasetId]?.getCurrentMinMaxD0DataPoints(), isSample {
                                
                                RuleMark(
                                    x: .value("Distance to training", minMaxD0DataPoints.minD0DataPoint.d0)
                                )
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [2, 3]))
                                .foregroundStyle(
                                    REConstants.Visualization.minMaxDistanceInSmapleLineColor
                                )
                                RuleMark(
                                    x: .value("Distance to training", minMaxD0DataPoints.maxD0DataPoint.d0)
                                )
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [2, 3]))
                                .foregroundStyle(
                                    REConstants.Visualization.minMaxDistanceInSmapleLineColor
                                )
                            }
                            
                        }
                    }
                    .frame(height: chartHeight) //500)
                    .chartXScale(domain: dataController.uncertaintyStatistics?.uncertaintyGraphCoordinator?.datasetId_To_inMemoryDataCoordinator[datasetId]?.getXRange(existingXRange: existingXRange) ?? 0...5, range: .plotDimension(startPadding: 20, endPadding: 20))
                    .chartYScale(domain: 0...1.0, range: .plotDimension(startPadding: 20, endPadding: 20))
                    .chartXAxis {
                        AxisMarks() { _ in
                            AxisTick(length: 0)
                            AxisGridLine()
                            AxisValueLabel(centered: false, anchor: .top)
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .chartXAxisLabel(position: .bottom, alignment: .center) {
                        Text("L\u{00B2} Distance to Training (d)")
                            .font(REConstants.Visualization.xAndYAxisFont)
                            .padding(.trailing, 100)
                    }
                    .chartYAxisLabel(position: .leading, alignment: .center) {
                        Text("(")
                            .tracking(2) +
                        Text("x")
                            .tracking(2)
                            .baselineOffset(1.0) +
                        Text(")")
                            .tracking(2) +
                        Text("ɟ")
                            .font(.custom(
                                "AmericanTypewriter",
                                fixedSize: 16))
                    }
                    .chartOverlay { proxy in
                        GeometryReader { geometry in
                            Rectangle().fill(.clear).contentShape(Rectangle())
                                .onContinuousHover { phase in
                                    findElementAndUpdateStructures(proxy: proxy, geometry: geometry, phase: phase)
                                }
                                .gesture(
                                    SpatialTapGesture()
                                        .onEnded { value in
                                            // The last condition will unselect if already selected.
                                            if let dataPointID = viewModel.selectedElement, distanceRangeForZoom == nil, viewModel.selectedTappedElement != dataPointID {
                                                viewModel.selectedTappedElement = dataPointID
                                            } else {
                                                viewModel.selectedTappedElement = nil
                                            }
                                        }
                                )
                                .gesture(DragGesture()
                                    .onChanged { value in
                                        // Find the x-coordinates in the chart’s plot area.
                                        if let plotAreaFrame = proxy.plotFrame {
                                            let xStart = value.startLocation.x - geometry[plotAreaFrame].origin.x
                                            let xCurrent = value.location.x - geometry[plotAreaFrame].origin.x
                                            // Find the date values at the x-coordinates.
                                            
                                            if let d0Start: Float32 = proxy.value(atX: xStart),
                                               let d0Current: Float32 = proxy.value(atX: xCurrent) {
                                                if d0Start <= d0Current {
                                                    distanceRangeForZoom = (d0Start, d0Current)
                                                } else {
                                                    distanceRangeForZoom = (d0Current, d0Start)
                                                }
                                            }
                                        }
                                    }
                                    .onEnded { _ in
                                        
                                        if let (lowerD0, upperD0) = distanceRangeForZoom {
                                            zoom(lowerD0: lowerD0, upperD0: upperD0)
                                            existingXRange = nil  // no longer aligned
                                        }
                                        distanceRangeForZoom = nil  // Clear the state on gesture end.
                                    }
                                )
                        }
                    }
                } else {
                    FMagnitudeCategoryToFrequencyChartView(datasetId: datasetId, graphState: $graphState, updateCounter: $chartView_counter)
                    DistanceCategoryToFrequencyChartView(datasetId: datasetId, graphState: $graphState, updateCounter: $chartView_counter)
                }

                QCategoryToFrequencyChartView(datasetId: datasetId, graphState: $graphState, updateCounter: $chartView_counter)
                
                PredictionsToFrequencyChartView(datasetId: datasetId, graphState: $graphState, updateCounter: $chartView_counter)
                
                HStack {
                    Spacer()
                    Button {
                        isShowingInfoForCalibrationReliability.toggle()
                    } label: {
                        Text(REConstants.CategoryDisplayLabels.calibrationReliabilityFull + " Guide")
                            .font(REConstants.Fonts.baseFont.smallCaps())
                            .foregroundStyle(.blue)
                            .padding(.trailing)
                    }
                    .buttonStyle(.borderless)
                    .padding(.trailing)
                    
                    .popover(isPresented: $isShowingInfoForCalibrationReliability) {
                        CalibrationReliabilityView()
                            .frame(width: 800, height: 600)
                    }
                }
                CalibrationReliabilityToFrequencyChartView(datasetId: datasetId, graphState: $graphState, updateCounter: $chartView_counter)
                
                LabelsToFrequencyChartView(datasetId: datasetId, graphState: $graphState, updateCounter: $chartView_counter)
                ValidKnownLabelsToAccuracyChartView(datasetId: datasetId, graphState: $graphState, updateCounter: $chartView_counter)
                UncertaintyPartitionAccuracyView(datasetId: datasetId, graphState: $graphState, updateCounter: $chartView_counter)
                    
            }
            .onAppear {
                if !dataController.compareGraphSelectionHasBeenShown {
                    isShowingInitializedAlert = true
                }
            }
            .alert("Charts initialized.", isPresented: $isShowingInitializedAlert) {
                Button {
                    dataController.compareGraphSelectionHasBeenShown = true
                } label: {
                    Text("OK")
                }
            } message: {
                Text(REConstants.SelectionDisplayLabels.selectionInitAlertMessage)
                
            }
//            .onAppear {
//                if dataController.compareGraphSelectionHasBeenShown {
//                    isShowingInitializedAlert = false
//                }
//            }
        //isShowingInitializedAlert
//            .onContinuousHover{ phase in
//                print("is hovering")
//            }
            /*.onAppear {
                print("did appear")
                print(statsFontSize)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    statsFontSize += 1.0
                    statsFontSize -= 1.0
                }
                updateSiblingGraphs()
            }*/
            .padding()
            .modifier(IntrospectViewPrimaryComponentsViewModifier())
        }
}
