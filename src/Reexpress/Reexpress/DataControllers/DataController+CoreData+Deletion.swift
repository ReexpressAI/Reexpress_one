//
//  DataController+CoreData+Deletion.swift
//  Alpha1
//
//  Created by A on 6/21/23.
//

import Foundation

import CoreData

extension DataController {
    
    func deleteDataset(datasetIdInt: Int, moc: NSManagedObjectContext) async throws {
        
        let taskContext = newTaskContext()
        try taskContext.performAndWait {  // be careful with control flow with .perform since it immediately returns (asynchronous)
        //try await taskContext.perform {
            
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Dataset")
            
            request.predicate = NSPredicate(format: "id == %@", NSNumber(value: datasetIdInt))
            
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: request)
            batchDeleteRequest.resultType = .resultTypeCount
            let _ = try taskContext.execute(batchDeleteRequest) as? NSBatchDeleteResult
        }

        // update the in-memory version, deleting the dataset
        try await MainActor.run {
            inMemory_Datasets[datasetIdInt] = nil
            // If a default dataset, re-create:
            if let datasetEnum = REConstants.DatasetsEnum(rawValue: datasetIdInt) { // will be nil if not a valid int corresponding to a dataset
                let dataset = Dataset(context: moc)
                dataset.id = datasetIdInt
                
                dataset.internalName = REConstants.Datasets.getInternalName(datasetId: datasetEnum)
                dataset.userSpecifiedName = REConstants.Datasets.getUserSpecifiedName(datasetId: datasetEnum)
                inMemory_Datasets[dataset.id] = InMemory_Dataset(id: dataset.id, internalName: dataset.internalName, count: 0, userSpecifiedName: dataset.userSpecifiedName)
                
                if moc.hasChanges {
                    try moc.save()
                }
            } else {  // The deleted datasplit was an additional eval set. Decrement the global counter of available eval sets.
                try decrementAvailableEvalSetCounter(moc: moc)
            }
            
            // Update model states
            var stateChange: StateChangeType = .noStateChange
            if datasetIdInt == REConstants.DatasetsEnum.train.rawValue {
                stateChange = .modelTrainingAndUncertaintyConditionsChanged
            } else if datasetIdInt == REConstants.DatasetsEnum.calibration.rawValue {
                stateChange = .onlyUncertaintyConditionsChanged
            }
            try updateBasedOnState(stateChange: stateChange, moc: moc)
        }
    }

    /// Decrement the global counter of available eval sets. Note that DatasetGlobalControl.nextAvailableDatasetId increases regardless of eval set deletes, which we recommend not changing to keep things simple, since we use dictionaries indexed by the id's for some of the in-memory data structures.
    /// This should only be called when a non-default datasplit is deleted.
    func decrementAvailableEvalSetCounter(moc: NSManagedObjectContext) throws {
        
        let fetchRequest = DatasetGlobalControl.fetchRequest()
        fetchRequest.fetchLimit = 1
        let results = try moc.fetch(fetchRequest)

        for datasetControl in results {
            // Decrement id counter:
            datasetControl.numberOfEvalSets = datasetControl.numberOfEvalSets - 1
            if moc.hasChanges {
                try moc.save()
                // Update in-memory counter:
                numberOfEvalSets -= 1
            }
        }
    }
}


