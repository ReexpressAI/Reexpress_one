//
//  Uncertainty+CoreDataProperties.swift
//  Alpha1
//
//  Created by A on 4/7/23.
//
//

import Foundation
import CoreData


extension Uncertainty {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Uncertainty> {
        return NSFetchRequest<Uncertainty>(entityName: "Uncertainty")
    }

    @NSManaged public var softmax: Data?
    @NSManaged public var d0: Float32
    @NSManaged public var f: Float32
    @NSManaged public var q: Int
    @NSManaged public var topKdistances: Data?
    @NSManaged public var topKIndexesAsDocumentIds: [String]?  // where each String is a document id from support/training
    @NSManaged public var document: Document?
    
    @NSManaged public var qdfCategoryID: String?
    @NSManaged public var uncertaintyModelUUID: String?
        
}

extension Uncertainty : Identifiable {

}
