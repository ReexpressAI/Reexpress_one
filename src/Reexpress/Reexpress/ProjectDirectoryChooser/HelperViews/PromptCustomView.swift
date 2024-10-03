//
//  PromptCustomView.swift
//  Alpha1
//
//  Created by A on 7/15/23.
//

import SwiftUI

struct PromptCustomView: View {
    @EnvironmentObject var initialSetupDataController: InitialSetupDataController
    var body: some View {
            LabeledContent {
                TextEditor(text: $initialSetupDataController.defaultPrompt)
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
                
            } label: {
                Text("Prompt:")
                    .modifier(CreateProjectViewControlTitlesViewModifier())
            }
            .onChange(of: initialSetupDataController.defaultPrompt) {
                // Ensure the prompt does not exceed the max length
                if !initialSetupDataController.defaultPrompt.isEmpty {
                    initialSetupDataController.defaultPrompt = String(initialSetupDataController.defaultPrompt.prefix(REConstants.DataValidator.maxPromptRawCharacterLength))
                }
            }
            Text("\(initialSetupDataController.defaultPrompt.count) / \(REConstants.DataValidator.maxPromptRawCharacterLength) characters")
        
    }
}


