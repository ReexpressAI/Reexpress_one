//
//  TrainingStorageEstimateView.swift
//  Alpha1
//
//  Created by A on 9/4/23.
//

import SwiftUI

struct TrainingStorageEstimateView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var dataController: DataController
    
    
    @Binding var datasetIds: Set<Int>
    @Binding var errorAlert: Bool
    @Binding var estimatesAvailable: Bool
    @State private var inferenceDatasetIds2EstimateTotalSize: [Int: Double] = [:]
    @State private var inferenceDatasetIds2EstimateAdditionalSize: [Int: Double] = [:]
    @State private var cacheToClearDatasetIds2EstimateTotalSize: [Int: Double] = [:]
    @State private var cacheToClearDatasetIds2EstimateAdditionalSize: [Int: Double] = [:]
    var body: some View {
        ScrollView {
            VStack {
                HStack {
                    Text("Estimating required storage space")
                        .font(.title2)
                        .bold()
                    Spacer()
                }
                .padding()
                Spacer()
            }
            
            VStack {
                HStack {
                    Text("Space estimate")
                        .font(.title3)
                        .foregroundStyle(.gray)
                    PopoverViewWithButtonLocalState(popoverViewText: "'Total' is the estimate for all documents in the datasplit. 'Additional' is an estimate for the storage needed excluding documents with cached states and/or predictions from a previous run. (A datasplit with 0 MB of estimated additional storage will still be updated if the existing predictions are out-of-date with the current model. The new predictions will replace those previously stored.)", optionalSubText: REConstants.HelpAssistanceInfo.storageEstimateDisclaimer)
                    
                    Spacer()
                }
                if estimatesAvailable {
                    VStack {
                        List {
                            ForEach(datasetIds.sorted(), id: \.self) { datasetId in
                                if datasetId != REConstants.Datasets.placeholderDatasetId {
                                    if let dataset = dataController.inMemory_Datasets[datasetId], (dataset.count ?? 0) > 0, inferenceDatasetIds2EstimateTotalSize[dataset.id] != nil, inferenceDatasetIds2EstimateAdditionalSize[dataset.id] != nil {
                                        VStack(alignment: .leading) {
                                            HStack(alignment: .firstTextBaseline) {
                                                
                                                if let datasetName = dataset.userSpecifiedName {
                                                    Text("\(datasetName)")
                                                        .font(REConstants.Fonts.baseFont)
                                                } else {
                                                    Text("\(dataset.internalName) (\(dataset.id)")
                                                        .font(REConstants.Fonts.baseFont)
                                                }
                                            }
                                            Grid {
                                                if cacheToClearDatasetIds2EstimateTotalSize[dataset.id] != nil, cacheToClearDatasetIds2EstimateAdditionalSize[dataset.id] != nil {
                                                    
                                                    GridRow {
                                                        Text("Estimated cache size for training")
                                                            .foregroundStyle(.gray)
                                                            .gridCellColumns(2)
                                                    }
                                                    GridRow {
                                                        Text("Total:")
                                                            .foregroundStyle(.gray)
                                                            .gridColumnAlignment(.trailing)
                                                        Text(REConstants.StorageEstimates.getEstimatedDataSizeForDisplay(datasetId: dataset.id, datasetId2EstimatedSize: cacheToClearDatasetIds2EstimateTotalSize))
                                                            .monospaced()
                                                            .foregroundStyle(.white)
                                                            .gridColumnAlignment(.leading)
                                                    }
                                                    GridRow {
                                                        Text("Additional:")
                                                            .foregroundStyle(.gray)
                                                        Text(REConstants.StorageEstimates.getEstimatedDataSizeForDisplay(datasetId: dataset.id, datasetId2EstimatedSize: cacheToClearDatasetIds2EstimateAdditionalSize))
                                                            .monospaced()
                                                            .foregroundStyle(.white)
                                                    }
                                                }
                                                GridRow {
                                                    Text("Estimated storage size for inference")
                                                        .foregroundStyle(.gray)
                                                        .gridCellColumns(2)
                                                }
                                                GridRow {
                                                    Text("Total:")
                                                        .foregroundStyle(.gray)
                                                        .gridColumnAlignment(.trailing)
                                                    Text(REConstants.StorageEstimates.getEstimatedDataSizeForDisplay(datasetId: dataset.id, datasetId2EstimatedSize: inferenceDatasetIds2EstimateTotalSize))
                                                        .monospaced()
                                                        .foregroundStyle(.white)
                                                        .gridColumnAlignment(.leading)
                                                }
                                                GridRow {
                                                    Text("Additional:")
                                                        .foregroundStyle(.gray)
                                                    Text(REConstants.StorageEstimates.getEstimatedDataSizeForDisplay(datasetId: dataset.id, datasetId2EstimatedSize: inferenceDatasetIds2EstimateAdditionalSize))
                                                        .monospaced()
                                                        .foregroundStyle(.white)
                                                }
                                            }
                                            .font(REConstants.Fonts.baseFont)
                                            .padding(.leading, 28)
                                        }
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
                        Text("Estimating storage")
                            .font(REConstants.Fonts.baseFont)
                            .foregroundStyle(.gray)
                        Spacer()
                    }
                    .padding()
                    .modifier(SimpleBaseBorderModifier())
                }
            }
            .frame(minHeight: 400)
            .padding()
        }
        .padding()
        .navigationBarBackButtonHidden(true)
        .onAppear {
            let datasetIds = datasetIds // for background thread
            // this task is sufficiently fast we can just let the system handle cancellation
            Task {
                do {
                    let cacheEstimatesDict = try await dataController.estimateCacheSizeIncludingAdditionalDiffTrainingAndCalibration()
                    let estimatesStructure = try await dataController.estimateInferenceSize(inferenceDatasetIds: datasetIds)
                    
                    await MainActor.run {
                        if !(cacheEstimatesDict.cacheToClearDatasetIds2EstimateTotalSize.isEmpty && cacheEstimatesDict.cacheToClearDatasetIds2EstimateAdditionalSize.isEmpty)  && !(estimatesStructure.inferenceDatasetIds2EstimateTotalSize.isEmpty && estimatesStructure.inferenceDatasetIds2EstimateAdditionalSize.isEmpty) {
                            
                            cacheToClearDatasetIds2EstimateTotalSize = cacheEstimatesDict.cacheToClearDatasetIds2EstimateTotalSize
                            cacheToClearDatasetIds2EstimateAdditionalSize = cacheEstimatesDict.cacheToClearDatasetIds2EstimateAdditionalSize
                            
                            inferenceDatasetIds2EstimateTotalSize = estimatesStructure.inferenceDatasetIds2EstimateTotalSize
                            inferenceDatasetIds2EstimateAdditionalSize = estimatesStructure.inferenceDatasetIds2EstimateAdditionalSize
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
