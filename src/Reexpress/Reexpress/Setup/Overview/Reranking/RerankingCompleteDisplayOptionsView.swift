//
//  RerankingCompleteDisplayOptionsView.swift
//  Alpha1
//
//  Created by A on 9/10/23.
//

import SwiftUI

struct RerankCompleteStatusView: View {
    var totalDocumentsInCurrentSelection: Int
    var body: some View {
        HStack {
            Divider()
                .frame(width: 2, height: 25)
                .overlay(.gray)
            Grid {
                GridRow {
                    Text("Documents available for display:")
                        .gridColumnAlignment(.trailing)
                        .foregroundStyle(.gray)
                        .font(REConstants.Fonts.baseFont)
                    Text(String(totalDocumentsInCurrentSelection))
                        .gridColumnAlignment(.leading)
                        .monospaced()
                        .font(REConstants.Fonts.baseFont)
                        .foregroundStyle(.orange)
                        .opacity(0.75)
                }
            }
        }
    }
}

struct RerankingCompleteDisplayOptionsView: View {
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var dataController: DataController
    
    @Binding var documentSelectionState: DocumentSelectionState
    
    @Binding var rerankedDocumentIDsStructure: (allRerankedCrossEncodedDocumentIDs: [String], onlyMatchesTargetRerankedCrossEncodedDocumentIDs: [String])
    @Binding var retrievingDocumentStats: Bool
    
    var totalDocumentsInCurrentSelection: Int {
        return rerankedDocumentIDsStructure.allRerankedCrossEncodedDocumentIDs.count
    }
    var totalDocumentsMatchingRerankingTarget: Int {
        return rerankedDocumentIDsStructure.onlyMatchesTargetRerankedCrossEncodedDocumentIDs.count
    }
    var body: some View {
        
        ScrollView {
            VStack(alignment: .leading) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Reranking Complete")
                        .font(.title2.bold())
                    if !retrievingDocumentStats {
                        RerankCompleteStatusView(totalDocumentsInCurrentSelection: totalDocumentsInCurrentSelection)
                    }
                    Spacer()
                }
                
                VStack {
                    if retrievingDocumentStats {
                        VStack {
                            Spacer()
                                HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                            Text("Retrieving display options")
                                .font(REConstants.Fonts.baseFont)
                                .foregroundStyle(.gray)
                            Spacer()
                        }
                        .padding()
                        .modifier(SimpleBaseBorderModifier())
                    } else {
                        VStack {
                            HStack {
                                Grid {
                                    GridRow {
                                        Text("Documents matching the reranking target label:")
                                            .gridColumnAlignment(.trailing)
                                            .foregroundStyle(.gray)
                                            .font(REConstants.Fonts.baseFont)
                                        Text(String(totalDocumentsMatchingRerankingTarget))
                                            .gridColumnAlignment(.leading)
                                            .monospaced()
                                            .font(REConstants.Fonts.baseFont)
                                            .foregroundStyle(.orange)
                                            .opacity(0.75)
                                    }
                                }
                                Spacer()
                            }
                            .padding()
                            HStack {
                                Toggle(isOn: $documentSelectionState.semanticSearchParameters.rerankParameters.rerankDisplayOptions.createNewDocumentInstance) {
                                    Text("Return the results as new cross-encoded document instances")
                                }
                                .toggleStyle(.switch)
                                Spacer()
                            }
                            .padding([.leading, .trailing, .top])
                            VStack {
                                if !documentSelectionState.semanticSearchParameters.rerankParameters.rerankDisplayOptions.createNewDocumentInstance {
                                    Text("The documents returned will be a subset of those from the initial semantic search. The uncertainty estimates displayed will be those of the original documents.")
                                        .padding([.leading, .trailing])
                                } else {
                                    Text("Pro-tip: The new documents can be labeled and saved to improve subsequent reranking. The new cross-encoded documents will be initialized as **unlabeled**, but for reference, the ground-truth label of the retrieved document is appended as a suffix to the new id with the following string: '_documentLabel_LABEL'.")
                                        .padding([.leading, .trailing])
                                }
                            }
                            .foregroundStyle(.gray)
                            .padding()
                            HStack {
                                Toggle(isOn: $documentSelectionState.semanticSearchParameters.rerankParameters.rerankDisplayOptions.onlyShowMatchesToTargetLabel) {
                                    Text("Only return documents with predictions that match the reranking target label")
                                }
                                .toggleStyle(.switch)
                                Spacer()
                            }
                            .padding([.leading, .trailing, .top])
                            if documentSelectionState.semanticSearchParameters.rerankParameters.rerankDisplayOptions.onlyShowMatchesToTargetLabel && totalDocumentsMatchingRerankingTarget == 0 {
                                VStack {
                                    Text("Since no documents matched the reranking target label, no documents will be returned with the current option selections.")
                                        .foregroundStyle(.red)
                                        .opacity(0.75)
                                        .italic()
                                        .padding([.leading, .trailing])
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
