//
//  DataController+CoreData+RetrieveSingleDocument.swift
//  Alpha1
//
//  Created by A on 8/16/23.
//

import Foundation
import CoreData

extension DataController {
    
    func retrieveOneDocument(documentId: String, moc: NSManagedObjectContext) throws -> Document? {
        let fetchRequest = Document.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", documentId)
        let documentRequest = try moc.fetch(fetchRequest) 
        
        if documentRequest.isEmpty {
            throw CoreDataErrors.retrievalError
        }
        if let document = documentRequest.first {
            return document
        }
        return nil
    }
}
