//
//  QCategoryCD+CoreDataProperties.swift
//  Alpha1
//
//  Created by A on 7/31/23.
//
//

import Foundation
import CoreData


extension QCategoryCD {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<QCategoryCD> {
        return NSFetchRequest<QCategoryCD>(entityName: "QCategoryCD")
    }

    @NSManaged public var qCategory: Int //Int64
    @NSManaged public var thresholds: Data?
    @NSManaged public var tpD0MedianByClass: Data?
    @NSManaged public var tpD0MaxByClass: Data?
    @NSManaged public var uncertaintyModelControl: UncertaintyModelControl?

}

extension QCategoryCD : Identifiable {

}
