//
//  RerankingMainView.swift
//  Alpha1
//
//  Created by A on 9/9/23.
//

import SwiftUI


struct CurrentRerankStatusView: View {
    @Binding var documentSelectionState: DocumentSelectionState
    var body: some View {
        HStack {
            Divider()
                .frame(width: 2, height: 25)
                .overlay(.gray)
            Grid {
                GridRow {
                    Text("Documents available for reranking:")
                        .gridColumnAlignment(.trailing)
                        .foregroundStyle(.gray)
                        .font(REConstants.Fonts.baseFont)
                        Text(String(documentSelectionState.semanticSearchParameters.retrievedDocumentIDs.count))
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

struct RerankingMainView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var dataController: DataController

    
    var semanticSearchResultsAvailableForReranking: Bool {
        return documentSelectionState.semanticSearchParameters.search && !documentSelectionState.semanticSearchParameters.searchText.isEmpty && documentSelectionState.semanticSearchParameters.retrievedDocumentIDs.count > 0
    }
    

    
    @State private var navPath = NavigationPath()
    enum Destinations {
        case setup
        case forward
        case complete
    }
    
    @State var errorMessage: String = ""
    

    @Binding var documentSelectionState: DocumentSelectionState
    @Binding var initiateFullRetrieval: Bool?
    
    @State var datasetIds: Set<Int> = Set([REConstants.DatasetsEnum.train.rawValue, REConstants.DatasetsEnum.calibration.rawValue, REConstants.Datasets.placeholderDatasetId])  // currently, train and calibration are always checked to ensure they are current

    @State var totalElapsedTime: String = ""

    @State var processStartTime: Date?

    @State var dataPredictionTask: Task<Void, Error>?
    @State var predictionTaskWasCancelled: Bool = false
    @State var predictionTaskIsComplete: Bool = false
    
    @State var rerankedDocumentIDsStructure: (allRerankedCrossEncodedDocumentIDs: [String], onlyMatchesTargetRerankedCrossEncodedDocumentIDs: [String]) = (allRerankedCrossEncodedDocumentIDs: [], onlyMatchesTargetRerankedCrossEncodedDocumentIDs: [])
    @State var retrievingDocumentStats: Bool = true
    @State var showingErrorAlert: Bool = false
    @State var showingExistingRerankErrorAlert: Bool = false
    
    func updateSemanticSearchIDsWithRerankingResult() {
        if documentSelectionState.semanticSearchParameters.rerankParameters.rerankDisplayOptions.onlyShowMatchesToTargetLabel {
            documentSelectionState.semanticSearchParameters.updateSemanticSearchResultsStructures(rerankedRetrievedDocumentIDs: rerankedDocumentIDsStructure.onlyMatchesTargetRerankedCrossEncodedDocumentIDs, createNewDocumentsViaCrossEncoding: documentSelectionState.semanticSearchParameters.rerankParameters.rerankDisplayOptions.createNewDocumentInstance)
        } else {
            documentSelectionState.semanticSearchParameters.updateSemanticSearchResultsStructures(rerankedRetrievedDocumentIDs: rerankedDocumentIDsStructure.allRerankedCrossEncodedDocumentIDs, createNewDocumentsViaCrossEncoding: documentSelectionState.semanticSearchParameters.rerankParameters.rerankDisplayOptions.createNewDocumentInstance)
        }
    }
 
    var rerankedDocumentsAvailableForDisplay: Bool {
        if documentSelectionState.semanticSearchParameters.rerankParameters.rerankDisplayOptions.onlyShowMatchesToTargetLabel {
            return rerankedDocumentIDsStructure.onlyMatchesTargetRerankedCrossEncodedDocumentIDs.count > 0
        }
        return rerankedDocumentIDsStructure.allRerankedCrossEncodedDocumentIDs.count > 0
    }
    var body: some View {
        NavigationStack(path: $navPath) {
            RerankingOptionsView(documentSelectionState: $documentSelectionState)
                .navigationDestination(for: Destinations.self) { i in
                    switch i {
                    case Destinations.setup:
                        RerankingOptionsView(documentSelectionState: $documentSelectionState)
                            .navigationBarBackButtonHidden()
                    case Destinations.forward:
                        MainForwardAfterTrainingView(inferenceDatasetIds: $datasetIds, dataPredictionTask: $dataPredictionTask, predictionTaskWasCancelled: $predictionTaskWasCancelled, predictionTaskIsComplete: $predictionTaskIsComplete, totalElapsedInferenceTime: $totalElapsedTime, existingProcessStartTime: processStartTime)
                            .navigationBarBackButtonHidden()
                    case Destinations.complete:
                        RerankingCompleteDisplayOptionsView(documentSelectionState: $documentSelectionState, rerankedDocumentIDsStructure: $rerankedDocumentIDsStructure, retrievingDocumentStats: $retrievingDocumentStats)
                            .navigationBarBackButtonHidden()
                    }
                }
        }
        .alert("An unexpected error was encountered.", isPresented: $showingErrorAlert) {
            Button {
                // it takes some time to cancel if in a forward pass, so need to show a screen
                dataPredictionTask?.cancel()

                initiateFullRetrieval = false  // this will handle resetting to previous
                dismiss()
            } label: {
                Text("OK")
            }
        } message: {
            Text("Unable to rerank. Please try again.")
        }
        .alert("An existing set of reranked results is present.", isPresented: $showingExistingRerankErrorAlert) {
            Button {
                // it takes some time to cancel if in a forward pass, so need to show a screen
                //dataPredictionTask?.cancel()

                //initiateFullRetrieval = false  // this will handle resetting to previous
                dismiss()
            } label: {
                Text("OK")
            }
        } message: {
            Text("To rerank again, please first rerun the semantic search.")
        }
        .onDisappear {
            dataPredictionTask?.cancel()
        }
        .onAppear {
            // Currently, an additional rerank cannot be initiated when an existing reranking set is being displayed. The user needs to go back to Select and re-run the semantic search.
            if documentSelectionState.semanticSearchParameters.rerankParameters.reranking {
                showingExistingRerankErrorAlert = true
            }
            // set initial defaults on first appeareance:
            if semanticSearchResultsAvailableForReranking && !documentSelectionState.semanticSearchParameters.rerankParameters.reranking {
                documentSelectionState.semanticSearchParameters.rerankParameters.rerankPrompt = documentSelectionState.semanticSearchParameters.searchPrompt
                documentSelectionState.semanticSearchParameters.rerankParameters.rerankSearchText = documentSelectionState.semanticSearchParameters.searchText
            }
        }

        .toolbar {
            
            ToolbarItem(placement: .cancellationAction) {
                // MARK: Note: This will also be called if the user taps ESC.
                
                Button("Cancel") {
                    // it takes some time to cancel if in a forward pass, so need to show a screen
                    dataPredictionTask?.cancel()

                    initiateFullRetrieval = false  // this will handle resetting to previous
                    if navPath.count == 1 {
                        predictionTaskWasCancelled = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + REConstants.ModelControl.defaultCancellingTimeToFreeResources) {
                            dismiss()
                        }
                    } else {
                        dismiss()
                    }
                }
                .disabled(predictionTaskWasCancelled)
            }
            
            
            ToolbarItem(placement: .confirmationAction) {
                
                if navPath.count == 0 {
                    // MARK: Note: documentSelectionState should stay on the main actor
                    Button {
                        
                        // initial core data tasks on main actor (currently, only a max of 100 documents) since documentSelectionState should stay on Main Actor
                        var rerankStructure: (jsonDocumentArray: [JSONDocument], retrievedDocumentIDs2NewDocumentIDs: [String: String], newDocumentIDs2RetrievedDocumentIDs: [String: String]) = (jsonDocumentArray: [], retrievedDocumentIDs2NewDocumentIDs: [:], newDocumentIDs2RetrievedDocumentIDs: [:])
                        do {
                            // refresh temporary storage
                            try dataController.refreshTemporaryStorageDatasetMainActor(moc: moc)
                            documentSelectionState.semanticSearchParameters.rerankParameters.reranking = true
                            rerankStructure = try dataController.constructJSONDocumentForReranking(documentSelectionState: documentSelectionState, moc: moc)
                            documentSelectionState.semanticSearchParameters.rerankParameters.newDocumentIDs2RetrievedDocumentIDs = rerankStructure.newDocumentIDs2RetrievedDocumentIDs
                            documentSelectionState.semanticSearchParameters.rerankParameters.retrievedDocumentIDs2NewDocumentIDs = rerankStructure.retrievedDocumentIDs2NewDocumentIDs
                            
                            
                            dataPredictionTask = Task {
                                do {
                                    
                                    try await dataController.addPreTokenizationDocumentsForDataset(jsonDocumentArray: rerankStructure.jsonDocumentArray, datasetId: REConstants.Datasets.placeholderDatasetId, moc: moc)

                                    
                                    await MainActor.run {
                                        navPath.append(Destinations.forward)
                                        
                                    }
                                } catch {
                                    await MainActor.run {
                                        showingErrorAlert = true
                                    }
                                }
                            }
                            
                        } catch {
                            showingErrorAlert = true
                        }
                        
                    } label: {
                        Text("Rerank")
                    }
                    .disabled(!semanticSearchResultsAvailableForReranking)

                } else if navPath.count == 1 {
                    Button {
                        navPath.append(Destinations.complete)
                        do {
                            rerankedDocumentIDsStructure = try dataController.rerankSearchCache(currentDocumentSelectionState: documentSelectionState, moc: moc)
                            retrievingDocumentStats = false
                        } catch {
                            retrievingDocumentStats = false
                            showingErrorAlert = true
                        }
                        
                    } label: {
                        Text("Display options")
                    }
                    .disabled(!predictionTaskIsComplete)
                } else if navPath.count == 2 {
                    Button {
                        updateSemanticSearchIDsWithRerankingResult()
                        initiateFullRetrieval = true
                        dismiss()
                    } label: {
                        Text("Display")
                    }
                    .disabled(retrievingDocumentStats || !rerankedDocumentsAvailableForDisplay)
                }
            }
        }
    }
}

