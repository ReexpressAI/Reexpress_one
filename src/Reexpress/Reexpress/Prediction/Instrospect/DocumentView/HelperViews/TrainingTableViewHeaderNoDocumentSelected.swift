//
//  TrainingTableViewHeaderNoDocumentSelected.swift
//  Alpha1
//
//  Created by A on 6/15/23.
//

import SwiftUI

struct TrainingTableViewHeaderNoDocumentSelected: View {
    @EnvironmentObject var dataController: DataController
    @Binding var currentlySelectedSupportDatasetId: Int
    var comparisonMode: Bool = false  // true if the user can choose another datasplit other than training
    var datasetId: Int
    var supportDatasetId: Int
    let displayColumnPickerMenuWidth: CGFloat
    
    var body: some View {
        if comparisonMode {
            VStack(alignment: .leading) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Nearest")
                        .font(.title2)
                    Picker(selection: $currentlySelectedSupportDatasetId.animation()) {
                        ForEach(Array(dataController.inMemory_Datasets.keys.sorted()), id: \.self) { datasetId in
                            /* disallow training for two reasons:
                             1. We pre-cache training as used for uncertainty.
                             2. Matching to other sets does not play a role in uncertainty, so we separate such auxilliary matching to other tables to make clear.
                             */
                            if (datasetId != REConstants.DatasetsEnum.train.rawValue) && (datasetId != REConstants.Datasets.placeholderDatasetId) {
                                Text("\(dataController.getDatasplitNameForDisplay(datasetId: datasetId))")
                                    .tag(datasetId)
                            }
                        }
                    } label: {
                    }
                    .frame(width: displayColumnPickerMenuWidth)
                    Text("  documents")
                        .font(.title2)
                }
                ZStack {
                    Text("First, select a")
                    +
                    Text(" \(dataController.getDatasplitNameForDisplay(datasetId: datasetId))")
                        .font(.title2.lowercaseSmallCaps())
                    +
                    Text(" document above in the \(Image(systemName: "tablecells")) Documents Table or \(Image(systemName: "chart.dots.scatter")) Graph.")
                }
                .foregroundStyle(.secondary)
            }
            .padding(.bottom, 10)
        } else {
            VStack(alignment: .leading) {
                Text("Nearest ")
                    .font(.title2)
                +
                Text("\(dataController.getDatasplitNameForDisplay(datasetId: supportDatasetId))")
                    .font(.title2.lowercaseSmallCaps())
                +
                Text(" documents")
                    .font(.title2)
                ZStack {
                    Text("First, select a")
                    +
                    Text(" \(dataController.getDatasplitNameForDisplay(datasetId: datasetId))")
                        .font(.title2.lowercaseSmallCaps())
                    +
                    Text(" document above in the \(Image(systemName: "tablecells")) Documents Table or \(Image(systemName: "chart.dots.scatter")) Graph.")
                }
                .foregroundStyle(.secondary)
            }
            .padding(.bottom, 10)
        }
    }
}

//struct TrainingTableViewNoDocumentSelected_Previews: PreviewProvider {
//    static var previews: some View {
//        TrainingTableViewNoDocumentSelected()
//    }
//}
