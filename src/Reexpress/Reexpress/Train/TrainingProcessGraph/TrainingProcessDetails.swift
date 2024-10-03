//
//  TrainingProcessDetails.swift
//  Alpha1
//
//  Created by A on 7/22/23.
//

import SwiftUI
import Accelerate

struct TrainingProcessDetails: View {
    var modelControlIdString: String = REConstants.ModelControl.keyModelId
    var isKeyModel: Bool {
        return modelControlIdString == REConstants.ModelControl.keyModelId
    }
    var highlightColor: Color {
        if isKeyModel {
            return REConstants.REColors.trainingHighlightColor
        } else {
            return REConstants.REColors.indexTrainingHighlightColor
        }
    }
    var trainingTypeTitleString: String {
        if isKeyModel {
            return "training"
        } else {
            return "model compression training"
        }
    }
//    @EnvironmentObject var dataController: DataController
    
    @State private var selectedElement: TrainingDataPointType? = nil
    
//    @State private var isHovering = false
//    @State private var timeRange: TimeRange = .last30Days
    
    @Environment(\.layoutDirection) var layoutDirection
    @State var infoPopoverShowing = false
    @State var runningBestMaxMetricEpoch: Int = 0
    
    @State var showBestTrainingLine = false
    @State var showBestValidationLine = false
    @State var showingDisplayOptionsPopover: Bool = false
    
    var metricStringName: String = "Loss"
    var data: [TrainingProcessDataStorage.MetricSeries]
    
    
    var bestEpochs: (training: Int?, trainingScore: Float32?, validation: Int?, validationScore: Float32?) {
        var trainingBestEpoch: Int?
        var validationBestEpoch: Int?
        var trainingBestScore: Float32?
        var validationBestScore: Float32?
        for dataForSplit in data {
            var index: Int?
            if dataForSplit.epochValueTuples.count > 0 {
                if metricStringName == "Loss" {
                    index = Int(vDSP.indexOfMinimum( dataForSplit.epochValueTuples.map { $0.value } ).0)
                } else {
                    index = Int(vDSP.indexOfMaximum( dataForSplit.epochValueTuples.map { $0.value } ).0)
                }
                if dataForSplit.id == TrainingProcessDataStorage.Constants.trainingSetIdString {
                    if let index = index {
                        trainingBestEpoch = dataForSplit.epochValueTuples[index].epoch // almost always, epoch == index, but in rare case, we might reduce size of archived data to save space
                        trainingBestScore = dataForSplit.epochValueTuples[index].value
                    }
                } else if dataForSplit.id == TrainingProcessDataStorage.Constants.validationSetIdString {
                    if let index = index {
                        validationBestEpoch = dataForSplit.epochValueTuples[index].epoch
                        validationBestScore = dataForSplit.epochValueTuples[index].value
                    }
                }
            }
        }
        return (training: trainingBestEpoch, trainingScore: trainingBestScore, validation: validationBestEpoch, validationScore: validationBestScore)
    }
    
    // Can query this value to determine whether or not there is data to graph.
    var dataIsAvailableToGraph: Bool {
        if data.count == 2 {
            return data[0].epochValueTuples.count > 0 && data[1].epochValueTuples.count > 0
        }
        return false
    }
    
    var body: some View {
        List {
            if !dataIsAvailableToGraph {
                VStack {
                }
            } else {
                VStack(alignment: .leading) {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading) {
                            if metricStringName == "Loss" {
                                Text("Cross-entropy loss during \(trainingTypeTitleString)")
                                    .font(.title2.bold())
                                
                                Text("Lower values are preferable")
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("\(metricStringName) during \(trainingTypeTitleString)")
                                    .font(.title2.bold())
                                
                                Text("Higher values are preferable")
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Button {
                            showingDisplayOptionsPopover.toggle()
                        } label: {
                            Image(systemName: "gear")
                                .foregroundStyle(.blue.gradient)
                                .font(REConstants.Fonts.baseFont)
                        }
                        .buttonStyle(.borderless)
                        .popover(isPresented: $showingDisplayOptionsPopover, arrowEdge: .top) {
                            TrainingProcessChartDisplayOptions(metricStringName: metricStringName, showBestTrainingLine: $showBestTrainingLine, showBestValidationLine: $showBestValidationLine)
                                //.padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 20))
                            
                        }
                    }
                    
                    let best = bestEpochs
                    TrainingProcessDetailsChart(selectedElement: $selectedElement, infoPopoverShowing: $infoPopoverShowing, data: data, runningBestMaxMetricEpoch: $runningBestMaxMetricEpoch, metricStringName: metricStringName, showBestTrainingLine: $showBestTrainingLine, showBestValidationLine: $showBestValidationLine, bestTrainScore: best.trainingScore, bestValidationScore: best.validationScore)
                        .frame(height: 150)
                    //                    .frame(minHeight: 300, maxHeight: .infinity)
                    
                    let bestTrain = (best.training != nil) ? "\(best.training ?? -1)" : "N/A"
                    let bestValidation = (best.validation != nil) ? "\(best.validation ?? -1)" : "N/A"
                    let bestTrainScore = (best.trainingScore != nil) ? "\(best.trainingScore ?? -1)" : "N/A"
                    let bestValidationScore = (best.validationScore != nil) ? "\(best.validationScore ?? -1)" : "N/A"
                    
                    if metricStringName == "Loss" {
                        Text("Lowest Training set loss of \(bestTrainScore) at epoch \(bestTrain).")
                            .font(REConstants.Fonts.baseFont)
                            .foregroundStyle(.gray)
                        Text("Lowest Calibration set loss of \(bestValidationScore) at epoch \(bestValidation).")
                            .font(REConstants.Fonts.baseFont)
                    } else {
                        Text("Highest Training set \(metricStringName) of \(bestTrainScore) at epoch \(bestTrain).")
                            .font(REConstants.Fonts.baseFont)
                            .foregroundStyle(.gray)
                        HStack(alignment: .firstTextBaseline, spacing: 0) {
                            Text("Highest Calibration set \(metricStringName) of ")
                            Text("\(bestValidationScore)")
                                .foregroundStyle(highlightColor)
                                .opacity(0.75)
                            Text(" at ")
                            Text("epoch \(bestValidation)")
                                .foregroundStyle(highlightColor)
                                .opacity(0.75)
                            Text(".")
                        }
                        .font(REConstants.Fonts.baseFont)
                    }
                    
                }
                .chartBackground { proxy in
                    ZStack(alignment: .topLeading) {
                        GeometryReader { nthGeoItem in
                            if let selectedElement = selectedElement, let plotAreaFrame = proxy.plotFrame {
                                
                                let startPositionX1 = proxy.position(forX: selectedElement.epoch) ?? 0
                                let startPositionX2 = proxy.position(forX: selectedElement.epoch) ?? 0
                                let midStartPositionX = (startPositionX1 + startPositionX2) / 2 + nthGeoItem[plotAreaFrame].origin.x
                                let lineX = layoutDirection == .rightToLeft ? nthGeoItem.size.width - midStartPositionX : midStartPositionX
                                
                                VStack() {  // This VStack is simply a placeholder for the popover
                                }
                                .popover(isPresented: $infoPopoverShowing, arrowEdge: .top) {
                                    TrainingDataPointPopoverView(selectedElement: selectedElement, metricStringName: metricStringName)
                                }
                                .position(x: lineX, y: nthGeoItem[plotAreaFrame].origin.y)
                            }
                        }
                    }
                }
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        //.scrollBounceBehavior(.basedOnSize)
    }
}
