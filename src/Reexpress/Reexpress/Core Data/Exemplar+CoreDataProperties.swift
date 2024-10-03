//
//  Exemplar+CoreDataProperties.swift
//  Alpha1
//
//  Created by A on 4/7/23.
//
//

import Foundation
import CoreData


extension Exemplar {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Exemplar> {
        return NSFetchRequest<Exemplar>(entityName: "Exemplar")
    }

    @NSManaged public var exemplar: Data?
    @NSManaged public var exemplarCompressed: Data?
    @NSManaged public var document: Document?

}

extension Exemplar : Identifiable {

}
