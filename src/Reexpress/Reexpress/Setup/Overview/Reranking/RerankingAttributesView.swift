//
//  RerankingAttributesView.swift
//  Alpha1
//
//  Created by A on 9/9/23.
//

import SwiftUI

struct RerankingAttributesView: View {
    
    @Binding var documentSelectionState: DocumentSelectionState
    var attributesWithIndex: [AttributesWithIndex] {
        if documentSelectionState.semanticSearchParameters.search {
            if documentSelectionState.semanticSearchParameters.rerankParameters.rerankAttributes.count <= REConstants.KeyModelConstraints.attributesSize {
                var data: [AttributesWithIndex] = []
                for attributeIndex in 0..<documentSelectionState.semanticSearchParameters.rerankParameters.rerankAttributes.count {
                    data.append(.init(index: attributeIndex, attributeValue: documentSelectionState.semanticSearchParameters.rerankParameters.rerankAttributes[attributeIndex]))
                }
                return data
            }
        }
        return []
    }
    @State private var unParsedAttributes: String = ""
    
    func parseAttributesString() {
        if unParsedAttributes.count > 0 {
            documentSelectionState.semanticSearchParameters.rerankParameters.rerankAttributes = REConstants.DataValidator.parseCommaSeparatedAttributesString(rawUnParsedAttributes: unParsedAttributes)
        } else {
            documentSelectionState.semanticSearchParameters.rerankParameters.rerankAttributes = []
        }
    }
    
    var body: some View {
            VStack {
                HStack {
                    Text("New \(REConstants.PropertyDisplayLabel.attributesFull) to be added to all cross-encoded documents")
                        .font(REConstants.Fonts.baseFont)
                        .bold()
                    Spacer()
                }
                .padding(.bottom)
                if documentSelectionState.semanticSearchParameters.searchAttributes.count > 0 {
                    HStack {
                        Text("Pre-fill:")
                            .foregroundStyle(.gray)
                            .font(REConstants.Fonts.baseFont)
                        Text("Search query attributes")
                            .monospaced()
                            .font(REConstants.Fonts.baseFont.smallCaps())
                            .foregroundStyle(.blue)
                    }
                        .onTapGesture {
                            let stringArray = documentSelectionState.semanticSearchParameters.searchAttributes.map { String($0) }
                            unParsedAttributes = stringArray.joined(separator: ",")
                            
                        }
                        .padding(.bottom)
                }
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
                        TextEditor(text: $unParsedAttributes)
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
                    VStack {
                        List {
                            ForEach(attributesWithIndex) { index in
                                HStack {
                                    HStack {
                                        Spacer()
                                        Text(index.indexAsString)
                                            .font(REConstants.Fonts.baseFont)
                                            .monospaced()
                                            .foregroundStyle(.gray)
                                    }
                                    .frame(width: 100)
                                    .padding([.leading, .trailing])
                                    
                                    HStack {
                                        Text(index.attributeValueAsString)
                                            .font(REConstants.Fonts.baseFont)
                                            .monospaced()
                                        Spacer()
                                    }
                                    .frame(width: 200)
                                    .padding([.leading, .trailing])
                                    Spacer()
                                }
                                
                            }
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

        .onAppear {
            if documentSelectionState.semanticSearchParameters.search, documentSelectionState.semanticSearchParameters.rerankParameters.rerankAttributes.count > 0 {
                
                let stringArray = documentSelectionState.semanticSearchParameters.rerankParameters.rerankAttributes.map { String($0) }
                unParsedAttributes = stringArray.joined(separator: ",")
            }
        }
    }
}

