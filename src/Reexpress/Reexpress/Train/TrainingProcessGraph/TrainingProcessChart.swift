//
//  TrainingProcessChart.swift
//  Charts2
//
//  Created by A on 4/3/23.
//

import Charts
import SwiftUI
import Accelerate


struct TrainingProcessDetailsChart: View {
    @Binding var selectedElement: TrainingDataPointType?
    @State private var isHovering = false
    @Binding var infoPopoverShowing: Bool
    let data: [TrainingProcessDataStorage.MetricSeries]
    @Binding var runningBestMaxMetricEpoch: Int
    var metricStringName: String = "Loss"
    
    @Binding var showBestTrainingLine: Bool
    @Binding var showBestValidationLine: Bool
//    var bestEpochs: (training: Int?, trainingScore: Float32?, validation: Int?, validationScore: Float32?)
    
    var bestTrainScore: Float32?
    var bestValidationScore: Float32?
    
    func findElementAndUpdateStructures(proxy: ChartProxy, geometry: GeometryProxy, phase: HoverPhase) {

        var hoverLocation: CGPoint = .zero

        switch phase {
        case .active(let location):
            hoverLocation = location
            isHovering = true
        case .ended:
            isHovering = false
            selectedElement = nil
            infoPopoverShowing = false
        }
        let value = hoverLocation
        // Convert the gesture location to the coordiante space of the plot area.
        guard let plotAreaFrame = proxy.plotFrame else {
            return
        }
        let origin = geometry[plotAreaFrame].origin
        
        let location = CGPoint(
            x: value.x - origin.x,
            y: value.y - origin.y
        )
        
        // Get the x (date) and y (price) value from the location.
        if let (epoch, metric) = proxy.value(at: location, as: (Double, Float32).self) {
            // get epoch
            let validEpoch = max(0, epoch).rounded(.toNearestOrAwayFromZero)
                                        
            var proposedElement: TrainingDataPointType?
            let epochIndex = Int(max(0, validEpoch))
            
            var minDistance = Float.infinity
            for dataForSplit in data {
                // Find and assign the nearest point, if applicable
                if 0 <= epochIndex && epochIndex < dataForSplit.epochValueTuples.count && dataForSplit.epochValueTuples[epochIndex].epoch == epochIndex {
                    if abs(metric - dataForSplit.epochValueTuples[epochIndex].value) < minDistance {
                        minDistance = abs(metric - dataForSplit.epochValueTuples[epochIndex].value)
                        proposedElement = TrainingDataPointType(id: dataForSplit.id, epoch: dataForSplit.epochValueTuples[epochIndex].epoch, value: dataForSplit.epochValueTuples[epochIndex].value)
                    }
                }
            }
            if let proposedElement = proposedElement {
                selectedElement = proposedElement
                infoPopoverShowing = isHovering
            }
            
        } else {
            selectedElement = nil
            infoPopoverShowing = isHovering
        }
        if !isHovering {
            selectedElement = nil
        }
 
    }
    
    var body: some View {
        Chart(data) { series in
            ForEach(series.epochValueTuples, id: \.epoch) { element in
                LineMark(
                    x: .value("Epoch", element.epoch),
                    y: .value(metricStringName, element.value)
                )
            }
            .foregroundStyle(by: .value("Id", series.id))
            .symbol(by: .value("Id", series.id))
            .interpolationMethod(.catmullRom)
            
            // show min/max values
            if showBestTrainingLine {
                if let bestScore = bestTrainScore {
                    RuleMark(
                        y: .value(metricStringName, bestScore)
                    )
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 10]))
                    .foregroundStyle(
                        TrainingProcessDataStorage.getColorForDataSet(id: TrainingProcessDataStorage.Constants.trainingSetIdString)
                    )
                }
            }
            if showBestValidationLine {
                if let bestScore = bestValidationScore {
                    RuleMark(
                        y: .value(metricStringName, bestScore)
                    )
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 10]))
                    .foregroundStyle(
                        TrainingProcessDataStorage.getColorForDataSet(id: TrainingProcessDataStorage.Constants.validationSetIdString)
                    )
                }
            }
            if let elementToHighlight = selectedElement {
                RuleMark(
                    x: .value("Epoch", elementToHighlight.epoch)
                )
                .lineStyle(StrokeStyle(lineWidth: 2))
                .foregroundStyle(.gray.opacity(0.5))
                
                PointMark(
                    x: .value("Epoch", elementToHighlight.epoch),
                    y: .value(metricStringName, elementToHighlight.value)
                )
                
                .annotation(position: .overlay, alignment: .center) {
                    VStack {
                        TrainingProcessDataStorage.getImageMarkerForDataSet(id: elementToHighlight.id)
                    }
                    .foregroundStyle(
                        TrainingProcessDataStorage.getColorForDataSet(id: elementToHighlight.id)
                    )
                    .font(.system(size: 10))
                }
                .symbolSize(0) // do not show the default shape symbol

            }
        }

        .chartForegroundStyleScale([
            TrainingProcessDataStorage.Constants.trainingSetIdString: TrainingProcessDataStorage.getColorForDataSet(id: TrainingProcessDataStorage.Constants.trainingSetIdString),
            TrainingProcessDataStorage.Constants.validationSetIdString: TrainingProcessDataStorage.getColorForDataSet(id: TrainingProcessDataStorage.Constants.validationSetIdString)
        ])
        .chartSymbolScale([
            TrainingProcessDataStorage.Constants.trainingSetIdString: Circle().strokeBorder(lineWidth: 2),
            TrainingProcessDataStorage.Constants.validationSetIdString: Square().strokeBorder(lineWidth: 2)
        ])
        .chartXScale(range: .plotDimension(startPadding: 10, endPadding: 20))  // prevents initial epoch 0 from being cutoff and hovering to trigger a scale rewrite
        .chartXAxis {
            AxisMarks() { _ in
                AxisTick(length: 0)
                AxisGridLine()
                AxisValueLabel(centered: false, anchor: .top)
            }
        }
        .chartXAxisLabel(position: .bottom, alignment: .center) {
            Text("Epoch")
        }
//        .chartYScale(range: .plotDimension(startPadding: 0, endPadding: 10))
        .chartYScale(range: .plotDimension(startPadding: 10, endPadding: 10))
//        .chartYScale(domain: (metricStringName != "Loss") ? 0...110 : .automatic(includesZero: true))
        .chartYAxisLabel(position: .trailing, alignment: .center) {
            Text(metricStringName)
        }
        .chartLegend(position: .top)
        
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle().fill(.clear).contentShape(Rectangle())
                    .onContinuousHover { phase in
                        findElementAndUpdateStructures(proxy: proxy, geometry: geometry, phase: phase)
                    }
            }
        }
        
    }
}




struct TrainingProcessLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        return path
    }
}

/// A square symbol for charts. From Apple SwiftCharts demo app
struct Square: ChartSymbolShape, InsettableShape {
    let inset: CGFloat
    
    init(inset: CGFloat = 0) {
        self.inset = inset
    }
    
    func path(in rect: CGRect) -> Path {
        let cornerRadius: CGFloat = 1
        let minDimension = min(rect.width, rect.height)
        return Path(
            roundedRect: .init(x: rect.midX - minDimension / 2, y: rect.midY - minDimension / 2, width: minDimension, height: minDimension),
            cornerRadius: cornerRadius
        )
    }
    
    func inset(by amount: CGFloat) -> Square {
        Square(inset: inset + amount)
    }
    
    var perceptualUnitRect: CGRect {
        // The width of the unit rectangle (square). Adjust this to
        // size the diamond symbol so it perceptually matches with
        // the circle.
        let scaleAdjustment: CGFloat = 0.75
        return CGRect(x: 0.5 - scaleAdjustment / 2, y: 0.5 - scaleAdjustment / 2, width: scaleAdjustment, height: scaleAdjustment)
    }
}

//struct TrainingProcessDetails_Previews: PreviewProvider {
//    static var previews: some View {
//        TrainingProcessDetails()
//    }
//}

