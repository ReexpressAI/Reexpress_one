//
//  DataController+SemanticSearch+IntraDocument.swift
//  Alpha1
//
//  Created by A on 8/31/23.
//

import Foundation
import CoreData
import NaturalLanguage
import Accelerate


extension DataController {
    func getHighlightRangeForSemanticSearch(queryExemplar: [Float32], supportDocumentId: String, idfStructure: (queryIDFRegisters: [Float32], supportIDsToIDFRegisters: [String: [Float32]], queryTokenToIDF: [String: Double], idfRegistersTokens: [String], idfRegistersIDFNorm: [Float32], bm25NormalizationTerm: Double, bm25NormalizationTermLinear: Double), queryDocumentExemplarCompressed: [Float32]) async throws -> Range<String.Index>? {
        
        let featureStructure = try await featureExemplarsAugmentedWithIDFRegisters(supportDocumentId: supportDocumentId, idfStructure: idfStructure)
        //(featureIndexArray: featureIndexArray, flattenedSupport: flattenedSupport)
        // data structures so that we can use the forward index for features method
        var featureIndexToRange: [Int: Range<String.Index>] = [:]
        var supportDocumentIdAndFeatureIndexArray: [(id: String, featureIndex: Int)] = []
        let placeholderID: String = ""
        for (featureIndex, featureRange) in featureStructure.featureIndexArray {
            featureIndexToRange[featureIndex] = featureRange
            supportDocumentIdAndFeatureIndexArray.append((id: placeholderID, featureIndex: featureIndex))
        }
        let matchStructure = try await runForwardIndexForFeatures(queryExemplar: queryExemplar, supportDocumentIdAndFeatureIndexArray: supportDocumentIdAndFeatureIndexArray, supportExemplarsFlattened: featureStructure.flattenedSupport, exemplarDimension: queryExemplar.count)
        if let topMatch = matchStructure.first, let featureRange = featureIndexToRange[topMatch.featureIndex] {
            return featureRange
        }
        return nil
    }
    
    func featureExemplarsAugmentedWithIDFRegisters(supportDocumentId: String, idfStructure: (queryIDFRegisters: [Float32], supportIDsToIDFRegisters: [String: [Float32]], queryTokenToIDF: [String: Double], idfRegistersTokens: [String], idfRegistersIDFNorm: [Float32], bm25NormalizationTerm: Double, bm25NormalizationTermLinear: Double)) async throws -> (featureIndexArray: [(featureIndex: Int, featureRange: Range<String.Index>)], flattenedSupport: [Float32]) {
        
        
        var featureIndexArray: [(featureIndex: Int, featureRange: Range<String.Index>)] = []
        var flattenedSupport: [Float32] = []
        let taskContext = newTaskContext()
        try taskContext.performAndWait {  // be careful with control flow with .perform since it immediately returns (asynchronous)
            let fetchRequest = Document.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", supportDocumentId)
            //fetchRequest.propertiesToFetch = ["id", "document"]
            let documentRequest = try taskContext.fetch(fetchRequest)
            if !documentRequest.isEmpty {
                if let documentObj = documentRequest.first {
                    
                    if let _ = documentObj.id, let sentenceRangeStartVector = documentObj.features?.sentenceRangeStartVector?.toArray(type: Int.self), let sentenceRangeEndVector = documentObj.features?.sentenceRangeEndVector?.toArray(type: Int.self), let startingSentenceArrayIndexOfDocument = documentObj.features?.startingSentenceArrayIndexOfDocument, let sentenceExemplarsCompressed = documentObj.features?.sentenceExemplarsCompressed?.toArray(type: Float32.self) {
                        
                        let documentLevelStructure = (documentWithPrompt: documentObj.documentWithPrompt, prediction: documentObj.prediction, sentenceRangeStartVector: sentenceRangeStartVector, sentenceRangeEndVector: sentenceRangeEndVector, startingSentenceArrayIndexOfDocument: startingSentenceArrayIndexOfDocument, sentenceExemplarsCompressed: sentenceExemplarsCompressed)
                        
                        let docLengths = try getFeatureExemplarAndCorrespondingDocumentText_DocLengths(docLevelStructure: documentLevelStructure)
                        let avgDocLengthForQuery: Double = vDSP.mean(docLengths)
                        let featureStructure = try getFeatureExemplarAndCorrespondingDocumentTextWithAugmentedIDFStructure(docLevelStructure: documentLevelStructure, idfStructure: idfStructure, avgDocLengthForQuery: avgDocLengthForQuery)
                        featureIndexArray = featureStructure.supportDocumentIdAndFeatureIndexArray
                        flattenedSupport = featureStructure.supportExemplarArray
                    }
                }
            }
            
        }
        if Task.isCancelled {
            throw DataSelectionErrors.semanticSearchCancelled
        }
        
        return (featureIndexArray: featureIndexArray, flattenedSupport: flattenedSupport)
    }
    
    func getFeatureExemplarAndCorrespondingDocumentTextWithAugmentedIDFStructure(docLevelStructure: (documentWithPrompt: String, prediction: Int, sentenceRangeStartVector: [Int], sentenceRangeEndVector: [Int], startingSentenceArrayIndexOfDocument: Int, sentenceExemplarsCompressed: [Float32]), idfStructure: (queryIDFRegisters: [Float32], supportIDsToIDFRegisters: [String: [Float32]], queryTokenToIDF: [String: Double], idfRegistersTokens: [String], idfRegistersIDFNorm: [Float32], bm25NormalizationTerm: Double, bm25NormalizationTermLinear: Double), avgDocLengthForQuery: Double ) throws -> (supportExemplarArray: [Float32], supportDocumentIdAndFeatureIndexArray: [(featureIndex: Int, featureRange: Range<String.Index>)]) {
        
        let bm25MaxCeiling: Double = REConstants.SemanticSearch.bm25MaxCeiling
        
        // Construct support of features. Here the rows correspond to each feature/sentence, so we need to maintain a correspondence back to the document id.
        var supportExemplarArray: [Float32] = []  // This is one flat array that will get reshaped when converting to MLShapedArray prior to the forward index.
        var supportDocumentIdAndFeatureIndexArray: [(featureIndex: Int, featureRange: Range<String.Index>)] = []
        //for (supportDocumentId, docLevelStructure) in documentLevelStructureDict {
        //let featureSearchType: FeatureSearchType = .documentOnly  // currently, we only consider the document text when highlighting emphasis from semantic searches
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
        var featureLevelExemplar: [Float32] = Array(docLevelStructure.sentenceExemplarsCompressed[startIndex..<endIndex])
        
        if featureLevelExemplar.isEmpty {
            break
        }
        if featureLevelExemplar.count != REConstants.ModelControl.indexModelDimension {
            throw IndexErrors.exemplarDimensionError
        }
        // Depending on the search intent, we may not include all features:
        var includeFeature = true
        /*switch featureSearchType {
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
        }*/
        if featureIndex < docLevelStructure.startingSentenceArrayIndexOfDocument {
            includeFeature = false
        }
        
        if includeFeature {
            //                    supportExemplarArray.append(contentsOf: featureLevelExemplar)
            if featureIndex < docLevelStructure.sentenceRangeStartVector.count, featureIndex < docLevelStructure.sentenceRangeEndVector.count {
                let featureRange = try getFeatureRangeFromProperties(documentWithPrompt: docLevelStructure.documentWithPrompt, sentenceRangeStart: docLevelStructure.sentenceRangeStartVector[featureIndex], sentenceRangeEnd: docLevelStructure.sentenceRangeEndVector[featureIndex])
                let featureText = String(docLevelStructure.documentWithPrompt[featureRange])
                
                var unnormalizedBM25: Double = 0.0
                //var queryInFeatureText: Set<String> = Set<String>()
                var supportRegister = [Float32](repeating: 0.0, count: idfStructure.idfRegistersIDFNorm.count+2) // final positions are for normalized bm25 exponentional term and linear term
                var i = 0
                for (queryToken, idfNorm) in zip(idfStructure.idfRegistersTokens, idfStructure.idfRegistersIDFNorm) {
                    if let termIDF = idfStructure.queryTokenToIDF[queryToken] {
                        let queryCount = countTokenOccurrencesInDocument(documentTextString: featureText, searchText: queryToken)
                        if queryCount > 0 {
                            supportRegister[i] = idfNorm
                            let bm25 = bm25_oneQueryTerm(idf: termIDF, freq: queryCount, docLength: Double(featureText.count), avgDocLength: avgDocLengthForQuery)
                            unnormalizedBM25 += bm25
                        }
                    }
                    i += 1
                }
                
                let unnormalizedBM25Ceiling = min(bm25MaxCeiling, unnormalizedBM25)
                supportRegister[i] = Float32(exp(unnormalizedBM25Ceiling) / idfStructure.bm25NormalizationTerm)
                i += 1
                if idfStructure.bm25NormalizationTermLinear > 0 {
                    supportRegister[i] = Float32(unnormalizedBM25Ceiling / idfStructure.bm25NormalizationTermLinear + 0.00001)
                } else {
                    supportRegister[i] = 1.0
                }
                featureLevelExemplar.append(contentsOf: supportRegister)
                supportExemplarArray.append(contentsOf: featureLevelExemplar)
                supportDocumentIdAndFeatureIndexArray.append( (featureIndex: featureIndex, featureRange: featureRange) )
            }
        }
        featureIndex += 1
        }
        //}
        // check if empty
        if supportDocumentIdAndFeatureIndexArray.isEmpty {
            throw IndexErrors.noDocumentsFound
        }
        return (supportExemplarArray: supportExemplarArray, supportDocumentIdAndFeatureIndexArray: supportDocumentIdAndFeatureIndexArray)
    }
    
    
    func getFeatureExemplarAndCorrespondingDocumentText_DocLengths(docLevelStructure: (documentWithPrompt: String, prediction: Int, sentenceRangeStartVector: [Int], sentenceRangeEndVector: [Int], startingSentenceArrayIndexOfDocument: Int, sentenceExemplarsCompressed: [Float32]) ) throws -> [Double] {
        // Construct support of features. Here the rows correspond to each feature/sentence, so we need to maintain a correspondence back to the document id.
        //var supportExemplarArray: [Float32] = []  // This is one flat array that will get reshaped when converting to MLShapedArray prior to the forward index.
        //var supportDocumentIdAndFeatureIndexArray: [(featureIndex: Int, featureRange: Range<String.Index>, featureText: String)] = []
        var docLengths: [Double] = []
        //for (supportDocumentId, docLevelStructure) in documentLevelStructureDict {
        let featureSearchType: FeatureSearchType = .documentOnly  // currently, we only consider the document text when highlighting emphasis from semantic searches
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
            //supportExemplarArray.append(contentsOf: featureLevelExemplar)
            if featureIndex < docLevelStructure.sentenceRangeStartVector.count, featureIndex < docLevelStructure.sentenceRangeEndVector.count {
                let featureRange = try getFeatureRangeFromProperties(documentWithPrompt: docLevelStructure.documentWithPrompt, sentenceRangeStart: docLevelStructure.sentenceRangeStartVector[featureIndex], sentenceRangeEnd: docLevelStructure.sentenceRangeEndVector[featureIndex])
                let featureText = docLevelStructure.documentWithPrompt[featureRange]
                docLengths.append(Double(featureText.count))
                //supportDocumentIdAndFeatureIndexArray.append( (featureIndex: featureIndex, featureRange: featureRange, featureText: String(featureText)) )
            }
        }
        featureIndex += 1
    }
        //}
        // check if empty
        //        if supportDocumentIdAndFeatureIndexArray.isEmpty {
        //            throw IndexErrors.noDocumentsFound
        //        }
        return docLengths
    }
}
