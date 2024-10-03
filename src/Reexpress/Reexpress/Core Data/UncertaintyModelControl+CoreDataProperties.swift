//
//  UncertaintyModelControl+CoreDataProperties.swift
//  Alpha1
//
//  Created by A on 7/31/23.
//
//

import Foundation
import CoreData


extension UncertaintyModelControl {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UncertaintyModelControl> {
        return NSFetchRequest<UncertaintyModelControl>(entityName: "UncertaintyModelControl")
    }

    @NSManaged public var indexModelUUID: String?
    @NSManaged public var uncertaintyModelUUID: String?
    @NSManaged public var needsRefresh: Bool
    @NSManaged public var qMax: Int //Int64
    @NSManaged public var alpha: Float
    @NSManaged public var validKnownLabelsMinD0: Float
    @NSManaged public var validKnownLabelsMaxD0: Float
    @NSManaged public var conformalThresholdTolerance: Float
    @NSManaged public var qdfCategories: Set<QDFCategoryCD>? //NSSet?
    @NSManaged public var qCategories: Set<QCategoryCD>? //NSSet?

}

// MARK: Generated accessors for qdfCategories
extension UncertaintyModelControl {

    @objc(addQdfCategoriesObject:)
    @NSManaged public func addToQdfCategories(_ value: QDFCategoryCD)

    @objc(removeQdfCategoriesObject:)
    @NSManaged public func removeFromQdfCategories(_ value: QDFCategoryCD)

    @objc(addQdfCategories:)
    @NSManaged public func addToQdfCategories(_ values: Set<QDFCategoryCD>) //NSSet)

    @objc(removeQdfCategories:)
    @NSManaged public func removeFromQdfCategories(_ values: Set<QDFCategoryCD>) //NSSet)

}

// MARK: Generated accessors for qCategories
extension UncertaintyModelControl {

    @objc(addQCategoriesObject:)
    @NSManaged public func addToQCategories(_ value: QCategoryCD)

    @objc(removeQCategoriesObject:)
    @NSManaged public func removeFromQCategories(_ value: QCategoryCD)

    @objc(addQCategories:)
    @NSManaged public func addToQCategories(_ values: Set<QCategoryCD>) //NSSet)

    @objc(removeQCategories:)
    @NSManaged public func removeFromQCategories(_ values: Set<QCategoryCD>) //NSSet)

}

extension UncertaintyModelControl : Identifiable {

}
