//
//  REConstants.swift
//  Alpha1
//
//  Created by A on 1/20/23.
//

import Foundation
import SwiftUI
import Accelerate

struct REConstants {
    /// Floor to tenth digit.
    static func floatProbToDisplaySignificantDigits(floatProb: Float32) -> String {
        let intProb = Int(floatProb*100.0)
        let floored = max(Uncertainty.minProbabilityPrecisionForDisplay, min(Uncertainty.maxProbabilityPrecisionForDisplay, Float(intProb)/100.0))
        return String(format: "%.2f", floored)
    }

    // Note that for consistency we always display the index of the calibrated distribution that corresponds to the original model's predicted class. Note that in some rare cases (e.g., with small category sizes, etc.), the argmax of the calibrated distribution may not be equal to that of the original predicted class.
    static func formatCalibratedOutput(dataPoint: UncertaintyStatistics.DataPoint) -> String {
        if let calibratedOutput = dataPoint.calibratedOutput, calibratedOutput.minDistribution.count > 0, dataPoint.prediction >= 0, dataPoint.prediction < calibratedOutput.minDistribution.count {
//            let maxCal = vDSP.indexOfMaximum(calibratedOutput.minDistribution)
//            return floatProbToDisplaySignificantDigits(floatProb: calibratedOutput.minDistribution[Int(maxCal.0)])
            return floatProbToDisplaySignificantDigits(floatProb: calibratedOutput.minDistribution[dataPoint.prediction])
        }
        return ""
    }
    
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter
    }()
    
    static let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.allowedUnits = [ .day, .hour, .minute, .second]
        return formatter
    }()
        
    struct ProgramIdentifiers {
        static let mainProgramName = "Reexpress one"
        static let mainProgramNameShort = "one"
        static let version = "v23a"
    }
    
    struct Visualization {
        // When there are more than maxNumberOfClassesToDisplay classes in the dataset, we only show the top maxNumberOfClassesToDisplay classes in the Uncertainty Graph popover.
        static let maxNumberOfClassesToDisplay = 10
        
        static let medianDistanceLineD0Color = distanceColorGradient  //Color.cyan.gradient
        static let oodDistanceLineD0Color = Color.purple.gradient
        static let minMaxDistanceInSmapleLineColor = Color.gray.gradient
        
        static let compositionThresholdLineColor = compositionColorGradient
        
        static let predictedLabelsColorGradient = Color.orange.gradient
        static let qCategoryColorGradient = Color.blue.gradient
        static let compositionColorGradient = Color.brown.gradient
        static let distanceColorGradient = Color.cyan.gradient
        
        static let graphPaddingRelativeDistance: Float32 = 0.05
        
        static let xAndYAxisFont = Font.system(size: 14, weight: .regular)
        
        static let popoverQuickViewGrid_VerticalSpacing: CGFloat = 8.0
        
        static let compareView_SampleIndicator = REColors.reSemanticHighlight
        
        static func getLabelDisplayColor(label: Int) -> (foregroundColor: Color, backgroundColor: Color) {
            let defaultForegroundColor = Color.black
            switch label {
            case DataValidator.unlabeledLabel:
                return (foregroundColor: Color.black, backgroundColor: REColors.reSoftHighlight)
            case DataValidator.oodLabel:
                return (foregroundColor: Color.white, backgroundColor: Color.purple)
            case 0:
                return (foregroundColor: defaultForegroundColor, backgroundColor: REColors.reHighlightNegative)
            case 1:
                return (foregroundColor: defaultForegroundColor, backgroundColor: REColors.reHighlightPositive)
            case 2:
                return (foregroundColor: defaultForegroundColor, backgroundColor: REColors.reLabelGreenLightest)
            case 3:
                return (foregroundColor: defaultForegroundColor, backgroundColor: REColors.reLabelBeigeLighter)
            case 4:
                return (foregroundColor: defaultForegroundColor, backgroundColor: REColors.reLabelBrown)
            case 5:
                return (foregroundColor: defaultForegroundColor, backgroundColor: REColors.reLabelMauve)
            case 6:
                return (foregroundColor: defaultForegroundColor, backgroundColor: REColors.reLabelSlate)
            case 7:
                return (foregroundColor: defaultForegroundColor, backgroundColor: REColors.reLabelBeige)
            case 8:
                return (foregroundColor: defaultForegroundColor, backgroundColor: REColors.reLabelTeal)
            case 9:
                return (foregroundColor: defaultForegroundColor, backgroundColor: REColors.reLabelLightBlueGreen)
            default:
                return (foregroundColor: defaultForegroundColor, backgroundColor: REColors.reLabelLightBlueGreen)                
            }
        }
    }
    
    struct KeywordSearch {
        static let maxAllowedCharacters = 250  //100  // should typically match the max length of info and group fields
        static let maxOccurrencesHighlightedInLocalSearch = 10
    }
    struct SemanticSearch {
        static let maxAllowedCharacters = 250
        static let maxQueryTokens = 32
        static let maxTokensForTagger = 120
        static let maxFrequency = 10 // we suspend the frequency count after this count is reached
        static let bm25MaxCeiling: Double = 50.0
        static let emphasisMultiplicativeFactor: Double = 3.0
        
        static let defaultQuestionPrompt = "Please answer the following question, explaining your reasoning step-by-step."
    }
    
    struct Fonts {
        static let baseFont = Font.system(size: 16.0)
        static let baseSubheadlineFont = Font.system(size: 12.0)
    }
        
    struct Persistence {
        static let defaultCoreDataBatchSize = 1000
    }
    
    struct ModelControl {
        static let keyModelId = "keyModel"
        static let indexModelId = "indexModel"
        static let keyModelDimension = 1000 //32 //1000 //128 //1000 //32 //1000
        static let indexModelDimension = 32
        
        // forwardIndexMaxSupportSize is determined by IndexOperator100. Typically, this is much larger than sufficient for full documents, but be mindful this isn't hit when indexing features. Features for each dataset should be indexed separately.
        static let forwardIndexMaxSupportSize = 10_000_000
//        static let keyModelBatchSize = 50
        
        
        static let forwardCacheAndSaveChunkSize = 10_000 // chunks of documents for each cache+embedding save
        static let batchUpdateCoreDataChunkSize = 5_000  // potentially an expensive operation since it includes deletion
        // Index (compresion) model has not yet been trained:
        static let defaultIndexModelUUID = ""
        
        static let defaultUncertaintyModelUUID = ""
        
        static let defaultCancellingTimeToFreeResources = 30.0  // fixed amount of time (in seconds) to free any remaining tasks on the gpu. Typically a simple overlay view is displayed for this amount of time before dismissing the forward/training modal.
    }
    
    struct Uncertainty {
        static let balancedAccuracyDescription = "Balanced Accuracy is the average of the Accuracy for each class. It is generally more informative as a single composite metric than overall Accuracy when there is class imbalance."
        
        static let minProbabilityPrecisionForDisplay: Float32 = 0.01
        static let maxProbabilityPrecisionForDisplay: Float32 = 0.99
        static let probabilityPrecisionStride: Float32 = 0.01
        
        static let minProbabilityPrecisionForDisplayAsInt: Int = 1
        static let maxProbabilityPrecisionForDisplayAsInt: Int = 99
        static let probabilityPrecisionStrideAsInt: Int = 1
        
        static let maxQAvailableFromIndexer: Int = 100 // This is the max k indexed. Note that this corresponds to the raw q value.
        static let defaultConformalAlpha: Float32 = 0.95 
        static let defaultConformalThresholdTolerance: Float32 = 0.001
        static let defaultQMax: Int = 25
        
        static let defaultDisplaySampleSize: Int = 100 //200 //1000 //1000 // max number of points rendered in the graph; in some cases, defaultDisplaySampleSize+1 points may be in the graph if there is a focus point that must be included in the graph
        static let maxZoomHistory: Int = 10
        
        static let minReliablePartitionSize = 100  // When the partition size is less than this value, we treat the calibration reliability as the lowest possible. Additional, some additional visual queues can be provided to the user (such as highlighting the size) to draw attention to the user.
    }
    struct Datasets {
        static let maxCharactersUserSpecifiedDatasetName = 50
        // This got a bit complicated because originally there were 4 distinct types of sets (Training, Calibration, Unlabeled, and Eval), but then we switched to only 3 distinct types (Training, Calibration, and Eval). In effect, now there can be a total of maxEvalDatasets + 3 (currently 15) datasets. The datasplits defined by DatasetsEnum always exists. If their content is deleted, they are then subsequently recreated. Other eval sets are completely erased, and there is a rising counter that determines the next available ID.
        static let numberOfRequiredDatasets = 4 // train+calibration+unlabeled+eval
        static let maxEvalDatasets = 12 //10
        static let maxTotalDatasets = maxEvalDatasets + 3 // train+calibration+unlabeled
        // the placeholder dataset is used for temporary scratch storage for predictions and reranking:
        static let placeholderDatasetId = 9999  //Int64(9999)
        static let placeholderDatasetName = "Placeholder"
        static let placeholderDatasetDisplayName = "Temporary Cache" //"Reranking Search Cache" // [Transfer to retain]"
        
        static func getInternalName(datasetId: DatasetsEnum) -> String {
            switch datasetId {
            case DatasetsEnum.train:
                return "Training set"
            case DatasetsEnum.calibration:
                return "Calibration set"
            case DatasetsEnum.validation:
                return "Eval set"
            case DatasetsEnum.test:
                return "Eval set"
            }
        }
        /// Names used for initial defaults.
        static func getUserSpecifiedName(datasetId: DatasetsEnum) -> String {
            switch datasetId {
            case DatasetsEnum.train:
                return "Training set"
            case DatasetsEnum.calibration:
                return "Calibration set"
            case DatasetsEnum.validation:
                return "Validation set"
            case DatasetsEnum.test:
                return "Eval set"
            }
        }
        static func getUserSpecifiedNameForAdditionalEvalSet(datasetIdInt: Int) -> String {
            return "Eval set (\(datasetIdInt))"
        }
    }
    
    enum DatasetsEnum: Int, CaseIterable { // these are used for initial construction. Note that these ids always exist, but the user can add additional eval/test sets.
        case train = 0
        case calibration = 1
        //case unlabeled = 2
        case validation = 2
        case test = 3
//        case train = "train"
//        case calibration = "calibration"
//        case unlabeled = "unlabeled"
//        case test = "test1"
    }
    
    struct DatasetsConstraints {
        static let maxEmbeddingSize = 1600
        static let maxFileSize = 2_000.0 // MB
        //        static let maxEmbeddingFileSize = 2_000_000.0 // MB
        
        static let maxJSONLabelsFileSize = 10.0 // MB
        static let maxTotalLines = 250_000
        //        static let maxTotalLines = 500
    }
    struct DatasetsViewConstraints {
        // This is the max number of rows displayed at a time in, for example, DataOverviewView. Note that this should exceed the total number of documents returned from a semantic search (currently 100). If not, then the logic needs to be updated to allow paging of the semantic search results (which is currently not implemented).
        static let maxViewableTableRows = 5000
        
    }
    struct KeyModelConstraints {
        static let maxAllowedEpochs: Int = 1000  // User can choose up to this many epochs for a single run
        static let maxSavedEpochs: Int = 2000  // For persistence of training process data, only this many epochs are retained. If this is exceeded, we save the best result as epoch 0 and continue.
        
        // We have to be rather careful that memory allocation remains consistent if we allow the batch size to change, so for now, the batch size remains constant at 50.
//        static let maxAllowedBatchSize: Int = 256 + 1 //128
        // Similarly, for the reason stated above, the defaultBatchSize should only be modified after the aforementioned issue has been resolved; otherwise, some subtle errors could be introduced.
        static let defaultBatchSize: Int = 50  // this should stay at 50
        
        static let defaultMaxEpochs: Int = 50
        static let defaultLearningRate: Float32 = 0.001
        
        // Note this is not used unless the user chooses to apply a decay schedule:
        static let defaultDecayEpoch: Int = Int(defaultMaxEpochs/2)
        static let defaultDecayFactor: Float32 = 10.0
        
        // Not currently user changeable:
        static let numberOfThreads: Int = 0 // 0 means system determines threads; was previously set at 20
        
        static let minNumberOfLabelsPerClassForTraining = 2
        
        static let attributesSize: Int = 32
    }
    
    struct Discover {
        static let maxFeaturesShown: Int = 1000
        
        static func getAllPossibleGroundTruthLabels(numberOfClasses: Int) -> [Int] {
            var labels: [Int] = [REConstants.DataValidator.oodLabel, REConstants.DataValidator.unlabeledLabel]
            for label in 0..<numberOfClasses {
                labels.append(label)
            }
            return labels
        }
    }
}
