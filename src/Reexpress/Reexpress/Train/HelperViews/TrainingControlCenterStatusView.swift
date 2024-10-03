//
//  TrainingControlCenterStatusView.swift
//  Alpha1
//
//  Created by A on 6/24/23.
//

import SwiftUI

struct TrainingControlCenterStatusView: View {
    var isKeyModel: Bool = true
    var highlightColor: Color {
        if isKeyModel {
            return REConstants.REColors.trainingHighlightColor
        } else {
            return REConstants.REColors.indexTrainingHighlightColor
        }
    }
    
    @EnvironmentObject var dataController: DataController
    @State private var isShowingMetricInfoPopover: Bool = false

    var body: some View {
        Grid(alignment: .leadingFirstTextBaseline, verticalSpacing: 5) {
            GridRow {
                Text("Training Status:")
                    .foregroundColor(.secondary)
                    .gridColumnAlignment(.trailing)
                Text("\(dataController.inMemory_KeyModelGlobalControl.getTrainingStateString())")
                    .gridColumnAlignment(.leading)
            }
            if let _ = dataController.inMemory_KeyModelGlobalControl.modelWeights {
                GridRow(alignment: .firstTextBaseline) {
                    Text("Last trained:")
                        .foregroundColor(.secondary)
                    if let date = dataController.inMemory_KeyModelGlobalControl.trainingTimestampLastModified {
                        Text(date, formatter: dataController.inMemory_KeyModelGlobalControl.dateFormatter)
                    } else {
                        Text("Unavailable")
                    }
                }
                GridRow(alignment: .firstTextBaseline) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Highest Calibration set \(dataController.inMemory_KeyModelGlobalControl.trainingMaxMetric.description):")
                            .foregroundColor(.secondary)
                        Button {
                            isShowingMetricInfoPopover.toggle()
                        } label: {
                            Image(systemName: "info.circle.fill")
                        }
                        .buttonStyle(.borderless)
                    }
                    Text("\(dataController.inMemory_KeyModelGlobalControl.trainingCurrentMaxMetric)")
                        .monospaced()
                        .foregroundStyle(highlightColor)
                        .opacity(0.75)
                        .popover(isPresented: $isShowingMetricInfoPopover, arrowEdge: .trailing) {
                            PopoverView(popoverViewText: "This is the highest Calibration set value seen during training and determined the epoch of the final model weights. (\(REConstants.Uncertainty.balancedAccuracyDescription))")
                        }
                }
                GridRow(alignment: .firstTextBaseline) {
                    Text("Training loss:")
                        .foregroundColor(.secondary)
                    Text("\(dataController.inMemory_KeyModelGlobalControl.trainingMinLoss)")
                        .monospaced()
                }
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill( //.black)
                    AnyShapeStyle(BackgroundStyle()))
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.gray)
                .opacity(0.5)
        }
    }
}

struct TrainingControlCenterStatusView_Previews: PreviewProvider {
    static var previews: some View {
        TrainingControlCenterStatusView()
    }
}
