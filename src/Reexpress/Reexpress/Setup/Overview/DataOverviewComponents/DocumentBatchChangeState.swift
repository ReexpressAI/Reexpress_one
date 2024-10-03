//
//  DocumentBatchChangeState.swift
//  Alpha1
//
//  Created by A on 8/28/23.
//

import Foundation

enum DocumentViewedState: Int, CaseIterable, Hashable {
    case viewed
    case unviewed
}
struct DocumentBatchChangeState {
    var applyChangesToAllDocumentsAndRowsInSelection: Bool = false // If true, all documents matching the current selection will be updated. This includes documents not explicitly selected in the table.
    
    var deleteAllDocuments: Bool = false
    var changeLabel: Bool = false
    var transferDatasplit: Bool = false
    var changeViewedState: Bool = false
    var changeInfoField: Bool = false
    var changeGroupField: Bool = false
    
    var newDocumentViewedState: DocumentViewedState = .viewed
    var newLabelID: Int? //= REConstants.DataValidator.oodLabel
    var newDatasplitID: Int? // = REConstants.DatasetsEnum.train.rawValue
    
    var infoFieldText: String = ""
    var groupFieldText: String = ""
    
    var atLeastOneChangeOperationSelected: Bool {
        return deleteAllDocuments || changeLabel || transferDatasplit || changeViewedState || changeInfoField || changeGroupField
    }
}


