//
//  DataController+DisplayHighlighting+FeatureExtraction.swift
//  Alpha1
//
//  Created by A on 9/5/23.
//

import Foundation

extension DataController {

    func highlightTextForInterpretabilityExtractFeature(documentObject: Document) -> HighlightStructureAbbreviated {
        
        var highlightStructure = HighlightStructureAbbreviated()
        let tokenizationCutoffRangeStart = documentObject.tokenizationCutoffRangeStart
        if tokenizationCutoffRangeStart == -1 || documentObject.document == nil || (documentObject.document ?? "").isEmpty {
            // tokenization has (unexpectedly) not yet occurred or the document is missing content, so return
            return highlightStructure
        }
        
        let documentText = documentObject.documentWithPrompt
        var documentWithPromptAttributedString = AttributedString(documentText)
        var truncatedWordsRange = documentText.endIndex..<documentText.endIndex
        
        if documentObject.tokenizationCutoffRangeStart != -1 {
            truncatedWordsRange = String.Index(utf16Offset: documentObject.tokenizationCutoffRangeStart, in: documentText)..<documentText.endIndex
        }

        // highlight max length exceeded, if applicable
        // Cutoff text is underlined (no option to disable):
        underlineAttributedString(documentTextAttributedString: &documentWithPromptAttributedString, stringRange: truncatedWordsRange)
                
        // extract feature
        
        if documentObject.featureMatchesDocLevelSentenceRangeStart != -1 && documentObject.featureMatchesDocLevelSentenceRangeEnd != -1 && DataController.isKnownValidLabel(label: documentObject.prediction, numberOfClasses: numberOfClasses) {
            let featureMatchesDocLevelSentenceRange = String.Index(utf16Offset: documentObject.featureMatchesDocLevelSentenceRangeStart, in: documentText)..<String.Index(utf16Offset: documentObject.featureMatchesDocLevelSentenceRangeEnd, in: documentText)
            highlightStructure.featureMatchesAttributedStringWithTruncationHighlighted = returnCoveredAttributedString(documentTextAttributedString: documentWithPromptAttributedString, stringRange: featureMatchesDocLevelSentenceRange)
            highlightStructure.featureMatchesDocLevelSoftmaxValString = REConstants.floatProbToDisplaySignificantDigits(floatProb: documentObject.featureMatchesDocLevelSoftmaxVal)
        }
        
        return highlightStructure
    }
}
