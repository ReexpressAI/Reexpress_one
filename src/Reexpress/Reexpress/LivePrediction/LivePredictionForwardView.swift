//
//  LivePredictionForwardView.swift
//  Alpha1
//
//  Created by A on 9/11/23.
//

import SwiftUI

struct LivePredictionForwardView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var dataController: DataController
    
    @Binding var liveDocumentState: LiveDocumentState
    
    @Binding var currrentLiveDocumentId: String?  // may be in temporary cache, so could disappear at any moment
    @Binding var selectedDocumentObject: Document?
    @Binding var showingSelectedDocumentDetails: Bool
      
    
    
    @State private var navPath = NavigationPath()
    enum Destinations {
        case setup
        case forward
    }
    
    @State var datasetIds: Set<Int> = Set([REConstants.DatasetsEnum.train.rawValue, REConstants.DatasetsEnum.calibration.rawValue, REConstants.Datasets.placeholderDatasetId])  // currently, train and calibration are always checked to ensure they are current
    
    @State var totalElapsedTime: String = ""
    
    @State var processStartTime: Date?
    
    @State var dataPredictionTask: Task<Void, Error>?
    @State var predictionTaskWasCancelled: Bool = false
    @State var predictionTaskIsComplete: Bool = false
    
    @State var retrievingDocumentStats: Bool = true
    @State var showingErrorAlert: Bool = false
    @State var showingExistingRerankErrorAlert: Bool = false
    
    func updateDocumentObjectAndDismiss() {
        if let documentId = currrentLiveDocumentId {
            selectedDocumentObject = try? dataController.retrieveOneDocument(documentId: documentId, moc: moc)
            
            dismiss()
            showingSelectedDocumentDetails = true
        }
    }
    var body: some View {
        NavigationStack(path: $navPath) {
            LivePredictionInitView()

                .navigationDestination(for: Destinations.self) { i in
                    switch i {
                    case Destinations.setup:
                        LivePredictionInitView()
                            .navigationBarBackButtonHidden()
                    case Destinations.forward:
                        MainForwardAfterTrainingView(inferenceDatasetIds: $datasetIds, dataPredictionTask: $dataPredictionTask, predictionTaskWasCancelled: $predictionTaskWasCancelled, predictionTaskIsComplete: $predictionTaskIsComplete, totalElapsedInferenceTime: $totalElapsedTime, existingProcessStartTime: processStartTime)
                            .navigationBarBackButtonHidden()
                    }
                }
                .onChange(of: predictionTaskIsComplete) {
                    if predictionTaskIsComplete && !predictionTaskWasCancelled && !showingErrorAlert && !totalElapsedTime.isEmpty {
                        updateDocumentObjectAndDismiss()
                    }
                }
                .onAppear {
                    // initial core data tasks on main actor since liveDocumentState should stay on the MainActor
                    do {
                        // refresh temporary storage
                        try dataController.refreshTemporaryStorageDatasetMainActor(moc: moc)
                        
                        let jsonDocumentArray = try dataController.constructJSONDocumentForLivePrediction(liveDocumentState: liveDocumentState, moc: moc)
                        
                        if jsonDocumentArray.count != 1 {
                            throw MLForwardErrors.livePredictionError
                        }
                        if let jsonDoc = jsonDocumentArray.first {
                            currrentLiveDocumentId = jsonDoc.id
                        }
                        dataPredictionTask = Task {
                            do {
                                try await dataController.addPreTokenizationDocumentsForDataset(jsonDocumentArray: jsonDocumentArray, datasetId: REConstants.Datasets.placeholderDatasetId, moc: moc)
                                
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
                }
                .onDisappear {
                    dataPredictionTask?.cancel()
                }
                .alert("Unable to run prediction.", isPresented: $showingErrorAlert) {
                    Button {
                        // it takes some time to cancel if in a forward pass, so need to show a screen
                        dataPredictionTask?.cancel()
                        currrentLiveDocumentId = nil
                        selectedDocumentObject = nil
                        dismiss()
                    } label: {
                        Text("OK")
                    }
                } message: {
                    Text("Please try again.")
                }
                .toolbar {
                    
                    ToolbarItem(placement: .cancellationAction) {
                        // MARK: Note: This will also be called if the user taps ESC.
                        
                        Button("Cancel") {
                            // it takes some time to cancel if in a forward pass, so need to show a screen
                            dataPredictionTask?.cancel()
                            
                            if navPath.count == 1 && !predictionTaskIsComplete {
                                predictionTaskWasCancelled = true
                                currrentLiveDocumentId = nil
                                selectedDocumentObject = nil
                                DispatchQueue.main.asyncAfter(deadline: .now() + REConstants.ModelControl.defaultCancellingTimeToFreeResources) {
                                    dismiss()
                                }
                            } else {
                                currrentLiveDocumentId = nil
                                selectedDocumentObject = nil
                                dismiss()
                            }
                        }
                        .disabled(predictionTaskWasCancelled)
                    }
                }
        }
    }
}
                    // Currently we auto display. This prevents the user from having to make an unnecessary extra click. This is triggered by the .onChange
                    /*ToolbarItem(placement: .confirmationAction) {
                        
                        if navPath.count == 1 {
                            // MARK: Note: documentSelectionState should stay on the main actor
                            Button {
                                updateDocumentObjectAndDismiss()
                                /*if let documentId = currrentLiveDocumentId {
                                    selectedDocumentObject = try? dataController.retrieveOneDocument(documentId: documentId, moc: moc)
                                    
                                    dismiss()
                                    showingSelectedDocumentDetails = true
                                }*/
                                
                                
                            } label: {
                                Text("Display")
                            }
                            .disabled(!predictionTaskIsComplete || predictionTaskWasCancelled)
                        }
                    }*/

