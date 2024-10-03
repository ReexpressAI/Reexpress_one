//
//  DataController+DisplayHighlighting+Guide.swift
//  Alpha1
//
//  Created by A on 8/22/23.
//

import Foundation

extension DataController {


    func returnCoveredAttributedString(documentTextAttributedString: AttributedString, stringRange: Range<String.Index>) -> AttributedString {
        if let start = AttributedString.Index(stringRange.lowerBound, within: documentTextAttributedString), let end = AttributedString.Index(stringRange.upperBound, within: documentTextAttributedString) {
            return AttributedString(documentTextAttributedString[start..<end])
        }
        return AttributedString("")
    }
    
    func highlightTextForInterpretabilityBinaryClassificationWithDocumentObjectReturnAsGuideStructure(documentObject: Document, searchParameters: SearchParameters?, semanticSearchParameters: SemanticSearchParameters?) -> HighlightStructure {
        
        var highlightStructure = HighlightStructure()
        let tokenizationCutoffRangeStart = documentObject.tokenizationCutoffRangeStart
        if tokenizationCutoffRangeStart == -1 || documentObject.document == nil || (documentObject.document ?? "").isEmpty {
            // tokenization has not yet occurred or the document is missing content, so return
            return highlightStructure
        }
        // important to not truncate
        let documentHighlighting = highlightTextForInterpretabilityBinaryClassificationWithDocumentObject(documentObject: documentObject, truncateToDocument: false, highlightFeatureInconsistentWithDocLevel: true, searchParameters: searchParameters, semanticSearchParameters: nil, highlightFeatureMatchesDocLevel: true, showSemanticSearchFocusInDocumentText: false)  // we do a second pass to get the semantic search, since it can potentialy overwrite the feature highlights
        let documentWithPromptAttributedString = documentHighlighting.attributedString
        let documentText = documentObject.documentWithPrompt
//        var attributedString = AttributedString(documentText)
//        var truncatedWordsRange = documentText.endIndex..<documentText.endIndex
//        var featureMatchesDocLevelSentenceRange = documentText.endIndex..<documentText.endIndex
//        var featureInconsistentWithDocLevelSentenceRange = documentText.endIndex..<documentText.endIndex
        
        if documentObject.tokenizationCutoffRangeStart != -1 {
            let truncatedWordsRange = String.Index(utf16Offset: documentObject.tokenizationCutoffRangeStart, in: documentText)..<documentText.endIndex
            highlightStructure.truncatedTextAttributedString = returnCoveredAttributedString(documentTextAttributedString: documentWithPromptAttributedString, stringRange: truncatedWordsRange)
        }
        if documentObject.featureMatchesDocLevelSentenceRangeStart != -1 && documentObject.featureMatchesDocLevelSentenceRangeEnd != -1 && DataController.isKnownValidLabel(label: documentObject.prediction, numberOfClasses: numberOfClasses) {
            let featureMatchesDocLevelSentenceRange = String.Index(utf16Offset: documentObject.featureMatchesDocLevelSentenceRangeStart, in: documentText)..<String.Index(utf16Offset: documentObject.featureMatchesDocLevelSentenceRangeEnd, in: documentText)
            highlightStructure.featureMatchesAttributedString = returnCoveredAttributedString(documentTextAttributedString: documentWithPromptAttributedString, stringRange: featureMatchesDocLevelSentenceRange)
            highlightStructure.featureMatchesDocLevelSoftmaxValString = REConstants.floatProbToDisplaySignificantDigits(floatProb: documentObject.featureMatchesDocLevelSoftmaxVal)
            highlightStructure.docLevelPredictionLabelString = labelToName[documentObject.prediction]
        }
        

        if documentObject.featureInconsistentWithDocLevelSentenceRangeStart != -1 && documentObject.featureInconsistentWithDocLevelSentenceRangeEnd != -1 && DataController.isKnownValidLabel(label: documentObject.prediction, numberOfClasses: numberOfClasses) && DataController.isKnownValidLabel(label: documentObject.featureInconsistentWithDocLevelPredictedClass, numberOfClasses: numberOfClasses) {
                let featureInconsistentWithDocLevelSentenceRange = String.Index(utf16Offset: documentObject.featureInconsistentWithDocLevelSentenceRangeStart, in: documentText)..<String.Index(utf16Offset: documentObject.featureInconsistentWithDocLevelSentenceRangeEnd, in: documentText)
                
                
                highlightStructure.featureInconsistentAttributedString = returnCoveredAttributedString(documentTextAttributedString: documentWithPromptAttributedString, stringRange: featureInconsistentWithDocLevelSentenceRange)
                highlightStructure.featureInconsistentWithDocLevelSoftmaxValString = REConstants.floatProbToDisplaySignificantDigits(floatProb: documentObject.featureInconsistentWithDocLevelSoftmaxVal)
                highlightStructure.featureInconsistentWithDocLevelPredictedClassLabelString = labelToName[documentObject.featureInconsistentWithDocLevelPredictedClass]
            }

//        if let datasetId = datasetIdForSearch {
//            highlightTextFromSearchIfAvailable(datasetId: datasetId, documentTextAttributedString: &attributedString)
//        }

        if let searchParameters = searchParameters, searchParameters.search, !searchParameters.searchText.isEmpty, documentHighlighting.didHighlightSearchKeywords {
            var keywordSearchAttributedString = AttributedString(searchParameters.searchText)
            let _ = highlightTextFromSearchViaSearchParametersIfAvailable(searchParameters: searchParameters, documentTextAttributedString: &keywordSearchAttributedString, documentText: searchParameters.searchText)
            highlightStructure.keywordSearchAttributedString = keywordSearchAttributedString
        }
        
        // Second pass to get the semantic search, if applicable, since it can potentialy overwrite the feature highlights; as above, important to not truncate
        if let semanticSearchParameters = semanticSearchParameters, semanticSearchParameters.search, !semanticSearchParameters.searchText.isEmpty, !semanticSearchParameters.retrievedDocumentIDs.isEmpty, let documentID = documentObject.id, let semanticSearchTextRange = semanticSearchParameters.retrievedDocumentIDs2HighlightRanges[documentID] {
         
            let documentWithPromptAttributedStringHighlightingWithSemanticSearch = highlightTextForInterpretabilityBinaryClassificationWithDocumentObject(documentObject: documentObject, truncateToDocument: false, highlightFeatureInconsistentWithDocLevel: false, searchParameters: nil, semanticSearchParameters: semanticSearchParameters, highlightFeatureMatchesDocLevel: false, showSemanticSearchFocusInDocumentText: true).attributedString
            
            highlightStructure.semanticSearchAttributedString = returnCoveredAttributedString(documentTextAttributedString: documentWithPromptAttributedStringHighlightingWithSemanticSearch, stringRange: semanticSearchTextRange)
            if let documentLevelSearchDistance = semanticSearchParameters.retrievedDocumentIDs2DocumentLevelSearchDistances[documentID] {
                highlightStructure.documentLevelSearchDistance = String(documentLevelSearchDistance)
            }
        }
        
        return highlightStructure
    }
}
