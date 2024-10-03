//
//  TrainingDataPointPopoverView.swift
//  Alpha1
//
//  Created by A on 7/22/23.
//

import SwiftUI

struct TrainingDataPointPopoverView: View {
    var selectedElement: TrainingDataPointType?
    var metricStringName: String = "Loss"
    
    var body: some View {
        VStack(alignment: .leading) {
            if let selectedElement = selectedElement {
                HStack {
                    Text("Split:")
                        .foregroundStyle(.secondary)
                    
                    Text("\(selectedElement.id)")
                        .foregroundColor(TrainingProcessDataStorage.getColorForDataSet(id: selectedElement.id))
                }
                Text("Epoch: \(selectedElement.epoch)")
                    .foregroundStyle(.secondary)
                HStack {
                    Text("\(metricStringName):")
                        .font(.title2.bold())
                        .foregroundStyle(.secondary)
                    Text("\(selectedElement.value)")
                        .font(.title2.bold())
                        .foregroundColor(TrainingProcessDataStorage.getColorForDataSet(id: selectedElement.id))
                }
            }
        }
        .padding()
        .frame(width: (metricStringName.count <= "Loss".count) ? 200 : 325)
    }
}
