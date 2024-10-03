//
//  PopoverView.swift
//  Alpha1
//
//  Created by A on 7/14/23.
//

import SwiftUI

struct PopoverView: View {
    var popoverViewText = ""
    var optionalSubText: String? = nil
    
    var body: some View {
        VStack {
            Text(popoverViewText)
            if let subText = optionalSubText {
                Text("")
                Text(subText)
                    .foregroundStyle(.gray)
            }
        }
        .padding()
        .frame(width: 200)
    }
}
