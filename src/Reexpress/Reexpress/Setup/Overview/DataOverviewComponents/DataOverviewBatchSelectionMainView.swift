//
//  DataOverviewBatchSelectionMainView.swift
//  Alpha1
//
//  Created by A on 8/27/23.
//

import SwiftUI

//struct DocumentBatchChangeState {
//    var deleteAllDocuments: Bool = false
//    var changeLabel: Bool = false
//    var transferDatasplit: Bool = false
//    var markAsViewed: Bool = false
//
//    var newLabelID: Int?
//    var newDatasplitID: Int?
//}


struct DataOverviewBatchSelectionMainView: View {
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var dataController: DataController
    
    @Binding var multipleSelectedDocuments: Set<TableDataPoint.ID>
    @Binding var documentBatchChangeState: DocumentBatchChangeState
    var datasetId: Int?
    enum ChangeOptionsIntent: Int, CaseIterable, Hashable {
        case viewed
        case label
        case datasplit
        case group
        case info
    }
    @State private var changeOptionsIntent: ChangeOptionsIntent = .viewed
    var totalDocumentsInCurrentSelection: Int = 0
    var body: some View {

        ScrollView {
            VStack(alignment: .leading) {
                VStack(alignment: .leading) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Batch Update Operation")
                            .font(.title2.bold())
                        CurrentMultiSelectionStatusView(multipleSelectedDocuments: $multipleSelectedDocuments, documentBatchChangeState: $documentBatchChangeState, totalDocumentsInCurrentSelection: totalDocumentsInCurrentSelection)
                        Spacer()
                    }
                    Toggle(isOn: $documentBatchChangeState.applyChangesToAllDocumentsAndRowsInSelection) {
                        Text("Apply changes to **all** documents (across **all** rows) currently retrieved.")
                            .font(REConstants.Fonts.baseFont)
                    }
                    
                    if multipleSelectedDocuments.isEmpty && !documentBatchChangeState.applyChangesToAllDocumentsAndRowsInSelection {
                        VStack(alignment: .center) {
                            Spacer()
                            HStack(alignment: .center) {
                                Spacer()
                                Text("Select one or more documents in the table to initiate a batch update operation. Alternatively, choose the option above to apply the changes to all currently retrieved documents.")
                                    .font(REConstants.Fonts.baseFont)
                                    .foregroundStyle(.gray)
                                    .italic()
                                Spacer()
                            }
                            .frame(height: 425)
                            Spacer()
                        }
                    }
                    
                }
                if !multipleSelectedDocuments.isEmpty || documentBatchChangeState.applyChangesToAllDocumentsAndRowsInSelection {
                    Toggle(isOn: $documentBatchChangeState.deleteAllDocuments) {
                        Text("Delete all selected documents.")
                            .font(REConstants.Fonts.baseFont)
                    }
                    
                        Picker(selection: $changeOptionsIntent) {
                            ForEach(ChangeOptionsIntent.allCases, id:\.self) { intent in
                                switch intent {
                                case .viewed:
                                    Text("Viewed").tag(intent)
                                case .label:
                                    Text("Label").tag(intent)
                                case .group:
                                    Text("Group").tag(intent)
                                case .info:
                                    Text("Info").tag(intent)
                                case .datasplit:
                                    Text("Datasplit").tag(intent)
                                }
                            }
                        } label: {
                            Text("Change Options:")
                        }
                        .pickerStyle(.segmented)
                        .disabled(documentBatchChangeState.deleteAllDocuments)
                    VStack {
                        if documentBatchChangeState.deleteAllDocuments {
                            VStack(alignment: .center) {
                                Spacer()
                                Grid(alignment: .center) {
                                    GridRow {
                                        Text("This action cannot be undone and will remove all data associated with the selected document(s).")
                                            .bold()
                                            .foregroundStyle(.red)
                                            .opacity(0.75)
                                            .gridColumnAlignment(.center)
                                    }
                                }
                                .padding()
                                .frame(height: 350)
                                Spacer()
                            }

                        } else {
                            VStack {
                                switch changeOptionsIntent {
                                case .viewed:
                                    HStack {
                                        Toggle(isOn: $documentBatchChangeState.changeViewedState) {
                                            Text("Change the Viewed State of all selected document(s)")
                                        }
                                        .toggleStyle(.switch)
                                        Spacer()
                                    }
                                    .padding([.leading, .trailing, .top])
                                    
                                    VStack {
                                        Picker(selection: $documentBatchChangeState.newDocumentViewedState) {
                                            HStack(alignment: .lastTextBaseline) {
                                                Text("Mark all as Viewed")
                                                PopoverViewWithButtonLocalState(popoverViewText: "The Last Viewed date of any existing Viewed document(s) will be updated, as well.")
                                                    .foregroundStyle(documentBatchChangeState.changeViewedState ? .white : .gray)
                                            }.tag(DocumentViewedState.viewed)
                                            Text("Mark all as Unviewed").tag(DocumentViewedState.unviewed)
                                        } label: {
                                            
                                        }
                                        .pickerStyle(.radioGroup)
                                        .disabled(!documentBatchChangeState.changeViewedState)
                                        //Spacer()
                                    }
                                    .padding([.leading, .trailing, .top])
                                    
                                case .label:
                                    HStack {
                                        Toggle(isOn: $documentBatchChangeState.changeLabel) {
                                            Text("Change the ground-truth label of all selected document(s)")
                                        }
                                        .toggleStyle(.switch)
                                        Spacer()
                                    }
                                    .padding([.leading, .trailing, .top])
                                    if documentBatchChangeState.changeLabel {
                                        DocumentBatchLabelChangeView(documentBatchChangeState: $documentBatchChangeState)
                                    }
                                    
                                case .datasplit:
                                    HStack {
                                        Toggle(isOn: $documentBatchChangeState.transferDatasplit) {
                                            Text("Transfer all selected document(s) to another datasplit")
                                        }
                                        .toggleStyle(.switch)
                                        Spacer()
                                    }
                                    .padding([.leading, .trailing, .top])
                                    HStack {
                                        Spacer()
                                        Text("A maximum of \(REConstants.DatasetsConstraints.maxTotalLines) documents are allowed per Datasplit")
                                            .font(.title3)
                                            .foregroundStyle(.gray)
                                        Spacer()
                                    }
                                    if documentBatchChangeState.transferDatasplit {
                                        DocumentBatchDatasplitTransferChangeView(documentBatchChangeState: $documentBatchChangeState, datasetId: datasetId, documentCountInSelection: multipleSelectedDocuments.count)
                                    }
                                case .group:
                                    HStack {
                                        Toggle(isOn: $documentBatchChangeState.changeGroupField) {
                                            HStack {
                                                HStack(spacing: 0) {
                                                    Text("Change the")
                                                        .font(REConstants.Fonts.baseFont)
                                                        .bold()
                                                    Text(" group ")
                                                        .font(REConstants.Fonts.baseFont)
                                                        .bold()
                                                        .foregroundColor(.gray)
                                                        .monospaced()
                                                    Text("field of all selected document(s)")
                                                        .font(REConstants.Fonts.baseFont)
                                                        .bold()
                                                }
                                            }
                                        }
                                        .toggleStyle(.switch)
                                        Spacer()
                                    }
                                    .padding([.leading, .trailing, .top])
                                    if documentBatchChangeState.changeGroupField {
                                        DocumentBatchGroupChangeView(documentBatchChangeState: $documentBatchChangeState)
                                    }
                                case .info:
                                    HStack {
                                        Toggle(isOn: $documentBatchChangeState.changeInfoField) {
                                            HStack {
                                                HStack(spacing: 0) {
                                                    Text("Change the")
                                                        .font(REConstants.Fonts.baseFont)
                                                        .bold()
                                                    Text(" info ")
                                                        .font(REConstants.Fonts.baseFont)
                                                        .bold()
                                                        .foregroundColor(.gray)
                                                        .monospaced()
                                                    Text("field of all selected document(s)")
                                                        .font(REConstants.Fonts.baseFont)
                                                        .bold()
                                                }
                                            }
                                        }
                                        .toggleStyle(.switch)
                                        Spacer()
                                    }
                                    .padding([.leading, .trailing, .top])
                                    if documentBatchChangeState.changeInfoField {
                                        DocumentBatchInfoChangeView(documentBatchChangeState: $documentBatchChangeState)
                                    }
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

//struct DataOverviewBatchSelectionMainView_Previews: PreviewProvider {
//    static var previews: some View {
//        DataOverviewBatchSelectionMainView()
//    }
//}
