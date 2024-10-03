//
//  UncertaintyChart+GeometryUtilities.swift
//  Alpha1
//
//  Created by A on 5/2/23.
//

import SwiftUI
//import Accelerate
import Charts

extension UncertaintyChart {
    // Currently it is assumed that the y axis is always 0...1. If this changes, the softmaxVal would also need to be normed accordingly.
    func findElementAndUpdateStructures(proxy: ChartProxy, geometry: GeometryProxy, phase: HoverPhase, isCalibration: Bool = true) {
        
        var hoverLocation: CGPoint = .zero
        
        switch phase {
        case .active(let location):
            hoverLocation = location
            viewModel.isHovering = true
        case .ended:
            viewModel.isHovering = false
            viewModel.selectedElement = nil
            infoPopoverShowing = false
        }
        let value = hoverLocation

        if let plotAreaFrame = proxy.plotFrame, let (d0Unnormed, softmaxVal) = proxy.value(at: CGPoint(x: value.x - geometry[plotAreaFrame].origin.x, y: value.y - geometry[plotAreaFrame].origin.y), as: (Float32, Float32).self) {
            var proposedElement: String?
            var minDistance = Float.infinity

            var d0Norm: Float32 = 1.0
            if let minMaxD0DataPoints = dataController.uncertaintyStatistics?.uncertaintyGraphCoordinator?.datasetId_To_inMemoryDataCoordinator[datasetId]?.getCurrentMinMaxD0DataPoints() {
                let minD0InCurrentView = minMaxD0DataPoints.minD0DataPoint.d0
                let maxD0InCurrentView = minMaxD0DataPoints.maxD0DataPoint.d0
                    d0Norm = abs(maxD0InCurrentView-minD0InCurrentView)
                    if d0Norm <= 0 {
                        d0Norm = 1.0
                    }
                
            }
            let d0 = d0Unnormed / d0Norm
            // Currently it is assumed that the y axis is always 0...1. If this changes, the softmaxVal would also need to be normed accordingly.
            for documentId in displayData {
                
                // Find and assign the nearest point, if applicable
                // This is scaled by min, max (x, y) so that the distance appears relative to the user (otherwise softmax distance will dominate on zoom).
                if let dataPoint = displayDocumentIdsToDataPoints[documentId], 0 <= d0 && 0 <= softmaxVal && softmaxVal <= 1.0 {

                    let dataPointD0Normed = dataPoint.d0 / d0Norm
                    if abs(d0 - dataPointD0Normed) + abs(softmaxVal - dataPoint.softmax[dataPoint.prediction]) < minDistance {
                        minDistance = abs(d0 - dataPointD0Normed) + abs(softmaxVal - dataPoint.softmax[dataPoint.prediction])
                        proposedElement =  dataPoint.id
                    }
                }
            }
            if let proposedElement = proposedElement {
                viewModel.selectedElement = proposedElement
                infoPopoverShowing = viewModel.isHovering
            }
            
        } else {
            viewModel.selectedElement = nil
            infoPopoverShowing = viewModel.isHovering
        }
        if !viewModel.isHovering {
            viewModel.selectedElement = nil
        }
        
    }
}
