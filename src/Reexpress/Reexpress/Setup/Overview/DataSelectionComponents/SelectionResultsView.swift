//
//  SelectionResultsView.swift
//  Alpha1
//
//  Created by A on 8/16/23.
//

import SwiftUI

struct SelectionResultsView: View {
    var body: some View {
        Grid {
            GridRow {
                Text("Documents currently displayed meeting the selected criteria:")
                    .gridColumnAlignment(.trailing)
                    .foregroundStyle(.gray)
                    .font(REConstants.Fonts.baseFont)
                Text("0")
                    .gridColumnAlignment(.leading)
                    .monospaced()
                    .font(REConstants.Fonts.baseFont)
                    .foregroundStyle(.orange)
                    .opacity(0.75)
            }
        }
    }
}

struct SelectionResultsView_Previews: PreviewProvider {
    static var previews: some View {
        SelectionResultsView()
    }
}
