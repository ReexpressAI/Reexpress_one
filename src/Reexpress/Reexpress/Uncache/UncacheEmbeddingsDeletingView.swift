//
//  UncacheEmbeddingsDeletingView.swift
//  Alpha1
//
//  Created by A on 9/2/23.
//

import SwiftUI

struct UncacheEmbeddingsDeletingView: View {
    //    @Environment(\.dismiss) var dismiss
    //    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var dataController: DataController
    
    @Binding var cacheToClearDatasetIds: Set<Int>
    @Binding var cacheToClearDatasetIds2EstimateSize: [Int: Double]
    var datasetId: Int = 0
    
    @State var allAvailableDatasetIds: Set<Int> = Set<Int>()
    
    @State var isShowingRequiredDatasetInfo: Bool = false
    
    @State var selectAll: Bool = false
    @Binding var estimatesAvailable: Bool
    @Binding var errorAlert: Bool
    @Binding var cacheSuccessfullyCleared: Bool
    @Binding var deletionTaskWasCancelled: Bool
    @Binding var dataDeleteTask: Task<Void, Error>?
    
    func getCacheSizeForDisplay(datasetId: Int) -> String {
        if let estimateStorage = cacheToClearDatasetIds2EstimateSize[datasetId] {
            if estimateStorage > 0.0 && estimateStorage < 1.0 {
                return "<1 MB"
            } else {
                return "\(estimateStorage) MB"
            }
        } else {
            return "0 MB"
        }
    }
    var body: some View {
        VStack {
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Uncache the Model's Hidden States")
                        .font(.title2.bold())
                }
                Spacer()
                HelpAssistanceView_Uncache()
            }
            
            if deletionTaskWasCancelled {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        ZStack {
                            CancellingAndFreeingResourcesView(taskWasCancelled: $deletionTaskWasCancelled)
                            Text("")
                        }
                        Spacer()
                    }
                    Spacer()
                }
                .padding()
                .modifier(SimpleBaseBorderModifier())
            } else {
                VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        Text("Clearing cache")
                            .font(REConstants.Fonts.baseFont)
                            .foregroundStyle(.gray)
                        Spacer()
                }
                .padding()
                .modifier(SimpleBaseBorderModifier())
            }
            
        }
        
        
        .onAppear {
            if cacheToClearDatasetIds.isEmpty {
                errorAlert = true
            } else {
                let datasetIds = cacheToClearDatasetIds // for background thread
                dataDeleteTask = Task {
                    do {
                        try await dataController.deleteEmbeddingForDatasets(cacheToClearDatasetIds: datasetIds)
                        await MainActor.run {
                            cacheSuccessfullyCleared = true
                        }
                    } catch {
                        await MainActor.run {
                            errorAlert = true
                        }
                    }
                }
            }
        }
    }
    
}
