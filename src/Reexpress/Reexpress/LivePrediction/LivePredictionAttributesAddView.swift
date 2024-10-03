//
//  LivePredictionAttributesAddView.swift
//  Alpha1
//
//  Created by A on 9/11/23.
//

import SwiftUI


struct LivePredictionAttributesAddView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var liveDocumentState: LiveDocumentState
    var attributesWithIndex: [AttributesWithIndex] {
            if liveDocumentState.attributes.count <= REConstants.KeyModelConstraints.attributesSize {
                var data: [AttributesWithIndex] = []
                for attributeIndex in 0..<liveDocumentState.attributes.count {
                    data.append(.init(index: attributeIndex, attributeValue: liveDocumentState.attributes[attributeIndex]))
                }
                return data
            }
        return []
    }
    @State private var unParsedAttributes: String = ""
    
    func parseAttributesString() {
        if unParsedAttributes.count > 0 {
            liveDocumentState.attributes = REConstants.DataValidator.parseCommaSeparatedAttributesString(rawUnParsedAttributes: unParsedAttributes)
        } else {
            liveDocumentState.attributes = []
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
        }
        
        .scrollBounceBehavior(.basedOnSize)
        .onAppear {
            if liveDocumentState.attributes.count > 0 {
                
                let stringArray = liveDocumentState.attributes.map { String($0) }
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


