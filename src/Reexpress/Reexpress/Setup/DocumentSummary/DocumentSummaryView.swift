//
//  DocumentSummaryView.swift
//  Alpha1
//
//  Created by A on 8/9/23.
//

import SwiftUI

struct DocumentSummaryView: View {
    
    @EnvironmentObject var dataController: DataController
    
    var datasetId: Int
    @State var dataTask: Task<Void, Error>?
    
    @State private var summaryStatsAvailable: Bool = false
    @State private var labelSummaryStatistics: (labelTotalsByClass: [Int: Float32], labelFreqByClass: [Int: Float32], totalDocuments: Int)?
    @State private var errorEncountered: Bool = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                VStack(alignment: .leading) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Label Summary")
                            .font(.title2.bold())
                        Spacer()
                    }
                    SingleDatasplitView(datasetId: datasetId)
                        .font(REConstants.Fonts.baseFont)
                        .monospaced()
                }
                
                if !summaryStatsAvailable {
                    VStack {
                        Spacer()
                        if !errorEncountered {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                            Text("Preparing label summary statistics")
                                .font(REConstants.Fonts.baseFont)
                                .foregroundStyle(.gray)
                        } else {
                            HStack {
                                Spacer()
                                Text("Unable to retrieve label summary statistics")
                                    .font(REConstants.Fonts.baseFont)
                                    .foregroundStyle(.gray)
                                    .italic()
                                Spacer()
                            }
                        }
                        Spacer()
                    }
                    .padding()
                    .modifier(SimpleBaseBorderModifier())
                } else {
                    HStack {
                        Text("Total documents: ")
                            .foregroundStyle(.gray)
                        Text("\(labelSummaryStatistics?.totalDocuments ?? 0)")
                            .monospaced()
                        Spacer()
                    }
                    if let labelSummaryStatistics = labelSummaryStatistics {
                        DocumentSummaryLabelStatsChartView(dataLoaded: $summaryStatsAvailable, labelSummaryStatistics: labelSummaryStatistics)
                    }
                }
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .padding()
        .onAppear {
            dataTask = Task {
                do {
                    let labelStats = try await dataController.getLabelSummaryStatistics(datasetId: datasetId)
                    
                    await MainActor.run {
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
//                            summaryStatsAvailable = true
//                            labelSummaryStatistics = labelStats
//                        }
                        summaryStatsAvailable = true
                        labelSummaryStatistics = labelStats
                    }
                } catch {
                    await MainActor.run {
                        errorEncountered = true
                    }
                }
            }
        }
        .onDisappear {
            dataTask?.cancel()
        }
    }
}

