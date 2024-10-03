//
//  DataMatchingView.swift
//  Alpha1
//
//  Created by A on 9/12/23.
//

import SwiftUI

struct DataMatchingView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var dataController: DataController
        
    @State private var matchTask: Task<Void, Error>?
    
    @AppStorage(REConstants.UserDefaults.documentFontSize) var documentFontSize: Double = Double(REConstants.UserDefaults.defaultDocumentFontSize)
    
    @AppStorage(REConstants.UserDefaults.showFeaturesInDocumentText) var showFeaturesInDocumentText: Bool = true
    @AppStorage(REConstants.UserDefaults.showLeadingFeatureInconsistentWithDocumentLevelInDocumentText) var showLeadingFeatureInconsistentWithDocumentLevelInDocumentText: Bool = false
    
    var documentFont: Font {
        let fontCGFloat = CGFloat(documentFontSize)
        return Font.system(size: max( REConstants.UserDefaults.minDocumentFontSize, min(fontCGFloat, REConstants.UserDefaults.maxDocumentFontSize) ) )
    }
    
    @AppStorage(REConstants.UserDefaults.documentTextOpacity) var documentTextOpacity: Double = REConstants.UserDefaults.documentTextDefaultOpacity
        
    @State private var documentMatchingState: DocumentMatchingState = DocumentMatchingState()
        
    func resetSearchState() {  // MUST be called from main queue
        // Clear existing:
        matchObject = (documentObjects: [], documentIdToOriginalRank: [:], documentId2queryDistance: [:])
        
        if documentMatchingState.selectedDatasetIdToMatch != REConstants.DatasetsEnum.train.rawValue {
            documentMatchingState.reIndexTraining = false
        }
        
        // dismiss popup:
        showingRetrievalSelectedDocumentDetails = false
        retrievalSelectedDocumentObject = nil
    }
    
    @Binding var selectedDocument: Document.ID?  // We directly access the Managed Object via documentObject, but we use this to refresh the view.
    @Binding var documentObject: Document?  // a Core Data managed object, so do not pass across threads
    var searchParameters: SearchParameters?  // these are needed in order to highlight any keywords, as applicable
    
    @State private var matchObject: (documentObjects: [Document], documentIdToOriginalRank: [String: Int], documentId2queryDistance: [String: Float32]) = (documentObjects: [], documentIdToOriginalRank: [:], documentId2queryDistance: [:])
    
    @State private var showingHelpAssistanceView: Bool = false
    
    @State private var showingFocusDocumentDetails: Bool = false
    @State private var showingRetrievalSelectedDocumentDetails: Bool = false
    
    @State private var showingDisplayOptionsPopover: Bool = false
    
    @State var documentRetrievalInProgress: Bool = false
    @State var documentRetrievalError: Bool = false
    @State var retrievalSelectedDocumentObject: Document?
    @State private var retrievalSelectedDocumentUniqueResultID: Document.ID?
    var body: some View {
        ScrollView {

            HStack {
                Text("Document-Level Matching")
                    .font(REConstants.Fonts.baseFont)
                Spacer()
                
                Button {
                    showingHelpAssistanceView.toggle()
                } label: {
                    UncertaintyGraphControlButtonLabelWithCaptionVStack(buttonImageName: "questionmark.circle", buttonTextCaption: "Help", buttonForegroundStyle: AnyShapeStyle(Color.gray.gradient))
                }
                .buttonStyle(.borderless)
                .popover(isPresented: $showingHelpAssistanceView) {
                    HelpAssistanceView_Document_Level_Matching()
                }
            }
            .padding([.bottom])
            
            
            Group {
                HStack {
                    Text("Document")
                        .font(.title3)
                        .foregroundStyle(.gray)
                    Spacer()
                    
                    HStack {
                        Image(systemName: "list.bullet.rectangle.portrait")
                            .foregroundStyle(Color.blue.gradient)
                        Text("Details")  // show popup
                            .font(.title3)
                            .foregroundStyle(.blue)
                    }
                    .onTapGesture {
                        showingFocusDocumentDetails = true
                    }
                }
                .padding([.leading, .trailing])
                
                ScrollView {
                    if let docObj = documentObject {
                        VStack(alignment: .leading) {

                            let documentOnlyAttributedString = dataController.highlightTextForInterpretabilityBinaryClassificationWithDocumentObject(documentObject: docObj, truncateToDocument: true, highlightFeatureInconsistentWithDocLevel: showLeadingFeatureInconsistentWithDocumentLevelInDocumentText, searchParameters: searchParameters, semanticSearchParameters: nil, highlightFeatureMatchesDocLevel: showFeaturesInDocumentText, showSemanticSearchFocusInDocumentText: false).attributedString

                                Text(documentOnlyAttributedString)
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
                    } else {
                        Text("")
                    }
                }
                .frame(minHeight: 250, maxHeight: 260)
                .padding()
                .modifier(PrimaryComponentsViewModifier(useReBackgroundDarker: true))
                .padding([.leading, .trailing])
    
            }
            
            Group {
                HStack {
                    Text("Matching Options")
                        .font(.title3)
                        .foregroundStyle(.gray)
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
                        GlobalTextDisplayOptionsView(hideSemanticSearchOption: true)
                    }
                }
                .padding([.leading, .trailing])
                HStack {
                    Form {
                        Picker(selection: $documentMatchingState.selectedDatasetIdToMatch) {
                            ForEach(Array(dataController.inMemory_Datasets.keys.sorted()), id: \.self) { datasetId in
                                // Note that it is safe to search the same datasplit with the focus feature, since we already account for this in the initial retrieval of data from core data.
                                if datasetId != REConstants.Datasets.placeholderDatasetId {
                                    Text("\(dataController.getDatasplitNameForDisplay(datasetId: datasetId))")
                                        .tag(datasetId)
                                }
                            }
                        } label: {
                            Text("Datasplit:")
                                .font(.title3)
                                .foregroundStyle(.gray)
                        }
                        if documentMatchingState.selectedDatasetIdToMatch == REConstants.DatasetsEnum.train.rawValue {
                            HStack {
                                Toggle(isOn: $documentMatchingState.reIndexTraining) {
                                    Text("Reindex:")
                                        .font(.title3)
                                        .foregroundStyle(.gray)
                                }
                                .toggleStyle(.switch)

                                PopoverViewWithButtonLocalStateOptionsLocalizedString(popoverViewText: "If enabled, the matches used for estimating uncertainty will be ignored and indexing will be re-run on training for the document. *This is typically not needed, but it may be useful when making rapid changes to the Training set (e.g., when initially labeling).* Keep in mind that the uncertainty estimates will not be updated until prediction on the full datasplit has been rerun via **\(REConstants.MenuNames.setupName)**->**Predict**.")
                            }
                        }
                        Picker(selection: $documentMatchingState.documentMatchDisplayType) {
                            Text("Prompt + Document").tag(DocumentMatchingState.DocumentMatchDisplayType.documentWithPrompt)
                            Text("Document").tag(DocumentMatchingState.DocumentMatchDisplayType.documentOnly)
                        } label: {
                            HStack {
                                Text("Field(s) to display:")
                                    .font(.title3)
                                    .foregroundStyle(.gray)
                                PopoverViewWithButtonLocalStateOptions(popoverViewText: "Document-level matching is determined by the full input to the model (i.e., **Prompt + Document**). This option only controls the text displayed in the box below.")
                            }
                        }
                        .pickerStyle(.segmented)
            
                        .onChange(of: documentMatchingState.reIndexTraining) {
                            withAnimation {
                                resetSearchState()
                            }
                        }
                        .onChange(of: documentMatchingState.selectedDatasetIdToMatch) { 
                            withAnimation {
                                resetSearchState()
                            }
                        }
                    }
                    .padding()
                    .frame(width: 500)
                    Spacer()
                }
                .modifier(SimpleBaseBorderModifier())
                .padding([.leading, .trailing])
            }
            
            Group {
                HStack {
                    Text("Nearest Matches")
                        .font(.title3)
                        .foregroundStyle(.gray)
                    PopoverViewWithButtonLocalStateOptionsLocalizedString(popoverViewText: LocalizedStringKey(REConstants.HelpAssistanceInfo.StateChanges.trainingMatchDiscrepancyExplanation), optionalSubText: REConstants.HelpAssistanceInfo.StateChanges.stateChangeTip_Prediction_Focus)
                    Spacer()

                }
                .padding([.leading, .trailing])
                ZStack {
                    TableRetrievalErrorView(documentRetrievalError: $documentRetrievalError)
                    TableRetrievalInProgressView(documentRetrievalInProgress: $documentRetrievalInProgress)
                    VStack {
                            List(matchObject.documentObjects, id:\.id, selection: $retrievalSelectedDocumentUniqueResultID) { matchResultDocumentObject in
                                if let matchedDocumentId = matchResultDocumentObject.id, let rank = matchObject.documentIdToOriginalRank[matchedDocumentId], let distanceToQuery = matchObject.documentId2queryDistance[matchedDocumentId] {
                                    VStack {
                                        HStack {
                                            HStack(alignment: .bottom, spacing: 0.0) {
                                                Group {
                                                    Text("Rank: ")
                                                        .foregroundStyle(.gray)
                                                    Text(String(rank))
                                                        .monospaced()
                                                        .opacity(documentTextOpacity)
                                                    Divider()
                                                        .frame(width: 2, height: 16.0)
                                                        .overlay(.gray)
                                                        .padding([.leading, .trailing])
                                                    
                                                    Text("Distance: ")
                                                        .foregroundStyle(.gray)
                                                    Text(String(distanceToQuery))
                                                        .monospaced()
                                                        .opacity(documentTextOpacity)
                                                    
                                                    Group {
                                                        Divider()
                                                            .frame(width: 2, height: 16.0)
                                                            .overlay(.gray)
                                                            .padding([.leading, .trailing])
                                                        
                                                        Text("Label: ")
                                                            .foregroundStyle(.gray)
                                                        if let labelDisplayName = dataController.labelToName[matchResultDocumentObject.label] {
                                                            Text(labelDisplayName)
                                                                .monospaced()
                                                                .opacity(documentTextOpacity)
                                                        } else {
                                                            Text("N/A")
                                                                .monospaced()
                                                                .opacity(documentTextOpacity)
                                                        }
                                                    }
                                                    Group {
                                                        Divider()
                                                            .frame(width: 2, height: 16.0)
                                                            .overlay(.gray)
                                                            .padding([.leading, .trailing])
                                                        
                                                        Text("Prediction: ")
                                                            .foregroundStyle(.gray)
                                                        if matchResultDocumentObject.prediction >= 0, let labelDisplayName = dataController.labelToName[matchResultDocumentObject.prediction] {
                                                            Text(labelDisplayName)
                                                                .monospaced()
                                                                .opacity(documentTextOpacity)
                                                        } else {
                                                            Text("N/A")
                                                                .monospaced()
                                                                .opacity(documentTextOpacity)
                                                        }
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
                                                retrievalSelectedDocumentObject = matchResultDocumentObject
                                            }
                                        }
                                        
                                        Divider()
                                        let matchedDocumentAttributedString = dataController.highlightTextForInterpretabilityBinaryClassificationWithDocumentObject(documentObject: matchResultDocumentObject, truncateToDocument: documentMatchingState.truncateToDocument, highlightFeatureInconsistentWithDocLevel: showLeadingFeatureInconsistentWithDocumentLevelInDocumentText, searchParameters: searchParameters, semanticSearchParameters: nil, highlightFeatureMatchesDocLevel: showFeaturesInDocumentText, showSemanticSearchFocusInDocumentText: false).attributedString

                                            Text(matchedDocumentAttributedString)
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
                                    .padding()
                                    .modifier(PrimaryComponentsViewModifier(useReBackgroundDarker: true, viewBoxScaling: 8.0))
                                }
                            }
                            .scrollContentBackground(.hidden)
                    }
                }
                .frame(minHeight: 320, maxHeight: 320)
                .modifier(SimpleBaseBorderModifier())
                .padding([.leading, .trailing])
            }
        }
        .sheet(isPresented: $showingFocusDocumentDetails,
               onDismiss: nil) {
            DataDetailsView(selectedDocument: $selectedDocument, documentObject: $documentObject, searchParameters: searchParameters, disableFeatureSearchViewAndDestructiveActions: true, calledFromTableThatNeedsUpdate: true, showDismissButton: true)
                .frame(
                    idealWidth: 1200, maxWidth: 1200,
                    idealHeight: 900, maxHeight: 900)
        }
        .sheet(isPresented: $showingRetrievalSelectedDocumentDetails,
               onDismiss: {
            // quick toggle to make sure refresh of any changes is updated
            let tempMatchedID = retrievalSelectedDocumentUniqueResultID
            retrievalSelectedDocumentUniqueResultID = nil
            retrievalSelectedDocumentUniqueResultID = tempMatchedID
        }) {
            DataDetailsView(selectedDocument: .constant(Optional("")), documentObject: $retrievalSelectedDocumentObject, searchParameters: searchParameters, disableFeatureSearchViewAndDestructiveActions: true, calledFromTableThatNeedsUpdate: false, showDismissButton: true)
                .frame(
                    idealWidth: 1200, maxWidth: 1200,
                    idealHeight: 900, maxHeight: 900)
        }
        .scrollBounceBehavior(.basedOnSize)
        .onDisappear {
            matchTask?.cancel()
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    matchTask?.cancel()
                    dismiss()
                } label: {
                    Text("Done")
                        .frame(width: 100)
                }
                .controlSize(.large)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    do {
                        documentRetrievalInProgress = true
                        if let docObj = documentObject, documentMatchingState.selectedDatasetIdToMatch == REConstants.DatasetsEnum.train.rawValue && !documentMatchingState.reIndexTraining {
                            matchObject = try dataController.generalMatchingTraining(documentMatchingState: documentMatchingState, queryDocumentObject: docObj, moc: moc)
                            documentRetrievalInProgress = false
                            documentRetrievalError = false
                        } else if let docObj = documentObject, let queryDocumentId = docObj.id {
                            let queryOutput = try dataController.getExemplarDataFromOneFetchedManagedObject(modelControlIdString: REConstants.ModelControl.keyModelId, document: docObj)
                            let datasetIdToMatchAgainst = documentMatchingState.selectedDatasetIdToMatch
                            matchTask = Task {
                                do {
                                    let matchStructure: (topKdistances: [Float32], topKIndexesAsDocumentIds: [String]) = try await dataController.getTopKForNearestMatchesForOneDocument(queryDocumentId: queryDocumentId, queryOutput: queryOutput, datasetIdToMatchAgainst: datasetIdToMatchAgainst, moc: moc)
                                    try await MainActor.run {
                                        matchObject = try dataController.getMatchedManagedObjectsForOneDocumentFromTopK(supportDatasetId: datasetIdToMatchAgainst, topKdistances: matchStructure.topKdistances, topKIndexesAsDocumentIds: matchStructure.topKIndexesAsDocumentIds, moc: moc)
                                        documentRetrievalInProgress = false
                                        documentRetrievalError = false
                                    }
                                } catch {
                                    documentRetrievalInProgress = false
                                    documentRetrievalError = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                        documentRetrievalError = false
                                    }
                                }
                            }
                        }
                    } catch {
                        documentRetrievalInProgress = false
                        documentRetrievalError = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            documentRetrievalError = false
                        }
                    }
                } label: {
                    Text("Match")
                        .frame(width: 100)
                }
                .controlSize(.large)
                .disabled(documentObject == nil)
            }
        }
    }
}
