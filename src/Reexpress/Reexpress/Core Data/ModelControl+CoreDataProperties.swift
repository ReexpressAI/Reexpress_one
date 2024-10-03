//
//  ModelControl+CoreDataProperties.swift
//  Alpha1
//
//  Created by A on 3/31/23.
//
//

import Foundation
import CoreData


extension ModelControl {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ModelControl> {
        return NSFetchRequest<ModelControl>(entityName: "ModelControl")
    }
    
    @NSManaged public var id: String?
    @NSManaged public var key0: Data?
    @NSManaged public var key0b: Data?
    @NSManaged public var key1: Data?
    @NSManaged public var key1b: Data?
    @NSManaged public var timestampLastModified: Date?
    @NSManaged public var maxMetric: Int
    @NSManaged public var currentMaxMetric: Float
    @NSManaged public var minLoss: Float
    @NSManaged public var state: Int
    
    // data accumulated per-epoch during training:
    @NSManaged public var trainingProcessDataTrainLoss: Data?
    @NSManaged public var trainingProcessDataValidLoss: Data?
    @NSManaged public var trainingProcessDataTrainMetric: Data?
    @NSManaged public var trainingProcessDataValidMetric: Data?
    
    // These are used to ensure the models stay up-to-date. The indexModelUUID is used for Document.modelUUID. indexModelUUID is "" or nil for the KeyModel.
    @NSManaged public var keyModelUUID: String?
    @NSManaged public var indexModelUUID: String?
}

extension ModelControl : Identifiable {

}
