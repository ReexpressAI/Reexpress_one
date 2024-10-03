//
//  DataSelectionMainView.swift
//  Alpha1
//
//  Created by A on 8/18/23.
//

import SwiftUI

enum SelectionIntent: Int, Hashable {
    case partition
    case constraints
    case sortOptions
    case keywordSearch
    case semanticSearch
}

struct DataSelectionMainView: View {
    
    //@Environment(\.dismiss) var dismiss
    //@Environment(\.managedObjectContext) var moc
    @EnvironmentObject var dataController: DataController
    
    @Binding var documentSelectionState: DocumentSelectionState
    
    @State private var selectionIntent: SelectionIntent = .partition
    
    @State private var partitionSelectionViewType: PartitionSelectionView.PartitionSelectionViewType = .visual
    var disableSemanticSearch: Bool = false
    var disableSortOptions: Bool = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                VStack(alignment: .leading) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Selection")
                            .font(.title2.bold())

                        Spacer()
                        HStack(alignment: .lastTextBaseline) {
                            Button {
                                documentSelectionState.reset()
                            } label: {
                                UncertaintyGraphControlButtonLabelWithCaptionVStack(buttonImageName: "restart", buttonTextCaption: "Reset")
                            }
                            .buttonStyle(.borderless)
                            
                            HelpAssistanceView_Selection()

                        }
                    }

                }

                HStack {
                    DatasplitSelectorViewSelectionRequired(selectedDatasetId: $documentSelectionState.datasetId, showLabelTitle: true)
                    Spacer()
                }
                Picker(selection: $selectionIntent) {
                    Text(REConstants.SelectionDisplayLabels.dataPartitionSelectionTab).tag(.partition as SelectionIntent)
                    Text("Constraints").tag(.constraints as SelectionIntent)
                    if !disableSortOptions {
                        Text("Sorting").tag(.sortOptions as SelectionIntent)
                    }
                    Text("Keyword Search").tag(.keywordSearch as SelectionIntent)
                    Text("Semantic Search").tag(.semanticSearch as SelectionIntent)
                } label: {
                    Text("Selection Options:")
                }
                .pickerStyle(.segmented)
                .font(REConstants.Fonts.baseFont)
                HStack {
                    switch selectionIntent {
                    case .partition:
                        PartitionSelectionView(documentSelectionState: $documentSelectionState, partitionSelectionViewType: $partitionSelectionViewType)
                    case .constraints:
                        ConstraintsSelectionView(documentSelectionState: $documentSelectionState)
                    case .sortOptions:
                        SortingSelectionView(documentSelectionState: $documentSelectionState)
                    case .keywordSearch:
                        KeywordSelectionView(documentSelectionState: $documentSelectionState)
                    case .semanticSearch:
                        if disableSemanticSearch {
                            SemanticSearchDisabledView()
                        } else {
                            SemanticSearchView(documentSelectionState: $documentSelectionState)
                        }
                    }
                }
            }
            .padding([.leading, .trailing])
        }
        .scrollBounceBehavior(.basedOnSize)
        .padding()
        .modifier(SimpleBaseBorderModifier())
        .padding()
    }
}

