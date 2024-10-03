//
//  String+Utilities.swift
//  Alpha1
//
//  Created by A on 3/18/23.
//

import Foundation

extension String {
    func truncateUpToMaxWithEllipsis(maxLength: Int) -> String {
        let length = self.count
        if length > maxLength {
            return String(self.prefix(maxLength)) + "..."
        }
        return self
    }
}

