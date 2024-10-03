//
//  PromptTemplateView.swift
//  Alpha1
//
//  Created by A on 7/15/23.
//

import SwiftUI

struct PromptTemplateView: View {
    @EnvironmentObject var initialSetupDataController: InitialSetupDataController

    /*
     Text(SentencepiecePrompts.getDefaultPromptWithOptions(topic: initialSetupDataController.defaultPromptTopic, documentType: initialSetupDataController.defaultPromptDocumentType))
     */
    func highlightPromptComponents() -> AttributedString {
        var prompt = AttributedString(SentencepiecePrompts.getDefaultPromptWithOptions(topic: initialSetupDataController.defaultPromptTopic, documentType: initialSetupDataController.defaultPromptDocumentType))

        if let range = prompt.range(of: initialSetupDataController.defaultPromptTopic) {
            prompt[range].backgroundColor = REConstants.REColors.reSoftHighlight // REConstants.REColors.reHighlightPositive
            prompt[range].foregroundColor = .black
        }
        if let range = prompt.range(of: initialSetupDataController.defaultPromptDocumentType) {
            prompt[range].backgroundColor = REConstants.REColors.reSoftHighlight //REConstants.REColors.reHighlightNegative
            prompt[range].foregroundColor = .black
        }
        
        return prompt
    }
//}
    var body: some View {
        //VStack {
        LabeledContent {
            Picker(selection: $initialSetupDataController.defaultPromptTopic) {
                ForEach(SentencepiecePrompts.getDefaultTopicOptions(), id:\.self) { promptTopicString in
                    Text(promptTopicString)
                        .modifier(CreateProjectViewControlViewModifier())
                        .tag(promptTopicString)
                }
            } label: {
                Text("")
//                HStack {
//                    Text("Task description:")
//                        .modifier(CreateProjectViewControlTitlesViewModifier())
//                }
            }
            .frame(width: 250)
            .pickerStyle(.menu)
        } label: {
//            Text("")
            Text("Task description:")
                .modifier(CreateProjectViewControlTitlesViewModifier())
        }
        LabeledContent {
            Picker(selection: $initialSetupDataController.defaultPromptDocumentType) {
                ForEach(SentencepiecePrompts.getDefaultDocumentTypeOptions(), id:\.self) { documentTypeString in
                    Text(documentTypeString)
                        .modifier(CreateProjectViewControlViewModifier())
                        .tag(documentTypeString)
                }
            } label: {
                Text("")
//                HStack {
//                    Text("Document type:")
//                        .modifier(CreateProjectViewControlTitlesViewModifier())
//                }
            }
            .frame(width: 250)
            .pickerStyle(.menu)
        } label: {
//            Text("")
            Text("Document type:")
                .modifier(CreateProjectViewControlTitlesViewModifier())
        }
        
        LabeledContent {
            Text(highlightPromptComponents())
                .lineLimit(3, reservesSpace: true)
                .frame(width: 400, height: 90)
                .modifier(CreateProjectViewControlViewModifier())
        } label: {
            Text("Prompt:")
                .modifier(CreateProjectViewControlTitlesViewModifier())
        }
        //}
    }
}

//struct PromptTemplateView_Previews: PreviewProvider {
//    static var previews: some View {
//        PromptTemplateView()
//    }
//}
