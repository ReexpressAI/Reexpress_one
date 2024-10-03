//
//  RerankingCrossEncodeOptionsView.swift
//  Alpha1
//
//  Created by A on 9/9/23.
//

import SwiftUI


struct RerankingCrossEncodeOptionsView: View {
    @EnvironmentObject var dataController: DataController
    @Binding var documentSelectionState: DocumentSelectionState
    
    var body: some View {
        VStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 20) {
                Text("Reranking constructs new documents with the following structure:")
                    .foregroundStyle(.gray)
                Grid {
                    GridRow {
                        Text("prompt:")
                            .gridColumnAlignment(.trailing)
                        
                        Text("Reranking prompt")
                            .gridColumnAlignment(.leading)
                            .foregroundStyle(.gray)
                    }
                    GridRow {
                        Text("document:")
                            .gridColumnAlignment(.trailing)
                        
                        Text("Search text + Retrieved document")
                            .gridColumnAlignment(.leading)
                            .foregroundStyle(.gray)
                    }
                }
                .monospaced()
                .padding()
                .modifier(SimpleBaseBorderModifier())
                .padding()
                Grid(alignment: .bottom) {
                    GridRow {
                        Text("The reranking prompt and search text can be the same as\nthose from the original semantic search, or changed below.")
                            .italic()
                            .foregroundStyle(.gray)
                            .gridColumnAlignment(.leading)
                        
                        PopoverViewWithButtonLocalStateOptions(popoverViewText: "The structure of the new documents should be similar to that seen by the model in the Training and Calibration sets.", optionalSubText: "Up to \(SentencepieceConstants.maxTokenLength) tokens of each resulting document will be seen by the model. No more than \(REConstants.DataValidator.maxDocumentRawCharacterLength) characters will be saved to the project file.", frameWidth: 400)
                            .gridColumnAlignment(.leading)
                    }
                }
                .padding([.leading, .trailing, .bottom])

            }
            .padding()
            Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 10, verticalSpacing: 10) {

                GridRow {
                    HStack(alignment: .center) {
                        Text("Reranking prompt:")
                            .font(.title3)
                            .foregroundStyle(.gray)
                    }
                    HStack(alignment: .lastTextBaseline, spacing: 0) {
                        Spacer()
                        Text("Pre-fill: ")
                            .font(.title3)
                            .foregroundStyle(.gray)
                        HStack(alignment: .center) {
                            Text("Search")
                                .font(.title3.smallCaps())
                                .monospaced()
                                .foregroundStyle(.blue)
                                .onTapGesture {
                                    documentSelectionState.semanticSearchParameters.rerankParameters.rerankPrompt = documentSelectionState.semanticSearchParameters.searchPrompt
                                }
                            Divider()
                                .frame(width: 1, height: 14)
                                .overlay(.gray)
                                .padding([.leading, .trailing], 5)
                            Text("Default")
                                .font(.title3.smallCaps())
                                .monospaced()
                                .foregroundStyle(.blue)
                                .onTapGesture {
                                    documentSelectionState.semanticSearchParameters.rerankParameters.rerankPrompt = dataController.defaultPrompt
                                }
                            Divider()
                                .frame(width: 1, height: 14)
                                .overlay(.gray)
                                .padding([.leading, .trailing], 5)
                            Text("Question")
                                .font(.title3.smallCaps())
                                .monospaced()
                                .foregroundStyle(.blue)
                                .onTapGesture {
                                    documentSelectionState.semanticSearchParameters.rerankParameters.rerankPrompt = REConstants.SemanticSearch.defaultQuestionPrompt
                                }
                        }
                    }
                }
                GridRow {
                    Color.clear
                        .gridCellUnsizedAxes([.vertical, .horizontal])
                    VStack {
                        TextEditor(text:  $documentSelectionState.semanticSearchParameters.rerankParameters.rerankPrompt)
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
                        Text("\(REConstants.DataValidator.maxPromptRawCharacterLength - documentSelectionState.semanticSearchParameters.rerankParameters.rerankPrompt.count) characters remaining")
                            .italic()
                            .font(REConstants.Fonts.baseSubheadlineFont)
                    }
                    .onChange(of: documentSelectionState.semanticSearchParameters.rerankParameters.rerankPrompt) {
                        if documentSelectionState.semanticSearchParameters.rerankParameters.rerankPrompt.count > REConstants.DataValidator.maxPromptRawCharacterLength {
                            documentSelectionState.semanticSearchParameters.rerankParameters.rerankPrompt = String(documentSelectionState.semanticSearchParameters.rerankParameters.rerankPrompt.prefix(REConstants.DataValidator.maxPromptRawCharacterLength))
                        }
                    }
                }
                GridRow {
                    Text("Search text:")
                        .font(.title3)
                        .foregroundStyle(.gray)
                    HStack(alignment: .lastTextBaseline) {
                        Spacer()
                        Text("Pre-fill: ")
                            .font(.title3)
                            .foregroundStyle(.gray)
                        Text("Search")
                            .font(.title3.smallCaps())
                            .monospaced()
                            .foregroundStyle(.blue)
                            .onTapGesture {
                                documentSelectionState.semanticSearchParameters.rerankParameters.rerankSearchText = documentSelectionState.semanticSearchParameters.searchText
                            }
                    }
                }
                GridRow {
                    Color.clear
                        .gridCellUnsizedAxes([.vertical, .horizontal])
                    VStack {
                        TextEditor(text:  $documentSelectionState.semanticSearchParameters.rerankParameters.rerankSearchText)
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
                        Text("\(REConstants.SemanticSearch.maxAllowedCharacters - documentSelectionState.semanticSearchParameters.rerankParameters.rerankSearchText.count) characters remaining")
                            .italic()
                            .font(REConstants.Fonts.baseSubheadlineFont)
                    }
                    .onChange(of: documentSelectionState.semanticSearchParameters.rerankParameters.rerankSearchText) {
                        if documentSelectionState.semanticSearchParameters.rerankParameters.rerankSearchText.count > REConstants.SemanticSearch.maxAllowedCharacters {
                            documentSelectionState.semanticSearchParameters.rerankParameters.rerankSearchText = String(documentSelectionState.semanticSearchParameters.rerankParameters.rerankSearchText.prefix(REConstants.SemanticSearch.maxAllowedCharacters))
                        }
                    }
                }


             }.font(REConstants.Fonts.baseFont)
            
            Spacer()
        }
        
    }
}

