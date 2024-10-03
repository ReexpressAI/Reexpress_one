//
//  Features+CoreDataProperties.swift
//  Alpha1
//
//  Created by A on 7/28/23.
//
//

import Foundation
import CoreData


extension Features {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Features> {
        return NSFetchRequest<Features>(entityName: "Features")
    }

    @NSManaged public var sentenceRangeStartVector: Data?  // Unlike most other Data properties (which are Float32), this is stored as an Int
    @NSManaged public var sentenceRangeEndVector: Data?  // Unlike most other Data properties (which are Float32), this is stored as an Int
    @NSManaged public var startingSentenceArrayIndexOfDocument: Int //Int64
    @NSManaged public var sentenceExemplarsCompressed: Data?
    @NSManaged public var document: Document?

}

extension Features : Identifiable {

}
