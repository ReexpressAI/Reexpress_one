//
//  SetupMainForwardAfterTrainingEstimateStorageView.swift
//  Alpha1
//
//  Created by A on 8/4/23.
//

import SwiftUI

struct SetupMainForwardAfterTrainingEstimateStorageView: View {
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var dataController: DataController
    
    
    @Binding var inferenceDatasetIds: Set<Int>
    @Binding var errorAlert: Bool
    @Binding var estimatesAvailable: Bool
    @State private var inferenceDatasetIds2EstimateTotalSize: [Int: Double] = [:]
    @State private var inferenceDatasetIds2EstimateAdditionalSize: [Int: Double] = [:]
    var body: some View {
        VStack {
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Predict")
                        .font(.title2.bold())
                    Text("Estimating required storage space")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                /*HStack(alignment: .firstTextBaseline) {
                    
                    Button {
                    } label: {
                        UncertaintyGraphControlButtonLabelWithCaptionVStack(buttonImageName: "questionmark.circle", buttonTextCaption: "Help", buttonForegroundStyle: AnyShapeStyle(Color.gray.gradient))
                    }
                    .buttonStyle(.borderless)
                }*/
            }
            
            HStack {
                Text("Space estimate")
                    .font(.title3)
                    .foregroundStyle(.gray)
                PopoverViewWithButtonLocalState(popoverViewText: "'Total' is the estimate for all documents in the datasplit. 'Additional' is an estimate for the storage needed excluding documents with predictions from previously running Predict. (A datasplit with 0 MB of estimated additional storage will still be updated if the predictions are out-of-date with the current model. The new predictions will replace those previously stored.)")
                Spacer()
            }
            if estimatesAvailable {
                VStack {
                    List {
                        ForEach(inferenceDatasetIds.sorted(), id: \.self) { datasetId in
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
                    Text("Estimating inference storage")
                        .font(REConstants.Fonts.baseFont)
                        .foregroundStyle(.gray)
                    Spacer()
                }
                .padding()
                .modifier(SimpleBaseBorderModifier())
            }
            //Spacer()
        }
        .padding()
        .navigationBarBackButtonHidden(true)
        .onAppear {
            let datasetIds = inferenceDatasetIds // for background thread
            // this task is sufficiently fast we can just let the system handle cancellation
            Task {
                do {
                    let estimatesStructure = try await dataController.estimateInferenceSize(inferenceDatasetIds: datasetIds)

                    await MainActor.run {
                        if !(estimatesStructure.inferenceDatasetIds2EstimateTotalSize.isEmpty && estimatesStructure.inferenceDatasetIds2EstimateAdditionalSize.isEmpty) {
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

//struct SetupMainForwardAfterTrainingEstimateStorageView_Previews: PreviewProvider {
//    static var previews: some View {
//        SetupMainForwardAfterTrainingEstimateStorageView( inferenceDatasetIds: .constant(Set<Int>([0,1,2])))
//    }
//}
