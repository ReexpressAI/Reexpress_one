//
//  ModelLicenseView.swift
//  Reexpress
//
//  Created by A on 10/23/23.
//

import SwiftUI

struct ModelLicenseView: View {
    var body: some View {
        ScrollView {
            VStack {
                Text(REConstants.ModelWeights.modelWeightsLicenseNotice)
                    .lineSpacing(6.0)
                    .monospaced(true)
                    .padding()
            }
        }
        .frame(width: 700, height: 500)
    }
}
