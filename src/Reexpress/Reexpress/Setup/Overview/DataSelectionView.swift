//
//  DataSelectionView.swift
//  Alpha1
//
//  Created by A on 8/16/23.
//

import SwiftUI


struct DataSelectionView: View {
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var dataController: DataController
    
    @Binding var documentSelectionState: DocumentSelectionState
    @Binding var initiateFullRetrieval: Bool?
    //var datasetIdCurrentlyDisplayed: Int?
    //@State var datasetId: Int = REConstants.DatasetsEnum.train.rawValue
    
    //@State private var selectionValid: Bool = false
    //@State private var selectionIntent: SelectionIntent = .partition
    //    var buttonDividerHeight: CGFloat = 40
    //    var navItems: [NavItem] = [.init(id: 0), .init(id: 1)]
    //    @State private var navigationState: [NavItem] = [.init(selectionIntent: .partition)]
    
    @State private var retrievalCount: Int = 0
    @State private var retrievalComplete: Bool = false
    
    @State private var navPath = NavigationPath()
    enum Destinations {
        case selectionOptions
        case retrieving
    }
    
    @State var semanticSearchTask: Task<Void, Error>?
    var semanticSearchRequest: Bool {
        return documentSelectionState.semanticSearchParameters.search && !documentSelectionState.semanticSearchParameters.searchText.isEmpty
    }
    @State private var inferenceErrorMessage: String = ""
    @State private var semanticSearchRunning: Bool = false
    @State var predictionTaskWasCancelled: Bool = false
    var disableSemanticSearch: Bool = false // In the graph view, we disable semantic search.
    var disableSortOptions: Bool = false  // In the graph view, sorting is not relevant.
    var body: some View {
        NavigationStack(path: $navPath) {
            DataSelectionMainView(documentSelectionState: $documentSelectionState, disableSemanticSearch: disableSemanticSearch, disableSortOptions: disableSortOptions)
                .navigationDestination(for: Destinations.self) { i in
                    switch i {
                    case Destinations.selectionOptions:
                        DataSelectionMainView(documentSelectionState: $documentSelectionState, disableSemanticSearch: disableSemanticSearch, disableSortOptions: disableSortOptions)
                    case Destinations.retrieving:
                        DataSelectionRetrievingResultsView(documentSelectionState: $documentSelectionState, retrievalCount: $retrievalCount, retrievalComplete: $retrievalComplete, inferenceErrorMessage: $inferenceErrorMessage, predictionTaskWasCancelled: $predictionTaskWasCancelled)
                            .navigationBarBackButtonHidden()
                    }
                }
        }
        .onDisappear {
            semanticSearchTask?.cancel()
            semanticSearchRunning = false
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                if navPath.count == 1 {
                    Button {
                        semanticSearchTask?.cancel()
                        semanticSearchRunning = false
                        navPath.removeLast()
                        retrievalComplete = false
                        retrievalCount = 0
                    } label: {
                        Text("Back")
                            .frame(width: 100)
                    }
                    .controlSize(.large)
                    .disabled(semanticSearchRunning || predictionTaskWasCancelled)
                }
            }
            
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    semanticSearchTask?.cancel()
                    if semanticSearchRunning {
                        predictionTaskWasCancelled = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + REConstants.ModelControl.defaultCancellingTimeToFreeResources) {
                            print("here to async")
                            semanticSearchRunning = false
                            initiateFullRetrieval = false
                            dismiss()
                        }
                    } else {
                        semanticSearchRunning = false
                        initiateFullRetrieval = false
                        dismiss()
                    }
                } label: {
                    Text("Cancel")
                        .frame(width: 100)
                }
                .controlSize(.large)
                .disabled(predictionTaskWasCancelled)
                
            }
            ToolbarItem(placement: .confirmationAction) {
                if navPath.count == 0 {
                    Button {
                        //selectionValid = true
                        navPath.append(Destinations.retrieving)
                        retrievalComplete = false
                        semanticSearchRunning = false
                        
                        // Reranking is reset each time a new selection is initiated
                        documentSelectionState.semanticSearchParameters.rerankParameters = RerankParameters()
                        
                        Task {
                            do {
                                let resultCount = try await dataController.getCountResult(documentSelectionState: documentSelectionState, moc: moc)
                                if resultCount > 0, semanticSearchRequest {
                                    semanticSearchRunning = true
                                        semanticSearchTask = Task {
                                            do {
                                            
                                                let semanticSearchResultStructure = try await dataController.semanticSearch(documentSelectionState: documentSelectionState, moc: moc)
                                                
                                                await MainActor.run {
                                                    documentSelectionState.semanticSearchParameters.retrievedDocumentIDs = semanticSearchResultStructure.retrievedDocumentIDs
                                                    documentSelectionState.semanticSearchParameters.retrievedDocumentIDs2HighlightRanges = semanticSearchResultStructure.retrievedDocumentIDs2HighlightRanges
                                                    documentSelectionState.semanticSearchParameters.retrievedDocumentIDs2DocumentLevelSearchDistances = semanticSearchResultStructure.retrievedDocumentIDs2DocumentLevelSearchDistances
                                                    
                                                    //print("Retrieved ranges: \(semanticSearchResultStructure.retrievedDocumentIDs2HighlightRanges.count)")
                                                    inferenceErrorMessage = ""
                                                    semanticSearchRunning = false
                                                    retrievalComplete = true
                                                    retrievalCount = documentSelectionState.semanticSearchParameters.retrievedDocumentIDs.count // resultCount
                                                }
                                            } catch KeyModelErrors.keyModelWeightsMissing {
                                                await MainActor.run {
                                                    inferenceErrorMessage = "The model must be trained to enable semantic searches. Consider a selection without a semantic search"
                                                    retrievalComplete = true
                                                    retrievalCount = 0
                                                    semanticSearchRunning = false
                                                }
                                            } catch KeyModelErrors.indexModelWeightsMissing {
                                                await MainActor.run {
                                                    inferenceErrorMessage = "The model must be compressed to enable semantic searches. Consider a selection without a semantic search"
                                                    retrievalComplete = true
                                                    retrievalCount = 0
                                                    semanticSearchRunning = false
                                                }
                                            } catch KeyModelErrors.compressionNotCurrent {
                                                await MainActor.run {
                                                    inferenceErrorMessage = "The model must be trained and compressed to enable semantic searches. Consider a selection without a semantic search, or train the compressed model before continuing."
                                                    retrievalComplete = true
                                                    retrievalCount = 0
                                                    semanticSearchRunning = false
                                                }
                                            } catch {
                                                inferenceErrorMessage = "Unable to find any reasonable matches for the semantic search. Consider adding additional words in the search box. If you have not yet run inference on this datasplit, go to Setup->Predict to get started."
                                                retrievalComplete = true
                                                retrievalCount = 0
                                                semanticSearchRunning = false
                                            }
                                        }
                                }
                                await MainActor.run {
                                    inferenceErrorMessage = ""
                                    retrievalComplete = true && !semanticSearchRunning
                                    retrievalCount = resultCount
                                }
                            } catch {
                                await MainActor.run {
                                    inferenceErrorMessage = ""
                                    retrievalComplete = true
                                    retrievalCount = 0
                                    semanticSearchRunning = false
                                }
                            }
                        }
                        
                    } label: {
                        Text("Select")
                            .frame(width: 100)
                    }
                    .controlSize(.large)
                } else {
                    Button {
                        //selectionValid = true
                        
                        initiateFullRetrieval = false // trigger on change
                        initiateFullRetrieval = true
                        dismiss()
                    } label: {
                        Text("Display Results")
                            .frame(width: 100)
                    }
                    .controlSize(.large)
                    .disabled(retrievalCount == 0 || semanticSearchRunning || predictionTaskWasCancelled)
                }
            }
        }
        
    }
}


