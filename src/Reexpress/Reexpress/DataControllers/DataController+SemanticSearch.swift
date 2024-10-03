//
//  DataController+SemanticSearch.swift
//  Alpha1
//
//  Created by A on 8/25/23.
//

import Foundation
import CoreData
import NaturalLanguage
import Accelerate

// MARK: TODO don't forget to append attributes
extension DataController {
    struct UniqueTokens: Identifiable {
        var id: UUID = UUID()
        var original: String
        var tokenized: String
    }
    // This version also returns an array with the de-duplicated (but un-lowercased) tokens to present to the user
    func tokenizeQueryTokensForSemanticSearchUpToMaxViaTaggerWithArray(text: String, tagger: NLTagger, options: NLTagger.Options) async -> [UniqueTokens] { //[(original: String, tokenized: String)]) {
        var lowercasedTokens = Set<String>()
        var tokensStructureArray: [UniqueTokens] = [] //[(original: String, tokenized: String)] = []
        tagger.string = text

        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass, options: options) { _, tokenRange in
            let wordToken = String(text[tokenRange]).lowercased()
            if !lowercasedTokens.contains(wordToken) { // de-duplicated
                tokensStructureArray.append(.init(original: String(text[tokenRange]), tokenized: wordToken))
            }
            lowercasedTokens.insert(wordToken)
            
            if lowercasedTokens.count >= REConstants.SemanticSearch.maxTokensForTagger {
                return false
            } else {
                return true
            }
        }
        return tokensStructureArray
    }
    // lower-cased, no whitespace, no punctuation
    func getQueryTokensForSemanticSearchWithArray(searchText: String) async -> [UniqueTokens] {
        let wordTokenizer = NLTagger(tagSchemes: [.lexicalClass])
        let tokenizerOptions: NLTagger.Options = [.omitWhitespace, .omitPunctuation]
        return await tokenizeQueryTokensForSemanticSearchUpToMaxViaTaggerWithArray(text: searchText, tagger: wordTokenizer, options: tokenizerOptions)
    }
    
    func tokenizeQueryTokensForSemanticSearchUpToMaxViaTagger(text: String, tagger: NLTagger, options: NLTagger.Options) async -> Set<String> {
        var lowercasedTokens = Set<String>()
        tagger.string = text

        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass, options: options) { _, tokenRange in
            let wordToken = String(text[tokenRange]).lowercased()
            lowercasedTokens.insert(wordToken)
            if lowercasedTokens.count >= REConstants.SemanticSearch.maxTokensForTagger {
                return false
            } else {
                return true
            }
        }
        return lowercasedTokens
    }
    // lower-cased, no whitespace, no punctuation
    func getQueryTokensForSemanticSearch(searchText: String) async -> Set<String> {
        let wordTokenizer = NLTagger(tagSchemes: [.lexicalClass])
        let tokenizerOptions: NLTagger.Options = [.omitWhitespace, .omitPunctuation]
        return await tokenizeQueryTokensForSemanticSearchUpToMaxViaTagger(text: searchText, tagger: wordTokenizer, options: tokenizerOptions)
    }
    
    func semanticSearchGetSupportIds(documentSelectionState: DocumentSelectionState, moc: NSManagedObjectContext) async throws -> Set<String> {
        //try await getCountResult(datasetId: datasetId, moc: moc)
        let documentRequestResult = try await MainActor.run {
            //var documentIdToIndex: [String: Int] = [:]
            
            // Another fecth to update the documents count. We re-fetch, because it is possible the user has uploaded duplicates.
            let fetchRequest = Document.fetchRequest()
            let compoundPredicate = try getFetchPredicateBasedOnDocumentSelectionState(documentSelectionState: documentSelectionState, moc: moc)
 
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: compoundPredicate)
                        
            fetchRequest.propertiesToFetch = ["id"]
            let documentRequest = try moc.fetch(fetchRequest)
            
            if documentRequest.isEmpty {
                throw DataSelectionErrors.noDocumentsFound
            }
            var supportDocumentIds = Set<String>()
            
            for i in 0..<documentRequest.count {
                if let id = documentRequest[i].id {
                    supportDocumentIds.insert(id)
                }
            }
            
            return supportDocumentIds
        }
        return documentRequestResult
    }
    // should still return if no exact token matches
    func semanticSearch(documentSelectionState: DocumentSelectionState, moc: NSManagedObjectContext) async throws -> (retrievedDocumentIDs: [String], retrievedDocumentIDs2HighlightRanges: [String: Range<String.Index>], retrievedDocumentIDs2DocumentLevelSearchDistances: [String: Float32]) {

        if !isModelTrainedandIndexed() {
            if inMemory_KeyModelGlobalControl.modelWeights == nil {
                throw KeyModelErrors.keyModelWeightsMissing
            }
            if inMemory_KeyModelGlobalControl.indexModelWeights == nil {
                throw KeyModelErrors.indexModelWeightsMissing
            }
            throw KeyModelErrors.compressionNotCurrent
        }
        // get support ids -- main queue
        let supportDocumentIds = try await semanticSearchGetSupportIds(documentSelectionState: documentSelectionState, moc: moc)
        
        if Task.isCancelled {
            throw DataSelectionErrors.semanticSearchCancelled
        }
        if documentSelectionState.semanticSearchParameters.searchText.isEmpty {
            throw DataSelectionErrors.semanticSearchMissingTokens
        }
        // get query tokens. There could be 0 processed tokens, but still characters in the searchText. We allow this case (no idf scores)
        let lowercasedTokens = await getQueryTokensForSemanticSearch(searchText: documentSelectionState.semanticSearchParameters.searchText)
        //var idfScoresPresent = false
        //var idfStructure: (queryIDFRegisters: [Float32], supportIDsToIDFRegisters: [String: [Float32]]) = (queryIDFRegisters: [], supportIDsToIDFRegisters: [:])
//        print("lowercasedTokens: \(lowercasedTokens)")
        if lowercasedTokens.count > 0 && supportDocumentIds.count > 0 {
            var tokensToEmphasize = Set<String>()
            if documentSelectionState.semanticSearchParameters.emphasizeSelectTokens && !documentSelectionState.semanticSearchParameters.tokensToEmphasize.isEmpty {
                tokensToEmphasize = documentSelectionState.semanticSearchParameters.tokensToEmphasize
            }
            let idfStructure = try await getIDFScores(queryTokens: lowercasedTokens, supportDocumentIds: supportDocumentIds, tokensToEmphasize: tokensToEmphasize)
            //                (queryIDFRegisters: idfRegistersIDFNorm, supportIDsToIDFRegisters: supportIDsToIDFRegisters)
            
            if Task.isCancelled {
                throw DataSelectionErrors.semanticSearchCancelled
            }
            // tokenize and run forward on search text (including the prompt and attributes)
            var queryDocumentExemplarCompressed = try await mainForwardSemanticSearch(documentSelectionState: documentSelectionState)
            //var queryDocumentExemplarCompressed = [Float32](repeating: 0.0, count: 32)
            queryDocumentExemplarCompressed.append(contentsOf: idfStructure.queryIDFRegisters)
            
            
            let supportIDsToExemplarsWithIDFRegisters = try await getCompressedGlobaExemplarsSupportWithRetrievalRegisters(supportIDsToIDFRegisters: idfStructure.supportIDsToIDFRegisters, expectedDimension: queryDocumentExemplarCompressed.count)
            // data structures so that we can use the forward index for features method
            var supportExemplarsFlattened: [Float32] = []
            var supportDocumentIdAndFeatureIndexArray: [(id: String, featureIndex: Int)] = []
            let placeholderFeatureIndex: Int = 0
            for (supportId, supportExemplar) in supportIDsToExemplarsWithIDFRegisters {
                supportExemplarsFlattened.append(contentsOf: supportExemplar)
                supportDocumentIdAndFeatureIndexArray.append((id: supportId, featureIndex: placeholderFeatureIndex))
            }
            let matchStructure = try await runForwardIndexForFeatures(queryExemplar: queryDocumentExemplarCompressed, supportDocumentIdAndFeatureIndexArray: supportDocumentIdAndFeatureIndexArray, supportExemplarsFlattened: supportExemplarsFlattened, exemplarDimension: queryDocumentExemplarCompressed.count)// async throws -> [(id: String, featureIndex: Int, distance: Float32)]
            //print(matchStructure[0])
//            print("------")
//            print("Query idf: \(idfStructure.queryIDFRegisters)")
            /*var matchStructureReranked: [(id: String, featureIndex: Int, distance: Float32)] = []
            for matchStructureIndex in 0..<(matchStructure.count) {
                let supportDocumentMatchStructure = matchStructure[matchStructureIndex]
                var bm25LinearTermRenormed: Float32 = 1.0
                if let registers = idfStructure.supportIDsToIDFRegisters[supportDocumentMatchStructure.id], let bm25LinearTerm = registers.last {
                    bm25LinearTermRenormed = bm25LinearTerm
                }
                
                matchStructureReranked.append((id: supportDocumentMatchStructure.id, featureIndex: 0, distance: supportDocumentMatchStructure.distance * bm25LinearTermRenormed))
//                let k = matchStructure[ki]
//                if ki < 20 {}
//                print("+++")
//                //print("Index: \(k)")
//                print("Distance: \(k.distance)")
//                if let registers = idfStructure.supportIDsToIDFRegisters[k.id] {
//                    print(registers)
//                }
            }
            
            let matchStructureRerankedSorted = matchStructureReranked.sorted { $0.distance < $1.distance }*/
//            let retrievedDocumentIDs = matchStructureRerankedSorted.map { $0.id }
            var retrievedDocumentIDs2DocumentLevelSearchDistances: [String: Float32] = [:]
            var retrievedDocumentIDs: [String] = []
//            let retrievedDocumentIDs = matchStructure.map { $0.id }
            for oneDocumentMatch in matchStructure {
                retrievedDocumentIDs.append(oneDocumentMatch.id)
                // also record the document-level semantic search distance for display:
                retrievedDocumentIDs2DocumentLevelSearchDistances[oneDocumentMatch.id] = oneDocumentMatch.distance
            }
            
            var retrievedDocumentIDs2HighlightRanges: [String: Range<String.Index>] = [:]
            
            if retrievedDocumentIDs.count > 0 {
                // now get intra-document highlights
                if Task.isCancelled {
                    throw DataSelectionErrors.semanticSearchCancelled
                }
                for retrievedSupportDocumentID in retrievedDocumentIDs {
                    if let highlightRange = try await getHighlightRangeForSemanticSearch(queryExemplar: queryDocumentExemplarCompressed, supportDocumentId: retrievedSupportDocumentID, idfStructure: idfStructure, queryDocumentExemplarCompressed: queryDocumentExemplarCompressed) {
                        retrievedDocumentIDs2HighlightRanges[retrievedSupportDocumentID] = highlightRange
                    }
                }
                return (retrievedDocumentIDs: retrievedDocumentIDs, retrievedDocumentIDs2HighlightRanges: retrievedDocumentIDs2HighlightRanges, retrievedDocumentIDs2DocumentLevelSearchDistances: retrievedDocumentIDs2DocumentLevelSearchDistances)
            }
        }
        throw DataSelectionErrors.semanticSearchMissingTokens

        
        
        //print(idfStructure.queryIDFRegisters)
        //print(idfStructure.supportIDsToIDFRegisters.first)
        //print(lowercasedTokens)
            // get idf
            // normalize idf
            // get compressed exemplars + concatenated attributes (if applicable; always 0 for query)
            // append normalized idf
            //search
        
    }
//    struct SemanticSearchIDFRegister {
//        var idfRegistersTokens: [String]
//        var idfRegistersIDFNorm: [Float32]
//        init(registerSize: Int) {
//            var idfRegistersTokens: [String]
//            var idfRegistersIDFNorm: [Float32]
//        }
//    }
    func idf(N: Double, n: Double) -> Double {
        return max(0, log((N-n+0.5)/(n+0.5)+1))
    }
    func bm25_oneQueryTerm(idf: Double, freq: Double, docLength: Double, avgDocLength: Double, k1: Double = 1.2, b: Double = 0.75) -> Double {
        let avgDocLength0Check = max(1, avgDocLength)
        let numerator = freq * (k1+1)
        let denominator = freq + k1*(1-b + b * (docLength/avgDocLength0Check))
        return idf * (numerator/denominator)
    }
    func getIDFScores(queryTokens: Set<String>, supportDocumentIds: Set<String>, tokensToEmphasize: Set<String>) async throws -> (queryIDFRegisters: [Float32], supportIDsToIDFRegisters: [String: [Float32]], queryTokenToIDF: [String: Double], idfRegistersTokens: [String], idfRegistersIDFNorm: [Float32], bm25NormalizationTerm: Double, bm25NormalizationTermLinear: Double) {
        if queryTokens.count == 0 || supportDocumentIds.count == 0 {
            return (queryIDFRegisters: [], supportIDsToIDFRegisters: [:], queryTokenToIDF: [:], idfRegistersTokens: [], idfRegistersIDFNorm: [], bm25NormalizationTerm: 1.0, bm25NormalizationTermLinear: 1.0)
        }
        let bm25MaxCeiling: Double = REConstants.SemanticSearch.bm25MaxCeiling // 50.0
        let queryTokensArray = Array(queryTokens)
        let supportDocumentIdsArray = Array(supportDocumentIds)
        let supportSizeDouble = Double(supportDocumentIdsArray.count)
        let idfNormalizationTerm: Double = exp(idf(N: supportSizeDouble, n: 1))
        
        var queryTokenToIDFNormDouble = [String: Double]()
        var nonzeroQueryToSupportIDs = [String: Set<String>]()
        var supportIDsToUnnormalizedBM25: [String: Double] = [:] // streaming addition
        
        var queryTokenToIDF = [String: Double]()  // Needed for generating estimates over new texts (e.g., intra-document)

        let taskContext = newTaskContext()
        try taskContext.performAndWait {  // be careful with control flow with .perform since it immediately returns (asynchronous)
            //try await taskContext.perform {
            for queryToken in queryTokensArray {
                let fetchRequest = Document.fetchRequest()
                var compoundPredicate: [NSPredicate] = []
                compoundPredicate.append(NSPredicate(format: "id in %@", supportDocumentIdsArray))
                compoundPredicate.append(NSPredicate(format: "document CONTAINS[cd] %@", queryToken))
                fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: compoundPredicate)
                fetchRequest.propertiesToFetch = ["id", "document"]
                let documentRequest = try taskContext.fetch(fetchRequest)
                //let tokenCount = try taskContext.count(for: fetchRequest)
                let tokenCount = documentRequest.count
                if tokenCount > 0 {
                    var termIDF = idf(N: supportSizeDouble, n: Double(tokenCount))
                    queryTokenToIDFNormDouble[queryToken] = exp(termIDF) / idfNormalizationTerm
                    //nonzeroQueryToSupportIDs[queryToken] = Set<String>(documentRequest.compactMap { $0.id })  // fold below to avoid extraneous loop
                    if !tokensToEmphasize.isEmpty && tokensToEmphasize.contains(queryToken) {
                        // boost the normed value (this is a big jump, since normally in [0,1]
                        queryTokenToIDFNormDouble[queryToken] = ((queryTokenToIDFNormDouble[queryToken] ?? 1.0) + 1.0) * REConstants.SemanticSearch.emphasisMultiplicativeFactor
                        // boost the raw idf (final bm25 will still be in [0,1]
                        termIDF = (termIDF + 1.0) * REConstants.SemanticSearch.emphasisMultiplicativeFactor
                    }
                    queryTokenToIDF[queryToken] = termIDF
                    nonzeroQueryToSupportIDs[queryToken] = Set<String>()
                    
                    var docLengths: [Double] = []
                    var idToDocLengths: [String: Double] = [:]
                    for documentObject in documentRequest {
                        if let documentID = documentObject.id, let document = documentObject.document {
                            nonzeroQueryToSupportIDs[queryToken]?.insert(documentID)
                            let docCount = Double(document.count)
                            docLengths.append(docCount)
                            idToDocLengths[documentID] = docCount
                        }
                    }
                    let avgDocLengthForQuery: Double = vDSP.mean(docLengths)  // here, local to query; character count rather than tokens
                    for documentObject in documentRequest {
                        if let documentID = documentObject.id, let document = documentObject.document {
                            let queryCount = countTokenOccurrencesInDocument(documentTextString: document, searchText: queryToken)
                            let bm25 = bm25_oneQueryTerm(idf: termIDF, freq: queryCount, docLength: idToDocLengths[documentID] ?? 0.0, avgDocLength: avgDocLengthForQuery)
                            if let _ = supportIDsToUnnormalizedBM25[documentID] {
                                supportIDsToUnnormalizedBM25[documentID]? += bm25
                            } else { //init
                                supportIDsToUnnormalizedBM25[documentID] = bm25
                            }
                        }
                    }
                }
            }
        }
        if Task.isCancelled {
            throw DataSelectionErrors.semanticSearchCancelled
        }
        let queryTokenToIDFNormDouble_Sorted = queryTokenToIDFNormDouble.sorted { $0.1 > $1.1 }
        var idfRegistersTokens: [String] = []
        var idfRegistersIDFNorm: [Float32] = []

        for sortedPairs in Array(queryTokenToIDFNormDouble_Sorted[0..<min(REConstants.SemanticSearch.maxQueryTokens, queryTokenToIDFNormDouble_Sorted.count)]) {
            idfRegistersTokens.append(sortedPairs.key)
            idfRegistersIDFNorm.append(Float32(sortedPairs.value))
        }
        var supportIDsToIDFRegisters: [String: [Float32]] = [:]
        
        var bm25NormalizationTerm: Double = 1.0
        var bm25NormalizationTermLinear: Double = 1.0
        if var bm25Max = supportIDsToUnnormalizedBM25.values.max() {
            bm25Max = min(bm25MaxCeiling, bm25Max)
            bm25NormalizationTerm = exp(bm25Max)
            bm25NormalizationTermLinear = bm25Max
        }
        for supportID in supportDocumentIdsArray {
            var supportRegister = [Float32](repeating: 0.0, count: idfRegistersIDFNorm.count+2) // final positions are for normalized bm25 exponentional term and linear term
            var i = 0
            for (queryToken, idfNorm) in zip(idfRegistersTokens, idfRegistersIDFNorm) {
                if let coveredSupportIDs = nonzeroQueryToSupportIDs[queryToken], coveredSupportIDs.contains(supportID) {
                    supportRegister[i] = idfNorm
                }
                i += 1
            }
            if let unnormalizedBM25 = supportIDsToUnnormalizedBM25[supportID] {
                let unnormalizedBM25Ceiling = min(bm25MaxCeiling, unnormalizedBM25)
                supportRegister[i] = Float32(exp(unnormalizedBM25Ceiling) / bm25NormalizationTerm)
                i += 1
                if bm25NormalizationTermLinear > 0 {
                    supportRegister[i] = Float32(unnormalizedBM25Ceiling / bm25NormalizationTermLinear + 0.00001)
                } else {
                    supportRegister[i] = 1.0
                }
//                // temp overwrite exponential term:
//                if bm25NormalizationTermLinear > 0 {
//                    supportRegister[i-1] = Float32(unnormalizedBM25Ceiling / bm25NormalizationTermLinear + 0.00001)
//                } else {
//                    supportRegister[i-1] = 1.0
//                }
            }
            supportIDsToIDFRegisters[supportID] = supportRegister
        }
//        print(supportIDsToIDFRegisters)
        //print("Sorted tokens: \(idfRegistersTokens)")
//        print(idfRegistersIDFNorm)
        var queryIDFRegisters = idfRegistersIDFNorm
        queryIDFRegisters.append(1.0)  // exp bm25 term
        queryIDFRegisters.append(1.0)  // linear bm25 term
        return (queryIDFRegisters: queryIDFRegisters, supportIDsToIDFRegisters: supportIDsToIDFRegisters, queryTokenToIDF: queryTokenToIDF, idfRegistersTokens: idfRegistersTokens, idfRegistersIDFNorm: idfRegistersIDFNorm, bm25NormalizationTerm: bm25NormalizationTerm, bm25NormalizationTermLinear: bm25NormalizationTermLinear)
    }

    
    func countTokenOccurrencesInDocument(documentTextString: String, searchText: String) -> Double {
        var count: Int = 0
        var startIndex = documentTextString.startIndex
        while true {
            if let range = getRangeOfOneOccurrence_StringIndex(documentTextString: documentTextString, searchText: searchText, startIndex: startIndex) {
                count += 1
                startIndex = range.upperBound
            } else {
                break
            }
            if count >= REConstants.SemanticSearch.maxFrequency {
                break
            }
        }
        return Double(count)
    }
    func getCompressedGlobaExemplarsSupportWithRetrievalRegisters(supportIDsToIDFRegisters: [String: [Float32]], expectedDimension: Int) async throws -> [String: [Float32]] {
        var supportIDsToExemplarsWithIDFRegisters: [String: [Float32]] = [:]
        let taskContext = newTaskContext()
        try taskContext.performAndWait {
            let fetchRequest = Document.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id in %@", Array(supportIDsToIDFRegisters.keys) )
            let documentRequest = try taskContext.fetch(fetchRequest)
            
            if documentRequest.isEmpty {
                throw CoreDataErrors.retrievalError
            }
            for documentObj in documentRequest {
                if let documentId = documentObj.id, var exemplarCompressed = documentObj.exemplar?.exemplarCompressed?.toArray(type: Float32.self), let idfRegister = supportIDsToIDFRegisters[documentId] {
                    exemplarCompressed.append(contentsOf: idfRegister)
                    if exemplarCompressed.count != expectedDimension {
                        throw CoreDataErrors.retrievalError
                    }
                    supportIDsToExemplarsWithIDFRegisters[documentId] = exemplarCompressed
                    // temp override:
//                    var ex1 = [Float32](repeating: 0.0, count: 32)
//                    ex1.append(contentsOf: idfRegister)
//                    supportIDsToExemplarsWithIDFRegisters[documentId] = ex1
                }
            }
        }

        return supportIDsToExemplarsWithIDFRegisters
    }
}

