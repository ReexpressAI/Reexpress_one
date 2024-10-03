//
//  LabelName+CoreDataProperties.swift
//  Alpha1
//
//  Created by A on 7/16/23.
//
//

import Foundation
import CoreData


extension LabelName {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LabelName> {
        return NSFetchRequest<LabelName>(entityName: "LabelName")
    }

    @NSManaged public var label: Int // Int64
    @NSManaged public var userSpecifiedName: String?
    @NSManaged public var datasetGlobalControl: DatasetGlobalControl?

}

extension LabelName : Identifiable {

}
