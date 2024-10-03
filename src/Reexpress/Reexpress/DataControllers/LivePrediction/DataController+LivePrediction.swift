//
//  DataController+LivePrediction.swift
//  Alpha1
//
//  Created by A on 9/11/23.
//

import Foundation
import CoreData

extension DataController {
    // Note that liveDocumentState should stay on the main actor
    func constructJSONDocumentForLivePrediction(liveDocumentState: LiveDocumentState, moc: NSManagedObjectContext) throws -> [JSONDocument] {
        
        var jsonDocuments: [JSONDocument] = []
        
        if liveDocumentState.documentText.isEmpty {
            return jsonDocuments
        }
        
        var promptText = liveDocumentState.prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        // In principle, this should already be caught before reaching this point. Here, we truncate rather than throw.
        if promptText.count > REConstants.DataValidator.maxPromptRawCharacterLength {
            promptText = String(promptText.prefix(REConstants.DataValidator.maxPromptRawCharacterLength))
        }
  
        var documentText = liveDocumentState.documentText.trimmingCharacters(in: .whitespacesAndNewlines)

        if documentText.count > REConstants.DataValidator.maxDocumentRawCharacterLength {
            documentText = String(documentText.prefix(REConstants.DataValidator.maxDocumentRawCharacterLength))
        }
        let newDocumentID = UUID().uuidString + "_composed"
        
        if liveDocumentState.attributes.count > REConstants.KeyModelConstraints.attributesSize {
            throw GeneralFileErrors.attributeMaxSizeError
        }

        // Note that the label is 'unlabeled' and info and group are blank but can be updated later by the user in the Details view.
        let aJSONDocument = JSONDocument(id: newDocumentID, label: REConstants.DataValidator.unlabeledLabel, document: documentText, info: "", attributes: liveDocumentState.attributes, prompt: promptText, group: "")
        jsonDocuments.append(aJSONDocument)
        
        return jsonDocuments
    }
}
