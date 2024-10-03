//
//  DocumentBatchInfoChangeView.swift
//  Alpha1
//
//  Created by A on 9/6/23.
//

import SwiftUI

struct DocumentBatchInfoChangeView: View {
    @Binding var documentBatchChangeState: DocumentBatchChangeState
    var body: some View {
        HStack {
            Spacer()
            VStack {
                
                TextEditor(text: $documentBatchChangeState.infoFieldText)
                    .cornerRadius(12)
                    .padding()
                    .overlay(
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.gray)
                                .opacity(0.5)
                        }
                    )
                    .scrollContentBackground(.hidden)
                    .frame(width: 400, height: 150)
                    .modifier(CreateProjectViewControlViewModifier())
                
                    .onChange(of: documentBatchChangeState.infoFieldText) {
                        // Ensure the text does not exceed the max length
                        if !documentBatchChangeState.infoFieldText.isEmpty {
                            documentBatchChangeState.infoFieldText = String(documentBatchChangeState.infoFieldText.prefix(REConstants.DataValidator.maxInfoRawCharacterLength))
                        }
                    }
                HStack {
                    Spacer()
                    Text("\(documentBatchChangeState.infoFieldText.count) / \(REConstants.DataValidator.maxInfoRawCharacterLength) characters")
                        .foregroundStyle(.gray)
                    Spacer()
                }
            }
        }
        .padding()
    }
}

