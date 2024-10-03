//
//  DataController+JSONDecoder+ForLabels.swift
//  Alpha1
//
//  Created by A on 7/17/23.
//

import Foundation
import CoreData


struct JSONLabels: Codable, Identifiable, Hashable {
    var id: Int { label }
    let label: Int
    let name: String
}


extension DataController {
    /// Validation. Consider further limiting length of fields
    func validateJSONLabelsFile(aJSONDocument: JSONLabels, labelsToNameDictionary: [Int: String], indexCounter: Int) throws {
        if aJSONDocument.label > numberOfClasses - 1  || aJSONDocument.label < 0 {
            throw GeneralFileErrors.outOfRangeLabel(errorIndexEstimate: indexCounter)
        }
        if aJSONDocument.name.count > REConstants.DataValidator.maxLabelDisplayNameCharacters {
            throw GeneralFileErrors.labelDisplayNameIsTooLong(errorIndexEstimate: indexCounter)
        }
        if aJSONDocument.name.isEmpty {
            throw GeneralFileErrors.blankLabelDisplayName(errorIndexEstimate: indexCounter)
        }
        if let _ = labelsToNameDictionary[aJSONDocument.label] {
            throw GeneralFileErrors.duplicateLabelsEncountered(errorIndexEstimate: indexCounter)
        }
    }

    
    func readJSONLinesLabelsFile(documentURL: URL?) async throws -> [Int: String] {
        guard let url = documentURL else {
            throw GeneralFileErrors.noFileFound
        }
        
        let attribute = try FileManager.default.attributesOfItem(atPath: url.path)
        if let size = attribute[FileAttributeKey.size] as? NSNumber {
            let sizeInMB = size.doubleValue / 1000000.0

            if sizeInMB > REConstants.DatasetsConstraints.maxJSONLabelsFileSize {
                throw GeneralFileErrors.maxFileSize
            }
        } else {
            throw GeneralFileErrors.noFileFound
        }

        var updatedLabelsToName: [Int: String] = [:]
        var counter = 0
        for try await line in url.lines {
            counter += 1
            if let lineAsData = line.data(using: .utf8) {
                if Task.isCancelled {
                    break
                }
                    let oneDocument = try decoder.decode(JSONLabels.self, from: lineAsData)
                    try validateJSONLabelsFile(aJSONDocument: oneDocument, labelsToNameDictionary: updatedLabelsToName, indexCounter: counter-1)

                    updatedLabelsToName[oneDocument.label] = oneDocument.name

            } else {
                throw GeneralFileErrors.documentFileFormatAtIndexEstimate(errorIndexEstimate: counter-1)
            }
        }
        return updatedLabelsToName
        
    }
    func readLabelsFileAsyncWithPrompt(documentURL: URL?) async throws -> [Int: String] {
        return try await self.readJSONLinesLabelsFile(documentURL: documentURL)
    }
    
    /// Data validation should already be applied to updatedLabelsToName before calling this method.
    func updateDatabaseWithLabelDisplayNames(updatedLabelsToName: [Int: String], moc: NSManagedObjectContext) async throws {
        try await MainActor.run {
            let fetchRequest = LabelName.fetchRequest()
            let results = try moc.fetch(fetchRequest)
            for labelNameManagedObject in results {
                // Check if the label is one to be updated. Note that the actual raw label value is not updatable here. (The number of labels stays constant for the lifetime of a project.) Note, too, that the user need not update all labels.
                if let updatedDisplayName = updatedLabelsToName[labelNameManagedObject.label] {
                    labelNameManagedObject.userSpecifiedName = updatedDisplayName
                }
            }
            do {
                if moc.hasChanges {
                    try moc.save()
                    // Update in memory copy
                    for label in updatedLabelsToName.keys {
                        /// labelToName is a property on DataController
                        if let _ = labelToName[label] {
                            labelToName[label] = updatedLabelsToName[label]
                        }
                    }
                }
            } catch {
                throw CoreDataErrors.saveError
            }
        }
    }
}
