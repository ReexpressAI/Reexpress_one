//
//  Data+Utilities.swift
//  Alpha1
//
//  Created by A on 3/21/23.
//

import Foundation

//  https://stackoverflow.com/questions/38023838/round-trip-swift-number-types-to-from-data
extension Data {
    // Note: [Float32] not [[Float32]]
    init<T>(fromArray values: [T]) {
        self = values.withUnsafeBytes { Data($0) }
    }
    
    func toArray<T>(type: T.Type) -> [T] where T: ExpressibleByIntegerLiteral {
        var array = Array<T>(repeating: 0, count: self.count/MemoryLayout<T>.stride)
        _ = array.withUnsafeMutableBytes { copyBytes(to: $0) }
        return array
    }
}
