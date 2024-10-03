//
//  DataExportState.swift
//  Alpha1
//
//  Created by A on 9/21/23.
//

import Foundation

struct DataExportState {
    var datasetId: Int = 0
    var id: Bool = true
    //var uncertaintyModelUUID: Bool = true
    
    var label: Bool = false
    var document: Bool = false
    
    // optional fields
    var info: Bool = false
    var attributes: Bool = false

    var prompt: Bool = false
    var group: Bool = false
    
    var prediction: Bool = false
    var probability: Bool = false
}
struct DataExportJSONDocument: Codable, Identifiable {
    let id: String
    var label: Int?
    var document: String?
    
    // optional fields
    var info: String?
    var attributes: [Float32]?
    
    var prompt: String?
    var group: String?
    var prediction: Int?
    var probability: String?
}
