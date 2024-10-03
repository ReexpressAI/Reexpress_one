//
//  DataController+FeatureSearch.swift
//  Alpha1
//
//  Created by A on 8/6/23.
//

import Foundation
import CoreData
import CoreML
import Accelerate


// Feature (~sentence-level) search using the compressed exemplars

extension DataController {
    
    // Extract the exemplar for a particular feature. This is necessary, since the vectors for all features are stored in a single array. This needs to be called on the main thread since documentObj is a Core Data managed object
    func getFeatureExemplarFromDocumentObject(documentObj: Document, featureIndex: Int) throws -> [Float32]? {
        var featureExemplar: [Float32]?
        if let sentenceExemplarsCompressed = documentObj.features?.sentenceExemplarsCompressed?.toArray(type: Float32.self) {
            let startIndex = featureIndex * REConstants.ModelControl.indexModelDimension
            let endIndex = min(startIndex + REConstants.ModelControl.indexModelDimension, sentenceExemplarsCompressed.count)
            featureExemplar = Array(sentenceExemplarsCompressed[startIndex..<endIndex])
            //print(featureExemplar)
            if (featureExemplar ?? []).count != REConstants.ModelControl.indexModelDimension {
                throw IndexErrors.exemplarDimensionError
            }
        }
        return featureExemplar
    }
    
    func getCompressedExemplarsSupport(queryDocumentId: String, datasetId: Int, moc: NSManagedObjectContext) async throws -> [String: (documentWithPrompt: String, prediction: Int, sentenceRangeStartVector: [Int], sentenceRangeEndVector: [Int], startingSentenceArrayIndexOfDocument: Int, sentenceExemplarsCompressed: [Float32]) ] {
        
        
        let documentLevelStructureDict = try await MainActor.run {
            let fetchRequest = Document.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "dataset.id == %@", NSNumber(value: datasetId))
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Document.id, ascending: true)]

            let documentRequest = try moc.fetch(fetchRequest)
            
            if documentRequest.isEmpty {
                throw CoreDataErrors.retrievalError
            }
            var documentLevelStructureDict: [String: (documentWithPrompt: String, prediction: Int, sentenceRangeStartVector: [Int], sentenceRangeEndVector: [Int], startingSentenceArrayIndexOfDocument: Int, sentenceExemplarsCompressed: [Float32]) ] = [:]
            for documentObj in documentRequest {
                
                if let documentId = documentObj.id, documentId != queryDocumentId, let sentenceRangeStartVector = documentObj.features?.sentenceRangeStartVector?.toArray(type: Int.self), let sentenceRangeEndVector = documentObj.features?.sentenceRangeEndVector?.toArray(type: Int.self), let startingSentenceArrayIndexOfDocument = documentObj.features?.startingSentenceArrayIndexOfDocument, let sentenceExemplarsCompressed = documentObj.features?.sentenceExemplarsCompressed?.toArray(type: Float32.self) {
                    // This needs further processing to break apart the features and the compressed exemplars, but we do that off the main thread.
                    documentLevelStructureDict[documentId] = (documentWithPrompt: documentObj.documentWithPrompt, prediction: documentObj.prediction, sentenceRangeStartVector: sentenceRangeStartVector, sentenceRangeEndVector: sentenceRangeEndVector, startingSentenceArrayIndexOfDocument: startingSentenceArrayIndexOfDocument, sentenceExemplarsCompressed: sentenceExemplarsCompressed)
                }
            }
            return documentLevelStructureDict
        }
        return documentLevelStructureDict
    }
    enum FeatureSearchType: Int, CaseIterable {
        case promptOnly = 1
        case documentOnly = 2
        case documentWithPrompt = 3
    }
    func matchQueryFeatures(featureSearchType: FeatureSearchType, queryCompressedExemplar: [Float32], documentLevelStructureDict: [String: (documentWithPrompt: String, prediction: Int, sentenceRangeStartVector: [Int], sentenceRangeEndVector: [Int], startingSentenceArrayIndexOfDocument: Int, sentenceExemplarsCompressed: [Float32]) ]) async throws -> [(id: String, featureIndex: Int, distance: Float32, documentWithPrompt: String, prediction: Int, featureRange: Range<String.Index>)] { 
        // Construct support of features. Here the rows correspond to each feature/sentence, so we need to maintain a correspondence back to the document id.
        var supportExemplarArray: [Float32] = []  // This is one flat array that will get reshaped when converting to MLShapedArray prior to the forward index.
        var supportDocumentIdAndFeatureIndexArray: [(id: String, featureIndex: Int)] = []
        
        for (supportDocumentId, docLevelStructure) in documentLevelStructureDict {

            if Task.isCancelled {  
                throw MLForwardErrors.forwardPassWasCancelled
            }
            
            if !(docLevelStructure.sentenceRangeStartVector.count == docLevelStructure.sentenceRangeEndVector.count && REConstants.ModelControl.indexModelDimension > 0 && (docLevelStructure.sentenceExemplarsCompressed.count / REConstants.ModelControl.indexModelDimension == docLevelStructure.sentenceRangeEndVector.count ) ) {
                throw IndexErrors.compressedExemplarConcatenatedDimensionError
            }
            var featureIndex = 0
            decomposeExemplarLoop: for chunkIndex in stride(from: 0, to: docLevelStructure.sentenceExemplarsCompressed.count, by: REConstants.ModelControl.indexModelDimension) {
                let startIndex = chunkIndex
                let endIndex = min(startIndex + REConstants.ModelControl.indexModelDimension, docLevelStructure.sentenceExemplarsCompressed.count)
                let featureLevelExemplar: [Float32] = Array(docLevelStructure.sentenceExemplarsCompressed[startIndex..<endIndex])
                
                if featureLevelExemplar.isEmpty {
                    break
                }
                if featureLevelExemplar.count != REConstants.ModelControl.indexModelDimension {
                    throw IndexErrors.exemplarDimensionError
                }
                // Depending on the search intent, we may not include all features:
                var includeFeature = true
                switch featureSearchType {
                case .promptOnly:
                    if featureIndex >= docLevelStructure.startingSentenceArrayIndexOfDocument {
                        break decomposeExemplarLoop
                    }
                case .documentOnly:
                    if featureIndex < docLevelStructure.startingSentenceArrayIndexOfDocument {
                        includeFeature = false
                    }
                case .documentWithPrompt:  // include all
                    break
                }
                if includeFeature {
                    supportExemplarArray.append(contentsOf: featureLevelExemplar)
                    supportDocumentIdAndFeatureIndexArray.append((id: supportDocumentId, featureIndex: featureIndex))
                }
                featureIndex += 1
            }
        }
        // check if empty
        if supportDocumentIdAndFeatureIndexArray.isEmpty {
            throw IndexErrors.noDocumentsFound
        }

        let matchResults = try await runForwardIndexForFeatures(queryExemplar: queryCompressedExemplar, supportDocumentIdAndFeatureIndexArray: supportDocumentIdAndFeatureIndexArray, supportExemplarsFlattened: supportExemplarArray)
        
        var matchStructure: [(id: String, featureIndex: Int, distance: Float32, documentWithPrompt: String, prediction: Int, featureRange: Range<String.Index>)] = []
        for match in matchResults {
            if let docLevelStructure = documentLevelStructureDict[match.id], match.featureIndex < docLevelStructure.sentenceRangeStartVector.count, match.featureIndex < docLevelStructure.sentenceRangeEndVector.count {
                
                
                let featureRange = try getFeatureRangeFromProperties(documentWithPrompt: docLevelStructure.documentWithPrompt, sentenceRangeStart: docLevelStructure.sentenceRangeStartVector[match.featureIndex], sentenceRangeEnd: docLevelStructure.sentenceRangeEndVector[match.featureIndex])
                
                matchStructure.append( (id: match.id, featureIndex: match.featureIndex, distance: match.distance, documentWithPrompt: docLevelStructure.documentWithPrompt, prediction: docLevelStructure.prediction, featureRange: featureRange) )
            }
        }
        return matchStructure
    }
    // Assumes range is in bounds of the text
    func getFeatureRangeFromProperties(documentWithPrompt: String, sentenceRangeStart: Int, sentenceRangeEnd: Int) throws -> Range<String.Index> {
        return String.Index(utf16Offset: sentenceRangeStart, in: documentWithPrompt)..<String.Index(utf16Offset: sentenceRangeEnd, in: documentWithPrompt)
    }
    
    /// In this case, we have already filtered support at the document-level to not include the document from which queryExemplar is derived.
    func runForwardIndexForFeatures(queryExemplar: [Float32], supportDocumentIdAndFeatureIndexArray: [(id: String, featureIndex: Int)], supportExemplarsFlattened: [Float32], exemplarDimension: Int = REConstants.ModelControl.indexModelDimension) async throws -> [(id: String, featureIndex: Int, distance: Float32)] {
        
        var filteredSupportDocumentIdAndFeatureIndexArrayWithDistances: [(id: String, featureIndex: Int, distance: Float32)] = []
        
        //let exemplarDimension = REConstants.ModelControl.indexModelDimension
        if queryExemplar.count != exemplarDimension {
            throw IndexErrors.exemplarDimensionError
        }
        if supportDocumentIdAndFeatureIndexArray.count > REConstants.ModelControl.forwardIndexMaxSupportSize {
            throw IndexErrors.supportMaxSizeError
        }
        
        let minSupportSize = 100  // support must be at least as large as the top k in the IndexOperator model
        let unaugmentedSupportSize = supportDocumentIdAndFeatureIndexArray.count
        let config = MLModelConfiguration()
        // Directly set cpu and gpu, as we want GPU on the targeted M1 Max and better with Float32, as opposed to the ANE
        config.computeUnits = .cpuAndGPU
        
        let model = try await IndexOperator100.load(configuration: config)
        
        var supportMLShapedArray = MLShapedArray<Float32>(scalars: supportExemplarsFlattened, shape: [supportDocumentIdAndFeatureIndexArray.count, exemplarDimension])
        if unaugmentedSupportSize < minSupportSize {
            // fill with zeros:
            let extendedSupport = MLShapedArray<Float32>(repeating: 0.0, shape: [minSupportSize-unaugmentedSupportSize, exemplarDimension])
            supportMLShapedArray = MLShapedArray<Float32>(concatenating: [supportMLShapedArray, extendedSupport], alongAxis: 0)
        }
        
        let queryMLShapedArray = MLShapedArray<Float32>(scalars: queryExemplar, shape: [1, exemplarDimension])
        let output = try model.prediction(query: queryMLShapedArray, support: supportMLShapedArray)
        let topKdistances = output.topKDistancesShapedArray.scalars  // Float32
        let topKIndexes = output.topKDistancesIdxShapedArray.scalars  // Int32 -- these get converted to document id's (String) below
        for matchIndex in 0..<topKdistances.count {
            let indexIntoSupport = Int(topKIndexes[matchIndex])
            if indexIntoSupport < unaugmentedSupportSize {  // otherwise, must be an augmented padding index
                filteredSupportDocumentIdAndFeatureIndexArrayWithDistances.append( (id: supportDocumentIdAndFeatureIndexArray[indexIntoSupport].id, featureIndex: supportDocumentIdAndFeatureIndexArray[indexIntoSupport].featureIndex, distance: topKdistances[matchIndex]) )
            }
        }
        return filteredSupportDocumentIdAndFeatureIndexArrayWithDistances
    }
}
