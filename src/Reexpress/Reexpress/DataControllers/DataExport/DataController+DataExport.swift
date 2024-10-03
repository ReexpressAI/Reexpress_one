//
//  DataController+DataExport.swift
//  Alpha1
//
//  Created by A on 9/21/23.
//

import Foundation
import CoreData


extension DataController {
    func exportJSONLabelsToStringLine(dataExportJSONDocument: JSONLabels) throws -> String {
        var exportAsString = ""
        do{
            let encoder = JSONEncoder()
            encoder.outputFormatting = .sortedKeys
            let data = try encoder.encode(dataExportJSONDocument)
            if let dataString = String(data: data, encoding: .utf8) {
                exportAsString = dataString
            }
        } catch {
            throw DocumentExportErrors.exportFailed
        }
        return exportAsString
    }
    
    func exportJSONToStringLine(dataExportJSONDocument: DataExportJSONDocument) throws -> String {
        var exportAsString = ""
        do{
            let encoder = JSONEncoder()
            encoder.outputFormatting = .sortedKeys
            let data = try encoder.encode(dataExportJSONDocument)
            if let dataString = String(data: data, encoding: .utf8) {
                exportAsString = dataString
            }
        } catch {
            throw DocumentExportErrors.exportFailed
        }
        return exportAsString
    }
    // Note that we do not currently check if the probability is up-to-date with the uncertainty model.
    func getProbabilityAsStringForExport_OnlyHighestReliability_NoUncertaintyStateCheck(documentObject: Document) -> String? {
        
        if documentObject.uncertainty?.uncertaintyModelUUID != nil, let qdfCategoryID = documentObject.uncertainty?.qdfCategoryID, let qdfCategory = UncertaintyStatistics.QDFCategory.initQDFCategoryFromIdString(idString: qdfCategoryID) {
            
            if let calibratedOutput = uncertaintyStatistics?.vennADMITCategory_To_CalibratedOutput[qdfCategory], let minDistribution = calibratedOutput?.minDistribution, documentObject.prediction < minDistribution.count, let sizeOfCategory = calibratedOutput?.sizeOfCategory, sizeOfCategory >= 0 {
                let calibrationReliability = UncertaintyStatistics.getRelativeCalibrationReliabilityForVennADMITCategory(vennADMITCategory: qdfCategory, sizeOfCategory: Int(sizeOfCategory))
                if calibrationReliability == .highestReliability {
                    let calibratedProbabilityString: String = REConstants.floatProbToDisplaySignificantDigits(floatProb: minDistribution[documentObject.prediction])
                    return calibratedProbabilityString
                }
            }
        }
        return nil
    }
    func getDataForExport(dataExportState: DataExportState) async throws -> String {
        
        var documentExportStrings: [String] = []
        
        let taskContext = newTaskContext()
        try taskContext.performAndWait {  // be careful with control flow with .perform since it immediately returns (asynchronous)
            let fetchRequest = Document.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "dataset.id == %@", NSNumber(value: dataExportState.datasetId))
            //fetchRequest.propertiesToFetch = ["id", "label"]
            let documentRequest = try taskContext.fetch(fetchRequest)
            if documentRequest.isEmpty {
                throw DocumentExportErrors.noDocumentsFound
            }
            for documentObject in documentRequest {
                if let documentId = documentObject.id {
                    var dataExportJSONDocument = DataExportJSONDocument(id: documentId)
                    if dataExportState.label {
                        dataExportJSONDocument.label = documentObject.label
                    }
                    if dataExportState.prompt {
                        dataExportJSONDocument.prompt = documentObject.prompt
                    }
                    if dataExportState.document {
                        dataExportJSONDocument.document = documentObject.document
                    }
                    if dataExportState.info {
                        dataExportJSONDocument.info = documentObject.info
                    }
                    if dataExportState.group {
                        dataExportJSONDocument.group = documentObject.group
                    }
                    if dataExportState.attributes {
                        if let attributes = documentObject.attributes?.vector?.toArray(type: Float32.self) {
                            dataExportJSONDocument.attributes = attributes
                        }
                    }
                    if dataExportState.prediction {
                        dataExportJSONDocument.prediction = documentObject.prediction
                    }
                    if dataExportState.probability {
                        if let probabilityString = getProbabilityAsStringForExport_OnlyHighestReliability_NoUncertaintyStateCheck(documentObject: documentObject) {
                            dataExportJSONDocument.probability = probabilityString
                        }
                    }
                    let exportedDocumentAsString = try exportJSONToStringLine(dataExportJSONDocument: dataExportJSONDocument)
                    documentExportStrings.append(exportedDocumentAsString)
                }
            }
        }
        
        return documentExportStrings.joined(separator: "\n")
    }
}

