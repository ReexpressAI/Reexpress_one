//
//  UncacheEmbeddingsView.swift
//  Alpha1
//
//  Created by A on 9/1/23.
//

import SwiftUI

extension UncacheEmbeddingsView {
    @MainActor class ViewModel: ObservableObject {
        
        enum Destinations {
            case cacheStorageEstimate
            case clearingCache
        }
        @Published var currentView = Destinations.cacheStorageEstimate
    }
}

struct UncacheEmbeddingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var dataController: DataController
    
    @StateObject var viewModel: ViewModel = ViewModel()
    
    var datasetId: Int = 0
    
    @State var dataDeleteTask: Task<Void, Error>?
    @State var isShowingRequiredDatasetInfo: Bool = false
    
    @State var selectAll: Bool = false
    
    @State private var navPath = NavigationPath()
    
    
    @State var cacheToClearDatasetIds: Set<Int> = Set<Int>()
    @State var cacheToClearDatasetIds2EstimateSize: [Int: Double] = [:]
    
    @State var predictionTaskWasCancelled: Bool = false
    @State var deletionTaskWasCancelled: Bool = false
    
    @State var estimatesAvailable: Bool = false
    @State var errorAlert: Bool = false
    @State var cacheSuccessfullyCleared: Bool = false
    
    var body: some View {
        NavigationStack(path: $navPath) {
            UncacheEmbeddingsEstimatingStorageView(cacheToClearDatasetIds: $cacheToClearDatasetIds, cacheToClearDatasetIds2EstimateSize: $cacheToClearDatasetIds2EstimateSize, datasetId: datasetId, estimatesAvailable: $estimatesAvailable, errorAlert: $errorAlert)
                .navigationDestination(for: ViewModel.Destinations.self) { i in
                    switch i {
                    case ViewModel.Destinations.cacheStorageEstimate:
                        UncacheEmbeddingsEstimatingStorageView(cacheToClearDatasetIds: $cacheToClearDatasetIds, cacheToClearDatasetIds2EstimateSize: $cacheToClearDatasetIds2EstimateSize, datasetId: datasetId, estimatesAvailable: $estimatesAvailable, errorAlert: $errorAlert)

                    case ViewModel.Destinations.clearingCache:
                        UncacheEmbeddingsDeletingView(cacheToClearDatasetIds: $cacheToClearDatasetIds, cacheToClearDatasetIds2EstimateSize: $cacheToClearDatasetIds2EstimateSize, datasetId: datasetId, estimatesAvailable: $estimatesAvailable, errorAlert: $errorAlert, cacheSuccessfullyCleared: $cacheSuccessfullyCleared, deletionTaskWasCancelled: $deletionTaskWasCancelled, dataDeleteTask: $dataDeleteTask)
                            .navigationBarBackButtonHidden()
                    }
                }
        }
        .alert("Success!", isPresented: $cacheSuccessfullyCleared) {
            Button {
                dismiss()
            } label: {
                Text("OK")
            }
        } message: {
            Text("Cache successfully cleared.")
        }
        .alert("An unexpected error was encountered.", isPresented: $errorAlert) {
            Button {
                dismiss()
            } label: {
                Text("OK")
            }
        } message: {
            Text("Unable to uncache.")
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                // MARK: Note: This will also be called if the user taps ESC.
                
                Button("Cancel") {
                    // it may take some time to cancel, so need to show a screen
                    dataDeleteTask?.cancel()
                    if navPath.count > 0 {
                        deletionTaskWasCancelled = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + REConstants.ModelControl.defaultCancellingTimeToFreeResources) {
                            dismiss()
                        }
                    } else {
                        dismiss()
                    }
                }
                .disabled(deletionTaskWasCancelled)
            }
            ToolbarItem(placement: .confirmationAction) {
                if navPath.count == 0 {
                    Button("Uncache") {
                        navPath.append(ViewModel.Destinations.clearingCache)
                    }
                    .disabled(cacheToClearDatasetIds.isEmpty)
                }
            }
        }
        .onDisappear {
            // Typically, we disable ESC closing the modal, but here we just always check that the task was properly canceled to be safe.
            dataDeleteTask?.cancel()
        }
    }
}
