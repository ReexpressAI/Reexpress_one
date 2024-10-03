//
//  DataController+Selection.swift
//  Alpha1
//
//  Created by A on 8/22/23.
//

import Foundation
import CoreData

extension DataController {
    
    func determineQDFPartitionsInSelectionAsStringSet(documentSelectionState: DocumentSelectionState) -> Set<String> {
        var qdfCategoriesInSelection = Set<String>()
        for qdfCategory in documentSelectionState.qdfCategoriesInSelection {
            qdfCategoriesInSelection.insert(qdfCategory.id)
        }
        return qdfCategoriesInSelection
    }
    
    // main queue; intersection with qdfCategoryIDsInSelection
    // In this case, any QDFCategoryCD not in Calibration corresponds to OOD -- or effectively probability of 0
    func getCDFCategoriesByProbabilityRestrictions(qdfCategoryIDsInSelection: Set<String>, documentSelectionState: DocumentSelectionState, moc: NSManagedObjectContext) throws -> Set<String> {
        
        let limitByProbability = !documentSelectionState.includeAllPartitions && (documentSelectionState.probabilityConstraint.lowerProbabilityInt != REConstants.Uncertainty.minProbabilityPrecisionForDisplayAsInt || documentSelectionState.probabilityConstraint.upperProbabilityInt != REConstants.Uncertainty.maxProbabilityPrecisionForDisplayAsInt)
        if limitByProbability {
            let fetchRequest = QDFCategoryCD.fetchRequest()
            // add tolerance to avoid numerical rounding issues
            let toleranceLowerProbability = documentSelectionState.probabilityConstraint.lowerProbability - 0.004
            let toleranceUpperProbability = documentSelectionState.probabilityConstraint.upperProbability + 0.004

            let compoundPredicateForQDFCategory =
            NSPredicate(format: "predictionProbability >= %@ && predictionProbability <= %@", NSNumber(value: toleranceLowerProbability), NSNumber(value: toleranceUpperProbability))
            
            fetchRequest.propertiesToFetch = ["id"]
            fetchRequest.predicate = compoundPredicateForQDFCategory
            let qdfRequest = try moc.fetch(fetchRequest)
            
            if qdfRequest.isEmpty {
                throw DataSelectionErrors.noDocumentsFound
            }
            var qdfCategoryIDsConstrained = Set<String>()
            for qdf in qdfRequest {
                if let qdfId = qdf.id {
                    qdfCategoryIDsConstrained.insert(qdfId)
                }
            }
            //print("ids by probability: \(qdfCategoryIDsConstrained)")
            
            if qdfCategoryIDsConstrained.isEmpty {
                throw DataSelectionErrors.noDocumentsFound
            }
            return qdfCategoryIDsConstrained.intersection(qdfCategoryIDsInSelection)
        } else {
            return qdfCategoryIDsInSelection
        }
    }
    // size 0 may not be in CoreData, so need to find intersection with all possible
    func getQDFCategoriesOfSize0(documentSelectionState: DocumentSelectionState, moc: NSManagedObjectContext) throws -> Set<String> {
        let fetchRequest = QDFCategoryCD.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "sizeOfCategory != 0")
        fetchRequest.propertiesToFetch = ["id"]
        let qdfRequest = try moc.fetch(fetchRequest)
        var nonZeroQDFCategoryIDs = Set<String>()
        for qdf in qdfRequest {
            if let qdfId = qdf.id {
                nonZeroQDFCategoryIDs.insert(qdfId)
            }
        }
        let allPossibleQDFCategoryIDs = documentSelectionState.getAllPossibleQDFCategoryIDs()
        // Remaining IDs are those with size 0 (i.e., never seen in Calibration)
        return allPossibleQDFCategoryIDs.subtracting(nonZeroQDFCategoryIDs)
    }
    // main queue; intersection with qdfCategoryIDsInSelection
    // this is tricky, because we also need to check for any categories not in calibration that are nonetheless in the other datasplit. This is particularly common for OOD.
    func getCDFCategoriesByCategorySizeRestrictions(qdfCategoryIDsInSelection: Set<String>, documentSelectionState: DocumentSelectionState, moc: NSManagedObjectContext) throws -> Set<String> {
        
        if documentSelectionState.qDFCategorySizeCharacterizationsAllSelected() {
            if documentSelectionState.partitionSizeConstraints.minPartitionSize == nil && documentSelectionState.partitionSizeConstraints.maxPartitionSize == nil {
                return qdfCategoryIDsInSelection
            }
        }
        // Note that this is an OR but the sizes might be discontinuous (e.g., >= 100 || 0, skipping 0<size<100)
        var compoundPredicate: [NSPredicate] = []
        var zeroInSelection = false
        
        for qDFCategorySizeCharacterization in documentSelectionState.qDFCategorySizeCharacterizations {
            
            switch qDFCategorySizeCharacterization {
            case .sufficient:
                compoundPredicate.append(NSPredicate(format: "sizeOfCategory >= %@", NSNumber(value: REConstants.Uncertainty.minReliablePartitionSize)))
            case .insufficient:
                compoundPredicate.append(NSPredicate(format: "sizeOfCategory > 0 && sizeOfCategory < %@", NSNumber(value: REConstants.Uncertainty.minReliablePartitionSize)))
            case .zero:
                zeroInSelection = true
                //compoundPredicate.append(NSPredicate(format: "sizeOfCategory == 0"))
            }
        }
        let fetchRequest = QDFCategoryCD.fetchRequest()
        if documentSelectionState.partitionSizeConstraints.restrictPartitionSize && (documentSelectionState.partitionSizeConstraints.minPartitionSize != nil || documentSelectionState.partitionSizeConstraints.maxPartitionSize != nil) {
            // In the case the user has supplied a size constraint range, we rebuild the predicate. This is simpler than above, since the range cannot be discontinuous and never contains zero.
            if let minPartitionSize = documentSelectionState.partitionSizeConstraints.minPartitionSize, let maxPartitionSize = documentSelectionState.partitionSizeConstraints.maxPartitionSize {
                fetchRequest.predicate = NSPredicate(format: "sizeOfCategory >= %@ && sizeOfCategory <= %@", NSNumber(value: minPartitionSize), NSNumber(value: maxPartitionSize))
            } else {
                if let minPartitionSize = documentSelectionState.partitionSizeConstraints.minPartitionSize {
                    fetchRequest.predicate = NSPredicate(format: "sizeOfCategory >= %@", NSNumber(value: minPartitionSize))
                } else if let maxPartitionSize = documentSelectionState.partitionSizeConstraints.maxPartitionSize {
                    fetchRequest.predicate = NSPredicate(format: "sizeOfCategory <= %@", NSNumber(value: maxPartitionSize))
                }
            }
            
            // It's assumed that minPartitionSize is >= REConstants.Uncertainty.minReliablePartitionSize+1, so no need to check for zero.
            zeroInSelection = false
            // Note, too, that we prevent the shortcircuit return with documentSelectionState.qDFCategorySizeCharacterizationsAllSelected() above
        } else {
            fetchRequest.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: compoundPredicate)
        }
        fetchRequest.propertiesToFetch = ["id"]
        let qdfRequest = try moc.fetch(fetchRequest)
        var qdfCategoriesOfSize0 = Set<String>()
        if zeroInSelection {
            qdfCategoriesOfSize0 = try getQDFCategoriesOfSize0(documentSelectionState: documentSelectionState, moc: moc)
        }
        
        var qdfCategoryIDsConstrained = qdfCategoriesOfSize0 //Set<String>()
        for qdf in qdfRequest {
            if let qdfId = qdf.id {
                qdfCategoryIDsConstrained.insert(qdfId)
            }
        }
        if qdfCategoryIDsConstrained.isEmpty {
            throw DataSelectionErrors.noDocumentsFound
        }
        
        return qdfCategoryIDsConstrained.intersection(qdfCategoryIDsInSelection)
    }
    
    func getKeywordSearchPredicate(searchParameters: SearchParameters) -> [NSPredicate] {
        var compoundPredicate: [NSPredicate] = []
        
        if searchParameters.caseSensitiveSearch {
            switch searchParameters.searchField {
            case "prompt":
                compoundPredicate.append(NSPredicate(format: "prompt CONTAINS %@", searchParameters.searchText))
            case "document":
                compoundPredicate.append(NSPredicate(format: "document CONTAINS %@", searchParameters.searchText))
            case "group":
                compoundPredicate.append(NSPredicate(format: "group CONTAINS %@", searchParameters.searchText))
            case "info":
                compoundPredicate.append(NSPredicate(format: "info CONTAINS %@", searchParameters.searchText))
            case "id":
                compoundPredicate.append(NSPredicate(format: "id CONTAINS %@", searchParameters.searchText))
            default:
                return []
            }
        } else {  // Note: Also diacritics insensitive
            switch searchParameters.searchField {
            case "prompt":
                compoundPredicate.append(NSPredicate(format: "prompt CONTAINS[cd] %@", searchParameters.searchText))
            case "document":
                compoundPredicate.append(NSPredicate(format: "document CONTAINS[cd] %@", searchParameters.searchText))
            case "group":
                compoundPredicate.append(NSPredicate(format: "group CONTAINS[cd] %@", searchParameters.searchText))
            case "info":
                compoundPredicate.append(NSPredicate(format: "info CONTAINS[cd] %@", searchParameters.searchText))
            case "id":
                compoundPredicate.append(NSPredicate(format: "id CONTAINS[cd] %@", searchParameters.searchText))
            default:
                return []
            }
        }
        return compoundPredicate
    }
    
    func getFetchPredicateBasedOnDocumentSelectionState(documentSelectionState: DocumentSelectionState, moc: NSManagedObjectContext) throws -> [NSPredicate] {
        var compoundPredicate: [NSPredicate] = []
        let basePredicate = NSPredicate(format: "dataset.id == %@", NSNumber(value: documentSelectionState.datasetId))
        compoundPredicate.append(basePredicate)
        
        if !documentSelectionState.includeAllPartitions {
            // Start with this set and winnow:
            var qdfCategoryIDsInSelection = determineQDFPartitionsInSelectionAsStringSet(documentSelectionState: documentSelectionState)
            
            qdfCategoryIDsInSelection = try getCDFCategoriesByProbabilityRestrictions(qdfCategoryIDsInSelection: qdfCategoryIDsInSelection, documentSelectionState: documentSelectionState, moc: moc)
            // This one is a bit tricky, because size 0 might not actually be saved in Core Data (since it literally never appeared in Calibration):
            qdfCategoryIDsInSelection = try getCDFCategoriesByCategorySizeRestrictions(qdfCategoryIDsInSelection: qdfCategoryIDsInSelection, documentSelectionState: documentSelectionState, moc: moc)
            
            if qdfCategoryIDsInSelection.count > 0 {
                compoundPredicate.append(NSPredicate(format: "uncertainty.qdfCategoryID in %@", Array(qdfCategoryIDsInSelection)))
            } else {
                throw DataSelectionErrors.noDocumentsFound
            }
        }
        switch documentSelectionState.currentLabelConstraint {
        case .allPoints:
            ()
        case .onlyCorrectPoints:
            compoundPredicate.append(NSPredicate(format: "prediction == label"))
        case .onlyWrongPoints:
            compoundPredicate.append(NSPredicate(format: "prediction != label"))
        }
        
        if documentSelectionState.displayedGroundTruthLabels.count > 0 && documentSelectionState.displayedGroundTruthLabels.count < documentSelectionState.numberOfClasses + 2 {
            compoundPredicate.append(NSPredicate(format: "label in %@", Array(documentSelectionState.displayedGroundTruthLabels)))
        }
        
        if documentSelectionState.lowerQConstraint != 0 || documentSelectionState.upperQConstraint != REConstants.Uncertainty.maxQAvailableFromIndexer {
            compoundPredicate.append(
                NSPredicate(format: "uncertainty.q >= %@ && uncertainty.q <= %@", NSNumber(value: documentSelectionState.lowerQConstraint), NSNumber(value: documentSelectionState.upperQConstraint))
            )
        }
        
        if documentSelectionState.distanceConstraints.minDistance != nil || documentSelectionState.distanceConstraints.maxDistance != nil {
            if let minDistance = documentSelectionState.distanceConstraints.minDistance, let maxDistance = documentSelectionState.distanceConstraints.maxDistance {
                compoundPredicate.append(
                    NSPredicate(format: "uncertainty.d0 >= %@ && uncertainty.d0 <= %@", NSNumber(value: minDistance), NSNumber(value: maxDistance))
                )
            } else {
                if let minDistance = documentSelectionState.distanceConstraints.minDistance {
                    compoundPredicate.append(
                        NSPredicate(format: "uncertainty.d0 >= %@", NSNumber(value: minDistance))
                    )
                } else if let maxDistance = documentSelectionState.distanceConstraints.maxDistance {
                    compoundPredicate.append(
                        NSPredicate(format: "uncertainty.d0 <= %@", NSNumber(value: maxDistance))
                    )
                }
            }
        }
        if documentSelectionState.magnitudeConstraints.minF != nil || documentSelectionState.magnitudeConstraints.maxF != nil {
            if let minF = documentSelectionState.magnitudeConstraints.minF, let maxF = documentSelectionState.magnitudeConstraints.maxF {
                compoundPredicate.append(
                    NSPredicate(format: "uncertainty.f >= %@ && uncertainty.f <= %@", NSNumber(value: minF), NSNumber(value: maxF))
                )
            } else {
                if let minF = documentSelectionState.magnitudeConstraints.minF {
                    compoundPredicate.append(
                        NSPredicate(format: "uncertainty.f >= %@", NSNumber(value: minF))
                    )
                } else if let maxF = documentSelectionState.magnitudeConstraints.maxF {
                    compoundPredicate.append(
                        NSPredicate(format: "uncertainty.f <= %@", NSNumber(value: maxF))
                    )
                }
            }
        }
        
        if documentSelectionState.changedDocumentsParameters.onlyShowModifiedDocuments {
            compoundPredicate.append(NSPredicate(format: "modified == TRUE"))
        }
        if documentSelectionState.changedDocumentsParameters.onlyShowViewedDocuments {
            compoundPredicate.append(NSPredicate(format: "viewed == TRUE"))
        }
        
        if documentSelectionState.inconsistentFeaturesParameters.onlyShowDocumentsWithFeaturesInconsistentWithDocLevelPredictedClass {
            if documentSelectionState.inconsistentFeaturesParameters.featureInconsistentWithDocLevelPredictedClasses.count > 0 {
                // This alone is not sufficient, since 0 is the default for featureInconsistentWithDocLevelPredictedClass
                compoundPredicate.append(NSPredicate(format: "prediction != featureInconsistentWithDocLevelPredictedClass"))
                compoundPredicate.append(NSPredicate(format: "featureInconsistentWithDocLevelPredictedClass in %@", Array(documentSelectionState.inconsistentFeaturesParameters.featureInconsistentWithDocLevelPredictedClasses)))
                compoundPredicate.append(NSPredicate(format: "featureInconsistentWithDocLevelSoftmaxVal > %@", NSNumber(value: 0.0)))
                compoundPredicate.append(NSPredicate(format: "featureInconsistentWithDocLevelSentenceRangeStart != %@", NSNumber(value: -1)))
                compoundPredicate.append(NSPredicate(format: "featureInconsistentWithDocLevelSentenceRangeEnd != %@", NSNumber(value: -1)))
            }
        }
        if documentSelectionState.consistentFeaturesParameters.onlyShowDocumentsWithAFeatureConsistentWithDocLevelPredictedClass {
            compoundPredicate.append(NSPredicate(format: "featureMatchesDocLevelSoftmaxVal > %@", NSNumber(value: 0.0)))
            compoundPredicate.append(NSPredicate(format: "featureMatchesDocLevelSentenceRangeStart != %@", NSNumber(value: -1)))
            compoundPredicate.append(NSPredicate(format: "featureMatchesDocLevelSentenceRangeEnd != %@", NSNumber(value: -1)))
        }
        if documentSelectionState.searchParameters.search {
            let searchPredicate = getKeywordSearchPredicate(searchParameters: documentSelectionState.searchParameters)
            if searchPredicate.count > 0 {
                compoundPredicate.append(contentsOf: searchPredicate)
            }
        }
        return compoundPredicate
    }
    // In the current approach, all selections occur in terms of a single datasplit.
    func getCountResult(documentSelectionState: DocumentSelectionState, moc: NSManagedObjectContext) async throws -> Int {
        
        //let taskContext = newTaskContext()
        //try taskContext.performAndWait {  // be careful with control flow with .perform since it immediately returns (asynchronous)
        //try await taskContext.perform {
        
        
        let retrievalCount = try await MainActor.run {
            let compoundPredicate = try getFetchPredicateBasedOnDocumentSelectionState(documentSelectionState: documentSelectionState, moc: moc)
            let fetchRequest = Document.fetchRequest()
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: compoundPredicate)
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Document.id, ascending: true)]
            return try moc.count(for: fetchRequest)
        }
        return retrievalCount
    }
    
    func getSortDescriptorsBasedOnDocumentSelectionState(documentSelectionState: DocumentSelectionState, moc: NSManagedObjectContext) -> [NSSortDescriptor] {
        var sortDescriptors: [NSSortDescriptor] = []
        
        for sortField in documentSelectionState.sortParameters.orderedSortFields {
            var isAscending = true
            if let isAscendingField = documentSelectionState.sortParameters.sortFieldToIsAscending[sortField] {
                isAscending = isAscendingField
            }
            if sortField == "id" {
                sortDescriptors.append(NSSortDescriptor(keyPath: \Document.id, ascending: isAscending))
            } else if sortField == "info" {
                sortDescriptors.append(NSSortDescriptor(keyPath: \Document.info, ascending: isAscending))
            } else if sortField == "group" {
                sortDescriptors.append(NSSortDescriptor(keyPath: \Document.group, ascending: isAscending))
            } else if sortField == "distance" {
                sortDescriptors.append(NSSortDescriptor(keyPath: \Document.uncertainty?.d0, ascending: isAscending))
            } else if sortField == "q" {
                sortDescriptors.append(NSSortDescriptor(keyPath: \Document.uncertainty?.q, ascending: isAscending))
            } else if sortField == "magnitude" {
                sortDescriptors.append(NSSortDescriptor(keyPath: \Document.uncertainty?.f, ascending: isAscending))
            } else if sortField == "Last Modified" {
                sortDescriptors.append(NSSortDescriptor(keyPath: \Document.lastModified, ascending: isAscending))
            } else if sortField == "Last Viewed" {
                sortDescriptors.append(NSSortDescriptor(keyPath: \Document.lastViewed, ascending: isAscending))
            } else if sortField == "Date Added" {
                sortDescriptors.append(NSSortDescriptor(keyPath: \Document.dateAdded, ascending: isAscending))
            } else if sortField == "featureMatchesDocLevelSoftmaxVal" {  // Not currently accessible by the user directly in Selection, but this is used in the Discover view
                sortDescriptors.append(NSSortDescriptor(keyPath: \Document.featureMatchesDocLevelSoftmaxVal, ascending: isAscending))
            }
        }
        if sortDescriptors.isEmpty {
            sortDescriptors.append(NSSortDescriptor(keyPath: \Document.id, ascending: true))
        }
        return sortDescriptors
    }
}
