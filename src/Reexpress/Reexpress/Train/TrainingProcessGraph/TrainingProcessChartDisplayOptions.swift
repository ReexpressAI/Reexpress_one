//
//  TrainingProcessChartDisplayOptions.swift
//  Alpha1
//
//  Created by A on 7/22/23.
//

import SwiftUI

struct TrainingProcessChartDisplayOptions: View {
    var metricStringName: String = "Loss"
    @Binding var showBestTrainingLine: Bool
    @Binding var showBestValidationLine: Bool
    
    var body: some View {
        VStack {
            HStack {
                Text("Display options")
                    .font(.title3.bold())
                Spacer()
            }
            
            Grid {
                GridRow {
                    Text("Show best \(TrainingProcessDataStorage.Constants.trainingSetIdString) \(metricStringName)")
                        .foregroundStyle(.gray)
                        .gridColumnAlignment(.trailing)
                    TrainingProcessLine()
                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [5, 10]))
                        .frame(width: 100, height: 1)
                        .foregroundStyle(
                            TrainingProcessDataStorage.getColorForDataSet(id: TrainingProcessDataStorage.Constants.trainingSetIdString)
                        )
                        .padding()
                        .gridColumnAlignment(.leading)
                    Toggle(isOn: $showBestTrainingLine.animation()) {
                    }
                    .toggleStyle(.switch)
                    .gridColumnAlignment(.leading)
                }
                GridRow {
                    Text("Show best \(TrainingProcessDataStorage.Constants.validationSetIdString) \(metricStringName)")
                        .foregroundStyle(.gray)
                    TrainingProcessLine()
                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [5, 10]))
                        .frame(width: 100, height: 1)
                        .foregroundStyle(
                            TrainingProcessDataStorage.getColorForDataSet(id: TrainingProcessDataStorage.Constants.validationSetIdString)
                        )
                        .padding()
                    Toggle(isOn: $showBestValidationLine.animation()) {
                    }
                    .toggleStyle(.switch)
                }
            }
            .padding()
            .modifier(SimpleBaseBorderModifier())
        }
        .frame(maxWidth: 600)
        .padding()
    }
}

struct TrainingProcessChartDisplayOptions_Previews: PreviewProvider {
    static var previews: some View {
        TrainingProcessChartDisplayOptions(showBestTrainingLine: .constant(false), showBestValidationLine: .constant(false))
    }
}
