//
//  FeatureSearchView.swift
//  Alpha1
//
//  Created by A on 8/6/23.
//

import SwiftUI

// We pass this to the feature search rather than the managed object, to avoid issues with passing across threads.
struct SelectedDocumentFeature: Identifiable, Hashable {
    let documentId: String
    var id: String {
        return documentId
    }
    let featureIndex: Int
    let featureExemplar: [Float32]
    let documentWithPrompt: String
    let prediction: Int
    let featureRange: Range<String.Index>
}



struct FeatureSearchView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var dataController: DataController
    
    @State private var selectedDocumentFeature: SelectedDocumentFeature?
    
    @State private var featureMatchTask: Task<Void, Error>?
    
    @AppStorage(REConstants.UserDefaults.documentFontSize) var documentFontSize: Double = Double(REConstants.UserDefaults.defaultDocumentFontSize)
    var documentFont: Font {
        let fontCGFloat = CGFloat(documentFontSize)
        return Font.system(size: max( REConstants.UserDefaults.minDocumentFontSize, min(fontCGFloat, REConstants.UserDefaults.maxDocumentFontSize) ) )
    }
    
    @AppStorage(REConstants.UserDefaults.documentTextOpacity) var documentTextOpacity: Double = REConstants.UserDefaults.documentTextDefaultOpacity
    
    let uuidURLKey: String = UUID().uuidString  // this can be unique to a view, but just needs to be consistent with that used to create the highlights if making use of embedded links
    
    @State private var featureSearchType: DataController.FeatureSearchType = .documentWithPrompt // .documentWithPrompt
    @State private var selectedDatasetIdToSearch: Int = 0
    let displayColumnPickerMenuWidth: CGFloat = 250
    
    func resetSearchState() {  // MUST be called from main queue
        // Clear existing:
        featureResultBackgroundQueue = []
        featureResultMainQueue = []
        // dismiss popup:
        showingRetrievalSelectedDocumentDetails = false
        retrievalSelectedDocumentObject = nil
    }
    func searchForNearestFeatureMatches(datasetId: Int) async throws {
        await MainActor.run {
            resetSearchState()
        }
        if let docFeature = selectedDocumentFeature {
            let queryDocumentId = docFeature.documentId
            let featureExemplar = docFeature.featureExemplar
            let documentLevelStructureDict = try await dataController.getCompressedExemplarsSupport(queryDocumentId: queryDocumentId, datasetId: datasetId, moc: moc)
            if Task.isCancelled {
                throw MLForwardErrors.featureMatchWasCancelled
            }
            let matchStructure = try await dataController.matchQueryFeatures(featureSearchType: featureSearchType, queryCompressedExemplar: featureExemplar, documentLevelStructureDict: documentLevelStructureDict) //var matchStructure: [(id: String, featureIndex: Int, distance: Float32, documentWithPrompt: String, prediction: Int, featureRange: Range<String.Index>)] = []
            
            var rank: Int = 0
            for docFeature in matchStructure {
                // convert to let and pass across threads:
                let attrString = dataController.highlightOneFocusFeatureInDocumentWithPrompt(documentWithPrompt: docFeature.documentWithPrompt, featureRange: docFeature.featureRange, featureIndex: docFeature.featureIndex, uuidURLKey: uuidURLKey)
                let matchDocumentId = docFeature.id
                let rankI = rank
                let distance = docFeature.distance
                let prediction = docFeature.prediction
                let uniqueResultId = UUID().uuidString
                // on main
                await MainActor.run {
                    featureResultBackgroundQueue.append((id: uniqueResultId, documentId: matchDocumentId, rank: rankI, distance: distance, documentWithPromptHighlighted: attrString, prediction: prediction))
                }
                rank += 1
            }
            await MainActor.run {
                featureResultMainQueue = featureResultBackgroundQueue
            }
        }
        
    }
    @State var featureResultBackgroundQueue: [(id: String, documentId: String, rank: Int, distance: Float32, documentWithPromptHighlighted: AttributedString, prediction: Int)] = []
    @State var featureResultMainQueue: [(id: String, documentId: String, rank: Int, distance: Float32, documentWithPromptHighlighted: AttributedString, prediction: Int)] = []
    
    @Binding var selectedDocument: Document.ID?  // We directly access the Managed Object via documentObject, but we use this to refresh the view.
    @Binding var documentObject: Document?  // a Core Data managed object, so do not pass across threads
    var searchParameters: SearchParameters?  // these are needed in order to highlight any keywords, as applicable
    
    @State private var showingHelpAssistanceView: Bool = false
    @State private var showingFeatureInfoPopover: Bool = false
    @State private var showingMatchDistanceInfoPopover: Bool = false
    
    @State private var showingFocusDocumentDetails: Bool = false
    @State private var showingRetrievalSelectedDocumentDetails: Bool = false
    
    @State private var showingDisplayOptionsPopover: Bool = false
    
    @State var documentRetrievalInProgress: Bool = false
    @State var documentRetrievalError: Bool = false
    @State var retrievalSelectedDocumentObject: Document?
    @State private var retrievalSelectedDocumentUniqueResultID: String?
    var body: some View {
        ScrollView {
            // May need an overarching scrollview, as well
            HStack {
                Text("Feature-Level Matching")
                    .font(REConstants.Fonts.baseFont)
                Spacer()
                
                Button {
                    showingHelpAssistanceView.toggle()
                } label: {
                    UncertaintyGraphControlButtonLabelWithCaptionVStack(buttonImageName: "questionmark.circle", buttonTextCaption: "Help", buttonForegroundStyle: AnyShapeStyle(Color.gray.gradient))
                }
                .buttonStyle(.borderless)
                .popover(isPresented: $showingHelpAssistanceView) {
                    HelpAssistanceView_Feature_Level_Search()
                }
            }
            .padding([.bottom])
            
            
            Group {
                HStack {
                    Text("Features: Prompt + Document")
                        .font(.title3)
                        .foregroundStyle(.gray)
                    PopoverViewWithButton(isShowingInfoPopover: $showingFeatureInfoPopover, popoverViewText: "Available features are highlighted. Click to select a feature as the focus for matching.")
                    Spacer()
                    
                    HStack {
                        Image(systemName: "list.bullet.rectangle.portrait")
                            .foregroundStyle(Color.blue.gradient)
                        Text("Details")  // show popup
                            .font(.title3)
                            .foregroundStyle(.blue)
                    }
//                    .popover(isPresented: $showingFocusDocumentDetails, arrowEdge: .top) {
//                        DataDetailsView(selectedDocument: $selectedDocument, documentObject: $documentObject, disableFeatureSearchViewAndDestructiveActions: true, calledFromTableThatNeedsUpdate: true, showDismissButton: true)
//                            .frame(
//                                minWidth: 1200, maxWidth: 1200,
//                                minHeight: 900, maxHeight: 900)
//                    }
                    .onTapGesture {
                        showingFocusDocumentDetails = true
                    }
                }
                .padding([.leading, .trailing])
                
                ScrollView {
                    if let documentObj = documentObject {
                        VStack(alignment: .leading) {
                            
                            Text(dataController.highlightFeaturesInDocumentWithPromptWithOptionalFocus(documentObj: documentObj, uuidURLKey: uuidURLKey, focusFeatureIndex: selectedDocumentFeature?.featureIndex))
                                .environment(\.openURL, OpenURLAction { url in
                                    let splitURLIdentity = url.relativeString.split(separator: "_")
                                    guard splitURLIdentity.count == 2, let featureIndex = Int(splitURLIdentity[0]), splitURLIdentity[1] == uuidURLKey else {
                                        return .handled
                                    }
                                    if let featureExemplar = try? dataController.getFeatureExemplarFromDocumentObject(documentObj: documentObj, featureIndex: featureIndex), let featureRange = try? dataController.getFeatureRangeFromDocumentObject(documentObj: documentObj, featureIndex: featureIndex) {
                                        withAnimation {
                                            selectedDocumentFeature = SelectedDocumentFeature(documentId: documentObj.id ?? "", featureIndex: featureIndex, featureExemplar: featureExemplar, documentWithPrompt: documentObj.documentWithPrompt, prediction: documentObj.prediction, featureRange: featureRange)
                                            
                                            // reset search
                                            withAnimation {
                                                resetSearchState()
                                            }
                                        }
                                    }
                                    return .handled
                                })
                                .monospaced()
                                .font(documentFont)
                                .lineSpacing(12.0)
                                .opacity(documentTextOpacity)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                        }
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
                        GlobalTextDisplayOptionsView(onlyDisplayFontSizeOption: true)
                    }
                }
                .padding([.leading, .trailing])
                HStack {
                    Form {
                        Picker(selection: $featureSearchType) {
                            Text("Prompt + Document").tag(DataController.FeatureSearchType.documentWithPrompt)
                            Text("Prompt").tag(DataController.FeatureSearchType.promptOnly)
                            Text("Document").tag(DataController.FeatureSearchType.documentOnly)
                        } label: {
                            Text("Field:")
                                .font(.title3)
                                .foregroundStyle(.gray)
                        }
                        .pickerStyle(.segmented)
                        
                        Picker(selection: $selectedDatasetIdToSearch) {
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
                        .onChange(of: featureSearchType) {
                            withAnimation {
                                resetSearchState()
                            }
                        }
                        .onChange(of: selectedDatasetIdToSearch) { 
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
                    PopoverViewWithButton(isShowingInfoPopover: $showingMatchDistanceInfoPopover, popoverViewText: "The Feature Distance is only provided for relative reference within the result set. It is not directly comparable to the document-level distances.")
                    Spacer()
                    /*VStack {
                    }
                    .popover(isPresented: $showingRetrievalSelectedDocumentDetails, arrowEdge: .top) {
                        DataDetailsView(selectedDocument: .constant(Optional("")), documentObject: $retrievalSelectedDocumentObject, disableFeatureSearchViewAndDestructiveActions: true, calledFromTableThatNeedsUpdate: false, showDismissButton: true)
                            .frame(
                                minWidth: 1200, maxWidth: 1200,
                                minHeight: 900, maxHeight: 900)
                    }*/
                }
                .padding([.leading, .trailing])
                ZStack {
                    TableRetrievalErrorView(documentRetrievalError: $documentRetrievalError)
                    TableRetrievalInProgressView(documentRetrievalInProgress: $documentRetrievalInProgress)
                    VStack {
                        if selectedDocumentFeature == nil {
                            VStack {
                                Text("Select a feature above to get started.")
                                    .font(REConstants.Fonts.baseFont)
                                    .italic()
                                    .foregroundStyle(.gray)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        } else {
                            List(featureResultMainQueue, id:\.id, selection: $retrievalSelectedDocumentUniqueResultID) { matchResult in
                                VStack {
                                    HStack {
                                        HStack(alignment: .bottom, spacing: 0.0) {
                                            Group {
                                                Text("Rank: ")
                                                    .foregroundStyle(.gray)
                                                Text(String(matchResult.rank))
                                                    .monospaced()
                                                    .opacity(documentTextOpacity)
                                                Divider()
                                                    .frame(width: 2, height: 16.0)
                                                    .overlay(.gray)
                                                    .padding([.leading, .trailing])
                                                
                                                Text("Feature Distance: ")
                                                    .foregroundStyle(.gray)
                                                Text(String(matchResult.distance))
                                                    .monospaced()
                                                    .opacity(documentTextOpacity)
                                                Divider()
                                                    .frame(width: 2, height: 16.0)
                                                    .overlay(.gray)
                                                    .padding([.leading, .trailing])
                                                
                                                Text("**Document-Level** Prediction: ")
                                                    .foregroundStyle(.gray)
                                                if matchResult.prediction >= 0, let labelDisplayName = dataController.labelToName[matchResult.prediction] {
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
                                        Spacer()
                                        HStack(alignment: .lastTextBaseline) {
                                            Image(systemName: "list.bullet.rectangle.portrait")
                                                .foregroundStyle(.blue.gradient)
                                            Text("Details")
                                                .foregroundStyle(.blue)
                                        }
                                        .onTapGesture {
                                            showingRetrievalSelectedDocumentDetails.toggle()
                                            retrievalSelectedDocumentObject = try? dataController.retrieveOneDocument(documentId: matchResult.documentId, moc: moc)
                                        }
                                    }
                                    
                                    Divider()
                                    Text(matchResult.documentWithPromptHighlighted)
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
                            .scrollContentBackground(.hidden)
                            
                        }
                    }
                }
                .frame(minHeight: 320, maxHeight: 320)
                .modifier(SimpleBaseBorderModifier())
                .padding([.leading, .trailing])
            }
        }
        .sheet(isPresented: $showingFocusDocumentDetails,
               onDismiss: nil) {
        //.popover(isPresented: $showingFocusDocumentDetails, arrowEdge: .top) {
            DataDetailsView(selectedDocument: $selectedDocument, documentObject: $documentObject, searchParameters: searchParameters, disableFeatureSearchViewAndDestructiveActions: true, calledFromTableThatNeedsUpdate: true, showDismissButton: true)
//                .frame(
//                    minWidth: 1200, maxWidth: 1200,
//                    minHeight: 900, maxHeight: 900)
                .frame(
                    idealWidth: 1200, maxWidth: 1200,
                    idealHeight: 900, maxHeight: 900)
        }
        .sheet(isPresented: $showingRetrievalSelectedDocumentDetails,
               onDismiss: nil) {
            DataDetailsView(selectedDocument: .constant(Optional("")), documentObject: $retrievalSelectedDocumentObject, searchParameters: searchParameters, disableFeatureSearchViewAndDestructiveActions: true, calledFromTableThatNeedsUpdate: false, showDismissButton: true)
                .frame(
                    idealWidth: 1200, maxWidth: 1200,
                    idealHeight: 900, maxHeight: 900)
        }
        .scrollBounceBehavior(.basedOnSize)
        .onDisappear {
            featureMatchTask?.cancel()
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    featureMatchTask?.cancel()
                    dismiss()
                } label: {
//                    Text("Cancel")
                    Text("Done")
                        .frame(width: 100)
                }
                .controlSize(.large)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    featureMatchTask = Task {
                        do {
                            await MainActor.run {
                                documentRetrievalInProgress = true
                                documentRetrievalError = false
                            }
                            try await searchForNearestFeatureMatches(datasetId: selectedDatasetIdToSearch)
                            await MainActor.run {
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
                } label: {
                    Text("Match")
                        .frame(width: 100)
                }
                .controlSize(.large)
                .disabled(selectedDocumentFeature == nil)
            }
        }
    }
}


