//
//  ModelComparisonView.swift
//  Alpha1
//
//  Created by A on 7/14/23.
//

import SwiftUI

struct ModelComparisonView: View {
    let m1MaxText = "M1 Max (32 GPU cores) 64 GB"
    let m2Ultra76GPUCoresText = "M2 Ultra (76 GPU cores) 128 GB"
    @State private var showingModelLicenseView: Bool = false
    var body: some View {
        VStack {
            Grid(horizontalSpacing: 50, verticalSpacing: 5) {
                GridRow {
                    Text("Mac")
                        .foregroundStyle(.gray)
                        .gridColumnAlignment(.leading)
                    Text("Model")
                        .foregroundStyle(.gray)
                        .gridColumnAlignment(.leading)
                    Text("Documents / Minute")
                        .foregroundStyle(.gray)
                        .gridColumnAlignment(.leading)
                }
                GridRow {
                    Divider()
                        .gridCellColumns(3)
                        .gridCellUnsizedAxes([.horizontal, .vertical])
                }
                Group {
                    GridRow {
                        Text("")
                        Text("")
                            .monospaced()
                        Text("")
                    }
                    
                    GridRow {
                        Text(m1MaxText)
                        Text(SentencepieceConstants.getModelGroupName(modelGroup: SentencepieceConstants.ModelGroup.Fast))
                            .monospaced()
                        Text("200")
                    }
                    GridRow {
                        Text(m2Ultra76GPUCoresText)
                        Text(SentencepieceConstants.getModelGroupName(modelGroup: SentencepieceConstants.ModelGroup.Fast))
                            .monospaced()
                        Text("400")
                    }
                }
                Group {
                    GridRow {
                        Text("")
                        Text("")
                            .monospaced()
                        Text("")
                    }
                    
                    GridRow {
                        Text(m1MaxText)
                        Text(SentencepieceConstants.getModelGroupName(modelGroup: SentencepieceConstants.ModelGroup.Faster))
                            .monospaced()
                        Text("500")
                    }
                    GridRow {
                        Text(m2Ultra76GPUCoresText)
                        Text(SentencepieceConstants.getModelGroupName(modelGroup: SentencepieceConstants.ModelGroup.Faster))
                            .monospaced()
                        Text("770")
                    }
                }
                Group {
                    GridRow {
                        Text("")
                        Text("")
                            .monospaced()
                        Text("")
                    }
                    
                    GridRow {
                        Text(m1MaxText)
                        Text(SentencepieceConstants.getModelGroupName(modelGroup: SentencepieceConstants.ModelGroup.Fastest))
                            .monospaced()
                        Text("860")
                    }
                    GridRow {
                        Text(m2Ultra76GPUCoresText)
                        Text(SentencepieceConstants.getModelGroupName(modelGroup: SentencepieceConstants.ModelGroup.Fastest))
                            .monospaced()
                        Text("1110")
                    }
                }
            }
            .padding()
            Text("Estimates, based on document prediction for binary classification. (Prediction \(Text("includes").underline()) calculating feature importance and estimating calibrated probabilities, which itself involves a dense vector matching step, here against a Training set of around 3000 documents.) Speed can vary considerably depending on operating conditions, such as the number of currently running programs. Before processing large datasets, we recommend restarting your Mac and closing all other running programs, keeping \(REConstants.ProgramIdentifiers.mainProgramName) running in the foreground.")
                .italic()
                .padding()
            Text("The models incorporate a subset of weights from Flan-T5 (xl, large, and base) and mT0-base, combined with additional layers and parameters. License information for the original weights is available \(Text("here").foregroundStyle(.blue).underline()).")
                .italic()
                .padding()
                .onTapGesture {
                    showingModelLicenseView = true
                }
        }
        .frame(width: 600)
        .popover(isPresented: $showingModelLicenseView, content: {
            ModelLicenseView()
        })
    }
}
