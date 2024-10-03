//
//  GeneralErrors.swift
//  Alpha1
//
//  Created by A on 1/30/23.
//

import Foundation

enum GeneralFileErrors: Error, LocalizedError {
    case noFileFound
    case maxFileSize
    case maxEmbeddingFileSize
    case documentFileFormat
    case projectDirURLIsNil
    case unexpectedEmbeddingSize
    case unableToCreateProjectFile
    case documentFileFormatAtIndexEstimate(errorIndexEstimate: Int)
    case maxTotalLinesInASingleJSONLinesFileLimit
    
    case attributeMaxSizeError
    
    // For document upload
    case documentLabelFormat(errorIndexEstimate: Int)
    case documentMaxPromptRawCharacterLength(errorIndexEstimate: Int)
    case documentMaxDocumentRawCharacterLength(errorIndexEstimate: Int)
    case documentMaxIDRawCharacterLength(errorIndexEstimate: Int)
    case documentMaxGroupRawCharacterLength(errorIndexEstimate: Int)
    case documentMaxInfoRawCharacterLength(errorIndexEstimate: Int)
    case documentMaxInputAttributeSize(errorIndexEstimate: Int)
     
    // For labels display names files:
    case duplicateLabelsEncountered(errorIndexEstimate: Int)
    case labelDisplayNameIsTooLong(errorIndexEstimate: Int)
    case outOfRangeLabel(errorIndexEstimate: Int)
    case blankLabelDisplayName(errorIndexEstimate: Int)
    
    public var errorDescription: String? {
        switch self {
        case let caughtError:
            return NSLocalizedString("Error: \(String(reflecting: caughtError))", comment: "Error reflection: \(String(reflecting: caughtError))")
        }
    }
}

enum DocumentUploadErrors: Error, LocalizedError {
    case fileAlreadySelected
    case indexError
    
    public var errorDescription: String? {
        switch self {
        case let caughtError:
            return NSLocalizedString("Error: \(String(reflecting: caughtError))", comment: "Error reflection: \(String(reflecting: caughtError))")
        }
    }
}

enum DocumentExportErrors: Error, LocalizedError {
    case exportFailed
    case noDocumentsFound
    
    public var errorDescription: String? {
        switch self {
        case let caughtError:
            return NSLocalizedString("Error: \(String(reflecting: caughtError))", comment: "Error reflection: \(String(reflecting: caughtError))")
        }
    }
}

//extension GeneralFileErrors: LocalizedError {
//    public var errorDescription: String? {
//        switch self {
//        case let caughtError:
//            return NSLocalizedString("Error: \(String(reflecting: caughtError))", comment: "Error reflection: \(String(reflecting: caughtError))")
//        }
//    }
//}
enum MLForwardErrors: Error, LocalizedError {

    case tokenizationDictionaryMismatch
    case forwardError
    case tokenizationWasCancelled
    case forwardPassWasCancelled
    
    case featureIndexingError
    case featureMatchWasCancelled
    
    case livePredictionError
    
    public var errorDescription: String? {
        switch self {
        case let caughtError:
            return NSLocalizedString("Error: \(String(reflecting: caughtError))", comment: "Error reflection: \(String(reflecting: caughtError))")
        }
    }
}

enum BatchUpdateErrors: Error, LocalizedError {

    case batchUpdateFailed
    
    public var errorDescription: String? {
        switch self {
        case let caughtError:
            return NSLocalizedString("Error: \(String(reflecting: caughtError))", comment: "Error reflection: \(String(reflecting: caughtError))")
        }
    }
}

enum UncertaintyErrors: Error, LocalizedError {

    case thresholdDimensionError
    case noDocumentsInSelectedPartition
    
    case unexpectedDataStructureInCoreData
    case uncertaintyStatisticsIsUnexepctedlyMissing
    
    case graphingError
    
    public var errorDescription: String? {
        switch self {
        case let caughtError:
            return NSLocalizedString("Error: \(String(reflecting: caughtError))", comment: "Error reflection: \(String(reflecting: caughtError))")
        }
    }
}

enum IndexErrors: Error, LocalizedError {

    case exemplarDimensionError
    case supportMaxSizeError
    
    // feature search:
    case compressedExemplarConcatenatedDimensionError
    case noDocumentsFound
    
    public var errorDescription: String? {
        switch self {
        case let caughtError:
            return NSLocalizedString("Error: \(String(reflecting: caughtError))", comment: "Error reflection: \(String(reflecting: caughtError))")
        }
    }
}

enum CoreDataErrors: Error, LocalizedError {
    case saveError
    case retrievalError
    case noDocumentsFound
    case datasetNotFound
    case deletionError
    case stateError
    case cacheClearTaskCancelled
    
    public var errorDescription: String? {
        switch self {
        case let caughtError:
            return NSLocalizedString("Error: \(String(reflecting: caughtError))", comment: "Error reflection: \(String(reflecting: caughtError))")
        }
    }
}

enum DataSelectionErrors: Error, LocalizedError {
    case noDocumentsFound
    case semanticSearchCancelled
    case semanticSearchMissingTokens
    case invalidDistanceConstraint
    case invalidMagnitdueConstraint
    case invalidPartitionSizeConstraint
    
    public var errorDescription: String? {
        switch self {
        case let caughtError:
            return NSLocalizedString("Error: \(String(reflecting: caughtError))", comment: "Error reflection: \(String(reflecting: caughtError))")
        }
    }
}
enum RerankingErrors: Error, LocalizedError {
    case noDocumentsFound
    case rerankingCancelled
    
    public var errorDescription: String? {
        switch self {
        case let caughtError:
            return NSLocalizedString("Error: \(String(reflecting: caughtError))", comment: "Error reflection: \(String(reflecting: caughtError))")
        }
    }
}

enum MatchingErrors: Error, LocalizedError {
    case topKIndexesMissing
    
    public var errorDescription: String? {
        switch self {
        case let caughtError:
            return NSLocalizedString("Error: \(String(reflecting: caughtError))", comment: "Error reflection: \(String(reflecting: caughtError))")
        }
    }
}

enum SummaryStatsErrors: Error, LocalizedError {
    case summaryStatsCancelled
    
    public var errorDescription: String? {
        switch self {
        case let caughtError:
            return NSLocalizedString("Error: \(String(reflecting: caughtError))", comment: "Error reflection: \(String(reflecting: caughtError))")
        }
    }
}

enum KeyModelErrors: Error, LocalizedError {
    case dataFormatError
    case trainingLossError
    case inferenceError
    case validationDataError
    case insufficientTrainingLabels
    case inputDimensionSizeMismatch
    case noFeatureProvidersAvailable
    
    case keyModelWeightsMissing
    case indexModelWeightsMissing
    case compressionNotCurrent
    
    case trainingWasCancelled
    
    public var errorDescription: String? {
        switch self {
        case let caughtError:
            return NSLocalizedString("Error: \(String(reflecting: caughtError))", comment: "Error reflection: \(String(reflecting: caughtError))")
        }
    }
}
