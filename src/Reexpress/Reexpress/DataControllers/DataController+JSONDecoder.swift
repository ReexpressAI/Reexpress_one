//
//  DataController+JSONDecoder.swift
//  Alpha1
//
//  Created by A on 3/20/23.
//

import Foundation


struct JSONDocument: Codable, Identifiable {  // change this to DocumentJSON
    let id: String
    let label: Int
    var document: String
    
    // optional fields
    let info: String?
    let attributes: [Float32]?
    
    var prompt: String?
    // optional for binary/multi-class classification, but required for QA classification
    let group: String?
    
    // the following fields may exist in the JSON on an export and then re-import
    //let prediction: Int?
    //let modified: Bool?
    
    // MARK: TODO: May need additional fields to ensure that exported fields can be re-imported.
}


extension DataController {

    func validateJSONDocument(aJSONDocument: JSONDocument, zeroIndexedLineCounter: Int) throws {
        
        if aJSONDocument.id.count > REConstants.DataValidator.maxIDRawCharacterLength {
            throw GeneralFileErrors.documentMaxIDRawCharacterLength(errorIndexEstimate: zeroIndexedLineCounter)
        }
        
        if !DataController.isValidLabel(label: aJSONDocument.label, numberOfClasses: numberOfClasses) {
            throw GeneralFileErrors.documentLabelFormat(errorIndexEstimate: zeroIndexedLineCounter)
        }
        
        if aJSONDocument.document.count > REConstants.DataValidator.maxDocumentRawCharacterLength {
            throw GeneralFileErrors.documentMaxDocumentRawCharacterLength(errorIndexEstimate: zeroIndexedLineCounter)
        }
        
        // Optional fields:
        if let info = aJSONDocument.info, info.count > REConstants.DataValidator.maxInfoRawCharacterLength {
            throw GeneralFileErrors.documentMaxInfoRawCharacterLength(errorIndexEstimate: zeroIndexedLineCounter)
        }
        if let attributes = aJSONDocument.attributes, attributes.count > REConstants.DataValidator.maxInputAttributeSize {
            throw GeneralFileErrors.documentMaxInputAttributeSize(errorIndexEstimate: zeroIndexedLineCounter)
        }
        if let prompt = aJSONDocument.prompt, prompt.count > REConstants.DataValidator.maxPromptRawCharacterLength {
            throw GeneralFileErrors.documentMaxPromptRawCharacterLength(errorIndexEstimate: zeroIndexedLineCounter)
        }
        if let group = aJSONDocument.group, group.count > REConstants.DataValidator.maxGroupRawCharacterLength {
            throw GeneralFileErrors.documentMaxGroupRawCharacterLength(errorIndexEstimate: zeroIndexedLineCounter)
        }
    }
    
    
    func readJSONLinesDocumentWithPrompt(documentURL: URL?, defaultPrompt: String) async throws -> [JSONDocument] { 
        guard let url = documentURL else {
            throw GeneralFileErrors.noFileFound
        }
        
        let attribute = try FileManager.default.attributesOfItem(atPath: url.path)
        if let size = attribute[FileAttributeKey.size] as? NSNumber {
            let sizeInMB = size.doubleValue / 1000000.0
//                            print("Size: \(sizeInMB)")
            //                await MainActor.run {
            //                    estimatedTotalLines = (1_000_000.0 / 4655.778154) * sizeInMB // upper, assuming 4k character documents, blank group, short info
            //                    //print("Estimated total lines: \(estimatedTotalLines)")
            //                }
            if sizeInMB > REConstants.DatasetsConstraints.maxFileSize {
                throw GeneralFileErrors.maxFileSize
            }
        } else {
            throw GeneralFileErrors.noFileFound
        }
        
        var jsonDocumentArray = [JSONDocument]()
        var counter = 0
        for try await line in url.lines {
            counter += 1
            if counter > REConstants.DatasetsConstraints.maxTotalLines {
                throw GeneralFileErrors.maxTotalLinesInASingleJSONLinesFileLimit
            }
            if let lineAsData = line.data(using: .utf8) {
                if Task.isCancelled {
                    break
                }
                do {
                    var oneDocument = try decoder.decode(JSONDocument.self, from: lineAsData)
                    try validateJSONDocument(aJSONDocument: oneDocument, zeroIndexedLineCounter: counter-1) // indexed by 0
                    // Simple: If user provides a prompt field in the JSON, we use that field (even if empty). Otherwise, we use the default prompt, which may be empty.
                    if oneDocument.prompt == nil {
                        oneDocument.prompt = defaultPrompt
                    }
                    /*if let userProvidedPrompt = oneDocument.prompt {
                        // use the provided prompt
                    } else {
                        oneDocument.prompt = defaultPrompt
                    }*/
                    
                    // If there is a user provided prompt, and non-empty
                    /*if let userProvidedPrompt = oneDocument.prompt, !userProvidedPrompt.isEmpty {
                        // use the provided prompt
                    } else {
                        if !defaultPrompt.isEmpty {
                            oneDocument.prompt = defaultPrompt
//                            oneDocument.document = prompt + " " + oneDocument.document
                        }
                    }*/
                    jsonDocumentArray.append(oneDocument)
                // We rethrow here so that we still catch a general line error in the default (as from decoder.decode)
                } catch GeneralFileErrors.documentMaxIDRawCharacterLength(let errorIndexEstimate) {
                    throw GeneralFileErrors.documentMaxIDRawCharacterLength(errorIndexEstimate: errorIndexEstimate)
                } catch GeneralFileErrors.documentLabelFormat(let errorIndexEstimate) {
                    throw GeneralFileErrors.documentLabelFormat(errorIndexEstimate: errorIndexEstimate)
                } catch GeneralFileErrors.documentMaxDocumentRawCharacterLength(let errorIndexEstimate) {
                    throw GeneralFileErrors.documentMaxDocumentRawCharacterLength(errorIndexEstimate: errorIndexEstimate)
                } catch GeneralFileErrors.documentMaxInfoRawCharacterLength(let errorIndexEstimate) {
                    throw GeneralFileErrors.documentMaxInfoRawCharacterLength(errorIndexEstimate: errorIndexEstimate)
                } catch GeneralFileErrors.documentMaxInputAttributeSize(let errorIndexEstimate) {
                    throw GeneralFileErrors.documentMaxInputAttributeSize(errorIndexEstimate: errorIndexEstimate)
                } catch GeneralFileErrors.documentMaxPromptRawCharacterLength(let errorIndexEstimate) {
                    throw GeneralFileErrors.documentMaxPromptRawCharacterLength(errorIndexEstimate: errorIndexEstimate)
                } catch GeneralFileErrors.documentMaxGroupRawCharacterLength(let errorIndexEstimate) {
                    throw GeneralFileErrors.documentMaxGroupRawCharacterLength(errorIndexEstimate: errorIndexEstimate)
                } catch {
                    throw GeneralFileErrors.documentFileFormatAtIndexEstimate(errorIndexEstimate: counter-1)  // indexed by 0
//                    throw GeneralFileErrors.documentFileFormat
                }
            } else {
                throw GeneralFileErrors.documentFileFormatAtIndexEstimate(errorIndexEstimate: counter-1)
            }
        }

        return jsonDocumentArray 
        
    }
    func readAsyncWithPrompt(documentURL: URL?, defaultPrompt: String) async throws -> [JSONDocument] {
        
        return try await self.readJSONLinesDocumentWithPrompt(documentURL: documentURL, defaultPrompt: defaultPrompt)
        
        
    }
}
