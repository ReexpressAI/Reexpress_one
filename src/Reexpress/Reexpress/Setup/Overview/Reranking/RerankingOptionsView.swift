//
//  RerankingOptionsView.swift
//  Alpha1
//
//  Created by A on 9/9/23.
//

import SwiftUI

struct RerankingOptionsView: View {
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var dataController: DataController
    
    @Binding var documentSelectionState: DocumentSelectionState
    var semanticSearchResultsAvailableForReranking: Bool {
        return documentSelectionState.semanticSearchParameters.search && !documentSelectionState.semanticSearchParameters.searchText.isEmpty && documentSelectionState.semanticSearchParameters.retrievedDocumentIDs.count > 0
    }
    
    enum RerankingOptionsIntent: Int, CaseIterable, Hashable {
        //case resultType
        case target
        case promptAndText
        case attributes
    }
    @State private var rerankingOptionsIntent: RerankingOptionsIntent = .target
    var totalDocumentsInCurrentSelection: Int = 0
    var body: some View {

        ScrollView {
            VStack(alignment: .leading) {
                VStack(alignment: .leading) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Rerank Semantic Search Results")
                            .font(.title2.bold())
                        CurrentRerankStatusView(documentSelectionState: $documentSelectionState)
                        Spacer()
                    }
                    
                    
                    if !semanticSearchResultsAvailableForReranking {
                        VStack(alignment: .center) {
                            Spacer()
                            VStack {
                                HStack(alignment: .center) {
                                    Spacer()
                                    Text("Run a semantic search to enable reranking of the results.")
                                        .font(REConstants.Fonts.baseFont)
                                        .foregroundStyle(.gray)
                                        .italic()
                                    Spacer()
                                }
                                HStack(alignment: .center) {
                                    Spacer()
                                    Text("Go to **Select**->**Semantic Search** to get started.")
                                        .font(REConstants.Fonts.baseFont)
                                        .foregroundStyle(.gray)
                                        .padding()
                                    Spacer()
                                }
                            }
                            .frame(height: 425)
                            Spacer()
                        }
                    }
                    
                }
                if semanticSearchResultsAvailableForReranking {

                    
                        Picker(selection: $rerankingOptionsIntent) {
                            ForEach(RerankingOptionsIntent.allCases, id:\.self) { intent in
                                switch intent {
                                case .target:
                                    Text("Target").tag(intent)
                                case .promptAndText:
                                    Text("Prompt+Text").tag(intent)
                                case .attributes:
                                    Text("Attributes").tag(intent)
                                }
                            }
                        } label: {
                            Text("Reranking Options:")
                        }
                        .pickerStyle(.segmented)

                    VStack {
                            VStack {
                                switch rerankingOptionsIntent {

                                case .target:

                                    HStack {
                                        Picker(selection: $documentSelectionState.semanticSearchParameters.rerankParameters.rerankTargetLabel) {
                                            ForEach(0..<dataController.numberOfClasses, id:\.self) { label in
                                                HStack(alignment: .firstTextBaseline) {
                                                    if let labelDisplayName = dataController.labelToName[label] {
                                                        Text(labelDisplayName)
                                                            .font(REConstants.Fonts.baseFont)
                                                    } else { // for completeness, but this case should never occur
                                                        Text("\(label)")
                                                            .font(REConstants.Fonts.baseFont)
                                                    }
                                                }
                                                .tag(label)
                                            }
                                        } label: {
                                            Text("Reranking target label:")
                                        }
                                        .frame(width: 450)
                                        Spacer()
                                    }
                                    .padding()
                                    VStack(alignment: .leading, spacing: 20) {
  
                                        HStack(alignment: .top) {
                                            PopoverViewWithButtonLocalStateOptions(popoverViewText: "For reranking, it is assumed that the model has been trained in a multi-task fashion.\n\nSpecifically, in addition to the document classification task, there should be two additional labels with the meaning of **Relevant** and **Not Relevant**. The documents in Training and Calibration for these two additional labels should resemble the structure of the documents returned by reranking (see the Prompt+Text tab).", frameWidth: 400)
                                            Text("The above target label should be the label that corresponds to **Relevant** among the multi-task retrieval labels.")
                                                .foregroundStyle(.gray)
                                        }
                                    }
                                    
                                    .padding()
                                    
                                case .promptAndText:
                                    RerankingCrossEncodeOptionsView(documentSelectionState: $documentSelectionState)
                                    
                                case .attributes:
                                    HStack {
                                        Text("By default, the **\(REConstants.PropertyDisplayLabel.attributesFull)** of the retrieved document will be used when constructing the new cross-encoded documents. Additional options are available below.")
                                            .foregroundStyle(.gray)
                                        Spacer()
                                    }
                                    .padding()

                                    VStack(alignment: .leading) {
                                        Text("\(REConstants.PropertyDisplayLabel.attributesFull) merge policy:")
                                            .foregroundStyle(.gray)
                                        
                                        Picker(selection: $documentSelectionState.semanticSearchParameters.rerankParameters.rerankAttributesMergeOption.animation()) {
                                            Text("Use the attributes of the retrieved document").tag(RerankParameters.RerankAttributesMergeOption.document)
                                            Text("Use the attributes of the semantic search query").tag(RerankParameters.RerankAttributesMergeOption.search)
                                            Text("Average the attributes of the retrieved document and the search query").tag(RerankParameters.RerankAttributesMergeOption.average)
                                            Text("Calculate the absolute value of the difference between the attributes of the retrieved document and the search query").tag(RerankParameters.RerankAttributesMergeOption.absDifference)
                                            Text("Provide new attributes below").tag(RerankParameters.RerankAttributesMergeOption.new)
                                            Text("No attributes (set to a vector of 0's)").tag(RerankParameters.RerankAttributesMergeOption.none)
                                        } label: {

                                        }
                                        .pickerStyle(.radioGroup)
                                        .padding()
                                    }
                                    .padding([.leading, .trailing])
                                    
                                    if documentSelectionState.semanticSearchParameters.rerankParameters.rerankAttributesMergeOption == .new {
                                        RerankingAttributesView(documentSelectionState: $documentSelectionState)
                                    }
                                }
                        }
                    }
                    
                }
            }
            .font(REConstants.Fonts.baseFont)
            .padding([.leading, .trailing])
        }
        .scrollBounceBehavior(.basedOnSize)
        .padding()
        .modifier(SimpleBaseBorderModifier())
        .padding()
    }
}
