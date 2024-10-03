//
//  ArrayDouble+Stats.swift
//  ModelTest1
//
//  Created by A on 1/7/23.
//

import Foundation

extension Array where Element == Double {
    
    func quantile(at quantileProportion: Double, sort: Bool = true) -> Double? {
        if self.count == 0 {
            return nil
        }
        var internalArray = self
        if sort {
            internalArray.sort()
        }
        
        // not using rounded, as in let quantileIndex = Int( (quantileProportion*Double(internalArray.count)).rounded() )
        let quantileIndex = Swift.min( Int( quantileProportion*Double(internalArray.count) ), internalArray.count-1)
        return internalArray[quantileIndex]
    }
    // If self.count > 0, always returns an array of length quantileProportions.count, duplicating the entry in case self.count < quantileProportions.count
    func quantiles(at quantileProportions: [Double] = [0.25, 0.5, 0.75], sort: Bool = true) -> [Double]? {
        if self.count == 0 {
            return nil
        }
        var internalArray = self
        if sort {
            internalArray.sort()
        }
        var quantilesArray = [Double]()
        quantilesArray.reserveCapacity(quantileProportions.count)
        for quantileProportion in quantileProportions {
            let quantileIndex = Swift.min( Int( quantileProportion*Double(internalArray.count) ), internalArray.count-1)
            quantilesArray.append(internalArray[quantileIndex])
        }
        return quantilesArray
    }
}

extension Array where Element == Float32 {
    
    func quantile(at quantileProportion: Float32, sort: Bool = true) -> Float32? {
        if self.count == 0 {
            return nil
        }
        var internalArray = self
        if sort {
            internalArray.sort()
        }
        
        // not using rounded, as in let quantileIndex = Int( (quantileProportion*Double(internalArray.count)).rounded() )
        let quantileIndex = Swift.min( Int( quantileProportion*Float32(internalArray.count) ), internalArray.count-1)
        return internalArray[quantileIndex]
    }
    // If self.count > 0, always returns an array of length quantileProportions.count, duplicating the entry in case self.count < quantileProportions.count
    func quantiles(at quantileProportions: [Float32] = [0.25, 0.5, 0.75], sort: Bool = true) -> [Float32]? {
        if self.count == 0 {
            return nil
        }
        var internalArray = self
        if sort {
            internalArray.sort()
        }
        var quantilesArray = [Float32]()
        quantilesArray.reserveCapacity(quantileProportions.count)
        for quantileProportion in quantileProportions {
            let quantileIndex = Swift.min( Int( quantileProportion*Float32(internalArray.count) ), internalArray.count-1)
            quantilesArray.append(internalArray[quantileIndex])
        }
        return quantilesArray
    }
}
