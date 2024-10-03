//
//  UncacheEmbeddingsEstimatingStorageView.swift
//  Alpha1
//
//  Created by A on 9/1/23.
//

import SwiftUI

struct UncacheEmbeddingsEstimatingStorageView: View {
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
    
//    func getCacheSizeForDisplay(datasetId: Int) -> String {
//        if let estimateStorage = cacheToClearDatasetIds2EstimateSize[datasetId] {
//            if estimateStorage > 0.0 && estimateStorage < 1.0 {
//                return "<1 MB"
//            } else {
//                let noDecimals = String(format: "%.0f", estimateStorage)
//                return "\(noDecimals) MB"
//            }
//        } else {
//            return "0 MB"
//        }
//    }

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
            
            HStack {
                Text("Available datasplits")
                    .font(.title3)
                    .foregroundStyle(.gray)
                Spacer()
            }
            if estimatesAvailable {
                VStack {
                    List {
                        VStack(alignment: .leading) {
                            HStack(alignment: .firstTextBaseline) {
                                Label("", systemImage: selectAll ? "checkmark.square.fill" : "square")
                                    .font(.title2)
                                    .foregroundStyle(!allAvailableDatasetIds.isEmpty ? Color.blue.gradient : Color.gray.gradient)
                                    .labelStyle(.iconOnly)
                                    .onTapGesture {
                                        if !allAvailableDatasetIds.isEmpty {
                                            if selectAll {
                                                cacheToClearDatasetIds = Set<Int>()
                                                selectAll = false
                                            } else {
                                                cacheToClearDatasetIds = Set(allAvailableDatasetIds)
                                                selectAll = true
                                            }
                                        }
                                    }
                                Text("Select All")
                                    .font(REConstants.Fonts.baseFont)
                                    .foregroundStyle(.gray)
                                    .italic()
                            }
                            Divider()
                        }
                        .listRowSeparator(.hidden)
                        ForEach(Array(dataController.inMemory_Datasets.keys.sorted()), id: \.self) { datasetId in
                            if datasetId != REConstants.Datasets.placeholderDatasetId {
                                if let dataset = dataController.inMemory_Datasets[datasetId], (dataset.count ?? 0) > 0, cacheToClearDatasetIds2EstimateSize[dataset.id] != nil {
                                    VStack(alignment: .leading) {
                                        HStack(alignment: .firstTextBaseline) {
                                            Label("", systemImage: cacheToClearDatasetIds.contains(datasetId) ? "checkmark.square.fill" : "square")
                                                .font(.title2)
                                                .foregroundStyle(.blue.gradient)
                                                .labelStyle(.iconOnly)
                                                .onTapGesture {
                                                    if cacheToClearDatasetIds.contains(datasetId) {
                                                        cacheToClearDatasetIds.remove(datasetId)
                                                    } else {
                                                        cacheToClearDatasetIds.insert(datasetId)
                                                    }
                                                    // This just maintains consistency with the Select All option (i.e., if the user manually selects all options, we update the indicator).
                                                    if cacheToClearDatasetIds == allAvailableDatasetIds {
                                                        selectAll = true
                                                    } else {
                                                        selectAll = false
                                                    }
                                                    
                                                }
                                            
                                            if let datasetName = dataset.userSpecifiedName {
                                                Text("\(datasetName)")
                                                    .font(REConstants.Fonts.baseFont)
                                            } else {
                                                Text("\(dataset.internalName) (\(dataset.id)")
                                                    .font(REConstants.Fonts.baseFont)
                                            }
                                        }
                                        HStack(spacing: 0) {
                                            Text("Estimated cache size: ")
                                                .foregroundStyle(.gray)
                                                .font(REConstants.Fonts.baseFont)
                                            Text(REConstants.StorageEstimates.getEstimatedDataSizeForDisplay(datasetId: dataset.id, datasetId2EstimatedSize: cacheToClearDatasetIds2EstimateSize))
                                                .monospaced()
                                                .foregroundStyle(.white)
                                                .font(REConstants.Fonts.baseFont)
                                        }
                                        .padding(.leading, 28)
                                    }
                                    .listRowSeparator(.hidden)
                                }
                            }
                        }
                    }
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
                    Text("Estimating cache size")
                        .font(REConstants.Fonts.baseFont)
                        .foregroundStyle(.gray)
                    Spacer()
                }
                .padding()
                .modifier(SimpleBaseBorderModifier())
            }
        }
        
        .padding()
        .onAppear {
            // Currently no pre-selection since not all datasplits have cached states
//            // initial dataset:
//            if let dataset = dataController.inMemory_Datasets[datasetId], (dataset.count ?? 0) > 0 {
//                cacheToClearDatasetIds.insert(datasetId)
//            }
            
            var datasetIds = Set<Int>() // for background thread
            for datasetId in Array(dataController.inMemory_Datasets.keys) {
                if datasetId != REConstants.Datasets.placeholderDatasetId, let dataset = dataController.inMemory_Datasets[datasetId], (dataset.count ?? 0) > 0 {
                    
                    datasetIds.insert(datasetId)
                }
            }
            // this task is sufficiently fast we can just let the system handle cancellation
            Task {
                do {
                    let estimatesDict = try await dataController.estimateCacheSize(cacheToClearDatasetIds: datasetIds)
                    await MainActor.run {
                        if !estimatesDict.isEmpty {
                            cacheToClearDatasetIds2EstimateSize = estimatesDict
                            allAvailableDatasetIds = Set(estimatesDict.keys)  // for display updating comparisons
                        }
                        estimatesAvailable = true
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
