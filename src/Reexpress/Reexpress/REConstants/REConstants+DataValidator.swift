//
//  REConstants+DataValidator.swift
//  Alpha1
//
//  Created by A on 9/6/23.
//

import Foundation

extension REConstants {
    struct DataValidator {
        static let unlabeledLabel = -1
        static let oodLabel = -99
        
        static func getDefaultLabelName(label: Int, abbreviated: Bool = false) -> String {
            switch label {
            case unlabeledLabel:
                return "unlabeled"
            case oodLabel:
                if abbreviated {
                    return "OOD"
                } else {
                    return "out-of-distribution (OOD)"
                }
            default:
                return ""
            }
        }
        
        static let maxLabelDisplayNameCharacters = 100
        
        // Max lengths:
        static let maxPromptRawCharacterLength = 250
        static let maxDocumentRawCharacterLength = 5_000
        static let maxIDRawCharacterLength = 250
        static let maxGroupRawCharacterLength = 250
        static let maxInfoRawCharacterLength = 250
        
        static let maxInputAttributeSize = REConstants.KeyModelConstraints.attributesSize
        
        static func parseCommaSeparatedAttributesString(rawUnParsedAttributes: String) -> [Float32] {
            let unParsedAttributes = rawUnParsedAttributes.trimmingCharacters(in: .whitespacesAndNewlines)
            if unParsedAttributes.count > 0 { // This is necessary, since we do not want [0.0] as the default
                let components = unParsedAttributes.components(separatedBy: ",")
                var newAttributes: [Float32] = []
                
                for stringFloat in components[0..<min(components.count, REConstants.KeyModelConstraints.attributesSize)] {
                    let trimmedStringFloat = stringFloat.trimmingCharacters(in: .whitespacesAndNewlines)
                    if let attribute = Float32(trimmedStringFloat), attribute.isFinite {
                        newAttributes.append(attribute)
                    } else {
                        newAttributes.append(0.0)
                    }
                }
                return newAttributes
            } else {
                return []
            }
        }
    }
}
