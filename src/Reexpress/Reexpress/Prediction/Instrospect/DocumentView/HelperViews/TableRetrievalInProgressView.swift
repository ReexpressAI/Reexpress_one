//
//  TableRetrievalInProgressView.swift
//  Alpha1
//
//  Created by A on 6/16/23.
//

import SwiftUI

struct TableRetrievalInProgressView: View {
    @Binding var documentRetrievalInProgress: Bool
    var progressText: String = "Retrieving documents"
    var body: some View {
        VStack {
            Text(progressText)
                .opacity(1.0)
                .font(.title2)
                .padding()
                .frame(width: 300, height: 150)
                .background {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(BackgroundStyle())
                        .opacity(0.75)
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(.gray)
                }
                .padding()
        }
        .opacity(documentRetrievalInProgress ? 1.0 : 0.0)
        .zIndex(documentRetrievalInProgress ? 1.0 : 0.0)
    }
}


struct TableRetrievalInProgressView_Previews: PreviewProvider {
    static var previews: some View {
        TableRetrievalInProgressView(documentRetrievalInProgress: .constant(true))
    }
}
