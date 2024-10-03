//
//  TableRetrievalErrorView.swift
//  Alpha1
//
//  Created by A on 6/15/23.
//
/*
 This view is used in the document tables to provide an indication that the retrieval was not successful. Typically this should be used in a ZStack to temporarily show the view. It is intended to be used as a lighter-weight indicator than a popup alert, which requires explicit feedback from the user.
 */

import SwiftUI

struct TableRetrievalErrorView: View {
    @Binding var documentRetrievalError: Bool
    var body: some View {
        VStack {
            Text("No matching documents found")
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
        .opacity(documentRetrievalError ? 1.0 : 0.0)
        .zIndex(documentRetrievalError ? 1.0 : 0.0)
    }
}

struct TableRetrievalErrorView_Previews: PreviewProvider {
    static var previews: some View {
        TableRetrievalErrorView(documentRetrievalError: .constant(true))
    }
}
