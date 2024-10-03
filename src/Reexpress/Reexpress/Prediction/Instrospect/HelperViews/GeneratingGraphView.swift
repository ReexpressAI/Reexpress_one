//
//  GeneratingGraphView.swift
//  Alpha1
//
//  Created by A on 9/17/23.
//

import SwiftUI

struct GeneratingGraphView: View {
    var body: some View {
        VStack {
            Text("Generating graph")
                .font(.title2)
                .foregroundStyle(.secondary)
            ProgressView()
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(REConstants.REColors.reBackgroundDarker)
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.gray)
                .opacity(0.5)
        }
        .padding()
    }
}

