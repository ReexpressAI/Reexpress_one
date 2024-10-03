//
//  DataOverviewView.swift
//  Alpha1
//
//  Created by A on 7/16/23.
//

import SwiftUI

struct RowNumberPickerView: View {
    @EnvironmentObject var dataController: DataController
    @Binding var selectedDBRow: DatabaseRetrievalRow?
    var showLabelTitle: Bool = false
    @Binding var databaseRetrievalRows: [DatabaseRetrievalRow]
    var body: some View {
        Picker(selection: $selectedDBRow) {
            Text("Refresh").tag(nil as DatabaseRetrievalRow?)
            ForEach(databaseRetrievalRows, id: \.self) { row in
                Text("\(row.startRow) to \(row.endRow)")
                    .tag(row as DatabaseRetrievalRow?)
            }
        } label: {
                Text("Rows:")
                    .foregroundStyle(.gray)
                    .font(.title2)
        }
        .frame(width: 250)
        .pickerStyle(.menu)
    }
}

struct DatabaseRetrievalRow: Identifiable, Hashable {
    let id = UUID()
    let startRow: Int
    let endRow: Int
}



struct DataOverviewView: View {
    @Environment(\.managedObjectContext) var moc
    @Binding var loadedDatasets: Bool
    @EnvironmentObject var dataController: DataController
    
    @State var documentRetrievalInProgress: Bool = false
    @State var documentRetrievalError: Bool = false
    
    @State var databaseRetrievalRows: [DatabaseRetrievalRow] = []
    @State var selectedDBRow: DatabaseRetrievalRow? = nil
    //selectedDBRow_DocumentsOverview
    
    // Total number of rows that are viewed at any time. Note that this should exceed the total number of documents returned from a semantic search (currently 100). If not, then the logic needs to be updated to allow paging of the semantic search results (which is currently not implemented).
    var batchSize = REConstants.DatasetsViewConstraints.maxViewableTableRows // 200 //5000
    
    @State var sortedDataPoints: [Document] = []
    @State var documentIdToIndex: [String: Int] = [:]
    @State var fetchOffset: Int = 0
    @State var selectedDocument: Document.ID? = nil
    
    @State var multipleSelectedDocuments = Set<TableDataPoint.ID>()
    
    var lineLimit: Int = 6
    
//    @State private var datasetId: Int?
    @State var shouldScrollToTop: Bool = false

    
    @State var documentObject: Document?
    @State var showingDetailsPanelOnRight: Bool = true
    @State var tableMaxWidth: CGFloat = .infinity
    let buttonDividerHeight: CGFloat = 40.0
    
    @State var dataSelectionPopoverShowing: Bool = false
    @State var documentSelectionState_proposal: DocumentSelectionState
    
    @State var initiateFullRetrieval: Bool? = false
    
    @State var showingBatchSelectionView: Bool = false
    @State var existingDBRow_TempCopy: DatabaseRetrievalRow? = nil
    
    @State var showingRerankView: Bool = false
    
    @AppStorage(REConstants.UserDefaults.exploreTableWidthIsMaxKey) var exploreTableWidthIsMaxKey: Bool = true
    
    @State var showingClearCacheAlert: Bool = false
    @State var clearCacheMessage: String = ""
    
    @AppStorage(REConstants.UserDefaults.documentTextOpacity) var documentTextOpacity: Double = REConstants.UserDefaults.documentTextDefaultOpacity
    
    @State private var shouldCalllInitiateRetrieval: Bool = false

    @State private var showingBatchUpdateUnvailableMessage: Bool = false
    //loadedDatasets
    init(numberOfClasses: Int, loadedDatasets: Binding<Bool>) {
        _loadedDatasets = loadedDatasets
        _documentSelectionState_proposal = State(initialValue: DocumentSelectionState(numberOfClasses: numberOfClasses))
    }
    //let screenSize = NSScreen.main?.frame.size ?? CGSize(width: 800, height: 600)
    var currentDatasetId: Int? {  // used by batch change
        if let documentSelectionState = dataController.documentSelectionState_DocumentsOverview {
            
            if documentSelectionState.semanticSearchParameters.rerankParameters.reranking, documentSelectionState.semanticSearchParameters.rerankParameters.rerankDisplayOptions.createNewDocumentInstance {
                return REConstants.Datasets.placeholderDatasetId
            }
            
            return documentSelectionState.datasetId
        }
        return nil
    }
    func refreshAfterBatchChange() {
        selectedDBRow = nil
    }
    
    var totalDocumentsInCurrentSelection: Int {
        if let finalRow = databaseRetrievalRows.last {
            return finalRow.endRow + 1 // +1 since 0 indexed
        }
        return 0
    }
    
    @State private var isShowingInitializedAlert: Bool = false
    
    func getGlobalRowIndex(relativeRowIndex: Int) -> Int {
        if let selectedRow = selectedDBRow {
            return selectedRow.startRow + relativeRowIndex
        }
        return relativeRowIndex
    }
    
    var body: some View {
        
        if loadedDatasets {
            HStack {
                VStack {
                    
                    HStack {
                        HStack(alignment: .top) {
                            VStack {
                                HStack {
                                    if let documentSelectionState = dataController.documentSelectionState_DocumentsOverview {
                                    Text("Datasplit: ")
                                        .font(REConstants.Fonts.baseFont)
                                        .foregroundStyle(.gray)
                                        
                                        SingleDatasplitView(datasetId: documentSelectionState.datasetId)
                                            .font(REConstants.Fonts.baseFont)
                                            .monospaced()
                                    } else {
                                        Text("Click Select to get started")
                                            .font(REConstants.Fonts.baseFont)
                                            .italic()
                                    }
//                                    DatasplitSelectorView(datasetId: $datasetId, showLabelTitle: true)
                                    Spacer()
                                }
                                if let documentSelectionState = dataController.documentSelectionState_DocumentsOverview {
                                    HStack {
                                        if documentSelectionState.semanticSearchParameters.rerankParameters.reranking {
                                            if documentSelectionState.semanticSearchParameters.rerankParameters.rerankDisplayOptions.createNewDocumentInstance {
                                                Text("[Reranked: Transfer to save]")
                                                    .font(REConstants.Fonts.baseFont)
                                                    .foregroundStyle(.orange)
                                                    .opacity(0.75)
                                                PopoverViewWithButtonLocalStateOptions(popoverViewText: "The new cross-encoded documents are saved to a temporary cache. To permanently save, transfer the new document(s) to one of the existing datasplits.", frameWidth: 350)
                                            } else {
                                                Text("[Reranked]")
                                                    .font(REConstants.Fonts.baseFont)
                                                    .foregroundStyle(.orange)
                                                    .opacity(0.75)
                                            }
                                        }
                                        Spacer()
                                    }
                                }
                                HStack(alignment: .lastTextBaseline) {
                                    RowNumberPickerView(selectedDBRow: $selectedDBRow, showLabelTitle: true, databaseRetrievalRows: $databaseRetrievalRows)
                                    Spacer()
                                }
                            }
                            //Spacer()
                            //VStack(alignment: .trailing) {
                                HStack(alignment: .lastTextBaseline) {
                                    Button {
                                        dataSelectionPopoverShowing.toggle()
                                    } label: {
                                        UncertaintyGraphControlButtonLabelWithCaptionVStack(buttonImageName: "square.on.square.squareshape.controlhandles", buttonTextCaption: REConstants.MenuNames.selectName) //Partition")
                                    }
                                    .buttonStyle(.borderless)
                                    
                                    Divider()
                                        .frame(height: buttonDividerHeight)

                                    Button {
                                        withAnimation {
                                            showingDetailsPanelOnRight.toggle()
                                            if !showingDetailsPanelOnRight {
                                                // if the Details panel isn't showing, the table can always fill the view.
                                                tableMaxWidth = .infinity
                                            }
                                        }
                                    } label: {
                                        UncertaintyGraphControlButtonLabelWithCaptionVStack(buttonImageName: "list.bullet.rectangle.portrait", buttonTextCaption: "Details", buttonForegroundStyle: AnyShapeStyle(Color.blue.gradient))
                                    }
                                    .buttonStyle(.borderless)
                                }

                        }
                    }
                    .padding(.bottom)
                    .onChange(of: selectedDBRow) {
                        if let newDBRow = selectedDBRow, initiateFullRetrieval != nil {//let selectedDatasetId = datasetId {
                            documentRetrievalInProgress = true
                            retrieve(documentSelectionState: dataController.documentSelectionState_DocumentsOverview, fetchOffset: newDBRow.startRow, batchSize: batchSize, initiateRows: false)
                            shouldScrollToTop = true
                            dataController.selectedDBRow_DocumentsOverview = newDBRow
                            multipleSelectedDocuments.removeAll()
                        } else {
                            // If the user clicks the top row (corresponding to nil selection), we refresh.
                            initiateFullRetrieval = true
                            if !shouldCalllInitiateRetrieval { // no need to call again after a selection
                                //print("called initiateRetrieval() from change of db row")
                                initiateRetrieval()
                            }
                            shouldCalllInitiateRetrieval = false
                            dataController.selectedDBRow_DocumentsOverview = nil
                        }
                    }
                    
                    VStack {
                        HStack(alignment: .lastTextBaseline) {                            
                            
                            Spacer()
                            
                            /*Button {
                                // Mark all as unviewed
                                //viewModel.isShowingSummaryModal.toggle()
                            } label: {
                                UncertaintyGraphControlButtonLabelWithCaptionVStack(buttonImageName: "rectangle.and.text.magnifyingglass", buttonTextCaption: "Summary", buttonForegroundStyle: AnyShapeStyle(Color.blue.gradient))
                            }
                            .buttonStyle(.borderless)
                            Button {
                                // Mark all as unviewed
                                //viewModel.isShowingSummaryModal.toggle()
                            } label: {
                                UncertaintyGraphControlButtonLabelWithCaptionVStack(buttonImageName: "chart.dots.scatter", buttonTextCaption: "Graph", buttonForegroundStyle: AnyShapeStyle(Color.blue.gradient))
                            }
                            .buttonStyle(.borderless)
                            
                            Divider()
                                .frame(height: buttonDividerHeight)*/
                            
                            Button {
                                showingRerankView.toggle()
                            } label: {
                                UncertaintyGraphControlButtonLabelWithCaptionVStack(buttonImageName: "list.number", buttonTextCaption: "Rerank", buttonForegroundStyle: AnyShapeStyle(Color.blue.gradient))
                            }
                            .buttonStyle(.borderless)
                            
                            Divider()
                                .frame(height: buttonDividerHeight)
                            
                                Button {
                                    if !showingDetailsPanelOnRight {
                                        showingBatchSelectionView.toggle()
                                    } else {
                                        showingBatchUpdateUnvailableMessage.toggle()
                                    }
                                } label: {
                                    UncertaintyGraphControlButtonLabelWithCaptionVStack(buttonImageName: "rectangle.3.group", buttonTextCaption: "Batch", buttonForegroundStyle: AnyShapeStyle(Color.blue.gradient))
                                }
                                .buttonStyle(.borderless)
                                .opacity(showingDetailsPanelOnRight ? 0.5 : 1.0)
                                //.disabled(showingDetailsPanelOnRight)
                            Divider()
                                .frame(height: buttonDividerHeight)

                            Button {
                                if tableMaxWidth == .infinity {
                                    tableMaxWidth = 600.0
                                    exploreTableWidthIsMaxKey = false
                                } else {
                                    tableMaxWidth = .infinity
                                    exploreTableWidthIsMaxKey = true
                                }
                            } label: {
                                UncertaintyGraphControlButtonLabelWithCaptionVStack(buttonImageName: "arrow.up.left.and.down.right.and.arrow.up.right.and.down.left", buttonTextCaption: "Resize")
                            }
                            .buttonStyle(.borderless)
                            .opacity(showingDetailsPanelOnRight ? 1.0 : 0.5)
                            .disabled(!showingDetailsPanelOnRight)
                        }
                    }
                    .padding(.bottom)
                    /*VStack {
                        Text("batch")
                        Text("width: \(screenSize.width)")
                        Text("height: \(screenSize.height)")
                    }*/
                    
                    /*VStack {
                        if let first = sortedDataPoints.first, let firstId = first.id {
                            Text("Min: \(firstId)")
                        }
                        if let last = sortedDataPoints.last, let lastId = last.id {
                            Text("Max: \(lastId)")
                        }
                        Text("Total: \(sortedDataPoints.count)")
                        Text("fetchOffset: \(fetchOffset)")
                        Text("batchSize: \(batchSize)")
                    }*/
                    
                    
                    ZStack {
                        TableRetrievalErrorView(documentRetrievalError: $documentRetrievalError)
                        TableRetrievalInProgressView(documentRetrievalInProgress: $documentRetrievalInProgress)
                        if showingDetailsPanelOnRight { // single selection Table
                            // MARK: Changes in the right panel (for example, changing the viewed property), do not get updated in the row if we put the main table in another view, so currently we in-line here.
                            //DataOverviewPrimaryTableSingleSelectionView(sortedDataPoints: $sortedDataPoints, documentIdToIndex: $documentIdToIndex, selectedDocument: $selectedDocument, shouldScrollToTop: $shouldScrollToTop, documentObject: $documentObject)
                            VStack {
                                Divider()
                                ScrollViewReader { (proxy: ScrollViewProxy) in
//                                    VStack {
//                                        
//                                    }
//                                    .tag(42)
//                                    .id(42)
                                    Table(sortedDataPoints, selection: $selectedDocument) {
                                        TableColumn("ID") { dataPoint in
                                            if let dataPointID = dataPoint.id, let relativeRowIndex = documentIdToIndex[dataPointID] {
                                                //Text("[\(relativeRowIndex)] \(dataPoint.id ?? "")")
                                                Text("[\(getGlobalRowIndex(relativeRowIndex: relativeRowIndex))] \(dataPoint.id ?? "")")
                                                    .lineLimit(lineLimit...lineLimit)
                                            } else {
                                                Text(dataPoint.id ?? "")
                                                    .lineLimit(lineLimit...lineLimit)
                                            }
                                        }
                                        .width(min: 70, ideal: 70)

                                        TableColumn("Viewed") { dataPoint in
                                            if dataPoint.viewed {
                                                Text("Yes")
                                                    .lineLimit(lineLimit...lineLimit)
                                            } else {
                                                Text("No")
                                                    .lineLimit(lineLimit...lineLimit)
                                            }
                                        }
                                        .width(min: 70, ideal: 70, max: 70)
                                        TableColumn("Modified") { dataPoint in
                                            if dataPoint.modified {
                                                Text("Yes")
                                                    .lineLimit(lineLimit...lineLimit)
                                            } else {
                                                Text("No")
                                                    .lineLimit(lineLimit...lineLimit)
                                            }
                                        }
                                        .width(min: 85, ideal: 85, max: 85)
                                        TableColumn("Label") { dataPoint in
                                            if let labelDisplayName = dataController.labelToName[dataPoint.label] {
                                                Text(labelDisplayName)
                                                    .lineLimit(lineLimit...lineLimit)
                                            } else {
                                                Text("")
                                                    .lineLimit(lineLimit...lineLimit)
                                            }
                                        }
                                        .width(min: 125, ideal: 125)
                                        TableColumn("Prediction") { dataPoint in
                                            if dataPoint.prediction >= 0, let labelDisplayName = dataController.labelToName[dataPoint.prediction] {
                                                Text(labelDisplayName)
                                                    .lineLimit(lineLimit...lineLimit)
                                            } else {
                                                Text("N/A")
                                                    .lineLimit(lineLimit...lineLimit)
                                            }
                                        }
                                        .width(min: 125, ideal: 125)
                                        TableColumn("Prompt") { dataPoint in
                                            Text(dataPoint.prompt ?? "")
                                                .lineLimit(lineLimit...lineLimit)
                                        }
                                        .width(min: 100)

                                        TableColumn("Document") { dataPoint in
                                            Text(dataPoint.document ?? "")
                                                .lineLimit(lineLimit...lineLimit)
                                        }
                                        .width(min: 500)
                                        TableColumn("Group") { dataPoint in
                                            Text(dataPoint.group ?? "")
                                                .lineLimit(lineLimit...lineLimit)
                                        }
                                        .width(min: 200)
                                        TableColumn("Info") { dataPoint in
                                            Text(dataPoint.info ?? "")
                                                .lineLimit(lineLimit...lineLimit)
                                        }
                                        .width(min: 200)
                                    }
                                    .monospaced()
                                    .opacity(documentTextOpacity)
                                    .tableStyle(.inset(alternatesRowBackgrounds: true))
                                    .font(REConstants.Fonts.baseFont)
                                    .onChange(of: shouldScrollToTop) {
                                        if let topDocument = sortedDataPoints.first {
                                            proxy.scrollTo(topDocument.id, anchor: .topLeading)
                                            
                                        }
                                        shouldScrollToTop = false
                                    }
                                    .onChange(of: selectedDocument) {
                                        if let selectedDocumentID = selectedDocument, let stringId = selectedDocumentID, let documentArrayId = documentIdToIndex[stringId], documentArrayId < sortedDataPoints.count {
                                            documentObject = sortedDataPoints[documentArrayId]
                                        } else {
                                            documentObject = nil
                                            selectedDocument = nil
                                        }
                                    }
                                }
                            }
                        } else {
                            DataOverviewPrimaryTableMultipleSelectionView(sortedDataPoints: $sortedDataPoints, documentIdToIndex: $documentIdToIndex, multipleSelectedDocuments: $multipleSelectedDocuments, shouldScrollToTop: $shouldScrollToTop, showingBatchSelectionView: $showingBatchSelectionView, selectedDBRow: $selectedDBRow)
                        }
                        
                    }
                }
                .padding()
                .modifier(PrimaryComponentsViewModifier(useReBackgroundDarker: false, viewBoxScaling: 8))
                .padding()
                .frame(maxWidth: tableMaxWidth) // 600)
                if showingDetailsPanelOnRight {
                    DataDetailsView(selectedDocument: $selectedDocument, documentObject: $documentObject, searchParameters: dataController.documentSelectionState_DocumentsOverview?.searchParameters, semanticSearchParameters: dataController.documentSelectionState_DocumentsOverview?.semanticSearchParameters)  //, datasetId: $datasetId
                        .padding()
                }
            }
            .onDisappear {
                existingDBRow_TempCopy = nil
            }
            .onAppear {
                if let documentSelectionState = dataController.documentSelectionState_DocumentsOverview {
                    // This has the effect of re-loading any existing selection when returning from another view.
                    documentSelectionState_proposal = documentSelectionState
                }
                // A temporary copy since dataController.selectedDBRow_DocumentsOverview gets overwritten on a table reset, as when initiating a new retrieval
                existingDBRow_TempCopy = dataController.selectedDBRow_DocumentsOverview
                initiateFullRetrieval = true
                //print("called initiateRetrieval() from onappear")
                initiateRetrieval() //existingDBRow: existingDBRow)

                if exploreTableWidthIsMaxKey {
                    tableMaxWidth = .infinity
                } else {
                    tableMaxWidth = 600.0
                }
                if !dataController.documentsOverviewSelectionHasBeenShown {
                    isShowingInitializedAlert = true
                }
            }
            //This is not necessary, since initiateRetrieval() will already be called with a change of selectedDBRow.
            .onChange(of: shouldCalllInitiateRetrieval) { oldValue, newValue in
                if newValue {
                    //print("called initiateRetrieval() from .onChange(of: shouldCalllInitiateRetrieval)")
                    initiateRetrieval()
                    //shouldCalllInitiateRetrieval = false
                }
                // always need to set to false, since on clicking 'Cancel' in a Selection, the above block will not be called. If the following line is ommitted, this would then mean that a new Selection could never be initiated after a Cancel. A similar approach is used in Compare.
                shouldCalllInitiateRetrieval = false
            }
            .alert("Table initialized.", isPresented: $isShowingInitializedAlert) {
                Button {
                    dataController.documentsOverviewSelectionHasBeenShown = true
                } label: {
                    Text("OK")
                }
            } message: {
                Text(REConstants.SelectionDisplayLabels.selectionInitAlertMessage)
            }
            .alert(clearCacheMessage, isPresented: $showingClearCacheAlert) { // MARK: TODO: This might no longer be needed
                Button {
                } label: {
                    Text("OK")
                }
            } message: {
                Text("")
            }
            .alert(REConstants.HelpAssistanceInfo.Explore.batchUpdateUnavailableMessage, isPresented: $showingBatchUpdateUnvailableMessage) {
                Button {
                } label: {
                    Text("OK")
                }
            } message: {
                Text("")
            }
            .sheet(isPresented: $dataSelectionPopoverShowing,
//                   onDismiss: initiateRetrieval) {
                   onDismiss: {
                // will get compiler warning about updating state if calling initiateRetrieval directly:
                /*
                 Publishing changes from within view updates is not allowed, this will cause undefined behavior.
                 */
                // so we trigger via on change instead
                shouldCalllInitiateRetrieval = true
            }) {
                DataSelectionView(documentSelectionState: $documentSelectionState_proposal, initiateFullRetrieval: $initiateFullRetrieval)
                    .padding()
//                    .frame(height: 400)
                    .frame(idealHeight: 1000, maxHeight: .infinity)
                // simulate 13.3:
//                    .frame(
//                        minWidth: 1200*0.741-1, maxWidth: 1200*0.741,
//                        minHeight: 1000*0.716-1, maxHeight: 1000*0.716)
//                    .frame(maxWidth: .infinity, maxHeight: .infinity)
//                    .frame(
//                        minWidth: 1200, maxWidth: 1200,
//                        minHeight: 1000, maxHeight: 1000)
            }
                   .sheet(isPresented: $showingBatchSelectionView, onDismiss: refreshAfterBatchChange) {
                       DataOverviewBatchSelectionView(multipleSelectedDocuments: $multipleSelectedDocuments, datasetId: currentDatasetId, totalDocumentsInCurrentSelection: totalDocumentsInCurrentSelection, documentSelectionState: $documentSelectionState_proposal) // dataController.documentSelectionState_DocumentsOverview?.datasetId)
                           .padding()
                           .frame(
                            minWidth: 800, maxWidth: 800,
                            minHeight: 600, maxHeight: 600)
                   }
                   .sheet(isPresented: $showingRerankView,
                          //onDismiss: initiateRetrieval) {
                   onDismiss: {
                       // will get compiler warning about updating state if calling initiateRetrieval directly:
                       /*
                        Publishing changes from within view updates is not allowed, this will cause undefined behavior.
                        */
                       // so we trigger via on change instead
                       shouldCalllInitiateRetrieval = true
                   }) {
                       RerankingMainView(documentSelectionState: $documentSelectionState_proposal, initiateFullRetrieval: $initiateFullRetrieval) // dataController.documentSelectionState_DocumentsOverview?.datasetId)
                           .padding()
                           .frame(
                            minWidth: 800, maxWidth: 800,
                            minHeight: 600, maxHeight: 600)
                   }
        }
    }
        
}

