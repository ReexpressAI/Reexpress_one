//
//  DataSelectionRetrievingResultsView.swift
//  Alpha1
//
//  Created by A on 8/18/23.
//

import SwiftUI

struct DataSelectionRetrievingResultsView: View {
    @EnvironmentObject var dataController: DataController
    
    @Binding var documentSelectionState: DocumentSelectionState
    
    @Binding var retrievalCount: Int
    @Binding var retrievalComplete: Bool
    @Binding var inferenceErrorMessage: String
    @Binding var predictionTaskWasCancelled: Bool
    var body: some View {
        //ScrollView {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Selection")
                        .font(.title2.bold())
                    //                        Divider()
                    //                            .frame(width: 2, height: 25)
                    //                            .overlay(.gray)
                    //CurrentSelectionResultsView()
                    //                        SelectionResultsView()
                    Spacer()
                    //                        HStack(alignment: .lastTextBaseline) {
                    //
                    //                        }
                }
            }
            Spacer()
            
            if predictionTaskWasCancelled {
                HStack {
                    Spacer()
                    CancellingAndFreeingResourcesView(taskWasCancelled: $predictionTaskWasCancelled)
                    Spacer()
                }
            } else {
                if !retrievalComplete {
                    VStack {
                        ProgressView()
                        HStack {
                            Spacer()
                            Text("Retrieving selection")
                                .font(REConstants.Fonts.baseFont)
                                .foregroundStyle(.gray)
                            Spacer()
                        }
                    }
                } else {
                    VStack {
                        VStack {
                            HStack(spacing: 0) {
                                Spacer()
                                Text("\(retrievalCount) documents")
                                    .monospaced()
                                    .foregroundStyle(.orange)
                                    .opacity(0.75)
                                Text(" meet the selection criteria in the the following datasplit: ")
                                    .foregroundStyle(.gray)
                                Spacer()
                            }
                            HStack(spacing: 0) {
                                Spacer()
                                SingleDatasplitView(datasetId: documentSelectionState.datasetId)
                                    .monospaced()
                                    .foregroundStyle(.orange)
                                    .opacity(0.75)
                                Spacer()
                            }
                        }
                        if !inferenceErrorMessage.isEmpty {
                            Text(inferenceErrorMessage)
                                .monospaced()
                                .foregroundStyle(.red)
                                .opacity(0.75)
                                .padding()
                                .modifier(SimpleBaseBorderModifier())
                                .padding()
                                .frame(width: 450)
                        }
                    }
                    .font(REConstants.Fonts.baseFont)
                }
            }
            Spacer()
        }
        .padding([.leading, .trailing])
        //}
        //.scrollBounceBehavior(.basedOnSize)
        .padding()
        .modifier(SimpleBaseBorderModifier())
        .padding()
    }
}


