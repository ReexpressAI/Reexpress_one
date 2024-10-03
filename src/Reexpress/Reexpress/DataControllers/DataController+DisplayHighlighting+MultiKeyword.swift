//
//  DataController+DisplayHighlighting+MultiKeyword.swift
//  Alpha1
//
//  Created by A on 8/25/23.
//

import Foundation
import SwiftUI

// Multi-occurrence keyword highlighting for local search
extension DataController {
    func highlightTextFromLocalKeywordSearch(searchParameters: SearchParameters, documentTextAttributedString: inout AttributedString, documentText: String) -> Bool {
        //https://stackoverflow.com/questions/62111551/highlight-a-specific-part-of-the-text-in-swiftui
        var didHighlightSearchKeywords: Bool = false
        if searchParameters.search, !searchParameters.searchText.isEmpty, searchParameters.searchField == "document" {
                        
            if searchParameters.caseSensitiveSearch {
                let ranges = getRangesForHighlights(documentTextAttributedString: documentTextAttributedString, searchText: searchParameters.searchText)
                for range in ranges {
                    highlightAttributedStringViaAttributedStringIndex(documentTextAttributedString:  &documentTextAttributedString, attributedStringRange: range, backgroundColor: .yellow, foregroundColor: .black)
                    didHighlightSearchKeywords = true
                }
            } else {
                // In this case, we operate on the string and perform a conversion in order to use the compare string options
                let ranges = getRangesForHighlights_StringIndex(documentTextString: documentText, searchText: searchParameters.searchText)
                for range in ranges {
                    highlightAttributedString(documentTextAttributedString: &documentTextAttributedString, stringRange: range, backgroundColor: .yellow, foregroundColor: .black)
                    didHighlightSearchKeywords = true
                }
            }
            
        }
        return didHighlightSearchKeywords
    }
    func highlightAttributedStringViaAttributedStringIndex(documentTextAttributedString: inout AttributedString, attributedStringRange: Range<AttributedString.Index>, backgroundColor: Color, foregroundColor: Color) {
            documentTextAttributedString[attributedStringRange].backgroundColor = backgroundColor
            documentTextAttributedString[attributedStringRange].foregroundColor = foregroundColor
    }
    
    func getRangesForHighlights(documentTextAttributedString: AttributedString, searchText: String) -> [Range<AttributedString.Index>] {
        var ranges: [Range<AttributedString.Index>] = []
        var startIndex = documentTextAttributedString.startIndex
        while true {
            if let range = getRangeOfOneOccurrence(documentTextAttributedString: documentTextAttributedString, searchText: searchText, startIndex: startIndex) {
                ranges.append(range)
                startIndex = range.upperBound
            } else {
                break
            }
            if ranges.count >= REConstants.KeywordSearch.maxOccurrencesHighlightedInLocalSearch { // show only first 10 occurrences
                break
            }
        }
        return ranges
    }
    func getRangeOfOneOccurrence(documentTextAttributedString: AttributedString, searchText: String, startIndex: AttributedString.Index) -> Range<AttributedString.Index>? {
            return documentTextAttributedString[startIndex..<documentTextAttributedString.endIndex].range(of: searchText)
    }
    
    func getRangesForHighlights_StringIndex(documentTextString: String, searchText: String) -> [Range<String.Index>] {
        var ranges: [Range<String.Index>] = []
        var startIndex = documentTextString.startIndex
        while true {
            if let range = getRangeOfOneOccurrence_StringIndex(documentTextString: documentTextString, searchText: searchText, startIndex: startIndex) {
                ranges.append(range)
                startIndex = range.upperBound
            } else {
                break
            }
            if ranges.count >= REConstants.KeywordSearch.maxOccurrencesHighlightedInLocalSearch { // show only first 10 occurrences
                break
            }
        }
        return ranges
    }
    func getRangeOfOneOccurrence_StringIndex(documentTextString: String, searchText: String, startIndex: String.Index) -> Range<String.Index>? {
        return documentTextString[startIndex..<documentTextString.endIndex].range(of: searchText, options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive])
    }
}
