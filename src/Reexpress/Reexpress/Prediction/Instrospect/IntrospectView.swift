//
//  IntrospectView.swift
//  Alpha1
//
//  Created by A on 4/24/23.
//

import SwiftUI
import Accelerate
import Charts



extension IntrospectView {
    @MainActor class ViewModel: ObservableObject {
        //        @Published var showUncertaintyGraph: Bool = true
        // For controls
        let buttonDividerHeight: CGFloat = 40
        let buttonFrameWidth: CGFloat = 70
        let buttonFrameHeight: CGFloat = 40
        let buttonPadding = EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5)
        
    }
}

enum GraphState: Int, CaseIterable {
    case graphing = 0
    case notAvailable = 1
    case displayed = 2
}

struct IntrospectView: View {
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var dataController: DataController
    
    @Binding var datasetId: Int?
    //@Binding var userDidScroll: Bool
    @ObservedObject var searchViewModel: IntrospectionMainViewGrid.ViewModel
    //@Binding var dataLoaded: Bool
    @Binding var graphState: GraphState
    @Binding var existingXRange: ClosedRange<Float32>?
    
    var isComparisonDatasplit: Bool = false
    
    @StateObject var viewModel = ViewModel()
    
    @State var expandGraphToFill = false
    @State var notAvailableMessage: String = REConstants.Compare.noDocumentsAvailable
    

    
    var body: some View {
        ScrollView {
            ZStack {
                GeneratingGraphView()
                    .opacity(graphState != .notAvailable ? 1.0 : 0.0)
                VStack {
                    if graphState == .notAvailable {
                        VStack {
                            Text(.init(notAvailableMessage))
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(REConstants.REColors.reBackgroundDarker)
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(.gray)
                                .opacity(0.5)
                        }
                        .padding()
                    } else if graphState == .displayed {
                        if let datasetId = datasetId, let _ = dataController.uncertaintyStatistics?.uncertaintyGraphCoordinator?.datasetId_To_inMemoryDataCoordinator[datasetId] {
                                UncertaintyChart(datasetId: datasetId, graphState: $graphState, searchViewModel: searchViewModel, existingXRange: $existingXRange, isComparisonDatasplit: isComparisonDatasplit)
                                    .padding(EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20))
                        }
                    }
                }
            }
            .modifier(IntrospectViewPrimaryComponentsViewModifier(useShadow: true))
        }
        .scrollBounceBehavior(.basedOnSize)
        /*.onChange(of: showUncertaintyGraph, initial: true) { oldValue, newValue in
            //.onAppear {
            dataLoaded = false
            //            let localDocumentSelectionState = dataController.documentSelectionState_CompareGraph
            print("task is running")
            if newValue, let datasetId = datasetId, var documentSelectionState = localDocumentSelectionState, let uncertaintyStatistics = dataController.uncertaintyStatistics {
                documentSelectionState.datasetId = datasetId
                // This has the effect of re-loading any existing selection when returning from another view.
                //documentSelectionState_proposal = documentSelectionState
                if documentSelectionState.semanticSearchParameters.search || documentSelectionState.semanticSearchParameters.rerankParameters.reranking {
                    notAvailableMessage = "To graph the results of a semantic search, first save the results to a datasplit"
                    graphState = .notAvailable
                } else {
                    Task {
                        do {
                            let uStatsDataPoints = try await dataController.getDataPointsForDatasetFromDatabaseAsUncertaintyStatisticsDatapoints(documentSelectionState: documentSelectionState, uncertaintyStatistics: uncertaintyStatistics, moc: moc)
                            await MainActor.run {
                                if uStatsDataPoints.count == 0 {
                                    notAvailableMessage = REConstants.Compare.noDocumentsAvailable
                                    graphState = .notAvailable
                                } else {
                                    
                                    let inMemoryDataCoordinator = UncertaintyStatistics.DatasetUncertaintyCoordinator(datasetId: datasetId, documentIdsToDataPoints: uStatsDataPoints, requiredDataPointId: nil, validKnownLabelsMinD0: uncertaintyStatistics.validKnownLabelsMinD0, validKnownLabelsMaxD0: uncertaintyStatistics.validKnownLabelsMaxD0)
                                    
                                    if var uncertaintyGraphCoordinator = uncertaintyStatistics.uncertaintyGraphCoordinator {
                                        uncertaintyGraphCoordinator.datasetId_To_inMemoryDataCoordinator[datasetId] = inMemoryDataCoordinator
                                        dataController.uncertaintyStatistics?.uncertaintyGraphCoordinator = uncertaintyGraphCoordinator
                                    } else {
                                        var uncertaintyGraphCoordinator = UncertaintyStatistics.UncertaintyGraphCoordinator()
                                        uncertaintyGraphCoordinator.datasetId_To_inMemoryDataCoordinator[datasetId] = inMemoryDataCoordinator
                                        dataController.uncertaintyStatistics?.uncertaintyGraphCoordinator = uncertaintyGraphCoordinator
                                    }
                                    dataLoaded = true
                                    graphState = .displayed
                                }
                            }
                        } catch {
                            await MainActor.run {
                                notAvailableMessage = REConstants.Compare.noDocumentsAvailable
                                graphState = .notAvailable
                            }
                        }
                    }
                }
            } else {
                notAvailableMessage = REConstants.Compare.noDocumentsAvailable
                graphState = .notAvailable
            }
        }*/
    }
}






