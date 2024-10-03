//
//  LivePredictionInitView.swift
//  Alpha1
//
//  Created by A on 9/11/23.
//

import SwiftUI

struct LivePredictionInitView: View {
    
    var body: some View {
        VStack {
            Spacer()
            ProgressView()
            HStack {
                Spacer()
                Text("Initializing")
                    .font(REConstants.Fonts.baseFont)
                    .foregroundStyle(.gray)
                Spacer()
            }
            Spacer()
        }
    }
}


