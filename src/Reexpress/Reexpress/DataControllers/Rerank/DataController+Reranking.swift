//
//  DataController+Reranking.swift
//  Alpha1
//
//  Created by A on 9/9/23.
//

import Foundation
import CoreData

extension DataController {
    func reconcileSearchAndDocumentAttributesForReranking(documentSelectionState: DocumentSelectionState, documentObject: Document) throws -> [Float32] {
        
        switch documentSelectionState.semanticSearchParameters.rerankParameters.rerankAttributesMergeOption {
        case .none:
            return []
        case .search:
            return documentSelectionState.semanticSearchParameters.searchAttributes
        case .document:
            if let attributes = documentObject.attributes?.vector?.toArray(type: Float32.self) {
                return attributes
            }
            return []
            
        case .average:
            var combinedAttributes: [Float32] = []
            var documentAttributes: [Float32] = []
            var searchAttributes: [Float32] = documentSelectionState.semanticSearchParameters.searchAttributes
            // expand attributes to full size:
            searchAttributes.append(contentsOf: [Float32](repeating: Float32(0.0), count: REConstants.KeyModelConstraints.attributesSize-searchAttributes.count))
            
            if var attributes = documentObject.attributes?.vector?.toArray(type: Float32.self) {
                // expand attributes to full size:
                attributes.append(contentsOf: [Float32](repeating: Float32(0.0), count: REConstants.KeyModelConstraints.attributesSize-attributes.count))
                documentAttributes = attributes
            }
            if searchAttributes.count != documentAttributes.count {
                throw GeneralFileErrors.attributeMaxSizeError
            }
            for i in 0..<searchAttributes.count {
                combinedAttributes.append(
                    (searchAttributes[i] + documentAttributes[i]) / Float32(2.0)
                )
            }
            return combinedAttributes
        case .absDifference:
            var combinedAttributes: [Float32] = []
            var documentAttributes: [Float32] = []
            var searchAttributes: [Float32] = documentSelectionState.semanticSearchParameters.searchAttributes
            // expand attributes to full size:
            searchAttributes.append(contentsOf: [Float32](repeating: Float32(0.0), count: REConstants.KeyModelConstraints.attributesSize-searchAttributes.count))
            
            if var attributes = documentObject.attributes?.vector?.toArray(type: Float32.self) {
                // expand attributes to full size:
                attributes.append(contentsOf: [Float32](repeating: Float32(0.0), count: REConstants.KeyModelConstraints.attributesSize-attributes.count))
                documentAttributes = attributes
            }
            if searchAttributes.count != documentAttributes.count {
                throw GeneralFileErrors.attributeMaxSizeError
            }
            for i in 0..<searchAttributes.count {
                combinedAttributes.append(
                    abs(searchAttributes[i] - documentAttributes[i])
                )
            }
            return combinedAttributes
        case .new:
            return documentSelectionState.semanticSearchParameters.rerankParameters.rerankAttributes
        }
    }
    
    // Note that documentSelectionState should stay on the main actor
    func constructJSONDocumentForReranking(documentSelectionState: DocumentSelectionState, moc: NSManagedObjectContext) throws -> (jsonDocumentArray: [JSONDocument], retrievedDocumentIDs2NewDocumentIDs: [String: String], newDocumentIDs2RetrievedDocumentIDs: [String: String]) {
        var retrievedDocumentIDs2NewDocumentIDs: [String: String] = [:]
        var newDocumentIDs2RetrievedDocumentIDs: [String: String] = [:]
        
        if !documentSelectionState.semanticSearchParameters.rerankParameters.reranking {
            return (jsonDocumentArray: [], retrievedDocumentIDs2NewDocumentIDs: [:], newDocumentIDs2RetrievedDocumentIDs: [:])
        }
        var jsonDocuments: [JSONDocument] = []
        let fetchRequest = Document.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id in %@", documentSelectionState.semanticSearchParameters.retrievedDocumentIDs)
        
        let documentRequest = try moc.fetch(fetchRequest)
        
        if documentRequest.isEmpty {
            throw RerankingErrors.noDocumentsFound
        }
        for documentObject in documentRequest {
            
            var promptText = documentSelectionState.semanticSearchParameters.rerankParameters.rerankPrompt
            // In principle, this should already be caught before reaching this point. Here, we truncate rather than throw.
            if promptText.count > REConstants.DataValidator.maxPromptRawCharacterLength {
                promptText = String(promptText.prefix(REConstants.DataValidator.maxPromptRawCharacterLength))
            }
            // The document is: rerank search text + original document text
            var documentText = documentSelectionState.semanticSearchParameters.rerankParameters.rerankSearchText
            if let document = documentObject.document {
                documentText = ([documentSelectionState.semanticSearchParameters.rerankParameters.rerankSearchText, document]).joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
            }
            if documentText.count > REConstants.DataValidator.maxDocumentRawCharacterLength {
                documentText = String(documentText.prefix(REConstants.DataValidator.maxDocumentRawCharacterLength))
            }
            let newDocumentID = UUID().uuidString + "_documentLabel_\(documentObject.label)"
            
            retrievedDocumentIDs2NewDocumentIDs[documentObject.id ?? ""] = newDocumentID
            newDocumentIDs2RetrievedDocumentIDs[newDocumentID] = documentObject.id ?? ""
            let combinedAttributes = try reconcileSearchAndDocumentAttributesForReranking(documentSelectionState: documentSelectionState, documentObject: documentObject)
            // also need to transfer label, info, and group
            // Note that the label becomes 'unlabeled'. We concatenate to the new ID for reference.
            let aJSONDocument = JSONDocument(id: newDocumentID, label: REConstants.DataValidator.unlabeledLabel, document: documentText, info: documentObject.info, attributes: combinedAttributes, prompt: promptText, group: documentObject.group)
            jsonDocuments.append(aJSONDocument)
        }
        
        return (jsonDocumentArray: jsonDocuments, retrievedDocumentIDs2NewDocumentIDs: retrievedDocumentIDs2NewDocumentIDs, newDocumentIDs2RetrievedDocumentIDs: newDocumentIDs2RetrievedDocumentIDs)
    }
    
    func getRerankedIDsFromCacheMainActor(documentSelectionState: DocumentSelectionState, moc: NSManagedObjectContext) throws -> [Document] {
        
        let fetchRequest = Document.fetchRequest()
        let compoundPredicate = try getFetchPredicateBasedOnDocumentSelectionState(documentSelectionState: documentSelectionState, moc: moc)
        
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: compoundPredicate)
        
        let sortDescriptors = getSortDescriptorsBasedOnDocumentSelectionState(documentSelectionState: documentSelectionState, moc: moc)
        
        fetchRequest.sortDescriptors = sortDescriptors
        
        let documentRequest = try moc.fetch(fetchRequest)
        return documentRequest
    }
    func getRerankedHighestAndHighIDsFromCache(target: Int, distanceCategory: UncertaintyStatistics.DistanceCategory, moc: NSManagedObjectContext) throws -> [Document] {
        var documentSelectionState = DocumentSelectionState(numberOfClasses: numberOfClasses)
        documentSelectionState.datasetId = REConstants.Datasets.placeholderDatasetId
        documentSelectionState.includeAllPartitions = false
        
        documentSelectionState.predictedClasses = Set([target])
        documentSelectionState.qCategories = Set([.qMax])
        documentSelectionState.distanceCategories = Set([distanceCategory])
        documentSelectionState.compositionCategories = Set([.singleton])
        documentSelectionState.qDFCategorySizeCharacterizations = Set([.sufficient])
        
        documentSelectionState.sortParameters.sortFields = Set(["q", "distance"])
        documentSelectionState.sortParameters.orderedSortFields = ["q", "distance"]
        documentSelectionState.sortParameters.sortFieldToIsAscending = [:]
        documentSelectionState.sortParameters.sortFieldToIsAscending["q"] = false
        documentSelectionState.sortParameters.sortFieldToIsAscending["distance"] = true
        
        let documentRequestResult = try getRerankedIDsFromCacheMainActor(documentSelectionState: documentSelectionState, moc: moc)
        return documentRequestResult
    }
    func getRerankedAllFromCache(target: Int?, moc: NSManagedObjectContext) throws -> [Document] {
        var documentSelectionState = DocumentSelectionState(numberOfClasses: numberOfClasses)
        documentSelectionState.datasetId = REConstants.Datasets.placeholderDatasetId
        
        if let target = target {
            documentSelectionState.includeAllPartitions = false
            documentSelectionState.predictedClasses = Set([target])
        }
        
        documentSelectionState.sortParameters.sortFields = Set(["q", "distance"])
        documentSelectionState.sortParameters.orderedSortFields = ["q", "distance"]
        documentSelectionState.sortParameters.sortFieldToIsAscending = [:]
        documentSelectionState.sortParameters.sortFieldToIsAscending["q"] = false
        documentSelectionState.sortParameters.sortFieldToIsAscending["distance"] = true
        
        let documentRequestResult = try getRerankedIDsFromCacheMainActor(documentSelectionState: documentSelectionState, moc: moc)
        return documentRequestResult
    }
    
    func updateRerankStructures(target: Int, documentRequest: [Document]?, coveredIDs: inout Set<String>, allRerankedCrossEncodedDocumentIDs: inout [String], onlyMatchesTargetRerankedCrossEncodedDocumentIDs: inout [String]) {
        if let documentRequest = documentRequest {
            for documentObj in documentRequest {
                if let id = documentObj.id {
                    if !coveredIDs.contains(id) {
                        allRerankedCrossEncodedDocumentIDs.append(id)
                        coveredIDs.insert(id)
                        if documentObj.prediction == target {
                            onlyMatchesTargetRerankedCrossEncodedDocumentIDs.append(id)
                        }
                    }
                }
            }
        }
    }
    func rerankSearchCache(currentDocumentSelectionState: DocumentSelectionState, moc: NSManagedObjectContext) throws -> (allRerankedCrossEncodedDocumentIDs: [String], onlyMatchesTargetRerankedCrossEncodedDocumentIDs: [String]) {
        let target = currentDocumentSelectionState.semanticSearchParameters.rerankParameters.rerankTargetLabel
        var allRerankedCrossEncodedDocumentIDs: [String] = []
        var onlyMatchesTargetRerankedCrossEncodedDocumentIDs: [String] = []
        var coveredIDs = Set<String>()
        // Within each, ordered by q and distance:
        // Highest, matching target
        // High, matching target
        // all else matching target
        // any remainder (i.e., those not matching the target)
        let documentRequestHighest = try? getRerankedHighestAndHighIDsFromCache(target: target, distanceCategory: .lessThanOrEqualToMedian, moc: moc)
        
        updateRerankStructures(target: target, documentRequest: documentRequestHighest, coveredIDs: &coveredIDs, allRerankedCrossEncodedDocumentIDs: &allRerankedCrossEncodedDocumentIDs, onlyMatchesTargetRerankedCrossEncodedDocumentIDs: &onlyMatchesTargetRerankedCrossEncodedDocumentIDs)
        
        let documentRequestHigh = try? getRerankedHighestAndHighIDsFromCache(target: target, distanceCategory: .greaterThanMedianAndLessThanOrEqualToOOD, moc: moc)
        
        updateRerankStructures(target: target, documentRequest: documentRequestHigh, coveredIDs: &coveredIDs, allRerankedCrossEncodedDocumentIDs: &allRerankedCrossEncodedDocumentIDs, onlyMatchesTargetRerankedCrossEncodedDocumentIDs: &onlyMatchesTargetRerankedCrossEncodedDocumentIDs)
        
        let allDocumentsMatchingTarget = try? getRerankedAllFromCache(target: target, moc: moc)
        updateRerankStructures(target: target, documentRequest: allDocumentsMatchingTarget, coveredIDs: &coveredIDs, allRerankedCrossEncodedDocumentIDs: &allRerankedCrossEncodedDocumentIDs, onlyMatchesTargetRerankedCrossEncodedDocumentIDs: &onlyMatchesTargetRerankedCrossEncodedDocumentIDs)
        
        let allDocuments = try? getRerankedAllFromCache(target: nil, moc: moc)
        updateRerankStructures(target: target, documentRequest: allDocuments, coveredIDs: &coveredIDs, allRerankedCrossEncodedDocumentIDs: &allRerankedCrossEncodedDocumentIDs, onlyMatchesTargetRerankedCrossEncodedDocumentIDs: &onlyMatchesTargetRerankedCrossEncodedDocumentIDs)
        
        return (allRerankedCrossEncodedDocumentIDs: allRerankedCrossEncodedDocumentIDs, onlyMatchesTargetRerankedCrossEncodedDocumentIDs: onlyMatchesTargetRerankedCrossEncodedDocumentIDs)
    }
}
