//
//  IntrospectionMainViewGrid.swift
//  Alpha1
//
//  Created by A on 9/15/23.
//

import SwiftUI

extension IntrospectionMainViewGrid {
    @MainActor class ViewModel: ObservableObject {
        
        let displayColumnPickerFont = Font.system(size: 16)
        let displayColumnPaddingEdgeInsets = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        let displayColumnPickerMenuWidth: CGFloat = 250
        
        let gridColumnMinWidth: CGFloat = 750  // also needs to be set consistently in init of the state var columns
        let gridColumnSpacing: CGFloat = 5  // also needs to be set consistently in init of the state var columns
        
    }
}

extension IntrospectionMainViewGrid {
    func updateGraphCoordinator(documentSelectionState: DocumentSelectionState?) throws {
        if let documentSelectionState = documentSelectionState, let uncertaintyStatistics = dataController.uncertaintyStatistics {
            let datasetId = documentSelectionState.datasetId
            if documentSelectionState.semanticSearchParameters.search || documentSelectionState.semanticSearchParameters.rerankParameters.reranking {
//                notAvailableMessage = "To graph the results of a semantic search, first save the results to a datasplit"
//                graphState = .notAvailable
                throw UncertaintyErrors.graphingError
            } else {
                    // clear existing:
                    dataController.uncertaintyStatistics?.uncertaintyGraphCoordinator?.datasetId_To_inMemoryDataCoordinator[datasetId] = nil
                    do {
                        let uStatsDataPoints = try  dataController.getDataPointsForDatasetFromDatabaseAsUncertaintyStatisticsDatapoints(documentSelectionState: documentSelectionState, uncertaintyStatistics: uncertaintyStatistics, moc: moc)

                            if uStatsDataPoints.count == 0 {
                                throw UncertaintyErrors.graphingError
//                                notAvailableMessage = REConstants.Compare.noDocumentsAvailable
//                                graphState = .notAvailable
                            } else {
                                
                                let inMemoryDataCoordinator = UncertaintyStatistics.DatasetUncertaintyCoordinator(datasetId: datasetId, documentIdsToDataPoints: uStatsDataPoints, requiredDataPointId: nil, validKnownLabelsMinD0: uncertaintyStatistics.validKnownLabelsMinD0, validKnownLabelsMaxD0: uncertaintyStatistics.validKnownLabelsMaxD0, numberOfClasses: dataController.numberOfClasses, qdfCategory_To_CalibratedOutput: uncertaintyStatistics.vennADMITCategory_To_CalibratedOutput)
                                
                                if var uncertaintyGraphCoordinator = uncertaintyStatistics.uncertaintyGraphCoordinator {
                                    uncertaintyGraphCoordinator.datasetId_To_inMemoryDataCoordinator[datasetId] = inMemoryDataCoordinator
                                    dataController.uncertaintyStatistics?.uncertaintyGraphCoordinator = uncertaintyGraphCoordinator
                                } else {
                                    var uncertaintyGraphCoordinator = UncertaintyStatistics.UncertaintyGraphCoordinator()
                                    uncertaintyGraphCoordinator.datasetId_To_inMemoryDataCoordinator[datasetId] = inMemoryDataCoordinator
                                    dataController.uncertaintyStatistics?.uncertaintyGraphCoordinator = uncertaintyGraphCoordinator
                                }
//                                dataLoaded = true
//                                graphState = .displayed
                            }
                    } catch {
                        throw UncertaintyErrors.graphingError
//                        await MainActor.run {
//                            notAvailableMessage = REConstants.Compare.noDocumentsAvailable
//                            graphState = .notAvailable
//                        }
                    }
            }
        } else {
            throw UncertaintyErrors.graphingError
//            notAvailableMessage = REConstants.Compare.noDocumentsAvailable
//            graphState = .notAvailable
        }
    }
}

struct IntrospectionMainViewGrid: View {
    @EnvironmentObject var dataController: DataController
    @Environment(\.managedObjectContext) var moc
    
    @Binding var loadedDatasets: Bool
    
    @StateObject var viewModel = ViewModel()
    
    @State var dataSelectionPopoverShowing: Bool = false
    @State var documentSelectionState_proposal: DocumentSelectionState
    @State private var shouldCalllInitiateRetrieval: Bool = false
    @State private var initiateFullRetrieval: Bool? = false
    
    //    @State var showUncertaintyGraphLeft: Bool = true
    //    @State var showUncertaintyGraphRight: Bool = true
    
    //@State private var showUncertaintyGraph: Bool = false
    
    @State var comparisonDatasetId: Int?
    @State var primaryDatasetId: Int?
    
    @State var primaryDocumentSelectionState: DocumentSelectionState?
    @State var comparisonDocumentSelectionState: DocumentSelectionState?
    
    // .flexibile is used here, as we want the view to fill all space if possible. When an additional dataset is shown, we explicitly add another GridItem by modifying this array.
    @State var columns: [GridItem] =
    [GridItem(.flexible(minimum: 750, maximum: .infinity), spacing: 5)]
    
    //@State var showLeftColumn: Bool = false
    
    //@State var userDidScroll: Bool = false
    
    @State var alignAxes: Bool = false
    @State var existingXRange: ClosedRange<Float32>? = nil
    
    //@State var primaryDataLoaded: Bool = false
    @State var primaryGraphState: GraphState = .graphing
    //@State var comparisonDataLoaded: Bool = false
    @State var comparisonGraphState: GraphState = .graphing
    
    @AppStorage(REConstants.UserDefaults.showingGraphViewSummaryStatisticsStringKey) var showingGraphViewSummaryStatistics: Bool = REConstants.UserDefaults.showingGraphViewSummaryStatisticsStringKeyDefault
    
    init(numberOfClasses: Int, loadedDatasets: Binding<Bool>) {
        _loadedDatasets = loadedDatasets
        _documentSelectionState_proposal = State(initialValue: DocumentSelectionState(numberOfClasses: numberOfClasses))
    }
    
    func isValidComparisonDatasetId(comparisonDatasetId: Int) -> Bool {
        guard let primaryDatasetId = dataController.documentSelectionState_CompareGraph?.datasetId else {
            return false
        }
        return comparisonDatasetId != REConstants.Datasets.placeholderDatasetId && comparisonDatasetId != primaryDatasetId
    }
    
    func updateColumns(bothColumnsAvailable: Bool) {
        if bothColumnsAvailable {
            //withAnimation {
                columns = [GridItem(.flexible(minimum: viewModel.gridColumnMinWidth, maximum: .infinity), spacing: viewModel.gridColumnSpacing),
                           GridItem(.flexible(minimum: viewModel.gridColumnMinWidth, maximum: .infinity), spacing: viewModel.gridColumnSpacing)]
            //}
        } else {
            columns = [GridItem(.flexible(minimum: viewModel.gridColumnMinWidth, maximum: .infinity), spacing: viewModel.gridColumnSpacing)]
        }
    }
    var body: some View {
        VStack {
            if loadedDatasets {
                
                VStack {
                    Grid {
                        GridRow {
                            Grid(alignment: .center, verticalSpacing: 0) {
                                GridRow {
                                    HStack {
                                        Button {
                                            dataSelectionPopoverShowing.toggle()
                                        } label: {
                                            UncertaintyGraphControlButtonLabelWithCaptionVStack(buttonImageName: "square.on.square.squareshape.controlhandles", buttonTextCaption: REConstants.MenuNames.selectName) //Partition")
                                        }
                                        .buttonStyle(.borderless)
                                        if let documentSelectionState = dataController.documentSelectionState_CompareGraph {
                                            Text("Datasplit: ")
                                                .font(REConstants.Fonts.baseFont)
                                                .foregroundStyle(.gray)
                                                .lineLimit(1)
                                            
                                            SingleDatasplitView(datasetId: documentSelectionState.datasetId)
                                                .font(REConstants.Fonts.baseFont)
                                                .monospaced()
                                                .lineLimit(1)
                                        } else {
                                            Text("Click **\(REConstants.MenuNames.selectName)** to change the current selection.")
                                                .font(REConstants.Fonts.baseFont)
                                                .italic()
                                        }
                                        Spacer()
                                    }
                                }
                            }
                            .gridColumnAlignment(.trailing)
                            Grid(alignment: .center, verticalSpacing: 0) {
                                GridRow {
                                    HStack {
                                        if dataController.documentSelectionState_CompareGraph != nil {
                                            Text("Comparison Datasplit: ")
                                                .font(REConstants.Fonts.baseFont)
                                                //.bold()
                                                .foregroundStyle(REConstants.REColors.reLabelBeige)
                                                .opacity(0.75)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.75)
                                                .help("Comparison Datasplit")
                                            
                                            Picker(selection: $comparisonDatasetId) {
                                                Text("Not displayed").tag(nil as Int?)
                                                ForEach(Array(dataController.inMemory_Datasets.keys.sorted()), id: \.self) { datasetId in
                                                    if isValidComparisonDatasetId(comparisonDatasetId: datasetId) {
                                                        SingleDatasplitView(datasetId: datasetId).tag(datasetId as Int?)
                                                    }
                                                }
                                            } label: {
                                                Text("")
                                            }
                                            .frame(width: 250)
                                            .pickerStyle(.menu)
                                        } else {
                                            Text("")
                                                .font(REConstants.Fonts.baseFont)
                                                .italic()
                                        }
                                        Spacer()
                                    }
                                }
                            }
                            .gridColumnAlignment(.trailing)
                            
                            Grid(alignment: .center, verticalSpacing: 0) {
                                GridRow {
                                    Picker(selection: $showingGraphViewSummaryStatistics) {
                                        Text(REConstants.Compare.graphViewMenu).tag(true)
                                        Text(REConstants.Compare.overviewViewMenu).tag(false)
                                    } label: {
                                        Text("")
                                    }
                                    .pickerStyle(.segmented)
                                    .font(REConstants.Fonts.baseFont)
                                    .frame(width: 250)
                                }
                            }
                            
                            Grid(alignment: .center, verticalSpacing: 0) {
                                GridRow {
                                    HStack(alignment: .lastTextBaseline) {
                                        
                                            Button {
                                                if comparisonGraphState == .displayed {
                                                    alignAxes.toggle()
                                                }
                                            } label: {
                                                UncertaintyGraphControlButtonLabelWithCaptionVStack(buttonImageName: "align.horizontal.center", buttonTextCaption: "Align x-axes", buttonFrameWidth: 80)
                                            }
                                            .buttonStyle(.borderless)
                                            .opacity((comparisonDatasetId != nil && existingXRange == nil && showingGraphViewSummaryStatistics) ? 1.0 : 0.25)
                                            .disabled(comparisonDatasetId == nil || existingXRange != nil || !showingGraphViewSummaryStatistics)
                                        HelpAssistanceView_Compare_Graph()
                                    }
                                    .gridColumnAlignment(.trailing)
                                }
                            }
                        }
                    }
                }
                .padding()
                .modifier(SimpleBaseBorderModifier(useShadow: true))
                .padding([.leading, .trailing, .top])

                .onAppear {
                    Task {
                        await MainActor.run {
                            if let documentSelectionState = dataController.documentSelectionState_CompareGraph {
                                documentSelectionState_proposal = documentSelectionState
                                primaryDocumentSelectionState = documentSelectionState
                                primaryDatasetId = documentSelectionState.datasetId
                                if let existingComparisonDatasetId = dataController.comparisonDatasetId_CompareGraph {
                                    comparisonDocumentSelectionState = documentSelectionState
                                    comparisonDocumentSelectionState?.datasetId = existingComparisonDatasetId
                                    comparisonDatasetId = existingComparisonDatasetId
                                }
                            }
                            do {
                                try updateGraphCoordinator(documentSelectionState: primaryDocumentSelectionState)
                                primaryGraphState = .displayed
                            } catch {
                                primaryGraphState = .notAvailable
                            }
                        }
                    }
                    
                }
                .onChange(of: comparisonDatasetId) {
                    comparisonGraphState = .graphing
                    updateColumns(bothColumnsAvailable: comparisonDatasetId != nil)
                    existingXRange = nil
                    Task {
                        await MainActor.run {
                            if let documentSelectionState = dataController.documentSelectionState_CompareGraph, let comparisonDatasetId = comparisonDatasetId {
                                
                                //if let comparisonDatasetId = comparisonDatasetId {
                                    comparisonGraphState = .graphing
                                    comparisonDocumentSelectionState = documentSelectionState
                                    comparisonDocumentSelectionState?.datasetId = comparisonDatasetId
                                    dataController.comparisonDatasetId_CompareGraph = comparisonDatasetId
                                    do {
                                        try updateGraphCoordinator(documentSelectionState: comparisonDocumentSelectionState)
                                        //withAnimation {
                                            comparisonGraphState = .displayed
                                        //}
                                    } catch {
                                        comparisonGraphState = .notAvailable
                                    }
                                //updateColumns(bothColumnsAvailable: true)
                            } else {
                                comparisonGraphState = .notAvailable
                                updateColumns(bothColumnsAvailable: false)
                            }
                            
                        }
                    }
                }
                .onChange(of: shouldCalllInitiateRetrieval) { oldValue, newValue in

                    if let shouldRetrieve = initiateFullRetrieval, shouldRetrieve && newValue {
                        Task {
                            await MainActor.run {
                                dataController.documentSelectionState_CompareGraph = documentSelectionState_proposal
                                primaryDocumentSelectionState = documentSelectionState_proposal
                                
                                primaryDatasetId = documentSelectionState_proposal.datasetId
                                do {
                                    try updateGraphCoordinator(documentSelectionState: primaryDocumentSelectionState)
                                    primaryGraphState = .displayed
                                } catch {
                                    primaryGraphState = .notAvailable
                                }
                                
                                existingXRange = nil
                                comparisonDocumentSelectionState = nil
                                comparisonDatasetId = nil
                                
                                initiateFullRetrieval = nil
                                shouldCalllInitiateRetrieval = false
                            }
                        }
                    }
                    // always need to set to false, since on clicking 'Cancel' in a Selection, the above block will not be called. If the following line is ommitted, this would then mean that a new Selection could never be initiated after a Cancel. A similar approach is used in Explore.
                    shouldCalllInitiateRetrieval = false

                }
                .onChange(of: alignAxes) { oldValue, newValue in
                    if newValue, let primaryDatasetId = primaryDocumentSelectionState?.datasetId, let comparisonDatasetId = comparisonDocumentSelectionState?.datasetId, let primaryXRange =                        dataController.uncertaintyStatistics?.uncertaintyGraphCoordinator?.datasetId_To_inMemoryDataCoordinator[primaryDatasetId]?.getXRange(), let combinedXRange = dataController.uncertaintyStatistics?.uncertaintyGraphCoordinator?.datasetId_To_inMemoryDataCoordinator[comparisonDatasetId]?.getXRange(existingXRange: primaryXRange) {
                        // update axes
                        existingXRange = combinedXRange
                        
                        alignAxes = false
                    }
                }
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 5) {
                        IntrospectView(datasetId: $primaryDatasetId, searchViewModel: viewModel, graphState: $primaryGraphState, existingXRange: $existingXRange, isComparisonDatasplit: false)
                    
                        if columns.count > 1 {
                            IntrospectView(datasetId: $comparisonDatasetId, searchViewModel: viewModel, graphState: $comparisonGraphState, existingXRange: $existingXRange, isComparisonDatasplit: true)
                        }
                    }
                }
                //.coordinateSpace(name: "scroll")
                .scrollBounceBehavior(.basedOnSize)
                .onDisappear {
                    dataController.uncertaintyStatistics?.uncertaintyGraphCoordinator = nil
                }
                .sheet(isPresented: $dataSelectionPopoverShowing,
                       onDismiss: {
                    shouldCalllInitiateRetrieval = true
                }) {
                    DataSelectionView(documentSelectionState: $documentSelectionState_proposal, initiateFullRetrieval: $initiateFullRetrieval, disableSemanticSearch: true, disableSortOptions: true)
                        .padding()
                        .frame(idealHeight: 1000, maxHeight: .infinity)
                }
            }
        }
    }
}

