//
//  Dataset+CoreDataProperties.swift
//  Alpha1
//
//  Created by A on 3/19/23.
//
//

import Foundation
import CoreData


extension Dataset {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Dataset> {
        return NSFetchRequest<Dataset>(entityName: "Dataset")
    }

    @NSManaged public var count: Int
    @NSManaged public var id: Int
//    @NSManaged public var count: Int64
//    @NSManaged public var id: Int64
    @NSManaged public var userSpecifiedName: String?
    @NSManaged public var internalName: String
//    @NSManaged public var modelTaskType: Int64
//    @NSManaged public var modelGroup: Int64
//    @NSManaged public var numberOfClasses: Int64
    @NSManaged public var documents: Set<Document>? //NSSet?

}

// MARK: Generated accessors for documents
extension Dataset {

    @objc(addDocumentsObject:)
    @NSManaged public func addToDocuments(_ value: Document)

    @objc(removeDocumentsObject:)
    @NSManaged public func removeFromDocuments(_ value: Document)

    @objc(addDocuments:)
    @NSManaged public func addToDocuments(_ values: Set<Document>)

    @objc(removeDocuments:)
    @NSManaged public func removeFromDocuments(_ values: Set<Document>)

}

extension Dataset : Identifiable {

}
