//
//  ModelPickerView.swift
//  Alpha1
//
//  Created by A on 7/15/23.
//

import SwiftUI

struct ModelPickerView: View {
    @EnvironmentObject var initialSetupDataController: InitialSetupDataController
    @EnvironmentObject var programModeController: ProgramModeController
    
    @State private var modelComparisonInfoPopoverShowing: Bool = false
    private var experimentalModeText: Text = 
        Text(REConstants.ExperimentalMode.experimentalModeFull)
        .font(REConstants.Fonts.baseFont.smallCaps())
        .bold()
        .foregroundStyle(.reRedGradientStart)
    private var fastModelText: Text = Text(SentencepieceConstants.getModelGroupName(modelGroup: SentencepieceConstants.ModelGroup.Fast)).monospaced().foregroundStyle(.white)
    private var fasterModelText: Text = Text(SentencepieceConstants.getModelGroupName(modelGroup: SentencepieceConstants.ModelGroup.Faster)).monospaced().foregroundStyle(.white)
    var body: some View {
        VStack {
            Group {
                if programModeController.isExperimentalMode {
                    VStack {
                        HStack(alignment: .lastTextBaseline) {
                            Text("Models \(fastModelText) and \(fasterModelText) are unavailable because \(experimentalModeText) is enabled.")
                                .font(REConstants.Fonts.baseFont)
                                .foregroundStyle(.gray)
                            PopoverViewWithButtonLocalStateOptions(popoverViewText: REConstants.ExperimentalMode.experimentalModeDisclaimer, optionalSubText: REConstants.ExperimentalMode.experimentalModeDisableDisclaimer)
                            Spacer()
                        }
                        .padding([.leading, .trailing])
                    }
                    .padding()
                }
            }
            HStack {

                Form {
                    
                    Picker(selection: $initialSetupDataController.modelGroup) {
                        if !programModeController.isExperimentalMode {
                            Text(
                                SentencepieceConstants.getModelGroupName(modelGroup: SentencepieceConstants.ModelGroup.Fast)
                            ).tag(SentencepieceConstants.ModelGroup.Fast)
                                .monospaced()
                                .modifier(CreateProjectViewControlViewModifier())
                            
                            Text(
                                SentencepieceConstants.getModelGroupName(modelGroup: SentencepieceConstants.ModelGroup.Faster)
                            ).tag(SentencepieceConstants.ModelGroup.Faster)
                                .monospaced()
                                .modifier(CreateProjectViewControlViewModifier())
                        }
                        Text(
                            SentencepieceConstants.getModelGroupName(modelGroup: SentencepieceConstants.ModelGroup.Fastest)
                        ).tag(SentencepieceConstants.ModelGroup.Fastest)
                            .monospaced()
                            .modifier(CreateProjectViewControlViewModifier())
                        
                    } label: {
                        HStack {
                            Text("Model:")
                                .modifier(CreateProjectViewControlTitlesViewModifier())
                            Button {
                                modelComparisonInfoPopoverShowing.toggle()
                            } label: {
                                Image(systemName: "info.circle.fill")
                            }
                            .popover(isPresented: $modelComparisonInfoPopoverShowing, arrowEdge: .trailing) {
                                ModelComparisonView()
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    .pickerStyle(.inline)
                }
                HStack {
                    HStack {
                        Text("Accuracy")
                        Image(systemName: "arrow.right")
                    }
                    .foregroundStyle(.green.gradient)
                    .opacity(0.8)
                    .rotationEffect(.degrees(270))
                    HStack {
                        Text("Speed")
                        Image(systemName: "arrow.right")
                    }
                    .foregroundStyle(.teal.gradient)
                    .rotationEffect(.degrees(90))
                    .offset(x: -60.0)
                }
                .padding([.bottom], 15)
                .opacity(programModeController.isExperimentalMode ? 0 : 1)
            }
        }
        .onAppear {
            if programModeController.isExperimentalMode {
                initialSetupDataController.modelGroup = SentencepieceConstants.ModelGroup.Fastest
            }
        }
    }
}

struct ModelPickerView_Previews: PreviewProvider {
    static var previews: some View {
        ModelPickerView()
    }
}
