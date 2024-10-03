//
//  DataController+CoreData+Interp.swift
//  Alpha1
//
//  Created by A on 7/28/23.
//

import Foundation
import CoreData

extension DataController {
    
//    typealias OutputFullAnalysisWithFeaturesPredictionType2 = (documentLevelPrediction: OutputPredictionType?, featureLevelAnalysisMatchesDocLevel: OutputFeaturePredictionType?, featureLevelAnalysisInconsistentWithDocLevel: OutputFeaturePredictionType?, documentExemplarCompressed: [Float32], documentSentencesRanges: [Range<String.Index>], startingSentenceArrayIndexOfDocument: Int, sentenceExemplarsCompressed: [Float32])
    
    func addOutputPredictionStructuresForExistingDocuments(documentArray: [(id: String, document: String, prompt: String, attributes: [Float32])], tokenizedDocumentDict: [Int: SentencepieceTokenizer.DocumentTokenizationResult], multiTokenizedDocumentDict: [Int: SentencepieceTokenizer.DocumentTokenizationResult], sentenceIndexToOutputPredictionStructure: [Int: OutputFullAnalysisWithFeaturesPredictionType], moc: NSManagedObjectContext) async throws {
        // update the published properties via the existing database
        // The fetch is on the main thread since there are not that many items and we need to update the UI
        try await MainActor.run {
            var documentIds: [String] = []
            var documentIdsToSentenceIndex: [String: Int] = [:]
            for sentenceIndex in 0..<documentArray.count {
                documentIds.append(documentArray[sentenceIndex].id)
                documentIdsToSentenceIndex[documentArray[sentenceIndex].id] = sentenceIndex
            }
            //documentArray.map { $0.id }
            let fetchRequest = Document.fetchRequest()
            // We do it this way because we are assuming the batch size is potentially << full dataset size, so we do not have to loop through.
            fetchRequest.predicate = NSPredicate(format: "id in %@", documentIds)
            let datasetRequest = try moc.fetch(fetchRequest) as [Document]
            
            if datasetRequest.isEmpty {
                throw CoreDataErrors.saveError
            }
            
            var total = 0
            var correctCount = 0
            for documentObj in datasetRequest {
                if let documentId = documentObj.id, let sentenceIndex = documentIdsToSentenceIndex[documentId], let documentPredictionStructure = sentenceIndexToOutputPredictionStructure[sentenceIndex], let startingIndexOfTruncatedWords = tokenizedDocumentDict[sentenceIndex]?.startingIndexOfTruncatedWords, let documentSentencesRanges = tokenizedDocumentDict[sentenceIndex]?.documentSentencesRanges, let documentWithPromptDocumentStartRangeIndex = tokenizedDocumentDict[sentenceIndex]?.documentWithPromptDocumentStartRangeIndex {
                    
                    
                    if let documentLevelPrediction = documentPredictionStructure.documentLevelPrediction {
                        documentObj.prediction = documentLevelPrediction.predictedClass
                        if documentObj.prediction == documentObj.label {
                            correctCount += 1
                        }
                        total += 1
                        // add Uncertainty and full Exemplar structures
                        if let _ = documentObj.uncertainty {
                            documentObj.uncertainty?.softmax = Data(fromArray: documentLevelPrediction.softmax)
                            if DataController.isKnownValidLabel(label: documentLevelPrediction.predictedClass, numberOfClasses: numberOfClasses) && documentLevelPrediction.predictedClass < documentLevelPrediction.softmax.count {
                                // Save the softmax output separately for the predicted class to enable CoreData predicate-based search:
                                documentObj.uncertainty?.f = documentLevelPrediction.softmax[documentLevelPrediction.predictedClass]
                            }
                        } else {
                            let uncertainty = Uncertainty(context: moc)
                            uncertainty.softmax = Data(fromArray: documentLevelPrediction.softmax)
                            if DataController.isKnownValidLabel(label: documentLevelPrediction.predictedClass, numberOfClasses: numberOfClasses) && documentLevelPrediction.predictedClass < documentLevelPrediction.softmax.count {
                                // Save the softmax output separately for the predicted class to enable CoreData predicate-based search:
                                uncertainty.f = documentLevelPrediction.softmax[documentLevelPrediction.predictedClass]
                            }
                            documentObj.uncertainty = uncertainty
                        }
                        
                        if let exemplarVector = documentLevelPrediction.exemplar {
                            if let _ = documentObj.exemplar {
                                documentObj.exemplar?.exemplar = Data(fromArray: exemplarVector)
                                documentObj.exemplar?.exemplarCompressed = Data(fromArray: documentPredictionStructure.documentExemplarCompressed)
                            } else {
                                let exemplar = Exemplar(context: moc)
                                exemplar.exemplar = Data(fromArray: exemplarVector)
                                exemplar.exemplarCompressed = Data(fromArray: documentPredictionStructure.documentExemplarCompressed)
                                documentObj.exemplar = exemplar
                            }
                        }
                        
                    }
                    documentObj.modelUUID = inMemory_KeyModelGlobalControl.indexModelUUID
//                    documentObj.modified = false
                    
                    // In order to have the correct token offsets, we must combine the prompt with the document in the same manner as when tokenizing
//                    var documentText: String = ""
//                    let prompt = documentObj.prompt ?? ""
//                    if prompt.isEmpty {
//                        documentText = documentObj.document ?? ""
//                    } else {
//                        documentText = prompt + " " + (documentObj.document ?? "")
//                    }
                    let documentText = documentObj.documentWithPrompt
                    
                    // Save features
                    // This could be slow:
                    var reOrderedDocumentSentencesRangesLower: [Int] = []
                    var reOrderedDocumentSentencesRangesUpper: [Int] = []
                    for sentenceIndexRange in documentPredictionStructure.documentSentencesRanges {
                        reOrderedDocumentSentencesRangesLower.append(sentenceIndexRange.lowerBound.utf16Offset(in: documentText))
                        reOrderedDocumentSentencesRangesUpper.append(sentenceIndexRange.upperBound.utf16Offset(in: documentText))
                    }
                    if let _ = documentObj.features {
                        documentObj.features?.startingSentenceArrayIndexOfDocument = documentPredictionStructure.startingSentenceArrayIndexOfDocument
                        documentObj.features?.sentenceExemplarsCompressed = Data(fromArray: documentPredictionStructure.sentenceExemplarsCompressed)
                        documentObj.features?.sentenceRangeStartVector = Data(fromArray: reOrderedDocumentSentencesRangesLower)
                        documentObj.features?.sentenceRangeEndVector = Data(fromArray: reOrderedDocumentSentencesRangesUpper)

                    } else {
                        let features = Features(context: moc)
                        features.startingSentenceArrayIndexOfDocument = documentPredictionStructure.startingSentenceArrayIndexOfDocument
                        features.sentenceExemplarsCompressed = Data(fromArray: documentPredictionStructure.sentenceExemplarsCompressed)
                        features.sentenceRangeStartVector = Data(fromArray: reOrderedDocumentSentencesRangesLower)
                        features.sentenceRangeEndVector = Data(fromArray: reOrderedDocumentSentencesRangesUpper)
                        documentObj.features = features
                    }
                    
                    // ranges needed to be converted to Int and then reconstructed
                    documentObj.tokenizationCutoffRangeStart = startingIndexOfTruncatedWords.utf16Offset(in: documentText)
                    documentObj.documentWithPromptDocumentStartRangeIndex = documentWithPromptDocumentStartRangeIndex.utf16Offset(in: documentText)
                    
                    // First, clear any existing feature highlight structures. This is important in order to avoid inconsistencies when re-predicting with a new model that may produce different highlights:
                    documentObj.featureMatchesDocLevelSoftmaxVal = Float(0.0)
                    documentObj.featureMatchesDocLevelSentenceRangeStart = -1
                    documentObj.featureMatchesDocLevelSentenceRangeEnd = -1
                    documentObj.featureInconsistentWithDocLevelPredictedClass = 0
                    documentObj.featureInconsistentWithDocLevelSoftmaxVal = Float(0.0)
                    documentObj.featureInconsistentWithDocLevelSentenceRangeStart = -1
                    documentObj.featureInconsistentWithDocLevelSentenceRangeEnd = -1
                    // Next, add any new feature highlight structures:
                    if let featureLevelAnalysis = documentPredictionStructure.featureLevelAnalysisMatchesDocLevel {
                        if featureLevelAnalysis.sentenceIndex < documentSentencesRanges.count, featureLevelAnalysis.predictedClass == documentObj.prediction {
                            documentObj.featureMatchesDocLevelSoftmaxVal = featureLevelAnalysis.predictedSoftmax
                            
                            let sentenceIndexRange = documentSentencesRanges[featureLevelAnalysis.sentenceIndex]
                            documentObj.featureMatchesDocLevelSentenceRangeStart = sentenceIndexRange.lowerBound.utf16Offset(in: documentText)
                            documentObj.featureMatchesDocLevelSentenceRangeEnd = sentenceIndexRange.upperBound.utf16Offset(in: documentText)
                        }
                    }
                    if let featureLevelAnalysis = documentPredictionStructure.featureLevelAnalysisInconsistentWithDocLevel {
                        if featureLevelAnalysis.sentenceIndex < documentSentencesRanges.count, featureLevelAnalysis.predictedClass != documentObj.prediction {
                            documentObj.featureInconsistentWithDocLevelPredictedClass = featureLevelAnalysis.predictedClass
                            documentObj.featureInconsistentWithDocLevelSoftmaxVal = featureLevelAnalysis.predictedSoftmax
                            
                            let sentenceIndexRange = documentSentencesRanges[featureLevelAnalysis.sentenceIndex]
                            documentObj.featureInconsistentWithDocLevelSentenceRangeStart = sentenceIndexRange.lowerBound.utf16Offset(in: documentText)
                            documentObj.featureInconsistentWithDocLevelSentenceRangeEnd = sentenceIndexRange.upperBound.utf16Offset(in: documentText)
                        }
                    }
                    
                    // Embedding only gets saved for Training and Calibration on training passes.
                    /*if let embedding = documentPredictionStructure.frozenNetworkDocumentEmbeddingsArray {
                        let newEmbedding = Embedding(context: moc)
                        newEmbedding.id = jsonDocumentInstance.id
                        newEmbedding.embedding = Data(fromArray: embedding)
                        //newEmbedding.attributes = Data(fromArray: jsonDocumentInstance.attributes ?? [])
                        // make a connection from the document to the embedding
                        documentObj.embedding = newEmbedding
                    }*/
                }
            }
            /*if total > 0 {
                print("Local acc: \(Double(correctCount)/Double(total)) out of \(total)")
            }*/
            do {
                if moc.hasChanges {
                    try moc.save()
                }
            } catch {
                throw CoreDataErrors.saveError
            }
        }
    }
    
    
    
}
