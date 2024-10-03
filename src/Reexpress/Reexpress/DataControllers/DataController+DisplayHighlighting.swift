//
//  DataController+DisplayHighlighting.swift
//  Alpha1
//
//  Created by A on 8/6/23.
//

import Foundation
import SwiftUI

extension DataController {
    func highlightLabeledStringAndReturnAsAttributedString(textString: String, label: Int) -> AttributedString {
        let labelDisplayColor = REConstants.Visualization.getLabelDisplayColor(label: label)
        var textAttributedString = AttributedString(textString)
        if textString.startIndex < textString.endIndex {
            highlightAttributedString(documentTextAttributedString: &textAttributedString, stringRange: textString.startIndex..<textString.endIndex, backgroundColor: labelDisplayColor.backgroundColor, foregroundColor: labelDisplayColor.foregroundColor)
        }
        return textAttributedString
    }
    
    func highlightAttributedString(documentTextAttributedString: inout AttributedString, stringRange: Range<String.Index>, backgroundColor: Color, foregroundColor: Color) {
        if let start = AttributedString.Index(stringRange.lowerBound, within: documentTextAttributedString), let end = AttributedString.Index(stringRange.upperBound, within: documentTextAttributedString) {
            documentTextAttributedString[start..<end].backgroundColor = backgroundColor
            documentTextAttributedString[start..<end].foregroundColor = foregroundColor
        }
    }
 
    
    func underlineAttributedString(documentTextAttributedString: inout AttributedString, stringRange: Range<String.Index>) {
        if let start = AttributedString.Index(stringRange.lowerBound, within: documentTextAttributedString), let end = AttributedString.Index(stringRange.upperBound, within: documentTextAttributedString) {
            documentTextAttributedString[start..<end].underlineStyle =  NSUnderlineStyle.single
//            documentTextAttributedString[start..<end].underlineStyle =  NSUnderlineStyle.patternDot.union(.single)
        }
    }
    
    func highlightAndTagAttributedString(documentTextAttributedString: inout AttributedString, stringRange: Range<String.Index>, backgroundColor: Color, foregroundColor: Color, linkIdentity: String, uuidURLKey: String) {
        if let start = AttributedString.Index(stringRange.lowerBound, within: documentTextAttributedString), let end = AttributedString.Index(stringRange.upperBound, within: documentTextAttributedString) {
            documentTextAttributedString[start..<end].backgroundColor = backgroundColor
            documentTextAttributedString[start..<end].foregroundColor = foregroundColor
            // We add this UUID hash to avoid any possible collisions with existing URLs in the document text.
            documentTextAttributedString[start..<end].link = URL(string: "\(linkIdentity)_\(uuidURLKey)")
        }
    }
    func highlightOneFocusFeatureInDocumentWithPrompt(documentWithPrompt: String, featureRange: Range<String.Index>, featureIndex: Int, uuidURLKey: String) -> AttributedString {
        var attributedString = AttributedString(documentWithPrompt)
        highlightAndTagAttributedString(documentTextAttributedString: &attributedString, stringRange: featureRange, backgroundColor: REConstants.REColors.reHighlightLight, foregroundColor: .black, linkIdentity: "\(featureIndex)", uuidURLKey: uuidURLKey)
        
        return attributedString
    }
    
    // must be on main thread
    func highlightFeaturesInDocumentWithPrompt(documentObj: Document, uuidURLKey: String) -> AttributedString {
        var attributedString = AttributedString(documentObj.documentWithPrompt)
        if let sentenceRangeStartVector = documentObj.features?.sentenceRangeStartVector?.toArray(type: Int.self), let sentenceRangeEndVector = documentObj.features?.sentenceRangeEndVector?.toArray(type: Int.self) {
            if sentenceRangeStartVector.count == sentenceRangeEndVector.count { // else just ignore (must be misformed)
                
                for rangeI in 0..<sentenceRangeStartVector.count {
                    let sentenceRangeStartInt = Int(sentenceRangeStartVector[rangeI])
                    let sentenceRangeEndInt = Int(sentenceRangeEndVector[rangeI])
                    let featureMatchesDocLevelSentenceRange = String.Index(utf16Offset: sentenceRangeStartInt, in: documentObj.documentWithPrompt)..<String.Index(utf16Offset: sentenceRangeEndInt, in: documentObj.documentWithPrompt)
                    // We apply an alternating color scheme to indicate to the user the feature boundaries. Note that text beyond the tokenizer max length will not be highlighted, which is as desired to indicate cutoffs.
                    highlightAndTagAttributedString(documentTextAttributedString: &attributedString, stringRange: featureMatchesDocLevelSentenceRange, backgroundColor: (rangeI % 2 == 0) ? REConstants.REColors.reSoftHighlight : REConstants.REColors.reSoftHighlight2, foregroundColor: .black, linkIdentity: "\(rangeI)", uuidURLKey: uuidURLKey)
                }
            }
        }
        return attributedString
    }
    
    // must be on main thread
    func highlightFeaturesInDocumentWithPromptWithOptionalFocus(documentObj: Document, uuidURLKey: String, focusFeatureIndex: Int?) -> AttributedString {

        var attributedString = AttributedString(documentObj.documentWithPrompt)
        if let sentenceRangeStartVector = documentObj.features?.sentenceRangeStartVector?.toArray(type: Int.self), let sentenceRangeEndVector = documentObj.features?.sentenceRangeEndVector?.toArray(type: Int.self) {
            if sentenceRangeStartVector.count == sentenceRangeEndVector.count { // else just ignore (must be misformed)
                
                for rangeI in 0..<sentenceRangeStartVector.count {
                    let sentenceRangeStartInt = Int(sentenceRangeStartVector[rangeI])
                    let sentenceRangeEndInt = Int(sentenceRangeEndVector[rangeI])
                    let featureMatchesDocLevelSentenceRange = String.Index(utf16Offset: sentenceRangeStartInt, in: documentObj.documentWithPrompt)..<String.Index(utf16Offset: sentenceRangeEndInt, in: documentObj.documentWithPrompt)
                    // We apply an alternating color scheme to indicate to the user the feature boundaries. Note that text beyond the tokenizer max length will not be highlighted, which is as desired to indicate cutoffs.
                    if let featureIndex = focusFeatureIndex, rangeI == featureIndex {
                        highlightAndTagAttributedString(documentTextAttributedString: &attributedString, stringRange: featureMatchesDocLevelSentenceRange, backgroundColor: REConstants.REColors.reHighlightLight, foregroundColor: .black, linkIdentity: "\(rangeI)", uuidURLKey: uuidURLKey)
                    } else {
                        highlightAndTagAttributedString(documentTextAttributedString: &attributedString, stringRange: featureMatchesDocLevelSentenceRange, backgroundColor: (rangeI % 2 == 0) ? REConstants.REColors.reSoftHighlight : REConstants.REColors.reSoftHighlight2, foregroundColor: .black, linkIdentity: "\(rangeI)", uuidURLKey: uuidURLKey)
                    }
                }
            }
        }
        return attributedString
    }
    
    // Extract the feature range for a particular feature. This needs to be called on the main thread since documentObj is a Core Data managed object
    func getFeatureRangeFromDocumentObject(documentObj: Document, featureIndex: Int) throws -> Range<String.Index>? {
        //var featureMatchesDocLevelSentenceRange: Range<String.Index>?
        
        if let sentenceRangeStartVector = documentObj.features?.sentenceRangeStartVector?.toArray(type: Int.self), let sentenceRangeEndVector = documentObj.features?.sentenceRangeEndVector?.toArray(type: Int.self) {
            if sentenceRangeStartVector.count == sentenceRangeEndVector.count && featureIndex < sentenceRangeEndVector.count { // else just ignore (must be misformed
                
                let sentenceRangeStartInt = Int(sentenceRangeStartVector[featureIndex])
                let sentenceRangeEndInt = Int(sentenceRangeEndVector[featureIndex])
                let featureMatchesDocLevelSentenceRange = String.Index(utf16Offset: sentenceRangeStartInt, in: documentObj.documentWithPrompt)..<String.Index(utf16Offset: sentenceRangeEndInt, in: documentObj.documentWithPrompt)
                return featureMatchesDocLevelSentenceRange
            }
        }
        return nil //featureMatchesDocLevelSentenceRange
    }
    
    
    func highlightTextForInterpretabilityBinaryClassificationWithDocumentObject(documentObject: Document, truncateToDocument: Bool = true, highlightFeatureInconsistentWithDocLevel: Bool = false, searchParameters: SearchParameters?, localSearchParameters: SearchParameters? = nil, semanticSearchParameters: SemanticSearchParameters?, highlightFeatureMatchesDocLevel: Bool, showSemanticSearchFocusInDocumentText: Bool) -> (attributedString: AttributedString, didHighlightSearchKeywords: Bool) {
        
        var didHighlightSearchKeywords: Bool = false
        
        let tokenizationCutoffRangeStart = documentObject.tokenizationCutoffRangeStart
        if tokenizationCutoffRangeStart == -1 || documentObject.document == nil || (documentObject.document ?? "").isEmpty {
            // tokenization has not yet occurred or the document is missing content, so return the document
            return (attributedString: AttributedString(documentObject.document ?? ""), didHighlightSearchKeywords: didHighlightSearchKeywords)
        }
        // reconstruct ranges from utf16 Int offsets
//        guard let documentText = dataPoint.document else {
//            return AttributedString("")
//        }
        let documentText = documentObject.documentWithPrompt
        var attributedString = AttributedString(documentText)
        var truncatedWordsRange = documentText.endIndex..<documentText.endIndex
        var featureMatchesDocLevelSentenceRange = documentText.endIndex..<documentText.endIndex
        var featureInconsistentWithDocLevelSentenceRange = documentText.endIndex..<documentText.endIndex
        
        if documentObject.tokenizationCutoffRangeStart != -1 {
            truncatedWordsRange = String.Index(utf16Offset: documentObject.tokenizationCutoffRangeStart, in: documentText)..<documentText.endIndex
//            highlightAttributedString(documentTextAttributedString: &attributedString, stringRange: truncatedWordsRange, backgroundColor: .gray, foregroundColor: .black)
        }
        if highlightFeatureMatchesDocLevel && documentObject.featureMatchesDocLevelSentenceRangeStart != -1 && documentObject.featureMatchesDocLevelSentenceRangeEnd != -1 && DataController.isKnownValidLabel(label: documentObject.prediction, numberOfClasses: numberOfClasses) {
            featureMatchesDocLevelSentenceRange = String.Index(utf16Offset: documentObject.featureMatchesDocLevelSentenceRangeStart, in: documentText)..<String.Index(utf16Offset: documentObject.featureMatchesDocLevelSentenceRangeEnd, in: documentText)
            
            let labelDisplayColor = REConstants.Visualization.getLabelDisplayColor(label: documentObject.prediction)
            highlightAttributedString(documentTextAttributedString: &attributedString, stringRange: featureMatchesDocLevelSentenceRange, backgroundColor: labelDisplayColor.backgroundColor, foregroundColor: labelDisplayColor.foregroundColor)
        }
        if highlightFeatureInconsistentWithDocLevel {
            if documentObject.featureInconsistentWithDocLevelSentenceRangeStart != -1 && documentObject.featureInconsistentWithDocLevelSentenceRangeEnd != -1 && DataController.isKnownValidLabel(label: documentObject.prediction, numberOfClasses: numberOfClasses) && DataController.isKnownValidLabel(label: documentObject.featureInconsistentWithDocLevelPredictedClass, numberOfClasses: numberOfClasses) { //, documentObject.featureInconsistentWithDocLevelPredictedClass >= 0 && documentObject.featureInconsistentWithDocLevelPredictedClass < numberOfClasses {
                featureInconsistentWithDocLevelSentenceRange = String.Index(utf16Offset: documentObject.featureInconsistentWithDocLevelSentenceRangeStart, in: documentText)..<String.Index(utf16Offset: documentObject.featureInconsistentWithDocLevelSentenceRangeEnd, in: documentText)
                
                let labelDisplayColor = REConstants.Visualization.getLabelDisplayColor(label: documentObject.featureInconsistentWithDocLevelPredictedClass)
                
                /*
                 @NSManaged public var featureMatchesDocLevelSoftmaxVal: Float
                 @NSManaged public var featureInconsistentWithDocLevelPredictedClass: Int
                 @NSManaged public var featureInconsistentWithDocLevelSoftmaxVal: Float
                 */
                highlightAttributedString(documentTextAttributedString: &attributedString, stringRange: featureInconsistentWithDocLevelSentenceRange, backgroundColor: labelDisplayColor.backgroundColor, foregroundColor: labelDisplayColor.foregroundColor)
            }
        }
//        if let datasetId = datasetIdForSearch {
//            highlightTextFromSearchIfAvailable(datasetId: datasetId, documentTextAttributedString: &attributedString)
//        }
        if let searchParameters = searchParameters {
            didHighlightSearchKeywords = highlightTextFromSearchViaSearchParametersIfAvailable(searchParameters: searchParameters, documentTextAttributedString: &attributedString, documentText: documentText)
        }

        if showSemanticSearchFocusInDocumentText, let semanticSearchParameters = semanticSearchParameters, semanticSearchParameters.search, !semanticSearchParameters.searchText.isEmpty, !semanticSearchParameters.retrievedDocumentIDs.isEmpty, let documentID = documentObject.id, let semanticSearchTextRange = semanticSearchParameters.retrievedDocumentIDs2HighlightRanges[documentID] {
            
            highlightAttributedString(documentTextAttributedString: &attributedString, stringRange: semanticSearchTextRange, backgroundColor: REConstants.REColors.reBackgroundDarker, foregroundColor: REConstants.REColors.reSemanticHighlight)
            
        }
        if let localSearchParameters = localSearchParameters {
            let _ = highlightTextFromLocalKeywordSearch(searchParameters: localSearchParameters, documentTextAttributedString: &attributedString, documentText: documentText)
            //let _ = highlightTextFromSearchViaSearchParametersIfAvailable(searchParameters: localSearchParameters, documentTextAttributedString: &attributedString, documentText: documentText)
        }
        // Cutoff text is underlined (no option to disable):
        underlineAttributedString(documentTextAttributedString: &attributedString, stringRange: truncatedWordsRange)

        if truncateToDocument {
            if ( (documentObject.featureMatchesDocLevelSentenceRangeStart != -1 && documentObject.featureMatchesDocLevelSentenceRangeEnd != -1) || (documentObject.featureInconsistentWithDocLevelSentenceRangeStart != -1 && documentObject.featureInconsistentWithDocLevelSentenceRangeEnd != -1) ) && documentObject.documentWithPromptDocumentStartRangeIndex != -1 {
                // This ends up being safer than using the stored documentObject.documentWithPromptDocumentStartRangeIndex, because there is an edge case in which the prompt itself has exceeded the max sentence count. (e.g., MMLU prompts). However, in practice, users should be discouraged from using long prompts. A malformed input (e.g., lots of periods) could still trigger this, so we use this to be safe.
                if let promptRange = documentText.range(of: documentObject.promptWithTrailingSpaceIfApplicable) {
                    if let start = AttributedString.Index(promptRange.upperBound, within: attributedString) {
                        return (attributedString: AttributedString(attributedString[start..<attributedString.endIndex]), didHighlightSearchKeywords: didHighlightSearchKeywords)
                    }
                }
                /*let documentWithPromptDocumentStartRange = String.Index(utf16Offset: documentObject.documentWithPromptDocumentStartRangeIndex, in: documentText)
                if let start = AttributedString.Index(documentWithPromptDocumentStartRange, within: attributedString) {
                    return AttributedString(attributedString[start..<attributedString.endIndex])
                }*/
            }
        }

        return (attributedString: attributedString, didHighlightSearchKeywords: didHighlightSearchKeywords)
    }
    
            
    /// Currently, we only highlight document text. (Note that the user can also search other fields.)
    func highlightTextFromSearchViaSearchParametersIfAvailable(searchParameters: SearchParameters, documentTextAttributedString: inout AttributedString, documentText: String) -> Bool {
        //https://stackoverflow.com/questions/62111551/highlight-a-specific-part-of-the-text-in-swiftui
        var didHighlightSearchKeywords: Bool = false
        if searchParameters.search, !searchParameters.searchText.isEmpty, searchParameters.searchField == "document" {
                        
            if searchParameters.caseSensitiveSearch {
                if let range = documentText.range(of: searchParameters.searchText) {
                    highlightAttributedString(documentTextAttributedString: &documentTextAttributedString, stringRange: range, backgroundColor: .yellow, foregroundColor: .black)
                    didHighlightSearchKeywords = true
                }
            } else {
                if let range = documentText.range(of: searchParameters.searchText, options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive]) {
                    highlightAttributedString(documentTextAttributedString: &documentTextAttributedString, stringRange: range, backgroundColor: .yellow, foregroundColor: .black)
                    didHighlightSearchKeywords = true
                }
            }
            
        }
        return didHighlightSearchKeywords
    }
}
