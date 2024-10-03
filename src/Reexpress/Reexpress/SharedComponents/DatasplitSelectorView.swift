//
//  DatasplitSelectorView.swift
//  Alpha1
//
//  Created by A on 7/18/23.
//

import SwiftUI

struct SingleDatasplitView: View {
    @EnvironmentObject var dataController: DataController
    var datasetId: Int
    var body: some View {
        if let dataset = dataController.inMemory_Datasets[datasetId] {
            if let datasetName = dataset.userSpecifiedName {
                Text("\(datasetName)")
            } else {
                Text("\(dataset.internalName) (\(dataset.id)")
            }
        }
    }
}

struct DatasplitSelectorView: View {
    @EnvironmentObject var dataController: DataController
    @Binding var datasetId: Int?
    var showLabelTitle: Bool = false
    
    var body: some View {
        Picker(selection: $datasetId) {
            Text("").tag(nil as Int?)
            ForEach(Array(dataController.inMemory_Datasets.keys.sorted()), id: \.self) { datasetId in
                if datasetId != REConstants.Datasets.placeholderDatasetId {
                    SingleDatasplitView(datasetId: datasetId).tag(datasetId as Int?)
                    
                    /*if let dataset = dataController.inMemory_Datasets[datasetId] {
                        if let datasetName = dataset.userSpecifiedName {
                            Text("\(datasetName)").tag(datasetId as Int?)
                        } else {
                            Text("\(dataset.internalName) (\(dataset.id)").tag(datasetId as Int?)
                        }
                    }*/
                }
            }
        } label: {
            if showLabelTitle {
                Text("Datasplit:")
                    .font(REConstants.Fonts.baseFont)
//                    .font(.title)
            }
        }
        .frame(width: 250)
        .pickerStyle(.menu)
        .onAppear {
            if datasetId == REConstants.Datasets.placeholderDatasetId {  // Must be in temporary cache as the result of a reranking. We do not want the user to transfer to cache because these get deleted periodically, so we set to nil (transfers are disallowed to nil).
                datasetId = nil
            }
        }
    }
}

struct DatasplitSelectorViewSelectionRequired: View {
    @EnvironmentObject var dataController: DataController
    @Binding var selectedDatasetId: Int
    var showLabelTitle: Bool = false
    
    var body: some View {
        Picker(selection: $selectedDatasetId) {
            ForEach(Array(dataController.inMemory_Datasets.keys.sorted()), id: \.self) { datasetId in
                if datasetId != REConstants.Datasets.placeholderDatasetId {
                    SingleDatasplitView(datasetId: datasetId).tag(datasetId as Int)
                }
            }
        } label: {
            if showLabelTitle {
                Text("Datasplit:")
                    .font(REConstants.Fonts.baseFont)
            }
        }
        .frame(width: 250)
        .pickerStyle(.menu)
    }
}

