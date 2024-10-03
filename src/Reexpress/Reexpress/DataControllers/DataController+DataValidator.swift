//
//  DataController+DataValidator.swift
//  Alpha1
//
//  Created by A on 3/30/23.
//

import Foundation

extension DataController {
    static func isKnownValidLabel(label: Int, numberOfClasses: Int) -> Bool {
        return label >= 0 && label < numberOfClasses

    }
    static func isValidLabel(label: Int, numberOfClasses: Int) -> Bool {
        switch label {
        case 0..<numberOfClasses:
            return true
        case REConstants.DataValidator.unlabeledLabel:
            return true
        case REConstants.DataValidator.oodLabel:
            return true
        default:
            return false
        }
    }
    static func allValidLabelsAsArray(numberOfClasses: Int) -> [Int] {
        var allValidLabels: [Int] = []
        allValidLabels.append(REConstants.DataValidator.oodLabel)
        allValidLabels.append(REConstants.DataValidator.unlabeledLabel)
        for label in 0..<numberOfClasses {
            allValidLabels.append(label)
        }
        return allValidLabels
    }
}
