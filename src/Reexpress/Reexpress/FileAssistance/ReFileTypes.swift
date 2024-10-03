//
//  ReFileTypes.swift
//  Alpha1
//
//  Created by A on 3/9/23.
//

import Foundation
import UniformTypeIdentifiers

extension UTType {
    static var re1ProjectType: UTType {
        UTType(exportedAs: "express.re.re1", conformingTo: .package)
    }

    static var jsonlType: UTType {
        UTType(exportedAs: "express.re.jsonl")
    }
}
