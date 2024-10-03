//
//  DiscoverViewFeatures.swift
//  Alpha1
//
//  Created by A on 8/30/23.
//

import SwiftUI

struct HighlightStructureAbbreviated {
    var featureMatchesAttributedStringWithTruncationHighlighted: AttributedString?
    var featureMatchesDocLevelSoftmaxValString: String?  // truncated to significant digits for dispaly
}

extension DiscoverViewFeatures {
    func getDataPointsForDatasetFromDatabaseMainActor(documentSelectionState: DocumentSelectionState, moc: NSManagedObjectContext, fetchOffset: Int, batchSize: Int) throws -> (documentRequest: [ Document ], documentIdToIndex: [String: Int], count: Int, documentIdToHighlightStructure: [String: HighlightStructureAbbreviated]) {
        
        var documentIdToIndex: [String: Int] = [:]
        var documentIdToHighlightStructure: [String: HighlightStructureAbbreviated] = [:]
        // Another fecth to update the documents count. We re-fetch, because it is possible the user has uploaded duplicates.
        let fetchRequest = Document.fetchRequest()
        let compoundPredicate = try dataController.getFetchPredicateBasedOnDocumentSelectionState(documentSelectionState: documentSelectionState, moc: moc)
        
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: compoundPredicate)
        
        let sortDescriptors = dataController.getSortDescriptorsBasedOnDocumentSelectionState(documentSelectionState: documentSelectionState, moc: moc)
        
        fetchRequest.sortDescriptors = sortDescriptors
        
        let count = try moc.count(for: fetchRequest)  // This is used to determine the total rows. Note that fetchBatchSize (and related) has not yet been applied. Currently we only show a single batch, but could allow paging in the future.
        fetchRequest.fetchOffset = fetchOffset
        fetchRequest.fetchBatchSize = batchSize
        fetchRequest.fetchLimit = batchSize
        
        let documentRequest = try moc.fetch(fetchRequest)
        
        if documentRequest.isEmpty {
            throw CoreDataErrors.retrievalError
        }
        for i in 0..<documentRequest.count {
            let dataPoint = documentRequest[i]
            if let id = dataPoint.id {
                documentIdToIndex[id] = i
                documentIdToHighlightStructure[id] = dataController.highlightTextForInterpretabilityExtractFeature(documentObject: dataPoint)
            }
        }
        return (documentRequest: documentRequest, documentIdToIndex: documentIdToIndex, count: count, documentIdToHighlightStructure: documentIdToHighlightStructure)
    }
    func retrieveProminentFeatures() throws {
        var documentSelectionState = DocumentSelectionState(numberOfClasses: dataController.numberOfClasses)
        documentSelectionState.datasetId = datasetId
        documentSelectionState.includeAllPartitions = false
        documentSelectionState.predictedClasses = Set([predictedClass])
        documentSelectionState.displayedGroundTruthLabels = Set([groundTruthLabel])
        
        documentSelectionState.qCategories = Set([.qMax])
        documentSelectionState.distanceCategories = Set([.lessThanOrEqualToMedian, .greaterThanMedianAndLessThanOrEqualToOOD])
        documentSelectionState.compositionCategories = Set([.singleton])
        documentSelectionState.qDFCategorySizeCharacterizations = Set([.sufficient])
        
        documentSelectionState.sortParameters.sortFields = Set(["q", "featureMatchesDocLevelSoftmaxVal"])
        documentSelectionState.sortParameters.orderedSortFields = ["q", "featureMatchesDocLevelSoftmaxVal"]
        documentSelectionState.sortParameters.sortFieldToIsAscending = [:]
        documentSelectionState.sortParameters.sortFieldToIsAscending["q"] = false
        documentSelectionState.sortParameters.sortFieldToIsAscending["featureMatchesDocLevelSoftmaxVal"] = false
        
        documentSelectionState.consistentFeaturesParameters.onlyShowDocumentsWithAFeatureConsistentWithDocLevelPredictedClass = true
        // be careful about threads
        
        let documentRequestResult = try getDataPointsForDatasetFromDatabaseMainActor(documentSelectionState: documentSelectionState, moc: moc, fetchOffset: 0, batchSize: REConstants.Discover.maxFeaturesShown)
        //print("subset: \(documentRequestResult.documentRequest.count) out of Count: \(documentRequestResult.count)")
        if documentRequestResult.documentRequest.count > 0 {
            sortedDataPoints = documentRequestResult.documentRequest
            documentIdToIndex = documentRequestResult.documentIdToIndex
            documentIdToHighlightStructure = documentRequestResult.documentIdToHighlightStructure
            shouldScrollToTop = true
        } else {
            resetTable()
        }
    }
    func resetTable() {
        sortedDataPoints = []
        documentIdToIndex = [:]
        documentIdToHighlightStructure = [:]
        selectedDocument = nil
        retrievalSelectedDocumentObject = nil
        
        shouldScrollToTop = false
        
    }
}

struct DiscoverViewFeatures: View {
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var dataController: DataController
    
    var headerTitle: String = "Prominent Features"
    @State private var datasetId: Int = REConstants.DatasetsEnum.train.rawValue
    
    //@State var documentSelectionState: DocumentSelectionState
    @State var groundTruthLabel: Int = 0 //REConstants.DataValidator.unlabeledLabel
    @State var predictedClass: Int = 0
    
    @State var dataRetrievalTask: Task<Void, Error>?
    
    @State var documentRetrievalInProgress: Bool = false
    @State var documentRetrievalError: Bool = false
    
    @State var sortedDataPoints: [Document] = []
    @State var documentIdToIndex: [String: Int] = [:]
    @State var documentIdToHighlightStructure: [String: HighlightStructureAbbreviated] = [:]
    @State var selectedDocument: Document.ID? = nil
    @State var retrievalSelectedDocumentObject: Document?
    
    @State private var showingDisplayOptionsPopover: Bool = false
    @State private var showingRetrievalSelectedDocumentDetails: Bool = false
    
    @State var shouldScrollToTop: Bool = false
    
    @AppStorage(REConstants.UserDefaults.documentFontSize) var documentFontSize: Double = Double(REConstants.UserDefaults.defaultDocumentFontSize)
    
    var documentFont: Font {
        let fontCGFloat = CGFloat(documentFontSize)
        return Font.system(size: max( REConstants.UserDefaults.minDocumentFontSize, min(fontCGFloat, REConstants.UserDefaults.maxDocumentFontSize) ) )
    }
    
    @AppStorage(REConstants.UserDefaults.documentTextOpacity) var documentTextOpacity: Double = REConstants.UserDefaults.documentTextDefaultOpacity
    
    //    init(numberOfClasses: Int) {
    //        _documentSelectionState = State(initialValue: DocumentSelectionState(numberOfClasses: numberOfClasses))
    //    }
    
    
    
    var body: some View {
        VStack {
            VStack {
                HStack {
                    DiscoverViewFeaturesHeaderTitleView(headerTitle: headerTitle, viewWidth: 730)
                }
                .padding(.bottom)
                
                
                VStack {
                    HStack {
                        Spacer()
                        Grid {
                            GridRow {
                                Text("Datasplit:")
                                    .font(REConstants.Fonts.baseFont)
                                    .foregroundStyle(.gray)
                                    .gridColumnAlignment(.trailing)
                                DatasplitSelectorViewSelectionRequired(selectedDatasetId: $datasetId, showLabelTitle: false)
                                    .gridColumnAlignment(.trailing)
                            }
                            GridRow {
                                Text("Ground-truth document-level label:")
                                    .foregroundStyle(.gray)
                                Picker(selection: $groundTruthLabel) {
                                    ForEach(REConstants.Discover.getAllPossibleGroundTruthLabels(numberOfClasses: dataController.numberOfClasses), id:\.self) { label in
                                        VStack {
                                            if let labelDisplayName = dataController.labelToName[label] {
                                                Text(labelDisplayName)
                                            } else { // for completeness, but this case should never occur
                                                Text("\(label)")
                                            }
                                        }
                                        .tag(label)
                                        .frame(height: 20)
                                    }
                                } label: {
                                }
                                .frame(width: 250)
                            }
                            GridRow {
                                Text("Document-level prediction:")
                                    .foregroundStyle(.gray)
                                Picker(selection: $predictedClass) {
                                    ForEach(0..<dataController.numberOfClasses, id:\.self) { label in
                                        if DataController.isKnownValidLabel(label: label, numberOfClasses: dataController.numberOfClasses) {
                                            VStack {
                                                if let labelDisplayName = dataController.labelToName[label] {
                                                    Text(labelDisplayName)
                                                } else { // for completeness, but this case should never occur
                                                    Text("\(label)")
                                                }
                                            }
                                            .tag(label)
                                            .frame(height: 20)
                                        }
                                    }
                                } label: {
                                }
                                .frame(width: 250)
                                
                            }
                            GridRow {
                                Color.clear
                                    .gridCellUnsizedAxes([.horizontal, .vertical])
                                
                                HStack {
                                    
                                    Button {
                                        documentRetrievalInProgress = true
                                        dataRetrievalTask = Task {
                                            do {
                                                try await MainActor.run {
                                                    resetTable()
                                                    try retrieveProminentFeatures()
                                                    documentRetrievalInProgress = false
                                                }
                                            } catch {
                                                await MainActor.run {
                                                    documentRetrievalInProgress = false
                                                    documentRetrievalError = true
                                                }
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                                    documentRetrievalError = false
                                                    resetTable()
                                                }
                                                //                                                await MainActor.run {
                                                //                                                    resetTable()
                                                //                                                }
                                                
                                            }
                                        }
                                        
                                    } label: {
                                        Text("Retrieve")
                                            .font(REConstants.Fonts.baseSubheadlineFont)
                                            .frame(width: 150)
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                            }
                        }
                        .font(REConstants.Fonts.baseFont)
                        //Spacer()
                    }
                    .padding([.leading, .trailing])
                    
                }
                .padding()
                .modifier(SimpleBaseBorderModifier())
                .padding()
                Group {
                    HStack {
                        Text("Top Features")
                            .font(.title3)
                            .foregroundStyle(.gray)
                        PopoverViewWithButtonLocalStateOptions(popoverViewText: REConstants.HelpAssistanceInfo.HighlightGuide.featureScore, optionalSubText: "Up to 1000 features are shown.", frameWidth: 250)
                        Spacer()
                        Button {
                            showingDisplayOptionsPopover.toggle()
                        } label: {
                            Image(systemName: "gear")
                                .foregroundStyle(.blue.gradient)
                                .font(REConstants.Fonts.baseFont)
                        }
                        .buttonStyle(.borderless)
                        .popover(isPresented: $showingDisplayOptionsPopover, arrowEdge: .top) {
                            GlobalTextDisplayOptionsView(onlyDisplayFontSizeOption: true)
                        }
                    }
                    .padding([.leading, .trailing])
                    ZStack {
                        TableRetrievalErrorView(documentRetrievalError: $documentRetrievalError)
                        TableRetrievalInProgressView(documentRetrievalInProgress: $documentRetrievalInProgress)
                        VStack {
                            /*if documentIdToIndex.isEmpty {
                                VStack {
                                    Text(showErrorMessage ? "More data is needed in the given selection in order to extract prominent features." : "")
                                        .font(REConstants.Fonts.baseFont)
                                        .italic()
                                        .foregroundStyle(.gray)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            } else {*/
                                ScrollViewReader { (proxy: ScrollViewProxy) in
                                    List(sortedDataPoints, selection: $selectedDocument) { documentObj in
                                        VStack {
                                            HStack {
                                                HStack(alignment: .bottom, spacing: 0.0) {
                                                    Group {
                                                        Text("Row: ")
                                                            .foregroundStyle(.gray)
                                                        if let id = documentObj.id, let rowIndex = documentIdToIndex[id] {
                                                            Text(String(rowIndex))
                                                                .monospaced()
                                                                .opacity(documentTextOpacity)
                                                        } else {
                                                            Text("")
                                                                .opacity(documentTextOpacity)
                                                        }
                                                        
                                                        Divider()
                                                            .frame(width: 2, height: 16.0)
                                                            .overlay(.gray)
                                                            .padding([.leading, .trailing])
                                                        
                                                        Text("Feature Score: ")
                                                            .foregroundStyle(.gray)
                                                        if let id = documentObj.id, let highlightStructureForDocument = documentIdToHighlightStructure[id], let featureScoreFormatted = highlightStructureForDocument.featureMatchesDocLevelSoftmaxValString {
                                                            Text(String(featureScoreFormatted))
                                                                .monospaced()
                                                                .opacity(documentTextOpacity)
                                                        }
                                                    }
                                                }
                                                Spacer()
                                                HStack(alignment: .lastTextBaseline) {
                                                    Image(systemName: "list.bullet.rectangle.portrait")
                                                        .foregroundStyle(.blue.gradient)
                                                    Text("Details")
                                                        .foregroundStyle(.blue)
                                                }
                                                .onTapGesture {
                                                    showingRetrievalSelectedDocumentDetails.toggle()
                                                    retrievalSelectedDocumentObject = documentObj
                                                }
                                            }
                                            
                                            Divider()
                                            if let id = documentObj.id, let highlightStructureForDocument = documentIdToHighlightStructure[id], let featureMatchesAttributedStringWithTruncationHighlighted = highlightStructureForDocument.featureMatchesAttributedStringWithTruncationHighlighted {
                                                Text(featureMatchesAttributedStringWithTruncationHighlighted)
                                                    .textSelection(.enabled)
                                                    .environment(\.openURL, OpenURLAction { url in
                                                        // Need this to prevent an attempt to open the marked URL's.
                                                        return .handled
                                                    })
                                                    .monospaced()
                                                    .font(documentFont)
                                                    .lineSpacing(12.0)
                                                    .opacity(documentTextOpacity)
                                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                                            }
                                        }
                                        .padding()
                                        .modifier(PrimaryComponentsViewModifier(useReBackgroundDarker: true, viewBoxScaling: 8.0))
                                    }
                                    //.frame(height: 750)
                                    .scrollContentBackground(.hidden)
                                    .onChange(of: shouldScrollToTop) {
                                        if let topDocument = sortedDataPoints.first {
                                            proxy.scrollTo(topDocument.id, anchor: .topLeading)
                                            
                                        }
                                        shouldScrollToTop = false
                                    }
                                    .onChange(of: datasetId) {
                                        resetTable()
                                    }
                                    .onChange(of: groundTruthLabel) {
                                        resetTable()
                                    }
                                    .onChange(of: predictedClass) {
                                        resetTable()
                                    }
                                }
                            //}
                        }.frame(height: 750)
                    }
                    //.frame(minHeight: 800)
//                    .frame(minHeight: 320, idealHeight: 640) //, maxHeight: 640)
                    //.frame(minHeight: 320) //, maxHeight: .infinity) //maxHeight: 320)
                    .modifier(SimpleBaseBorderModifier())
                    .padding([.leading, .trailing, .bottom])
                }
                Spacer()
                .sheet(isPresented: $showingRetrievalSelectedDocumentDetails,
                       onDismiss: nil) {
                    DataDetailsView(selectedDocument: .constant(Optional("")), documentObject: $retrievalSelectedDocumentObject, searchParameters: nil, disableFeatureSearchViewAndDestructiveActions: false, calledFromTableThatNeedsUpdate: false, showDismissButton: true)
                        .frame(
                            idealWidth: 1200, maxWidth: 1200,
                            idealHeight: 900, maxHeight: 900)
                }
            }
        }
        //.frame(maxHeight: .infinity)
        .onDisappear {
            dataRetrievalTask?.cancel()
        }
    }
}

