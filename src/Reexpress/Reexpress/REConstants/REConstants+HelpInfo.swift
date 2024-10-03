//
//  REConstants+HelpInfo.swift
//  Alpha1
//
//  Created by A on 8/10/23.
//

import Foundation
import SwiftUI

extension REConstants {
    struct HelpAssistanceInfo {
        static let lastModifiedInfoString = "Date, if applicable, when the label was last changed."
        static let qdfInfoString = "The three values \(CategoryDisplayLabels.qShort), \(CategoryDisplayLabels.dShort), and \(CategoryDisplayLabels.fShort) determine the data partition and calibrated probability of this document." //"The three values q, d, and f determine the data partition and calibrated probability of this document."
        static let qInfoString = "Value between 0 and \(REConstants.Uncertainty.maxQAvailableFromIndexer). Higher values are preferable."
        static let d0InfoString = "L\u{00B2} distance to the nearest match in training. Values start at 0 (an exact match) and increase. Lower values are preferable."
        static let fInfoString = "The uncalibrated softmax output from the model for the predicted class. Values between 0 and 1. Higher values are preferable."
        static let fCalibratedInfoString = "The calibrated probability for the model's predicted class. Values between 0 and 1. Higher values are preferable."
        
        static let selectionInfoString = "For multiple individual selections, press the command-key while clicking. For selecting ranges, press the shift-key while clicking the start and end items. To select all, press the command-key + A."
        
        static let storageEstimateDisclaimer = "Storage estimates are approximations that may not reliably reflect the total disk space under some operating conditions."
        
        static let compressedModelSufficientBalancedAccuracy = "Balanced Accuracy above 90% is typically sufficient for the compressed approximation of the model."  //85%
        
        struct HighlightGuide {
            static let truncation = "These are words that exceeded the max tokenization length of \(SentencepieceConstants.maxTokenLength), so they are not taken into consideration when making predictions."
            static let featureScore = "The Feature Score, a value between 0 and 1, is provided for relative reference, but it is not accompanied with an uncertainty estimate, since the model is not trained with labels at that level of granularity (i.e., more fine-grained than the document level)."
            static let semanticSearch = "If the selection included a semantic search, this is the section of the document estimated to be most relevant. The semantic search is not fully supervised, so it is intended for exploratory analysis and is not accompanied with an uncertainty estimate. The search distance (lower is preferable) is provided for informal, relative reference. (Semantic search highlights take precedence over feature highlights in the case of an overlap.)"
        }
        struct Explore {
            static let batchUpdateUnavailableMessage: String = "To initiate a batch update operation, first click Details to hide the document navigator."
        }
        struct Discover {
            static let possibleLabelErrors = "These are documents with relatively high probability predictions (determined with the highest calibration reliability) that differ from the ground-truth class label."
            static let lowProbabilityExplainer = "In particular, label errors in documents on which the model predicts with low probability (and/or non-highest calibration reliability) cannot be uncovered with this algorithm."
        }
        
        struct UserInput {
            static let attributes = "Up to \(REConstants.KeyModelConstraints.attributesSize) numbers, each separated by a comma. For example: 0.0,-0.1,0.2\n\n*The ouput of another language model, or any other auxiliary information about a document, can be provided as input here.*"  // (with no intervening spaces)
            static let attributesAdditionalInfo = "It is not a formal requirement, but typically each value should be between -2.0 and 2.0. The order of the attributes is taken into account. The value 0.0 will implicitly be used for any attribute not provided.\n\nTechnical note: Each attribute must be within the range of a single-precision floating-point number."
            
            static let documentTextInput = "Up to \(SentencepieceConstants.maxTokenLength) tokens (including the prompt) will be seen by the model. No more than \(DataValidator.maxDocumentRawCharacterLength) characters of document text will be saved to the project file."
            static let documentTextInputMaxCharacterStorageNote = "Keep in mind that \(DataValidator.maxDocumentRawCharacterLength) characters typically far exceeds the \(SentencepieceConstants.maxTokenLength) token limit seen by the model. Keyword searches (as in **\(REConstants.MenuNames.exploreName)**) do, however, have access to all characters saved to the project file."
        }
        struct HelperReferenceCodeForUser {
            static let characterCountCodeString =
            """
            func countOfCharacters(inString inputString: String) -> Int {
                return inputString.count
            }
            """
        }
        
        struct StateChanges {
            static let stateChangeTip_Training_Focus: LocalizedStringKey = "If the data in the Training and/or Calibration sets changes (e.g., modifying labels or adding new documents), it is generally a good idea to re-run training. The \(Image(systemName: "square.stack.3d.up.fill")) tab provides a running **Status** indicator for the model."
            
            static let trainingMatchDiscrepancyExplanation = "Pro-tip: Discrepancies between the returned matches and the uncertainty estimate for a given document can arise if the Training and/or Calibration set changes without a subsequent update to the uncertainty estimate by re-running prediction."
            
            static let stateChangeTip_Prediction_Focus: LocalizedStringKey = "If the data in the Training and/or Calibration sets changes (e.g., modifying labels or adding new documents), we recommend at least re-running prediction to update the uncertainty estimates (**\(REConstants.MenuNames.setupName)**->**Predict**). Consider re-running training, as well, when there are major changes to the data. The \(Image(systemName: "square.stack.3d.up.fill")) tab provides a running **Status** indicator for the model."
        }
    }
}
