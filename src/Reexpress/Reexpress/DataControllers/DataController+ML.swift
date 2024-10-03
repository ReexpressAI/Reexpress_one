//
//  DataController+ML.swift
//  Alpha1
//
//  Created by A on 3/22/23.
//

import Foundation
import CoreML
import Accelerate

extension DataController {
    func getPaddedShapedArrays(documentTokenIds: [TokenIdType], padId: TokenIdType, maxLength: Int) -> (inputShapedArray: MLShapedArray<TokenIdType>, attentionMaskArray: MLShapedArray<TokenIdType>) {
        var documentTokenIds = documentTokenIds
        var baseAttnMask = [TokenIdType](repeating: TokenIdType(1.0), count: documentTokenIds.count)
        baseAttnMask.append(contentsOf: [TokenIdType](repeating: TokenIdType(0.0), count: maxLength-documentTokenIds.count))
        documentTokenIds.append(contentsOf: [TokenIdType](repeating: padId, count: maxLength-documentTokenIds.count))
        
        let inputShapedArray = MLShapedArray<TokenIdType>(scalars: documentTokenIds, shape: [1, documentTokenIds.count])
        let attentionMaskArray = MLShapedArray<TokenIdType>(scalars: baseAttnMask, shape: [1, baseAttnMask.count])
        return (inputShapedArray: inputShapedArray, attentionMaskArray: attentionMaskArray)
    }
}
