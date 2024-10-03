//
//  SemanticSearchView.swift
//  Alpha1
//
//  Created by A on 8/22/23.
//

import SwiftUI

struct SemanticSearchView: View {
    @EnvironmentObject var dataController: DataController
    @Binding var documentSelectionState: DocumentSelectionState
    
    @State private var tokensAvailableForEmphasis: [DataController.UniqueTokens] = []
    var emphasisTokenPairs: [(id: String, left: DataController.UniqueTokens, right: DataController.UniqueTokens?)] {
        var tokenPairs: [(id: String, left: DataController.UniqueTokens, right: DataController.UniqueTokens?)] = []
        var i = 0
        while i < tokensAvailableForEmphasis.count {
            let left: DataController.UniqueTokens = tokensAvailableForEmphasis[i]
            var right: DataController.UniqueTokens? = nil
            i += 1
            if i < tokensAvailableForEmphasis.count {
                right = tokensAvailableForEmphasis[i]
                i += 1
            }
            tokenPairs.append((id: UUID().uuidString, left: left, right: right))
        }
        return tokenPairs
    }
    
    
    func resetTokenEmphasis() {
            tokensAvailableForEmphasis = []
            documentSelectionState.semanticSearchParameters.resetEmphasisStructures()
    }
    func getAvailableEmphasisTokens() async {
        Task {
            let tokensStructure = await dataController.getQueryTokensForSemanticSearchWithArray(searchText: documentSelectionState.semanticSearchParameters.searchText)
                                            
            await MainActor.run {
                if tokensStructure.isEmpty {
                    documentSelectionState.semanticSearchParameters.tokensToEmphasize = Set<String>()
                    tokensAvailableForEmphasis = []
                } else {
                    tokensAvailableForEmphasis = tokensStructure
                }
            }
        }
    }
    var searchTextIsAvailable: Bool {
        return documentSelectionState.semanticSearchParameters.search && !documentSelectionState.semanticSearchParameters.searchText.isEmpty
    }
    
    @State private var searchPromptIsShowing: Bool = false
    @State private var attributesViewIsShowing: Bool = false

        
    var body: some View {
        
        VStack {
            VStack(alignment: .leading) {
                Text("Semantic search options")
                    .font(.title2.bold())
                
                Text("This will limit the result set to a maximum of 100 documents sorted by relevance.")
                    .font(REConstants.Fonts.baseSubheadlineFont)
                    .foregroundStyle(.gray)
                Text("The model must be trained and compressed in order to run a semantic search.")
                    .font(REConstants.Fonts.baseSubheadlineFont)
                    .foregroundStyle(.gray)
                Divider()
                    .padding(.bottom)
            }
            .padding([.leading, .trailing])
            
            HStack {
                Toggle(isOn: $documentSelectionState.semanticSearchParameters.search) {
                    Text("Semantic search")
                }
                .toggleStyle(.switch)
                Spacer()
            }
            .padding([.leading, .trailing, .top])

            VStack(alignment: .center) {
                Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 10, verticalSpacing: 10) {
                    GridRow {
                        Text("Datasplit to search:")
                            .font(.title3)
                            .foregroundStyle(.gray)
                            .gridCellAnchor(.leading)
                        SingleDatasplitView(datasetId: documentSelectionState.datasetId)
                            .monospaced()
                            .gridCellAnchor(.leading)
                    }
                    GridRow {
                        Text("Search text:")
                            .font(.title3)
                            .foregroundStyle(.gray)
                            .gridCellColumns(2)
                    }
                    GridRow {
                        Color.clear
                            .gridCellUnsizedAxes([.vertical, .horizontal])
                        VStack {
                            TextEditor(text:  $documentSelectionState.semanticSearchParameters.searchText)
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
                            Text("\(REConstants.SemanticSearch.maxAllowedCharacters - documentSelectionState.semanticSearchParameters.searchText.count) characters remaining")
                                .italic()
                                .font(REConstants.Fonts.baseSubheadlineFont)
                        }
                        .onChange(of: documentSelectionState.semanticSearchParameters.searchText) {
                            if documentSelectionState.semanticSearchParameters.searchText.count > REConstants.SemanticSearch.maxAllowedCharacters {
                                documentSelectionState.semanticSearchParameters.searchText = String(documentSelectionState.semanticSearchParameters.searchText.prefix(REConstants.SemanticSearch.maxAllowedCharacters))
                            }
                            // whenever the search text changes, reset the token emphasis structures:
                            resetTokenEmphasis()
                        }
                    }
                    GridRow {
                        HStack(alignment: .center) {
                            Image(systemName: "rectangle.and.pencil.and.ellipsis")
                                .foregroundStyle(searchTextIsAvailable ? Color.blue.gradient : Color.gray.gradient)
                            Text("Search prompt:")
                                .font(.title3)
                                .foregroundStyle(.gray)
                            PopoverViewWithButtonLocalState(popoverViewText: "The above search text will be placed after this prompt. This prompt can be empty, but the above search text must always be non-empty to successfully run a search.")
                        }
                        HStack(alignment: .lastTextBaseline) {
                            Text("Characters: \(documentSelectionState.semanticSearchParameters.searchPrompt.count)")
                                .font(.title3)
                                .monospaced()
                                .foregroundStyle(.gray)
                            Spacer()

                            Text("Pre-fill: ")
                                .font(.title3)
                                .foregroundStyle(.gray)
                            HStack(alignment: .center) {
                                Text("Default")
                                    .font(.title3.smallCaps())
                                    .monospaced()
                                    .foregroundStyle(.blue)
                                    .onTapGesture {
                                        documentSelectionState.semanticSearchParameters.searchPrompt = dataController.defaultPrompt
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
                                        documentSelectionState.semanticSearchParameters.searchPrompt = REConstants.SemanticSearch.defaultQuestionPrompt
                                    }
                            }
                        }
                    }
                    .onTapGesture {
                        if searchTextIsAvailable {
                            withAnimation {
                                searchPromptIsShowing.toggle()
                            }
                        }
                    }
                    if searchPromptIsShowing {
                        GridRow {
                            Color.clear
                                .gridCellUnsizedAxes([.vertical, .horizontal])
                            VStack {
                                TextEditor(text:  $documentSelectionState.semanticSearchParameters.searchPrompt)
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
                                Text("\(REConstants.DataValidator.maxPromptRawCharacterLength - documentSelectionState.semanticSearchParameters.searchPrompt.count) characters remaining")
                                    .italic()
                                    .font(REConstants.Fonts.baseSubheadlineFont)
                            }
                            .onChange(of: documentSelectionState.semanticSearchParameters.searchPrompt) {
                                if documentSelectionState.semanticSearchParameters.searchPrompt.count > REConstants.DataValidator.maxPromptRawCharacterLength {
                                    documentSelectionState.semanticSearchParameters.searchPrompt = String(documentSelectionState.semanticSearchParameters.searchPrompt.prefix(REConstants.DataValidator.maxPromptRawCharacterLength))
                                }
                                // Currently, the prompt does not participate in the token emphasis:
                                //resetTokenEmphasis()
                            }
                        }
                    }
    
                    GridRow {
                        HStack(alignment: .center) {
                            Image(systemName: "point.3.filled.connected.trianglepath.dotted")
                                .foregroundStyle(searchTextIsAvailable ? Color.blue.gradient : Color.gray.gradient)
                            Text(REConstants.PropertyDisplayLabel.attributesFull+":")
                                .font(.title3)
                                .foregroundStyle(.gray)
                        }
                        Text("Count: \(documentSelectionState.semanticSearchParameters.searchAttributes.count)")
                            .font(.title3)
                            .monospaced()
                            .foregroundStyle(.gray)
                    }
                    .onTapGesture {
                        if searchTextIsAvailable {
                            attributesViewIsShowing.toggle()
                        }
                    }
                    GridRow {
                        Text("Field to search:")
                            .font(.title3)
                            .foregroundStyle(.gray)
                        Text("document")
                            .font(.title3)
                            .foregroundStyle(.gray)
                    }
                    GridRow {
                        Text("Emphasize select keywords")
                            .font(.title3)
                            .foregroundStyle(.gray)
                        Toggle(isOn: $documentSelectionState.semanticSearchParameters.emphasizeSelectTokens) {
                        }
                        .toggleStyle(.switch)
                    }
                    .disabled(!searchTextIsAvailable)
                    .onChange(of: documentSelectionState.semanticSearchParameters.emphasizeSelectTokens) {
                        if documentSelectionState.semanticSearchParameters.emphasizeSelectTokens, documentSelectionState.semanticSearchParameters.search, !documentSelectionState.semanticSearchParameters.searchText.isEmpty {
                            Task {
                                await getAvailableEmphasisTokens()
                            }
                        } else {
                            resetTokenEmphasis()
                        }
                    }
                    if documentSelectionState.semanticSearchParameters.emphasizeSelectTokens && tokensAvailableForEmphasis.isEmpty {
                        GridRow {
                            Color.clear
                                .gridCellUnsizedAxes([.vertical, .horizontal])
                            VStack {
                                ProgressView()
                                HStack {
                                    Spacer()
                                    Text("Retrieving available keywords")
                                        .font(REConstants.Fonts.baseFont)
                                        .foregroundStyle(.gray)
                                    Spacer()
                                }
                            }
                        }
                    }
                }.font(REConstants.Fonts.baseFont)
                
                ScrollView {
                    VStack {
                        if documentSelectionState.semanticSearchParameters.emphasizeSelectTokens && !tokensAvailableForEmphasis.isEmpty {
                            HStack {
                                Spacer()
                                Text("Select keywords to emphasize")
                                    .foregroundStyle(.gray)
                                PopoverViewWithButtonLocalStateOptions(popoverViewText: "Click a keyword to emphasize / de-emphasize.", frameWidth: 250)
                                Spacer()
                            }
                            .font(REConstants.Fonts.baseFont)

                            ForEach(emphasisTokenPairs, id:\.id) { tokenPair in
                                
                                HStack(alignment: .lastTextBaseline) {
                                    let token = tokenPair.left
                                    HStack {
                                        Text(token.original)
                                            .padding(8)
                                    }
                                    .frame(height: 30)
                                    .foregroundStyle(documentSelectionState.semanticSearchParameters.tokensToEmphasize.contains(token.tokenized) ? REConstants.REColors.reSemanticHighlight : .gray)
                                    .underline(documentSelectionState.semanticSearchParameters.tokensToEmphasize.contains(token.tokenized))
                                    .font(.system(size: 18))
                                    .frame(maxWidth: .infinity)
                                    .modifier(SimpleBaseBorderModifierWithColorOption(useReBackgroundDarker: documentSelectionState.semanticSearchParameters.tokensToEmphasize.contains(token.tokenized)))
                                    .onTapGesture {
                                        if documentSelectionState.semanticSearchParameters.tokensToEmphasize.contains(token.tokenized) {
                                            documentSelectionState.semanticSearchParameters.tokensToEmphasize.remove(token.tokenized)
                                        } else {
                                            documentSelectionState.semanticSearchParameters.tokensToEmphasize.insert(token.tokenized)
                                        }
                                    }
                                    if let token = tokenPair.right {
                                        HStack {
                                            Text(token.original)
                                                .padding(8)
                                        }
                                        .frame(height: 30)
                                        .foregroundStyle(documentSelectionState.semanticSearchParameters.tokensToEmphasize.contains(token.tokenized) ? REConstants.REColors.reSemanticHighlight : .gray)
                                        .underline(documentSelectionState.semanticSearchParameters.tokensToEmphasize.contains(token.tokenized))
                                        .font(.system(size: 18))
                                        .frame(maxWidth: .infinity)
                                        .modifier(SimpleBaseBorderModifierWithColorOption(useReBackgroundDarker: documentSelectionState.semanticSearchParameters.tokensToEmphasize.contains(token.tokenized)))
                                        .onTapGesture {
                                            if documentSelectionState.semanticSearchParameters.tokensToEmphasize.contains(token.tokenized) {
                                                documentSelectionState.semanticSearchParameters.tokensToEmphasize.remove(token.tokenized)
                                            } else {
                                                documentSelectionState.semanticSearchParameters.tokensToEmphasize.insert(token.tokenized)
                                            }
                                        }
                                    } else {
                                        HStack {
                                            Text("")
                                                .padding(8)
                                        }
                                        .frame(height: 30)
                                        .foregroundStyle(.gray)
                                        .font(.system(size: 18))
                                        .frame(maxWidth: .infinity)
                                        .modifier(SimpleBaseBorderModifierWithColorOption())
                                        .hidden()
                                    }
                                }
                            }
                        }
                    }
                    .padding([.leading, .trailing])
                    .padding([.leading, .trailing])
                }
                
                Spacer()
            }
            .onAppear {
                if documentSelectionState.semanticSearchParameters.search, !documentSelectionState.semanticSearchParameters.searchText.isEmpty, documentSelectionState.semanticSearchParameters.emphasizeSelectTokens {
                    Task {
                        await getAvailableEmphasisTokens()
                    }
                }
            }
            .disabled(!documentSelectionState.semanticSearchParameters.search)
            .opacity(!documentSelectionState.semanticSearchParameters.search ? 0.25 : 1.0)
            
        }

        .frame(height: 715+300)
        .font(REConstants.Fonts.baseFont)
        .padding()
        .modifier(SimpleBaseBorderModifier())
        .padding()
        
        .sheet(isPresented: $attributesViewIsShowing,
               onDismiss: {
//            refreshInterface()
        }) {
            SemanticSearchAttributesView(documentSelectionState: $documentSelectionState)
                .padding()
                .frame(
                 minWidth: 600, maxWidth: 800,
                 minHeight: 600, maxHeight: 600)
        }
    }
}

