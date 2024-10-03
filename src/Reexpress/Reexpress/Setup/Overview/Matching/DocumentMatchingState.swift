//
//  DocumentMatchingState.swift
//  Alpha1
//
//  Created by A on 9/13/23.
//

import Foundation

struct DocumentMatchingState {
    var documentMatchDisplayType: DocumentMatchDisplayType = .documentOnly
    var selectedDatasetIdToMatch: Int = REConstants.DatasetsEnum.train.rawValue
    // With training, the user has the option to reindex. If true, we ignore the archived topK indexes. The user should be informed that this can diverge from the values used to determine the uncertainty estimate for the document.
    var reIndexTraining: Bool = false
    
    enum DocumentMatchDisplayType: Int, CaseIterable {
        case documentOnly = 1
        case documentWithPrompt = 2
    }
    
    var truncateToDocument: Bool {
        return documentMatchDisplayType == DocumentMatchDisplayType.documentOnly
    }
}
