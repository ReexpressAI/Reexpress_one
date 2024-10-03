//
//  DataController+SemanticSearch+QueryForward.swift
//  Alpha1
//
//  Created by A on 8/26/23.
//

import Foundation
import CoreData
import NaturalLanguage
import Accelerate

// MARK: TODO don't forget to append attributes
extension DataController {
    
    
    func semanticSearch_forward_modelGroup_singleInstance(documentSelectionState: DocumentSelectionState) async throws -> [Float32] {
        var documentExemplarCompressed: [Float32] = []
        switch modelGroup {
        case .Fast:
            documentExemplarCompressed = try await semanticSearch_forward_MFastM1v1D_singleInstance(documentSelectionState: documentSelectionState)
        case .Faster:
            documentExemplarCompressed = try await semanticSearch_forward_MFasterM1v1D_singleInstance(documentSelectionState: documentSelectionState)
        case .Fastest:
            documentExemplarCompressed = try await semanticSearch_forward_MFastestM1v1D_singleInstance(documentSelectionState: documentSelectionState)
        }
        if Task.isCancelled {
            throw MLForwardErrors.forwardPassWasCancelled
        }
        if documentExemplarCompressed.count == 0 {
            throw MLForwardErrors.forwardError
        }
        return documentExemplarCompressed
    }
    
    func mainForwardSemanticSearch(documentSelectionState: DocumentSelectionState) async throws -> [Float32] {
        if !isModelTrainedandIndexed() {
            if inMemory_KeyModelGlobalControl.modelWeights == nil {
                throw KeyModelErrors.keyModelWeightsMissing
            }
            if inMemory_KeyModelGlobalControl.indexModelWeights == nil {
                throw KeyModelErrors.indexModelWeightsMissing
            }
            throw KeyModelErrors.compressionNotCurrent
        }

        return try await semanticSearch_forward_modelGroup_singleInstance(documentSelectionState: documentSelectionState)
        
    }
}
