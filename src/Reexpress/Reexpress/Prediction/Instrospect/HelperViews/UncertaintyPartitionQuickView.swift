//
//  UncertaintyPartitionQuickView.swift
//  Alpha1
//
//  Created by A on 5/8/23.
//

import SwiftUI

struct UncertaintyPartitionQuickView: View {
    //@State private var selectionSizeInfoPopoverShowing: Bool = false
    //@State private var sampleSizeInfoPopoverShowing: Bool = false
    
    //var sampleSizeSummary: (datasetSize: Int, selectionSize: Int, sampleSize: Int)?
    var sampleSizeSummary: (selectionSize: Int, currentViewPopulation: Int, sampleSize: Int)?
    var datasetSize: Int?
    
    var body: some View {
        Grid(alignment: .leadingFirstTextBaseline, verticalSpacing: 5) {
            GridRow {
                Color.clear
                    .gridCellUnsizedAxes([.horizontal, .vertical])
                Text("Documents")
                    .foregroundColor(.secondary)
                    .gridColumnAlignment(.center)
            }
            GridRow {
                Text("Datasplit total:")
                    .foregroundColor(.secondary)
                    .gridColumnAlignment(.trailing)
                if let datasetSize = datasetSize {
                    Text("\(datasetSize)")
                } else {
                    Text("")
                }
            }
            GridRow {
                HStack {
                    Text(REConstants.CategoryDisplayLabels.currentSelectionLabel+":")
                        .foregroundColor(.secondary)
                    PopoverViewWithButtonLocalStateOptionsLocalizedString(popoverViewText: "The documents in the *\(REConstants.CategoryDisplayLabels.currentSelectionLabel)* are determined via the options in **\(REConstants.MenuNames.selectName)**.", optionalSubText: "The **\(REConstants.Compare.overviewViewMenu)** charts (accessible via the toggle above) display summary statistics for all of the documents in the *\(REConstants.CategoryDisplayLabels.currentSelectionLabel)*. In contrast, the charts displayed here reflect the documents currently displayed in the graph, which may be a subset of the *\(REConstants.CategoryDisplayLabels.currentSelectionLabel)* due to zooming, or due to sampling to efficiently render the points in the graph.")
                }
                if let sampleSizeSummary = sampleSizeSummary {
                    Text("\(sampleSizeSummary.selectionSize)")
                } else {
                    Text("")
                }

            }
            GridRow {
                HStack {
                    Text(REConstants.CategoryDisplayLabels.currentViewLabel+":")
                        .foregroundColor(.secondary)
                    PopoverViewWithButtonLocalStateOptionsLocalizedString(popoverViewText: "The documents in the *\(REConstants.CategoryDisplayLabels.currentViewLabel)* differ from those in the *\(REConstants.CategoryDisplayLabels.currentSelectionLabel)* if the zoom level has changed.")
                }
                if let sampleSizeSummary = sampleSizeSummary {
                    Text("\(sampleSizeSummary.currentViewPopulation)")
                } else {
                    Text("")
                }
            }
            GridRow {
                HStack {
                    Text(REConstants.CategoryDisplayLabels.currentViewSampleLabel+":")
//                        .foregroundColor(.secondary)
                        .foregroundStyle(REConstants.Visualization.compareView_SampleIndicator)

                        PopoverViewWithButtonLocalStateOptionsLocalizedString(popoverViewText: "When more than \(REConstants.Uncertainty.defaultDisplaySampleSize) documents are in the *\(REConstants.CategoryDisplayLabels.currentViewLabel)*, a sample of documents is shown in the graph, with the dotted white lines indicating the min and max distances present in the population of the *\(REConstants.CategoryDisplayLabels.currentViewLabel)*. Zoom or re-sample to see additional documents.")
                }
                if let sampleSizeSummary = sampleSizeSummary, sampleSizeSummary.currentViewPopulation != sampleSizeSummary.sampleSize {
                    Text("\(sampleSizeSummary.sampleSize)")
                } else {
                    Text("N/A")
                }
            }
        }
        .font(.system(size: 14))
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

struct UncertaintyPartitionQuickView_Previews: PreviewProvider {
    static var previews: some View {
        UncertaintyPartitionQuickView()
    }
}
