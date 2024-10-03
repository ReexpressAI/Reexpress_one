//
//  HelpAssistanceView_Compare_Graph.swift
//  Alpha1
//
//  Created by A on 9/15/23.
//

import SwiftUI

struct HelpAssistanceView_Compare_Graph_Content: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        Text("Compare ")
                            .bold()
                            .foregroundStyle(REConstants.REColors.reLabelBeige)
                            .opacity(0.75)
                        Text("the distribution of a ")
                        Text("selection ")
                            .bold()
                            .foregroundStyle(.gray)
                        Text("across datasplits.")
                        Spacer()
                    }
                }
                .padding()
                
                HStack {
                    Spacer()
                    Grid(alignment: .top, horizontalSpacing: 20, verticalSpacing: 20) {
                        GridRow {
                            Text("Graph:")
                                .gridColumnAlignment(.trailing)
                            VStack(alignment: .leading) {
                                Text("Drag to zoom. Click to focus.")
                                    .monospaced()
                                    .italic()
                                    .foregroundStyle(.gray)
                                Text("Hover for \(REConstants.CategoryDisplayLabels.qdfPartitionLabel_TextStruct) partition membership.")
                                    .monospaced()
                                    .italic()
                                    .foregroundStyle(.gray)
                            }
                            .gridColumnAlignment(.leading)
                        }
                        GridRow {
                            Text("Charts:")
                            Text("Hover for details.")
                                .monospaced()
                                .italic()
                                .foregroundStyle(.gray)
                        }
                    }
                    Spacer()
                }
                .padding([.leading, .trailing, .bottom])
                
                VStack(alignment: .leading) {
                    Text("The documents in the *\(REConstants.CategoryDisplayLabels.currentSelectionLabel)* for the chosen **Datasplit** are determined via the options in **\(REConstants.MenuNames.selectName)**. Optionally, these same selection criteria can be applied to a **Comparison Datasplit**. When graphs for two datasplits are shown, click **Align x-axes** to redraw the graphs with a shared x-axis range." )
                }
                .foregroundStyle(.gray)
                .padding([.leading, .trailing, .bottom])
                
                VStack(alignment: .leading) {
                    Text("To review summary statistics for all of the documents in the *\(REConstants.CategoryDisplayLabels.currentSelectionLabel)*, switch the toggle to **\(REConstants.Compare.overviewViewMenu)**.")
                }
                .foregroundStyle(.gray)
                .padding([.leading, .trailing, .bottom])
                
                VStack(alignment: .leading) {
                    Text("When the toggle is set to **\(REConstants.Compare.graphViewMenu)**, the charts reflect the documents currently displayed in the graph. For graphing, we make distinctions among the following three sets of documents:")
                    Grid(alignment: .top, horizontalSpacing: 20, verticalSpacing: 20) {
                        GridRow {
                            Text("*\(REConstants.CategoryDisplayLabels.currentSelectionLabel)*")
                                .gridColumnAlignment(.trailing)
                            Text("As noted above, these are all documents that meet the selection criteria choosen in **\(REConstants.MenuNames.selectName)**.")
                                .gridColumnAlignment(.leading)
                        }
                        GridRow {
                            Text("*\(REConstants.CategoryDisplayLabels.currentViewLabel)*")
                            Text("The subset of *\(REConstants.CategoryDisplayLabels.currentSelectionLabel)* contained in the current zoom level. *\(REConstants.CategoryDisplayLabels.currentSelectionLabel)* and *\(REConstants.CategoryDisplayLabels.currentViewLabel)* are the same if zooming has not occurred. This is the population of documents considered for graphing.")
                        }
                        GridRow {
                            Text("*\(REConstants.CategoryDisplayLabels.currentViewSampleLabel)*")
                            Text("When more than \(REConstants.Uncertainty.defaultDisplaySampleSize) documents are in the *\(REConstants.CategoryDisplayLabels.currentViewLabel)*, this random sample of documents from the *\(REConstants.CategoryDisplayLabels.currentViewLabel)* is shown in the graph.")
                        }
                    }
                    .padding()
                    Text("When a sample of documents is being shown in the graph, the following dotted white lines indicate the min and max distances present in the population of the *\(REConstants.CategoryDisplayLabels.currentViewLabel)*:")
                    HStack {
                        Spacer()
                        Grid {
                            GridRow {
                                Text("Min/max points' distance")
                                    .foregroundStyle(.gray)
                                    .gridColumnAlignment(.trailing)
                                TrainingProcessLine()
                                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [2, 3]))
                                    .frame(width: 100, height: 1)
                                    .foregroundStyle(
                                        REConstants.Visualization.minMaxDistanceInSmapleLineColor
                                    )
                                    .gridColumnAlignment(.leading)
                            }
                        }
                        .font(Font.system(size: 14))
                        .padding()
                        .modifier(SimpleBaseBorderModifier())
                        Spacer()
                    }
                    .padding([.leading, .trailing, .bottom])
                    Text("Zoom (by dragging in the graph), or re-sample by clicking \(Image(systemName: "dice")), to see additional documents.")
                        .padding([.leading, .trailing])
                }
                .foregroundStyle(.gray)
                .padding([.leading, .trailing, .bottom])
                VStack(alignment: .leading) {
                    Text("Hovering over a point in the graph highlights points from the same \(REConstants.CategoryDisplayLabels.qdfPartitionLabel_TextStruct) partition. All such points share the same calibrated probability. If viewable given the current zoom, the following values for the partition are shown for reference:")
                    HStack {
                        Spacer()
                        Grid {
                            GridRow {
                                Text(REConstants.CategoryDisplayLabels.fFull + " threshold")
                                    .foregroundStyle(.gray)
                                    .gridColumnAlignment(.trailing)
                                TrainingProcessLine()
                                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [5, 10]))
                                    .frame(width: 100, height: 1)
                                    .foregroundStyle(
                                        REConstants.Visualization.compositionThresholdLineColor
                                    )
                                    .padding()
                                    .gridColumnAlignment(.leading)
                            }
                            GridRow {
                                Text("Median true-positive distance")
                                    .foregroundStyle(.gray)
                                TrainingProcessLine()
                                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [5, 10]))
                                    .frame(width: 100, height: 1)
                                    .foregroundStyle(
                                        REConstants.Visualization.medianDistanceLineD0Color
                                    )
                                    .padding()
                            }
                            GridRow {
                                Text("OOD limit distance")
                                    .foregroundStyle(.gray)
                                TrainingProcessLine()
                                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [2, 4]))
                                    .frame(width: 100, height: 1)
                                    .foregroundStyle(
                                        REConstants.Visualization.oodDistanceLineD0Color
                                    )
                                    .padding()
                            }
                        }
                        .font(Font.system(size: 14))
                        .padding()
                        .modifier(SimpleBaseBorderModifier())
                        Spacer()
                    }
                    Text("*Tip*: On initial load when opening a project, there may be a slight delay until hovering over a chart is enabled to display additional information. If the delay persists, you can manually refresh by clicking on another tab (e.g., **Data**) and then returning to **Compare**.")
                    .padding([.top, .leading, .trailing])
                    
                }
                .foregroundStyle(.gray)
                .padding([.leading, .trailing, .bottom])
                
            }
            .fixedSize(horizontal: false, vertical: true)  // This will cause Text() to wrap.
            .font(REConstants.Fonts.baseFont)
            .padding()
            .frame(width: 600)
        }
        .scrollBounceBehavior(.basedOnSize)
        .frame(idealHeight: 600)
    }
}

struct HelpAssistanceView_Compare_Graph: View {
    @State private var showingHelpAssistanceView: Bool = false
    var body: some View {
        Button {
            showingHelpAssistanceView.toggle()
        } label: {
            UncertaintyGraphControlButtonLabelWithCaptionVStack(buttonImageName: "questionmark.circle", buttonTextCaption: "Help", buttonForegroundStyle: AnyShapeStyle(Color.gray.gradient))
        }
        .buttonStyle(.borderless)
        .popover(isPresented: $showingHelpAssistanceView) {
            HelpAssistanceView_Compare_Graph_Content()
        }
    }
}
