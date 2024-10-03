//
//  DataController+DisplayUtilities.swift
//  Alpha1
//
//  Created by A on 6/15/23.
//

import Foundation

extension DataController {
    func getDatasplitNameForDisplay(datasetId: Int) -> String {
        var datasplitName = ""
        if let dataset = inMemory_Datasets[datasetId] {
            if let datasetName = dataset.userSpecifiedName {
                datasplitName = datasetName
            } else {
                datasplitName = "\(dataset.internalName) (\(dataset.id))"
            }
        }
        return datasplitName
    }
}

