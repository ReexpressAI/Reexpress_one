//
//  Document+CoreDataProperties.swift
//  Alpha1
//
//  Created by A on 2/4/23.
//
//

import Foundation
import CoreData

/// Additional Notes:
///
/* The following should all have -1 as a default value. NOTE this must be configured in .xcdatamodeld
 @NSManaged public var featureMatchesDocLevelSentenceRangeStart: Int
@NSManaged public var featureMatchesDocLevelSentenceRangeEnd: Int
@NSManaged public var featureInconsistentWithDocLevelSentenceRangeStart: Int
@NSManaged public var featureInconsistentWithDocLevelSentenceRangeEnd: Int
@NSManaged public var tokenizationCutoffRangeStart: Int*/

extension Document {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Document> {
        return NSFetchRequest<Document>(entityName: "Document")
    }

    @NSManaged public var id: String?
    @NSManaged public var document: String?
    @NSManaged public var prompt: String?
    @NSManaged public var label: Int
    @NSManaged public var group: String?
    @NSManaged public var info: String?
//    @NSManaged public var metricLabel: Int
    @NSManaged public var prediction: Int
    @NSManaged public var dataset: Dataset?
    @NSManaged public var embedding: Embedding?
    
    @NSManaged public var modified: Bool
    @NSManaged public var viewed: Bool
    
    @NSManaged public var featureMatchesDocLevelSentenceRangeStart: Int
    @NSManaged public var featureMatchesDocLevelSentenceRangeEnd: Int
    @NSManaged public var featureMatchesDocLevelSoftmaxVal: Float
    @NSManaged public var featureInconsistentWithDocLevelPredictedClass: Int
    @NSManaged public var featureInconsistentWithDocLevelSoftmaxVal: Float
    @NSManaged public var featureInconsistentWithDocLevelSentenceRangeStart: Int
    @NSManaged public var featureInconsistentWithDocLevelSentenceRangeEnd: Int
    
    @NSManaged public var tokenizationCutoffRangeStart: Int
    // This is the index of the start of the document text in prompt + " " + document.
    @NSManaged public var documentWithPromptDocumentStartRangeIndex: Int
    // "" if not predicted; otherwise, the indexModelUUID. Use this to determine whether inference has been run, and if so, if was using the current model.
    @NSManaged public var modelUUID: String?
    
    @NSManaged public var lastModified: Date?
    @NSManaged public var lastViewed: Date?
    
    @NSManaged public var dateAdded: Date?
    
    @NSManaged public var uncertainty: Uncertainty?
    @NSManaged public var exemplar: Exemplar?
    @NSManaged public var attributes: Attributes?
    @NSManaged public var features: Features?
}

extension Document : Identifiable {
    
    public var documentWithPrompt: String {
        // In order to have the correct token offsets, we must combine the prompt with the document in the same manner as when tokenizing.
        let prompt = prompt ?? ""
        if prompt.isEmpty {
            return document ?? ""
        } else {
            return prompt + " " + (document ?? "")
        }
    }
    
    public var promptWithTrailingSpaceIfApplicable: String {
        let prompt = prompt ?? ""
        if !prompt.isEmpty {
            return prompt + " "
        }
        return ""
    }
    
}

