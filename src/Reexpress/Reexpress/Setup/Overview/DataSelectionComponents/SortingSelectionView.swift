//
//  SortingSelectionView.swift
//  Alpha1
//
//  Created by A on 8/16/23.
//

import SwiftUI

struct SortingSelectionView: View {
    @EnvironmentObject var dataController: DataController
    @Binding var documentSelectionState: DocumentSelectionState
    
    var mainFrameWidth: CGFloat = 300
    
    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                Text("Sort order of returned results")
                    .font(.title2.bold())
                Text("By default results are ordered by document ID. Optionally, choose the sort fields and order. (Adding additional fields may slow result retrieval.)")
                    .font(REConstants.Fonts.baseSubheadlineFont)
                    .foregroundStyle(.gray)
                Divider()
                    .padding(.bottom)
            }
            .padding([.leading, .trailing])
            VStack(alignment: .center) {
                Grid(alignment: .leadingFirstTextBaseline) {
                    GridRow {
                        Text("Order the selection results using the following fields:")
                            .gridCellColumns(3)
                            .gridCellAnchor(.leading)
                    }
                    GridRow {
                        Color.clear
                            .gridCellUnsizedAxes([.vertical, .horizontal])
                        SortingSelectionFieldSelectionView(documentSelectionState: $documentSelectionState)
                        Color.clear
                            .gridCellUnsizedAxes([.vertical, .horizontal])
                    }
                }
                
                HStack {
                    if documentSelectionState.sortParameters.orderedSortFields.count > 0 {
                        Spacer()
                        SortingSelectionSortOrderView(documentSelectionState: $documentSelectionState)
                        SortingSelectionSortAscendingView(documentSelectionState: $documentSelectionState)
                        Spacer()
                    }
                }
            }
            .padding([.leading, .trailing]) //, .bottom])
        }
        .font(REConstants.Fonts.baseFont)
        .padding()
        .modifier(SimpleBaseBorderModifier())
        .padding()
    }
}

