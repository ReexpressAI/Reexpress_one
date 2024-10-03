//
//  SemanticSearchAttributesView.swift
//  Alpha1
//
//  Created by A on 9/8/23.
//

import SwiftUI



struct SemanticSearchAttributesView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var dataController: DataController
    
    
    @Binding var documentSelectionState: DocumentSelectionState
    var attributesWithIndex: [AttributesWithIndex] {
        if documentSelectionState.semanticSearchParameters.search {
            if documentSelectionState.semanticSearchParameters.searchAttributes.count <= REConstants.KeyModelConstraints.attributesSize {
                var data: [AttributesWithIndex] = []
                for attributeIndex in 0..<documentSelectionState.semanticSearchParameters.searchAttributes.count {
                    data.append(.init(index: attributeIndex, attributeValue: documentSelectionState.semanticSearchParameters.searchAttributes[attributeIndex]))
                }
                return data
            }
        }
        return []
    }
    @State private var unParsedAttributes: String = ""
    
    func parseAttributesString() {
        if unParsedAttributes.count > 0 {
            documentSelectionState.semanticSearchParameters.searchAttributes = REConstants.DataValidator.parseCommaSeparatedAttributesString(rawUnParsedAttributes: unParsedAttributes)
        } else {
            documentSelectionState.semanticSearchParameters.searchAttributes = []
        }
    }
    
    var body: some View {
        ScrollView {
            VStack {
                HStack {
                    Text(REConstants.PropertyDisplayLabel.attributesFull)
                        .font(REConstants.Fonts.baseFont)
                        .bold()
                    Spacer()
                }
                .padding(.bottom)
                VStack {
                    HStack {
                        Text("Comma separated list of attributes:")
                            .font(REConstants.Fonts.baseFont)
                            .foregroundStyle(.gray)
                        PopoverViewWithButtonLocalStateOptions(popoverViewText: REConstants.HelpAssistanceInfo.UserInput.attributes, optionalSubText: REConstants.HelpAssistanceInfo.UserInput.attributesAdditionalInfo, frameWidth: 400)
                        Spacer()
                    }
                    .padding([.leading, .trailing])
                    VStack {
                        TextEditor(text:  $unParsedAttributes)
                            .font(REConstants.Fonts.baseFont)
                            .monospaced(true)
                            .frame(width: 400, height: 125)
                            .foregroundColor(.white)
                            .scrollContentBackground(.hidden)
                            .opacity(0.75)
                            .padding()
                            .background {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(
                                        REConstants.REColors.reBackgroundDarker)
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(.gray)
                                    .opacity(0.5)
                            }
                    }
                    HStack {
                        Spacer()
                        Button {
                            parseAttributesString()
                        } label: {
                            Text("Add")
                                .font(REConstants.Fonts.baseSubheadlineFont)
                                .frame(width: 100)
                        }
                        .buttonStyle(.borderedProminent)
                        .padding([.trailing], 40)
                    }
                    .padding([.top, .leading, .trailing])
                }
                VStack {
                    HStack {
                        HStack {
                            Spacer()
                            Text("Index")
                                .foregroundStyle(.gray)
                        }
                        .frame(width: 100)
                        .padding([.leading, .trailing])
                        HStack {
                            Text("Value")
                            Spacer()
                        }
                        .frame(width: 200)
                        .padding([.leading, .trailing])
                        Spacer()
                    }
                    .font(REConstants.Fonts.baseFont)
                    .monospaced()
                    .padding([.leading, .trailing])
                    Divider()
                    List {
                        ForEach(attributesWithIndex) { index in
                            HStack {
                                HStack {
                                    Spacer()
                                    Text(index.indexAsString)
                                        .foregroundStyle(.gray)
                                }
                                .frame(width: 100)
                                .padding([.leading, .trailing])
                                
                                HStack {
                                    Text(index.attributeValueAsString)
                                    Spacer()
                                }
                                .frame(width: 200)
                                .padding([.leading, .trailing])
                                Spacer()
                            }
                            
                            .font(REConstants.Fonts.baseFont)
                            .monospaced()
                        }
                    }
                    .frame(height: 350)
                    .listStyle(.inset(alternatesRowBackgrounds: true))
                }
                .padding()
                .modifier(SimpleBaseBorderModifier())
                .padding()
            }
            .padding()
        }
        .scrollBounceBehavior(.basedOnSize)
        .onAppear {
            if documentSelectionState.semanticSearchParameters.search, documentSelectionState.semanticSearchParameters.searchAttributes.count > 0 {
                
                let stringArray = documentSelectionState.semanticSearchParameters.searchAttributes.map { String($0) }
                unParsedAttributes = stringArray.joined(separator: ",")
            }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .frame(width: 100)
                }
                .controlSize(.large)
                
            }
        }
    }
}

