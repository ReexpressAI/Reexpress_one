//
//  ForwardWithInterpretability+ModelGroup.swift
//  Alpha1
//
//  Created by A on 8/3/23.
//

import SwiftUI
import CoreML

extension MainForwardAfterTrainingView {
    
    func forward_modelGroup(batchSize: Int, datasetId: Int) async throws {
        switch dataController.modelGroup {
        case .Fast:
            try await forward_MFastM1v1D(batchSize: batchSize, datasetId: datasetId)
        case .Faster:
            try await forward_MFasterM1v1D(batchSize: batchSize, datasetId: datasetId)
        case .Fastest:
            try await forward_MFastestM1v1D(batchSize: batchSize, datasetId: datasetId)
        }
        if Task.isCancelled {
            throw MLForwardErrors.forwardPassWasCancelled
        }
    }
}

