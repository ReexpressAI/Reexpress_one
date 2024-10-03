//
//  GlobalStatusView.swift
//  Alpha1
//
//  Created by A on 4/27/23.
//

import SwiftUI

struct GlobalStatusView: View {
    @EnvironmentObject var dataController: DataController
    @Binding var loadedDatasets: Bool
    
    @EnvironmentObject var programModeController: ProgramModeController
    
    //    let gradient = LinearGradient(
    //        colors: [.yellow, .orange], //[.blue, .green],
    //        startPoint: .leading,
    //        endPoint: .trailing
    //    )
    @State private var isShowingUncertaintyStatusExplainer: Bool = false
    var body: some View {
        
        VStack {
            if loadedDatasets {
                HStack {
                    Text("Overview")
                        .font(.title)
                        .foregroundStyle(.gray)
                        .padding([.leading, .trailing])
                    Spacer()
                    Button {
                        if let projectDirectoryURL = dataController.projectURL {
                            NSWorkspace.shared.activateFileViewerSelecting([projectDirectoryURL])
                        }
                    } label: {
                        UncertaintyGraphControlButtonLabelWithCaptionVStack(buttonImageName: "filemenu.and.cursorarrow", buttonTextCaption: "Finder")
                    }
                    .buttonStyle(.borderless)
                    .disabled(dataController.projectURL == nil)
                    .padding([.leading]) //, .trailing])
                }
                .padding([.leading, .trailing])
                
                //ScrollView {
                VStack {
                    HStack(alignment: .lastTextBaseline) {
                        Text("Model")
                            .font(REConstants.Fonts.baseFont)
                            .foregroundStyle(.gray)
                        Spacer()
                    }
                    .padding([.leading, .trailing])
                    HStack(alignment: .top) {
                        Text("\(SentencepieceConstants.getModelGroupName(modelGroup: dataController.modelGroup))")
                            .font(REConstants.Fonts.baseFont)
                            .monospaced()
                        Spacer()
                    }
                    .padding()
                    .modifier(SimpleBaseBorderModifier())
                    .padding([.leading, .trailing])
                }
                .padding([.leading, .trailing])
                
                
                VStack {
                    HStack(alignment: .lastTextBaseline) {
                        Text("Task")
                            .font(REConstants.Fonts.baseFont)
                            .foregroundStyle(.gray)
                        Spacer()
                    }
                    .padding([.leading, .trailing])
                    HStack(alignment: .top) {
                        Text("\(dataController.modelTaskType.stringValue(numberOfClasses: dataController.numberOfClasses))")
                        //                    Text("\(dataController.numberOfClasses)")
                            .font(REConstants.Fonts.baseFont)
                            .monospaced()
                        Spacer()
                    }
                    .padding()
                    .modifier(SimpleBaseBorderModifier())
                    .padding([.leading, .trailing])
                }
                .padding([.leading, .trailing])
                
                VStack {
                    HStack(alignment: .lastTextBaseline) {
                        Text("Status")
                            .font(REConstants.Fonts.baseFont)
                            .foregroundStyle(.gray)
                        Spacer()
                    }
                    .padding([.leading, .trailing])
                    HStack {
                        
                        Grid(verticalSpacing: 5) {
                            GridRow {
                                Text("Primary Model Status:")
                                    .foregroundColor(.secondary)
                                    .gridColumnAlignment(.trailing)
                                Text("\(dataController.inMemory_KeyModelGlobalControl.getTrainingStateString())")
                                    .gridColumnAlignment(.leading)
                            }
                            GridRow {
                                Text("Model Compression Status:")
                                    .foregroundColor(.secondary)
                                Text("\(dataController.inMemory_KeyModelGlobalControl.getIndexStateString())")
                            }
                            
                            GridRow {
                                Text("Uncertainty Estimates:")
                                    .foregroundColor(.secondary)
                                VStack {
                                    if dataController.isUncertaintyModelCurrent() {
                                        HStack {
                                            Text("Ready for inference.")
                                            PopoverViewWithButton(isShowingInfoPopover: $isShowingUncertaintyStatusExplainer, popoverViewText: "Estimates are up-to-date on the Training and Calibration Sets.", optionalSubText: "(Up-to-date probability estimates will be generated when running the prediction step on any existing or new datasplits.)")
                                                .font(REConstants.Fonts.baseFont)
                                        }
                                    } else {
                                        if dataController.uncertaintyStatistics != nil {
                                            Text("Needs refresh (data changed). Re-run prediction.")
                                        } else {
                                            Text("Unavailable. Run prediction.")
                                        }
                                    }
                                }
                            }
                        }
                        .font(REConstants.Fonts.baseFont)
                        
                        
                        
                        Spacer()
                    }
                    .padding()
                    .modifier(SimpleBaseBorderModifier())
                    .padding([.leading, .trailing])
                }
                .padding([.leading, .trailing])
                
                //}
                
                
                Group {
                    //Spacer()
                    HStack {
                        Text("Default prompt")
                            .font(.title3)
                            .foregroundStyle(.gray)
                        Spacer()
                    }
                    .padding([.leading, .trailing])
                    
                    ScrollView {
                        let defaultPrompt = dataController.defaultPrompt
                        
                        if !defaultPrompt.isEmpty {
                            VStack(alignment: .leading) {
                                Text(defaultPrompt)
                                    .textSelection(.enabled)
                                    .monospaced()
                                    .font(REConstants.Fonts.baseFont)
                                    .lineSpacing(12.0)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                            }
                        } else {
                            Text("")
                        }
                    }
                    .frame(minHeight: 50, maxHeight: 60) //.infinity)
                    .padding()
                    .modifier(PrimaryComponentsViewModifier(useReBackgroundDarker: true, viewBoxScaling: 8))
                    .padding([.leading, .trailing])
                }
                .padding([.leading, .trailing]) //, .bottom])
                
                Group {
                    if programModeController.isExperimentalMode {
                        VStack {
                            HStack(alignment: .lastTextBaseline) {
                                Text(REConstants.ExperimentalMode.experimentalModeFull)
                                    .font(REConstants.Fonts.baseFont.smallCaps())
                                    .bold()
                                    .foregroundStyle(.reRedGradientStart) //.foregroundStyle(REConstants.REColors.sphereGradient_Yellow)
                                Text("is enabled.")
                                    .font(REConstants.Fonts.baseFont)
                                PopoverViewWithButtonLocalStateOptions(popoverViewText: REConstants.ExperimentalMode.experimentalModeDisclaimer, optionalSubText: REConstants.ExperimentalMode.experimentalModeDisableDisclaimer)
                                Spacer()
                            }
                            .padding([.leading, .trailing])
                        }
                        .padding([.top, .leading, .trailing])
                    }
                }
                
            } else {
                HStack(alignment: .lastTextBaseline) {
                    Spacer()
                    Text("An unexpected error was encountered when attempting to open the project file. Please close and restart **\(REConstants.ProgramIdentifiers.mainProgramName)**, and then re-open the project file from within **\(REConstants.ProgramIdentifiers.mainProgramName)**.")
                        .font(REConstants.Fonts.baseFont)
                        .foregroundStyle(.gray)
                    Spacer()
                }
                .padding([.leading, .trailing, .top])
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .padding([.top, .bottom])
        .padding(EdgeInsets(top: 0, leading: 0, bottom: 20, trailing: 0))
        .modifier(SimpleBaseBorderModifier())
        .padding()
    }
}

