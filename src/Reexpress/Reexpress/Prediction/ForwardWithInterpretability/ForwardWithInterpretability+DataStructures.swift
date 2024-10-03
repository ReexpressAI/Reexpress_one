//
//  ForwardWithInterpretability+DataStructures.swift
//  Alpha1
//
//  Created by A on 8/3/23.
//

import SwiftUI

extension MainForwardAfterTrainingView {
    
    enum InferenceProgressStatus: Int, CaseIterable {
        case noDocumentsAvailable = 0
        case notStarted = 1
        case inference = 2
        case indexing = 3
        case calibrating = 4
        case complete = 5
    }
    
    struct InferenceProgress: Identifiable, Hashable {
        var id: Int {
            return datasetId
        }
        let datasetId: Int
        var totalDocuments: Int = 0
        var currentDocumentProgress: Int = 0
        var inferenceProgressStatus: InferenceProgressStatus = .notStarted
        var statusString: String {
            switch inferenceProgressStatus {
            case .noDocumentsAvailable:
                return "N/A"
            case .notStarted:
                return "Not yet started"
            case .inference:
                return "\(currentDocumentProgress) out of \(totalDocuments) documents"
            case .indexing:
                return "\(currentDocumentProgress) out of \(totalDocuments) documents"
            case .calibrating:
                return "\(currentDocumentProgress) out of \(totalDocuments) documents"
            case .complete:
                return "All available documents have been processed."
            }
        }
        var progressProportion: Double {
            if inferenceProgressStatus == .complete {
                return 1.0
            }
            if totalDocuments > 0 {
                // In principle, should never be greater than 1, just an extra check:
                return min(1.0, Double(currentDocumentProgress) / Double(totalDocuments))
            } else {
                return 0.0
            }
        }
        var progressTitleString: String {
            switch inferenceProgressStatus {
            case .noDocumentsAvailable:
                return "N/A"
            case .notStarted:
                return "Pending..."
            case .inference:
                return "Predicting..."
            case .indexing:
                return "Indexing..."
            case .calibrating:
                return "Calibrating..."
            case .complete:
                return "Complete."
            }
        }
    }
}
