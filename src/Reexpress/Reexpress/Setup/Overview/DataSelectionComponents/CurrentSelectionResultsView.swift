//
//  CurrentSelectionResultsView.swift
//  Alpha1
//
//  Created by A on 8/16/23.
//

import SwiftUI

struct CurrentSelectionResultsView: View {
    @State private var isShowingInfoPopover: Bool = false
    var body: some View {
        HStack {
            Divider()
                .frame(width: 2, height: 25)
                .overlay(.gray)
            Grid {
                GridRow {
                    Text("Documents currently displayed meeting the selected criteria:")
                        .gridColumnAlignment(.trailing)
                        .foregroundStyle(.gray)
                        .font(REConstants.Fonts.baseFont)
                    Text("N/A")
                        .gridColumnAlignment(.leading)
                        .monospaced()
                        .font(REConstants.Fonts.baseFont)
                        .foregroundStyle(.orange)
                        .opacity(0.75)
                    PopoverViewWithButton(isShowingInfoPopover: $isShowingInfoPopover, popoverViewText: "The count may not be current if one or more documents were deleted from this Datasplit after the most recent selection.")
                        .gridColumnAlignment(.leading)
                }
            }
        }
    }
}
struct CurrentSelectionResultsView_Previews: PreviewProvider {
    static var previews: some View {
        CurrentSelectionResultsView()
    }
}
