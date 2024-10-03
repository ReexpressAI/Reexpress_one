//
//  KeyModel+ReInit.swift
//  BNNS-Training-Sample
//
//  Created by A on 3/28/23.
//  Copyright © 2023 Apple. All rights reserved.
//

import Foundation
import Accelerate

extension KeyModel {
 
    
    func exportWeights() -> ModelWeights {
////        self.convolutionBias.makeArray(of: <#T##T.Type#>)
//        print(self.convolutionWeights.makeArray(of: Float.self)?.count)
//        print(self.convolutionBias.makeArray(of: Float.self)?.count)
//
//        print(self.fullyConnectedWeights.makeArray(of: Float.self)?.count)
//        print(self.fullyConnectedBias.makeArray(of: Float.self)?.count)

        
        return (cnnWeights: self.convolutionWeights.makeArray(of: Float.self), cnnBias: self.convolutionBias.makeArray(of: Float.self), fcWeights: self.fullyConnectedWeights.makeArray(of: Float.self), fcBias: self.fullyConnectedBias.makeArray(of: Float.self))
//        guard
//            let cnnWeights = self.convolutionWeights.makeArray(
//                of: Float.self,
//                batchSize: batchSize) else {
//            fatalError("Unable to create arrays for evaluation.")
//        }
    }
    
}
    
