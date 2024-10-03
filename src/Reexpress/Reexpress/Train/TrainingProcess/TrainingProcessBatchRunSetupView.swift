//
//  TrainingProcessBatchRunSetupView.swift
//  Alpha1
//
//  Created by A on 9/4/23.
//

import SwiftUI

struct TrainingProcessBatchRunSetupView: View {
    @EnvironmentObject var dataController: DataController
    
    @ObservedObject var trainingProcessController: TrainingProcessController
    @ObservedObject var trainingProcessControllerIndexForBatchRun:TrainingProcessController
    @Binding var inferenceDatasetIds: Set<Int>
    var body: some View {
            ScrollView {
                VStack {
                    HStack {
                        Text("Training+Predict Batch Setup")
                            .font(.title)
                            .foregroundStyle(.gray)
                            .bold()
                        Spacer()
                    }
                    .padding()
                    Spacer()
                }
                VStack {
                    TrainingProcessSetupView(batchRun: true, modelControlIdString: REConstants.ModelControl.keyModelId, trainingProcessController: trainingProcessController)
                    TrainingProcessSetupView(batchRun: true, modelControlIdString: REConstants.ModelControl.indexModelId, trainingProcessController: trainingProcessControllerIndexForBatchRun)

                    VStack {
                        HStack {
                            Text("Choose datasplits for post-training inference")
                                .font(.title2)
                                .bold()
                            Spacer()
                        }
                        .padding()
                        SetupMainForwardAfterTrainingView(inferenceDatasetIds: $inferenceDatasetIds, datasetId: REConstants.DatasetsEnum.train.rawValue, hideTitle: true)
                            .frame(minHeight: 400)
                            .padding([.leading, .trailing], 40)
                    }
                    .padding()
                }
            }
    }
}

