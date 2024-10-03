//
//  DatasetGlobalControl+CoreDataProperties.swift
//  Alpha1
//
//  Created by A on 3/19/23.
//
//

import Foundation
import CoreData


extension DatasetGlobalControl {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DatasetGlobalControl> {
        return NSFetchRequest<DatasetGlobalControl>(entityName: "DatasetGlobalControl")
    }

    @NSManaged public var id: String
//    @NSManaged public var modelTaskType: Int64
//    @NSManaged public var numberOfClasses: Int64
//    @NSManaged public var modelGroup: Int64
//    @NSManaged public var numberOfEvalSets: Int64
    @NSManaged public var modelTaskType: Int
    @NSManaged public var numberOfClasses: Int
    @NSManaged public var modelGroup: Int
    @NSManaged public var numberOfEvalSets: Int
    
    @NSManaged public var nextAvailableDatasetId: Int

    @NSManaged public var version: String?
    
    @NSManaged public var defaultPrompt: String?
    @NSManaged public var labelNames: Set<LabelName>? //NSSet?
}

// MARK: Generated accessors for labelNames
extension DatasetGlobalControl {

    @objc(addLabelNamesObject:)
    @NSManaged public func addToLabelNames(_ value: LabelName)

    @objc(removeLabelNamesObject:)
    @NSManaged public func removeFromLabelNames(_ value: LabelName)

    @objc(addLabelNames:)
    @NSManaged public func addToLabelNames(_ values: Set<LabelName>) //NSSet)

    @objc(removeLabelNames:)
    @NSManaged public func removeFromLabelNames(_ values: Set<LabelName>) //NSSet)

}

extension DatasetGlobalControl : Identifiable {

}
