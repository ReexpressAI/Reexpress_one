//
//  DataOverviewView+Features.swift
//  Alpha1
//
//  Created by A on 8/5/23.
//

import SwiftUI

extension DataOverviewView {
    func highlightAttributedString(documentTextAttributedString: inout AttributedString, stringRange: Range<String.Index>, backgroundColor: Color, foregroundColor: Color) {
        if let start = AttributedString.Index(stringRange.lowerBound, within: documentTextAttributedString), let end = AttributedString.Index(stringRange.upperBound, within: documentTextAttributedString) {
            documentTextAttributedString[start..<end].backgroundColor = backgroundColor
            documentTextAttributedString[start..<end].foregroundColor = foregroundColor
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
        highlightAndTagAttributedString(documentTextAttributedString: &attributedString, stringRange: featureRange, backgroundColor: REConstants.REColors.reSoftHighlight, foregroundColor: .black, linkIdentity: "\(featureIndex)", uuidURLKey: uuidURLKey)
        
        return attributedString
    }

}
