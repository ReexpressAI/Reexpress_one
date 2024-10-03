//
//  DocumentBatchGroupChangeView.swift
//  Alpha1
//
//  Created by A on 9/6/23.
//

import SwiftUI

struct DocumentBatchGroupChangeView: View {
    @Binding var documentBatchChangeState: DocumentBatchChangeState
    
    var body: some View {
        HStack {
            Spacer()
            VStack {
                
                TextEditor(text: $documentBatchChangeState.groupFieldText)
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
                
                    .onChange(of: documentBatchChangeState.groupFieldText) {
                        // Ensure the text does not exceed the max length
                        if !documentBatchChangeState.groupFieldText.isEmpty {
                            documentBatchChangeState.groupFieldText = String(documentBatchChangeState.groupFieldText.prefix(REConstants.DataValidator.maxGroupRawCharacterLength))
                        }
                    }
                HStack {
                    Spacer()
                    Text("\(documentBatchChangeState.groupFieldText.count) / \(REConstants.DataValidator.maxGroupRawCharacterLength) characters")
                        .foregroundStyle(.gray)
                    Spacer()
                }
            }
        }
        .padding()
    }
}
