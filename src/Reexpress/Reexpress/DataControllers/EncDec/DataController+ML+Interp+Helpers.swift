//
//  DataController+ML+Interp.swift
//  Alpha1
//
//  Created by A on 4/6/23.
//

import Foundation
import CoreML
import Accelerate

extension DataController {
    func constructInterpretabilityMask(totalLength: Int, sentenceRangeTuple: (Int, Int)) -> MLMultiArray {
        var interpretabilityMask = [TokenIdType](repeating: TokenIdType(0.0), count: totalLength)
        interpretabilityMask.replaceSubrange(sentenceRangeTuple.0..<sentenceRangeTuple.1, with: [TokenIdType](repeating: TokenIdType(1.0), count: sentenceRangeTuple.1-sentenceRangeTuple.0))
        let interpretabilityMaskArray = MLMultiArray( MLShapedArray<TokenIdType>(scalars: interpretabilityMask, shape: [1, interpretabilityMask.count]) )
        return interpretabilityMaskArray
    }
    
    func updateFeatureAnalysis(featureLevelAnalysisMatch: OutputFeaturePredictionType?, outPredictionStructure: OutputPredictionType, absoluteFeatureSentenceIndex: Int) -> OutputFeaturePredictionType? {
        var updatedFeatureLevelAnalysisMatch: OutputFeaturePredictionType?
        var newFeatureIsPreferable = false
        if let existingMatch = featureLevelAnalysisMatch {
            if outPredictionStructure.softmax[outPredictionStructure.predictedClass] > existingMatch.predictedSoftmax {
                newFeatureIsPreferable = true
            } else {
                updatedFeatureLevelAnalysisMatch = existingMatch
            }
        } else {
            newFeatureIsPreferable = true
        }
        if newFeatureIsPreferable {
            updatedFeatureLevelAnalysisMatch = (predictedClass: outPredictionStructure.predictedClass, predictedSoftmax: outPredictionStructure.softmax[outPredictionStructure.predictedClass], sentenceIndex: absoluteFeatureSentenceIndex)
        }
        return updatedFeatureLevelAnalysisMatch
    }
    
}
