//
//  DataController+SummaryStats.swift
//  Alpha1
//
//  Created by A on 9/11/23.
//

import Foundation
import CoreData
import Accelerate


extension DataController {

    func getLabelSummaryStatistics(datasetId: Int) async throws -> (labelTotalsByClass: [Int: Float32], labelFreqByClass: [Int: Float32], totalDocuments: Int) {
        
        // ground-truth labels:
        var labelTotalsByClass: [Int: Float32] = [:]
        var labelFreqByClass: [Int: Float32] = [:]
        let allValidLabels = DataController.allValidLabelsAsArray(numberOfClasses: numberOfClasses)
        for label in allValidLabels {
            labelTotalsByClass[label] = 0.0
            labelFreqByClass[label] = 0.0
        }

        let taskContext = newTaskContext()
        try taskContext.performAndWait {  // be careful with control flow with .perform since it immediately returns (asynchronous)
            
            let fetchRequest = Document.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "dataset.id == %@", NSNumber(value: datasetId))
            fetchRequest.propertiesToFetch = ["id", "label"]
            let documentRequest = try taskContext.fetch(fetchRequest)
            if documentRequest.isEmpty {
                throw CoreDataErrors.noDocumentsFound
            }
            for documentObject in documentRequest {
                if DataController.isValidLabel(label: documentObject.label, numberOfClasses: numberOfClasses) {
                    labelTotalsByClass[documentObject.label]? += 1.0
                }
            }
        }
        
        let groundTruthLabelTotal = vDSP.sum(Array(labelTotalsByClass.values))
        if groundTruthLabelTotal > 0 {
            for (label, classTotal) in labelTotalsByClass {
                labelFreqByClass[label] = Float32(classTotal) / groundTruthLabelTotal
            }
        }
        return (labelTotalsByClass: labelTotalsByClass, labelFreqByClass: labelFreqByClass, totalDocuments: Int(groundTruthLabelTotal))
    }
}
