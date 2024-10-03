//
//  UncertaintyStatistics+GraphCoordinator.swift
//  Alpha1
//
//  Created by A on 4/24/23.
//

import Foundation

import Foundation
import CoreData
import CoreML
import Accelerate

extension UncertaintyStatistics {
    /*
     DatasetUncertaintyCoordinator holds the current dataset in memory. The high-level structure is as follows: The dictionary documentIdsToDataPoints holds all of the DataPoint instances. A separate dictionary vennADMITCategory_To_DocumentIds maps from the Venn-ADMIT category to the dataPoint id. Note that the hyperparameters alpha and qMax are tied to the UncertaintyStatistics instances, since changing them entails re-calculating the partitions over the calibration set.
     Separate data structures are used to display the DataPoints. These sample the points, since only a relatively small number of points can be rendered at a time in reasonable time. This is fine, since a huge block of overlapping points isn't useful anyway. The only thing to be careful about is to make sure outliers do not become inaccessible/not readily apparent. We get around this by keeping the min and max d0 of the *population* for any sample, which we always plot. In this way, the end-user knows to zoom to the edges of the chart, as needed.
     
     */
    struct SummaryStatsStructures {
        var numberOfClasses: Int
        
        var qCategory2Total: [QCategory: Int] = [:]
        var qCategory2Proportion: [QCategory: Float32] = [:]
        
        var distanceCategory2Total: [DistanceCategory: Int] = [:]
        var distanceCategory2Proportion: [DistanceCategory: Float32] = [:]
        
        var compositionCategory2Total: [CompositionCategory: Int] = [:]
        var compositionCategory2Proportion: [CompositionCategory: Float32] = [:]
        
        var calibrationReliability2Total: [QDFCategoryReliability: Int] = [:]
        var calibrationReliability2Proportion: [QDFCategoryReliability: Float32] = [:]
        
        // ground-truth labels:
        var labelTotalsByClass: [Int: Float32] = [:]
        var labelFreqByClass: [Int: Float32] = [:]
        
        var accuracy: Float32 = 0.0
        var balancedAccuracy: Float32 = 0.0
        var balancedAccuracy_NonzeroClasses: Int = 0
        var totalCorrect: Float32 = 0.0
        var totalPredicted: Float32 = 0.0
        
        var totalCorrectByLabel: [Float32]
        var totalPredictedByLabel: [Float32]  // count of prediction AND label are KnownValid
        var accuracyByLabel: [Float32]
        
        var predictionTotalsByClass: [Float32]
        var predictionFreqByClass: [Float32]
        
        init(numberOfClasses: Int) {
            self.numberOfClasses = numberOfClasses
            let allValidLabels = DataController.allValidLabelsAsArray(numberOfClasses: numberOfClasses)
            for label in allValidLabels {
                self.labelTotalsByClass[label] = 0.0
                self.labelFreqByClass[label] = 0.0
            }
//            self.labelTotalsByClass = [Float32](repeating: 0.0, count: allValidLabels.count)
//            self.labelFreqByClass = [Float32](repeating: 0.0, count: allValidLabels.count)
            self.totalCorrectByLabel = [Float32](repeating: 0.0, count: numberOfClasses)
            self.totalPredictedByLabel = [Float32](repeating: 0.0, count: numberOfClasses)
            self.accuracyByLabel = [Float32](repeating: 0.0, count: numberOfClasses)
            self.predictionTotalsByClass = [Float32](repeating: 0.0, count: numberOfClasses)
            self.predictionFreqByClass = [Float32](repeating: 0.0, count: numberOfClasses)
        }
        
        mutating func getPerQCategoryStats(dataPointIds: [String], documentIdsToDataPoints: [String: DataPoint]) {
 
            for qCategory in QCategory.allCases {
                qCategory2Total[qCategory] = 0
                qCategory2Proportion[qCategory] = 0.0
            }
            var total: Float32 = 0.0
            for dataPointId in dataPointIds {
                if let dataPoint = documentIdsToDataPoints[dataPointId] {
                    qCategory2Total[dataPoint.qCategory]? += 1
                    total += 1.0
                }
            }
            if total > 0 {
                for qCategory in QCategory.allCases {
                    if let qCategoryN = qCategory2Total[qCategory] {
                        qCategory2Proportion[qCategory] = Float32(qCategoryN) / total
                    }
                }
            }
        }
        
        mutating func getPerDistanceCategoryStats(dataPointIds: [String], documentIdsToDataPoints: [String: DataPoint]) {
            for distanceCategory in DistanceCategory.allCases {
                distanceCategory2Total[distanceCategory] = 0
                distanceCategory2Proportion[distanceCategory] = 0.0
            }
            var total: Float32 = 0.0
            for dataPointId in dataPointIds {
                if let dataPoint = documentIdsToDataPoints[dataPointId] {
                    distanceCategory2Total[dataPoint.distanceCategory]? += 1
                    total += 1.0
                }
            }
            if total > 0 {
                for category in DistanceCategory.allCases {
                    if let categoryN = distanceCategory2Total[category] {
                        distanceCategory2Proportion[category] = Float32(categoryN) / total
                    }
                }
            }
        }
        mutating func getPerCompositionCategoryStats(dataPointIds: [String], documentIdsToDataPoints: [String: DataPoint]) {
            for category in CompositionCategory.allCases {
                compositionCategory2Total[category] = 0
                compositionCategory2Proportion[category] = 0.0
            }
            var total: Float32 = 0.0
            for dataPointId in dataPointIds {
                if let dataPoint = documentIdsToDataPoints[dataPointId], let compositionCategory = dataPoint.qdfCategory?.compositionCategory {
                    compositionCategory2Total[compositionCategory]? += 1
                    total += 1.0
                }
            }
            if total > 0 {
                for category in CompositionCategory.allCases {
                    if let categoryN = compositionCategory2Total[category] {
                        compositionCategory2Proportion[category] = Float32(categoryN) / total
                    }
                }
            }
        }

        mutating func getPerCalibrationReliabilityCategoryStats(dataPointIds: [String], documentIdsToDataPoints: [String: DataPoint], qdfCategory_To_CalibratedOutput: [QDFCategory: CalibratedOutputType?]) {
            for category in QDFCategoryReliability.allCases {
                calibrationReliability2Total[category] = 0
                calibrationReliability2Proportion[category] = 0.0
            }
            var total: Float32 = 0.0
            for dataPointId in dataPointIds {
                if let dataPoint = documentIdsToDataPoints[dataPointId], let qdfCategory = dataPoint.qdfCategory, let calibratedOutput = qdfCategory_To_CalibratedOutput[qdfCategory], let sizeOfCategory = calibratedOutput?.sizeOfCategory {
                    var sizeOfCategoryInt: Int = 0
                    if sizeOfCategory >= 0 {
                        sizeOfCategoryInt = Int(sizeOfCategory)
                    }
                    let qdfCategoryMinReliability = UncertaintyStatistics.getRelativeCalibrationReliabilityForVennADMITCategory(vennADMITCategory: qdfCategory, sizeOfCategory: sizeOfCategoryInt)
                    calibrationReliability2Total[qdfCategoryMinReliability]? += 1
                    total += 1.0
                }
            }
            if total > 0 {
                for category in QDFCategoryReliability.allCases {
                    if let categoryN = calibrationReliability2Total[category] {
                        calibrationReliability2Proportion[category] = Float32(categoryN) / total
                    }
                }
            }
        }
        
        mutating func updateAccuracyStructures(dataPointIds: [String], documentIdsToDataPoints: [String: DataPoint]) {
            
            for dataPointId in dataPointIds {
                if let dataPoint = documentIdsToDataPoints[dataPointId] {
                    if DataController.isKnownValidLabel(label: dataPoint.prediction, numberOfClasses: numberOfClasses) {
                        predictionTotalsByClass[dataPoint.prediction] += 1.0
                        if DataController.isKnownValidLabel(label: dataPoint.label, numberOfClasses: numberOfClasses) {
                            if dataPoint.label == dataPoint.prediction {
                                totalCorrectByLabel[dataPoint.label] += 1.0 // This is the numerator for accuracy.
                            }
                            totalPredictedByLabel[dataPoint.label] += 1.0  // predicted among labeled documents. This is the denominator for accuracy.
                        }
                    }
                    if DataController.isValidLabel(label: dataPoint.label, numberOfClasses: numberOfClasses) {
                        labelTotalsByClass[dataPoint.label]? += 1.0  // this is separate from the above, since prediction may not necessarily have been run on all points currently in the datasplit. And this also includes ood and unlabeled.
                    }
                }
            }
            var accuracyByNonZeroLabel: [Float32] = [] // for balanced accuracy, we exclude any classes for which there are no groundtruth labels present. Note that this edge case does not occur when training, since we require 2 labels per class.
            for label in 0..<numberOfClasses {
                if totalPredictedByLabel[label] > 0 {
                    accuracyByLabel[label] = totalCorrectByLabel[label] / totalPredictedByLabel[label]
                    accuracyByNonZeroLabel.append(accuracyByLabel[label])
                }
            }
            if accuracyByNonZeroLabel.count > 0 {  // if accuracyByNonZeroLabel == [], vDSP.mean(accuracyByNonZeroLabel) returns nan
                balancedAccuracy = vDSP.mean(accuracyByNonZeroLabel)
            }
            balancedAccuracy_NonzeroClasses = accuracyByNonZeroLabel.count
            totalCorrect = vDSP.sum(totalCorrectByLabel)
            totalPredicted = vDSP.sum(totalPredictedByLabel)
            if totalPredicted > 0 {
                accuracy = totalCorrect / totalPredicted
            }
            
            // Prediction and label proportions:
            let predictionTotal = vDSP.sum(predictionTotalsByClass)
            if predictionTotal > 0 {
                predictionFreqByClass = vDSP.divide(predictionTotalsByClass, predictionTotal)
            }
            
            let groundTruthLabelTotal = vDSP.sum(Array(labelTotalsByClass.values))
            if groundTruthLabelTotal > 0 {
                for (label, classTotal) in labelTotalsByClass {
                    labelFreqByClass[label] = Float32(classTotal) / groundTruthLabelTotal
                }
            }
        }
        
        mutating func updateStructures(dataPointIds: [String], documentIdsToDataPoints: [String: DataPoint], qdfCategory_To_CalibratedOutput: [QDFCategory: CalibratedOutputType?]) {
            // Currently, this is a bit inefficient, since we're passing over points multiple times. However, in practice, it's fast enough at these scales, so keeping as-is for the moment.
            getPerQCategoryStats(dataPointIds: dataPointIds, documentIdsToDataPoints: documentIdsToDataPoints)
            getPerDistanceCategoryStats(dataPointIds: dataPointIds, documentIdsToDataPoints: documentIdsToDataPoints)
            getPerCompositionCategoryStats(dataPointIds: dataPointIds, documentIdsToDataPoints: documentIdsToDataPoints)
            getPerCalibrationReliabilityCategoryStats(dataPointIds: dataPointIds, documentIdsToDataPoints: documentIdsToDataPoints, qdfCategory_To_CalibratedOutput: qdfCategory_To_CalibratedOutput)
            updateAccuracyStructures(dataPointIds: dataPointIds, documentIdsToDataPoints: documentIdsToDataPoints)
        }
        
    }
    struct DatasetUncertaintyCoordinator {
        
        var datasetId: Int
        var numberOfClasses: Int
        var documentIdsToDataPoints: [String: DataPoint] = [:]
        //var vennADMITCategory_To_DocumentIds: [VennADMITCategory: Set<String>] = [:]
        var documentIdsSortedByD0: [String] = []
    
        var qdfCategory_To_CalibratedOutput: [QDFCategory: CalibratedOutputType?] = [:]  // needs a copy in order to generate summary stats on reliability. We use this copy rather than passing in via an argument to the lower-level functions.
//        var selectionQCategory2Total: [QCategory: Int] = [:]
//        var selectionQCategory2Proportion: [QCategory: Float32] = [:]
        
        var summaryStats: SummaryStatsStructures  // This is for the full selection. Each view of the data may have a more restricted subset.
        
        struct CurrentViewConstraints { // local to the current view constraints
            var population: Int  // unsampled size of this particular partition/stratification/zoom
            var sortedSampledDocumentIdsForDisplay: [String] = []
            
//            var qCategory2Total: [QCategory: Int] = [:]
//            var qCategory2Proportion: [QCategory: Float32] = [:]
            // distance constraints:
            var currentRangePoint: (minD0DataPointId: String, maxD0DataPointId: String)?
            
            var summaryStats: SummaryStatsStructures
            
        }
        // we retain a history for zooming out, up to REConstants.Uncertainty.maxZoomHistory
        var currentViewConstraintsStack = [CurrentViewConstraints]()
        
        // The larger of the population min/max AND *calibration* min/max. This is used to set the initial x-axis bounds when showing the graph for the first time, choosing a new partition, and/or resetting.
        var defaultBoundedRangeD0: (minD0: Float32, maxD0: Float32)?
        
        // The initial view is always retained for fast re-setting. Note that the initial view can be popped from currentViewConstraintsStack if the history exceeds REConstants.Uncertainty.maxZoomHistory, so this ensures it is always available.
        var initialViewConstraint: CurrentViewConstraints?
        
        init(datasetId: Int, documentIdsToDataPoints: [String: DataPoint], requiredDataPointId: String?, sampleSize: Int = REConstants.Uncertainty.defaultDisplaySampleSize, validKnownLabelsMinD0: Float32, validKnownLabelsMaxD0: Float32, numberOfClasses: Int, qdfCategory_To_CalibratedOutput: [QDFCategory: CalibratedOutputType?]) {
            self.datasetId = datasetId
            self.numberOfClasses = numberOfClasses
            
            self.summaryStats = SummaryStatsStructures(numberOfClasses: numberOfClasses)
            
            self.documentIdsToDataPoints = documentIdsToDataPoints
            self.qdfCategory_To_CalibratedOutput = qdfCategory_To_CalibratedOutput
            //self.vennADMITCategory_To_DocumentIds = getDataPointsByVennADMITCategory(dataPointsDictionary: documentIdsToDataPoints)
            //let selectionPerQCategoryStats = getPerQCategoryStats(dataPointIds: Array(documentIdsToDataPoints.keys))
            //self.selectionQCategory2Total = selectionPerQCategoryStats.qCategory2Total
            //self.selectionQCategory2Proportion = selectionPerQCategoryStats.qCategory2Proportion
            
            self.summaryStats.updateStructures(dataPointIds: Array(documentIdsToDataPoints.keys), documentIdsToDataPoints: documentIdsToDataPoints, qdfCategory_To_CalibratedOutput: qdfCategory_To_CalibratedOutput)
            
            let sortedSampledDocumentIdsForDisplay = getDataPointIdsForDisplay(requiredDataPointId: requiredDataPointId, dataPointsDictionary: self.documentIdsToDataPoints, sampleSize: sampleSize)
            //let perQCategoryStats = getPerQCategoryStats(dataPointIds: sortedSampledDocumentIdsForDisplay)
            
            // one time initial sort of all points by d0 for zooming
            self.documentIdsSortedByD0 = sortDataPointsByD0(dataPointsDictionary: self.documentIdsToDataPoints)
            let overallRangePoint = getRangePointFromSortedDocumentIds(documentIdsSortedByD0: self.documentIdsSortedByD0) //overallRangePoint
            if let currentRangePoint = overallRangePoint, let minD0 = documentIdsToDataPoints[currentRangePoint.minD0DataPointId]?.d0, let maxD0 = documentIdsToDataPoints[currentRangePoint.maxD0DataPointId]?.d0 {
                let boundedMinD0 = min(validKnownLabelsMinD0, minD0)
                let boundedMaxD0 = max(validKnownLabelsMaxD0, maxD0)
                defaultBoundedRangeD0 = (minD0: boundedMinD0, maxD0: boundedMaxD0)
            }
            
            
            // initial view constraint:
            var viewSummaryStats = SummaryStatsStructures(numberOfClasses: numberOfClasses)
            viewSummaryStats.updateStructures(dataPointIds: sortedSampledDocumentIdsForDisplay, documentIdsToDataPoints: documentIdsToDataPoints, qdfCategory_To_CalibratedOutput: qdfCategory_To_CalibratedOutput)
            let firstView = CurrentViewConstraints(population: self.documentIdsToDataPoints.count, sortedSampledDocumentIdsForDisplay: sortedSampledDocumentIdsForDisplay, currentRangePoint: overallRangePoint, summaryStats: viewSummaryStats)
            self.initialViewConstraint = firstView
            self.currentViewConstraintsStack.append(firstView)
        }
        
        
        mutating func resetView() {
            self.currentViewConstraintsStack.removeAll()
            if let initialViewConstraint = self.initialViewConstraint {
                self.currentViewConstraintsStack.append(initialViewConstraint)
            }
        }
        /*
         Note that a user can zoom in the graph, but that does not change the underlying "selection". We calculate separate stats for the view sample (separate from those of the full selection), but we do not calculate separate stats for the zoom population. (If a user needs the later, they need to re-run a selection with the corresponding distance constraint.)
         */
        func getSampleSizeSummary() -> (selectionSize: Int, currentViewPopulation: Int, sampleSize: Int)? {
            guard let currentViewCount = currentViewConstraintsStack.last?.sortedSampledDocumentIdsForDisplay.count, let currentViewPopulation = currentViewConstraintsStack.last?.population else {
                return nil
            }
            let selectionSize = documentIdsToDataPoints.count
            return (selectionSize: selectionSize, currentViewPopulation: currentViewPopulation, sampleSize: currentViewCount)
        }
        
        func currentViewIsSample() -> Bool {
            guard let currentViewCount = currentViewConstraintsStack.last?.sortedSampledDocumentIdsForDisplay.count, let currentViewPopulation = currentViewConstraintsStack.last?.population else {
                return false
            }
            return currentViewCount != currentViewPopulation
        }
        
        func viewHistoryIsAvailable() -> Bool {
            return currentViewConstraintsStack.count > 1
        }
        mutating func goBackInViewHistory() {
            if viewHistoryIsAvailable() {
                currentViewConstraintsStack.removeLast()
            }
        }
        
        
        func d0InXRange(d0: Float32) -> Bool {
            guard let currentXRange = getXRange() else {
                return false
            }
            switch d0 {
            case currentXRange:
                return true
            default:
                return false
            }
        }
        
        func getSingleXRange() -> ClosedRange<Float32>? {
            if let defaultBoundedRangeD0 = defaultBoundedRangeD0, currentViewConstraintsStack.count == 1 {
                let minD0 = defaultBoundedRangeD0.minD0
                let maxD0 = defaultBoundedRangeD0.maxD0
                let absDiffOffset = abs(maxD0 - minD0) * REConstants.Visualization.graphPaddingRelativeDistance
                return (minD0-absDiffOffset)...(maxD0+absDiffOffset)
            } else if let currentRangePoint = currentViewConstraintsStack.last?.currentRangePoint, let minD0 = documentIdsToDataPoints[currentRangePoint.minD0DataPointId]?.d0, let maxD0 = documentIdsToDataPoints[currentRangePoint.maxD0DataPointId]?.d0 {
                let absDiffOffset = abs(maxD0 - minD0) * REConstants.Visualization.graphPaddingRelativeDistance
                return (minD0-absDiffOffset)...(maxD0+absDiffOffset)
            }
            return nil
        }
        /// existingXRange can be provided to take the min/max (as when syncing multiple graphs---e.g., test and calibration)
        func getXRange(existingXRange: ClosedRange<Float32>? = nil) -> ClosedRange<Float32>? {
            if let existingXRange = existingXRange {
                if let newXRange = getSingleXRange() {
                    return min(newXRange.lowerBound, existingXRange.lowerBound)...max(newXRange.upperBound, existingXRange.upperBound)
                }
            } else {
                return getSingleXRange()
            }
            return nil
            
        }
        func getCurrentMinMaxD0DataPoints() -> (minD0DataPoint: DataPoint, maxD0DataPoint: DataPoint)? {
            if let currentRangePoint = currentViewConstraintsStack.last?.currentRangePoint, let minD0DataPoint = documentIdsToDataPoints[currentRangePoint.minD0DataPointId], let maxD0DataPoint = documentIdsToDataPoints[currentRangePoint.maxD0DataPointId] {
                return (minD0DataPoint: minD0DataPoint, maxD0DataPoint: maxD0DataPoint)
            }
            return nil // this should not occur in normal usage
        }
        
        
        func getRangePointFromSortedDocumentIds(documentIdsSortedByD0: [String]) -> (minD0DataPointId: String, maxD0DataPointId: String)? {
            var rangePoint: (minD0DataPointId: String, maxD0DataPointId: String)?
            if let minD0DataPointId = documentIdsSortedByD0.first, let maxD0DataPointId = documentIdsSortedByD0.last {
                rangePoint = (minD0DataPointId: minD0DataPointId, maxD0DataPointId: maxD0DataPointId)
            }
            return rangePoint
        }
        
        mutating func resampleCurrentView(requiredDataPointId: String?, sampleSize: Int = REConstants.Uncertainty.defaultDisplaySampleSize) -> String? {
            if currentViewIsSample() {
                guard let _ = currentViewConstraintsStack.last else {
                    return nil
                }
                
                let minMaxD0DataPoints = getCurrentMinMaxD0DataPoints()
                // Resampling an existing view, so do not need to handle the thrown case of no points.
                return try? resampleDocumentIdsFilteredByConstraint(lowerD0: minMaxD0DataPoints?.minD0DataPoint.d0, upperD0: minMaxD0DataPoints?.maxD0DataPoint.d0, requiredDataPointId: requiredDataPointId, sampleSize: sampleSize)
            }
            return nil
        }
        mutating func resampleDocumentIdsFilteredByConstraint(lowerD0: Float32?, upperD0: Float32?, requiredDataPointId: String?, sampleSize: Int = REConstants.Uncertainty.defaultDisplaySampleSize) throws -> String? { //, showMedianDistances: Bool, showOODDistances: Bool showMedianAndOODDistances: Bool = false) throws {
            let constrainedStructure = getDataPointIdsFilteredByConstraint(lowerD0: lowerD0, upperD0: upperD0)
            // only modify the view if at least 1 remaining point
            let constrainedIds = constrainedStructure.constrainedIds
            guard let rangePoint = constrainedStructure.rangePoint, !constrainedIds.isEmpty else {
                // alert for user
                throw UncertaintyErrors.noDocumentsInSelectedPartition
            }
            
            let sortStructure: (sortedConstrainedIds: [String], updatedRequiredDataPointId: String?)
            //            let sortedConstrainedIds: [String]
            let populationSize = constrainedIds.count
            if populationSize >= sampleSize {
                sortStructure = sampleAndSortConstrainedIds(requiredDataPointId: requiredDataPointId, dataPointIdsSet: constrainedIds, sampleSize: sampleSize)
            } else {
                sortStructure = sortDataPointsSetByD0(requiredDataPointId: requiredDataPointId, dataPointIdsSet: constrainedIds)
            }
            
            //let perQCategoryStats = getPerQCategoryStats(dataPointIds: sortStructure.sortedConstrainedIds)
            // update view stack
            var viewSummaryStats = SummaryStatsStructures(numberOfClasses: numberOfClasses)
            viewSummaryStats.updateStructures(dataPointIds: sortStructure.sortedConstrainedIds, documentIdsToDataPoints: documentIdsToDataPoints, qdfCategory_To_CalibratedOutput: qdfCategory_To_CalibratedOutput)
            let newViewConstraint = CurrentViewConstraints(population: populationSize, sortedSampledDocumentIdsForDisplay: sortStructure.sortedConstrainedIds, currentRangePoint: rangePoint, summaryStats: viewSummaryStats)
            
            if currentViewConstraintsStack.count == REConstants.Uncertainty.maxZoomHistory {
                currentViewConstraintsStack.remove(at: 0)
            }
            currentViewConstraintsStack.append(newViewConstraint)
            return sortStructure.updatedRequiredDataPointId
        }
        
        func getDataPointIdsFilteredByConstraint(lowerD0: Float32?, upperD0: Float32?) -> (constrainedIds: Set<String>, rangePoint: (minD0DataPointId: String, maxD0DataPointId: String)?) {
            var constrainedIds = Set<String>()
            
            var minD0DataPoint: DataPoint?
            var maxD0DataPoint: DataPoint?
            for dataPoint in documentIdsToDataPoints.values {
                var includePoint = true
                
                
                // distance
                if let d0Contraint = lowerD0 {
                    if dataPoint.d0 < d0Contraint {
                        includePoint = false
                    }
                }
                if let d0Contraint = upperD0 {
                    if dataPoint.d0 > d0Contraint {
                        includePoint = false
                    }
                }
                
                if includePoint {
                    constrainedIds.insert(dataPoint.id)
                    if let rangeDP = minD0DataPoint {
                        if dataPoint.d0 < rangeDP.d0 {
                            minD0DataPoint = dataPoint
                        }
                    } else {
                        minD0DataPoint = dataPoint
                    }
                    if let rangeDP = maxD0DataPoint {
                        if dataPoint.d0 > rangeDP.d0 {
                            maxD0DataPoint = dataPoint
                        }
                    } else {
                        maxD0DataPoint = dataPoint
                    }
                    
                }
            }
            if let minD0DataPoint = minD0DataPoint, let maxD0DataPoint = maxD0DataPoint {
                return (constrainedIds: constrainedIds, rangePoint: (minD0DataPointId: minD0DataPoint.id, maxD0DataPointId: maxD0DataPoint.id))
            }
            
            return (constrainedIds: constrainedIds, rangePoint: nil)
        }
        
//        func getPerQCategoryStats(dataPointIds: [String]) -> (qCategory2Total: [QCategory: Int], qCategory2Proportion: [QCategory: Float32]) {
//            var qCategory2Total: [QCategory: Int] = [:]
//            var qCategory2Proportion: [QCategory: Float32] = [:]
//            for qCategory in QCategory.allCases {
//                qCategory2Total[qCategory] = 0
//                qCategory2Proportion[qCategory] = 0.0
//            }
//            var total: Float32 = 0.0
//            for dataPointId in dataPointIds {
//                if let dataPoint = documentIdsToDataPoints[dataPointId] {
//                    qCategory2Total[dataPoint.qCategory]? += 1
//                    total += 1.0
//                }
//            }
//            if total > 0 {
//                for qCategory in QCategory.allCases {
//                    if let qCategoryN = qCategory2Total[qCategory] {
//                        qCategory2Proportion[qCategory] = Float32(qCategoryN) / total
//                    }
//                }
//            }
//            return (qCategory2Total: qCategory2Total, qCategory2Proportion: qCategory2Proportion)
//        }
        
        /// requiredDataPointId is guaranteed to be in the sample
        func getDataPointIdsForDisplay(requiredDataPointId: String?, dataPointsDictionary: [ String: DataPoint ], sampleSize: Int = REConstants.Uncertainty.defaultDisplaySampleSize) -> [String] {
            if dataPointsDictionary.count < sampleSize {
                return sortDataPointsByD0(dataPointsDictionary: dataPointsDictionary)
            } else {
                var dataPointIdsSampleSet = sampleDataPoints(dataPointsDictionary: dataPointsDictionary, sampleSize: sampleSize)
                if let requiredDataPointId = requiredDataPointId, let _ = dataPointsDictionary[requiredDataPointId] {
                    dataPointIdsSampleSet.insert(requiredDataPointId)
                }
                
                // get sorted ids
                let sortedArray = dataPointIdsSampleSet.sorted { (first, second) -> Bool in
                    return dataPointsDictionary[first]!.d0 < dataPointsDictionary[second]!.d0
                }
                return sortedArray
            }
        }
        
        func sortDataPointsByD0(dataPointsDictionary: [ String: DataPoint ]) -> [String] {
            let sortedArray = dataPointsDictionary.sorted { (first, second) -> Bool in
                return first.value.d0 < second.value.d0
            }
            return sortedArray.map { $0.key }  // only keep keys (documentIds) to reduce memory
        }
        
        
        /// Sort AND sample databpoints by the distance to training. Note that the requiredDataPointId, if provided, must be present in the *population*, as determined by dataPointIdsSet. The requiredDataPointId could fall out of the population due to a zoom, change in partition, etc.
        func sampleAndSortConstrainedIds(requiredDataPointId: String?, dataPointIdsSet: Set<String>, sampleSize: Int = REConstants.Uncertainty.defaultDisplaySampleSize) -> (sortedConstrainedIds: [String], updatedRequiredDataPointId: String?) {
            let shuffledIds = dataPointIdsSet.shuffled()
            var dataPointIdsSampleSet = Set(shuffledIds[0..<min(sampleSize, shuffledIds.count)])
            var updatedRequiredDataPointId = requiredDataPointId
            if let requiredDataPointId = requiredDataPointId, let _ = self.documentIdsToDataPoints[requiredDataPointId] {
                if dataPointIdsSet.contains(requiredDataPointId) {  // requiredDataPointId must be in the (constrained) population, but it may not be in the sample, dataPointIdsSampleSet, without re-adding here
                    dataPointIdsSampleSet.insert(requiredDataPointId)
                } else {
                    updatedRequiredDataPointId = nil
                }
            }
            let sortedSampledArray = dataPointIdsSampleSet.sorted { (first, second) -> Bool in
                return self.documentIdsToDataPoints[first]!.d0 < self.documentIdsToDataPoints[second]!.d0
            }
            return (sortedConstrainedIds: sortedSampledArray, updatedRequiredDataPointId: updatedRequiredDataPointId)
        }
        /// Sort databpoints by the distance to training. Note that the requiredDataPointId, if provided, must be present in the population, as determined by dataPointIdsSet. The requiredDataPointId could fall out of the population due to a zoom, change in partition, etc.
        func sortDataPointsSetByD0(requiredDataPointId: String?, dataPointIdsSet: Set<String>) -> (sortedConstrainedIds: [String], updatedRequiredDataPointId: String?) {
            var dataPointIdsSet = dataPointIdsSet
            var updatedRequiredDataPointId = requiredDataPointId
            if let requiredDataPointId = requiredDataPointId, let _ = self.documentIdsToDataPoints[requiredDataPointId] {
                if dataPointIdsSet.contains(requiredDataPointId) {
                    dataPointIdsSet.insert(requiredDataPointId)
                } else {
                    updatedRequiredDataPointId = nil
                }
            }
            let sortedSampledArray = dataPointIdsSet.sorted { (first, second) -> Bool in
                return self.documentIdsToDataPoints[first]!.d0 < self.documentIdsToDataPoints[second]!.d0
            }
            return (sortedConstrainedIds: sortedSampledArray, updatedRequiredDataPointId: updatedRequiredDataPointId)
        }
        
        func sampleDataPoints(dataPointsDictionary: [ String: DataPoint ], sampleSize: Int = REConstants.Uncertainty.defaultDisplaySampleSize) -> Set<String> {
            let shuffledIds = dataPointsDictionary.keys.shuffled()
            return Set(shuffledIds[0..<min(sampleSize, shuffledIds.count)])
        }
    }
    
    struct UncertaintyGraphCoordinator {
        var datasetId_To_inMemoryDataCoordinator: [Int: DatasetUncertaintyCoordinator] = [:]
    }
    
}
