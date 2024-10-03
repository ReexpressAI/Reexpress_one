//
//  SetupMainForwardAfterTrainingView.swift
//  Alpha1
//
//  Created by A on 7/26/23.
//

import SwiftUI


//extension SetupMainForwardAfterTrainingView {
//    @MainActor class ViewModel: ObservableObject {
//        @Published var inferenceDatasetIds: Set<Int> = Set<Int>([REConstants.DatasetsEnum.train.rawValue, REConstants.DatasetsEnum.calibration.rawValue])
//        var allAvailableDatasetIds: Set<Int> = Set<Int>()
//    }
//}


struct SetupMainForwardAfterTrainingView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var dataController: DataController
    
    //@StateObject var viewModel: ViewModel = ViewModel()
    
    @Binding var inferenceDatasetIds: Set<Int>
    var datasetId: Int = 0
    
    @State var allAvailableDatasetIds: Set<Int> = Set<Int>()
    
    //@State var dataPredictionTask: Task<Void, Error>?
    @State var isShowingRequiredDatasetInfo: Bool = false
    
    @State var selectAll: Bool = false
    var hideTitle: Bool = false
    
    var body: some View {
        VStack {
            if !hideTitle {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Predict")
                            .font(.title2.bold())
                        Text("Run this step to predict labels for the selected documents using the trained model.")
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
            }
            
            HStack {
                Text("Required")
                    .font(.title3)
                    .foregroundStyle(.orange)
                    .opacity(0.85)
                PopoverViewWithButton(isShowingInfoPopover: $isShowingRequiredDatasetInfo, popoverViewText: "Predictions must be up-to-date on both the Training set and the Calibration set before making predictions on additional datasplits.", arrowEdge: .trailing)
                Spacer()
            }
            List {
                ForEach([REConstants.DatasetsEnum.train.rawValue, REConstants.DatasetsEnum.calibration.rawValue], id: \.self) { datasetId in
                    if let dataset = dataController.inMemory_Datasets[datasetId], (dataset.count ?? 0) > 0 {
                        HStack(alignment: .firstTextBaseline) {
                            Label("", systemImage: "checkmark.square.fill")
                                .font(.title2)
                                .foregroundStyle(.orange.gradient)
                                .opacity(0.85)
                                .labelStyle(.iconOnly)
                            
                            if let datasetName = dataset.userSpecifiedName {
                                Text("\(datasetName)")
                                    .font(REConstants.Fonts.baseFont)
                            } else {
                                Text("\(dataset.internalName) (\(dataset.id)")
                                    .font(REConstants.Fonts.baseFont)
                            }
                        }
                        .listRowSeparator(.hidden)
                    }
                }
            }
            .frame(height: 75)
            .padding()
            
            .modifier(SimpleBaseBorderModifier())
            
            
            HStack {
                Text("Available datasplits")
                    .font(.title3)
                    .foregroundStyle(.gray)
                Spacer()
            }
            VStack {
                List {
                    if allAvailableDatasetIds.count > 2 {
                        VStack(alignment: .leading) {
                            HStack(alignment: .firstTextBaseline) {
                                Label("", systemImage: selectAll ? "checkmark.square.fill" : "square")
                                    .font(.title2)
                                    .foregroundStyle(Color.blue.gradient)
                                    .labelStyle(.iconOnly)
                                    .onTapGesture {
                                        if selectAll {
                                            inferenceDatasetIds = Set<Int>([REConstants.DatasetsEnum.train.rawValue, REConstants.DatasetsEnum.calibration.rawValue])
                                            selectAll = false
                                        } else {
                                            inferenceDatasetIds = Set(allAvailableDatasetIds)
                                            selectAll = true
                                        }
                                    }
                                
                                Text("Select All")
                                    .font(REConstants.Fonts.baseFont)
                                    .foregroundStyle(.gray)
                                    .italic()
                                
                            }
                            .listRowSeparator(.hidden)
                            Divider()
                        }
                    }
                    ForEach(Array(dataController.inMemory_Datasets.keys.sorted()), id: \.self) { datasetId in
                        if datasetId != REConstants.Datasets.placeholderDatasetId && datasetId != REConstants.DatasetsEnum.train.rawValue && datasetId != REConstants.DatasetsEnum.calibration.rawValue {
                            if let dataset = dataController.inMemory_Datasets[datasetId], (dataset.count ?? 0) > 0 {
                                HStack(alignment: .firstTextBaseline) {
                                    Label("", systemImage: inferenceDatasetIds.contains(datasetId) ? "checkmark.square.fill" : "square")
                                        .font(.title2)
                                        .foregroundStyle(.blue.gradient)
                                        .labelStyle(.iconOnly)
                                        .onTapGesture {
                                            if inferenceDatasetIds.contains(datasetId) {
                                                inferenceDatasetIds.remove(datasetId)
                                            } else {
                                                inferenceDatasetIds.insert(datasetId)
                                            }
                                            // This just maintains consistency with the Select All option (i.e., if the user manually selects all options, we update the indicator).
                                            if inferenceDatasetIds == allAvailableDatasetIds {
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
                                .listRowSeparator(.hidden)
                            }
                        }
                    }
                }
            }
            
            .padding()
            .modifier(SimpleBaseBorderModifier())
        }
        
        .padding()

        .onAppear {
            // initial dataset:
            if let dataset = dataController.inMemory_Datasets[datasetId], (dataset.count ?? 0) > 0 {
                inferenceDatasetIds.insert(datasetId)
            }
            
            // all available datasets (for fast comparisons)
            for datasetId in Array(dataController.inMemory_Datasets.keys) {
                if datasetId != REConstants.Datasets.placeholderDatasetId, let dataset = dataController.inMemory_Datasets[datasetId], (dataset.count ?? 0) > 0 {
                    allAvailableDatasetIds.insert(datasetId)
                }
            }
        }
    }
}
