//
//  Embedding+CoreDataProperties.swift
//  Alpha1
//
//  Created by A on 2/6/23.
//
//

import Foundation
import CoreData


extension Embedding {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Embedding> {
        return NSFetchRequest<Embedding>(entityName: "Embedding")
    }

    @NSManaged public var id: String?
    @NSManaged public var embedding: Data?
    //@NSManaged public var attributes: Data?
    @NSManaged public var document: Document?
}

extension Embedding : Identifiable {

}
