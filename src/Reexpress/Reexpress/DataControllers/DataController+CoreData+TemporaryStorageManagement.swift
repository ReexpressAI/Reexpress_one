//
//  DataController+CoreData+TemporaryStorageManagement.swift
//  Alpha1
//
//  Created by A on 9/9/23.
//

import Foundation

import CoreData

extension DataController {
    
    func refreshTemporaryStorageDatasetMainActor(moc: NSManagedObjectContext) throws {
        
        let taskContext = newTaskContext()
        try taskContext.performAndWait {
            
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Dataset")
            
            request.predicate = NSPredicate(format: "id == %@", NSNumber(value: REConstants.Datasets.placeholderDatasetId))
            
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: request)
            batchDeleteRequest.resultType = .resultTypeCount
            let _ = try taskContext.execute(batchDeleteRequest) as? NSBatchDeleteResult
        }

        // re-add the placeholder:
        let dataset = Dataset(context: moc)
        dataset.id = REConstants.Datasets.placeholderDatasetId
        dataset.internalName = REConstants.Datasets.placeholderDatasetName
        dataset.userSpecifiedName = REConstants.Datasets.placeholderDatasetDisplayName
        inMemory_Datasets[REConstants.Datasets.placeholderDatasetId] = InMemory_Dataset(id: REConstants.Datasets.placeholderDatasetId, internalName: REConstants.Datasets.placeholderDatasetName, count: 0, userSpecifiedName: REConstants.Datasets.placeholderDatasetDisplayName)
        if moc.hasChanges {
            try moc.save()
        }
    }
}


