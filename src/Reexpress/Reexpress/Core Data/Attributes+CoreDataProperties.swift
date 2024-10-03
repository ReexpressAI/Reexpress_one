//
//  Attributes+CoreDataProperties.swift
//  Alpha1
//
//  Created by A on 7/16/23.
//
//

import Foundation
import CoreData


extension Attributes {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Attributes> {
        return NSFetchRequest<Attributes>(entityName: "Attributes")
    }

    @NSManaged public var vector: Data?
    @NSManaged public var document: Document?

}

extension Attributes : Identifiable {

}
