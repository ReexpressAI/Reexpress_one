//
//  DataOverviewBatchSelectionView.swift
//  Alpha1
//
//  Created by A on 8/27/23.
//

import SwiftUI

struct CurrentMultiSelectionStatusView: View {
    @Binding var multipleSelectedDocuments: Set<TableDataPoint.ID>
    @Binding var documentBatchChangeState: DocumentBatchChangeState
    var totalDocumentsInCurrentSelection: Int = 0
    var body: some View {
        HStack {
            Divider()
                .frame(width: 2, height: 25)
                .overlay(.gray)
            Grid {
                GridRow {
                    Text("Documents currently selected:")
                        .gridColumnAlignment(.trailing)
                        .foregroundStyle(.gray)
                        .font(REConstants.Fonts.baseFont)
                    if documentBatchChangeState.applyChangesToAllDocumentsAndRowsInSelection {
                        Text(String(totalDocumentsInCurrentSelection))
                            .gridColumnAlignment(.leading)
                            .monospaced()
                            .font(REConstants.Fonts.baseFont)
                            .foregroundStyle(.orange)
                            .opacity(0.75)
                    } else {
                        Text(String(multipleSelectedDocuments.count))
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
}

struct DataOverviewBatchSelectionView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var dataController: DataController

    @Binding var multipleSelectedDocuments: Set<TableDataPoint.ID>
    var datasetId: Int? // this is needed to update the model state
    
    @State private var navPath = NavigationPath()
    enum Destinations {
        case changeOptions
        case processingChange
    }
    @State var dataUpdateTask: Task<Void, Error>?
    @State var documentBatchChangeState: DocumentBatchChangeState = DocumentBatchChangeState()
    @State var changeProcessing: Bool = false
    @State var errorMessage: String = ""
    
    var totalDocumentsInCurrentSelection: Int = 0
    @Binding var documentSelectionState: DocumentSelectionState
    
    var ifTransferringNewDatasplitHasSpaceAvailable: Bool {
        if documentBatchChangeState.transferDatasplit, let newDatasplitID = documentBatchChangeState.newDatasplitID, let dataset = dataController.inMemory_Datasets[newDatasplitID], let currentCount = dataset.count {
            // check for space:
            return currentCount + multipleSelectedDocuments.count <= REConstants.DatasetsConstraints.maxTotalLines
        }
        return true
    }
    var ifTransferringNewDatasplitDiffersFromExisting: Bool {
        if documentBatchChangeState.transferDatasplit {
            if let newDatasplitID = documentBatchChangeState.newDatasplitID {
                if let currentDatasetID = datasetId {
                    return currentDatasetID != newDatasplitID
                } else {
                    return false
                }
            } else {
                return false
            }
        }
        return true
    }
    var ifLabelChangeLabelIsSelected: Bool {
        if documentBatchChangeState.changeLabel {
            return documentBatchChangeState.newLabelID != nil
        }
        return true
    }
    var selectionSizeIsSufficient: Bool {
        if documentBatchChangeState.applyChangesToAllDocumentsAndRowsInSelection {
            return totalDocumentsInCurrentSelection > 0
        } else {
            return !multipleSelectedDocuments.isEmpty && totalDocumentsInCurrentSelection > 0
        }
    }
    // Note that group and info can be empty strings
    var processingCannotStart: Bool {
        return !documentBatchChangeState.atLeastOneChangeOperationSelected || !selectionSizeIsSufficient || !ifTransferringNewDatasplitHasSpaceAvailable || !ifLabelChangeLabelIsSelected || !ifTransferringNewDatasplitDiffersFromExisting
    }
    var disableProcessStart: Bool {
        return processingCannotStart || changeProcessing || !errorMessage.isEmpty
    }
    var body: some View {
        NavigationStack(path: $navPath) {
            DataOverviewBatchSelectionMainView(multipleSelectedDocuments: $multipleSelectedDocuments, documentBatchChangeState: $documentBatchChangeState, datasetId: datasetId, totalDocumentsInCurrentSelection: totalDocumentsInCurrentSelection)
                .navigationDestination(for: Destinations.self) { i in
                    switch i {
                    case Destinations.changeOptions:
                        DataOverviewBatchSelectionMainView(multipleSelectedDocuments: $multipleSelectedDocuments, documentBatchChangeState: $documentBatchChangeState, datasetId: datasetId, totalDocumentsInCurrentSelection: totalDocumentsInCurrentSelection)
                    case Destinations.processingChange:
                        DataOverviewBatchSelectionProcessingChangeView(changeProcessing: $changeProcessing, errorMessage: $errorMessage)
                            .navigationBarBackButtonHidden()
                    }
                }
        }
        .onDisappear {
            dataUpdateTask?.cancel()
        }
        .toolbar {
            if navPath.count == 0 || (navPath.count == 1 && changeProcessing) {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dataUpdateTask?.cancel()
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .frame(width: 100)
                    }
                    .controlSize(.large)
                    .disabled(!errorMessage.isEmpty)
//                    .disabled(changeProcessing || !errorMessage.isEmpty)
                }
                
            }
            ToolbarItem(placement: .confirmationAction) {
                if navPath.count == 0 {
                    Button {
                        changeProcessing = true
                        navPath.append(Destinations.processingChange)
                        dataUpdateTask = Task {
                            do {
                                // if for some unexpected reason the datasetId is nil, we throw
                                guard let datasetId = datasetId else {
                                    throw BatchUpdateErrors.batchUpdateFailed
                                }
                                let expectedSizeOfUpdate: Int
                                if documentBatchChangeState.applyChangesToAllDocumentsAndRowsInSelection {
                                    // This is just an additional check that the currently viewed selection matches the documentSelectionState structure
                                    expectedSizeOfUpdate = totalDocumentsInCurrentSelection
                                } else {
                                    expectedSizeOfUpdate = multipleSelectedDocuments.count
                                }
                                try await dataController.processBatchUpdate(datasetId: datasetId, documentBatchChangeState: documentBatchChangeState, multipleSelectedDocuments: multipleSelectedDocuments, moc: moc, documentSelectionState: documentSelectionState, expectedSizeOfUpdate: expectedSizeOfUpdate)
                                try? await dataController.updateInMemoryDatasetStats(moc: moc, dataController: dataController)
                                
                                await MainActor.run {
                                    changeProcessing = false
                                    // need to deselect
                                    //dismiss()
                                    multipleSelectedDocuments.removeAll()
                                }
                            } catch {
                                // Update in case there were partial changes
                                try? await dataController.updateInMemoryDatasetStats(moc: moc, dataController: dataController)
                                // Need to display error message
                                await MainActor.run {
                                    errorMessage = "Unable to complete the batch update operation."
                                    changeProcessing = false
                                    multipleSelectedDocuments.removeAll()
                                    //dismiss()
                                }
                            }
                        }
                        
                    } label: {
                        Text("Process Update")
                            .frame(width: 100)
                    }
                    .controlSize(.large)
                    .disabled(disableProcessStart)
                } else {
                    Button {
                        dismiss()
                    } label: {
                        Text(errorMessage.isEmpty ? "Done" : "OK")
                            .frame(width: 100)
                    }
                    .controlSize(.large)
                    .disabled(changeProcessing) // || !errorMessage.isEmpty)
                }
            }
        }
    }
}

