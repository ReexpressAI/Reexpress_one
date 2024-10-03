//
//  PassIdentifiers.swift
//  Reexpress
//
//  Created by A on 10/5/23.
//

import SwiftUI

public struct PassIdentifiers {
    public var group: String
    
    public var fed_2023v1: String
}

public extension EnvironmentValues {
    
    private enum PassIDsKey: EnvironmentKey {
        static var defaultValue = PassIdentifiers(
            group: "TODO some value",
            fed_2023v1: "TODO some value"
        )
    }
    
    var passIDs: PassIdentifiers {
        get { self[PassIDsKey.self] }
        set { self[PassIDsKey.self] = newValue }
    }
    
}
