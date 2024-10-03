//
//  QDFCategoryCD+CoreDataProperties.swift
//  Alpha1
//
//  Created by A on 7/31/23.
//
//

import Foundation
import CoreData


extension QDFCategoryCD {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<QDFCategoryCD> {
        return NSFetchRequest<QDFCategoryCD>(entityName: "QDFCategoryCD")
    }

    @NSManaged public var prediction: Int //Int64
    @NSManaged public var qCategory: Int //Int64
    @NSManaged public var distanceCategory: Int //Int64
    @NSManaged public var compositionCategory: Int //Int64
    @NSManaged public var sizeOfCategory: Int //Int64
    @NSManaged public var predictionProbability: Float32 //Float
    @NSManaged public var id: String?
    @NSManaged public var minDistribution: Data?
    @NSManaged public var uncertaintyModelControl: UncertaintyModelControl?
}

extension QDFCategoryCD : Identifiable {

}
