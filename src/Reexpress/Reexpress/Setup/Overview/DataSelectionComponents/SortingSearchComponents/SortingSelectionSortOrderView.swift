//
//  SortingSelectionSortOrderView.swift
//  Alpha1
//
//  Created by A on 8/18/23.
//

import SwiftUI

struct SortingSelectionSortOrderView: View {
    @EnvironmentObject var dataController: DataController
    @Binding var documentSelectionState: DocumentSelectionState
    
    var mainFrameWidth: CGFloat = 300
    var mainListHeight: CGFloat = 220+25
    
    var body: some View {

            Grid(alignment: .leadingFirstTextBaseline) {
                GridRow {
                    HStack {
                        Text("Field application order:")
                        PopoverViewWithButtonLocalState(popoverViewText: "Drag to determine the order in which the sort for each field is applied. Sorting will be applied in turn for each field by the order of appearance in this list (serially top-to-bottom).")
                        Spacer()
                    }
                        .gridCellColumns(3)
                        .gridCellAnchor(.leading)
                }
                GridRow {
                    Color.clear
                        .gridCellUnsizedAxes([.vertical, .horizontal])
                    VStack {
                        VStack {
                            List {
                                ForEach(documentSelectionState.sortParameters.orderedSortFields, id: \.self) { sortField in
                                    HStack {
                                        Text(sortField == REConstants.CategoryDisplayLabels.qVar ? "\(REConstants.CategoryDisplayLabels.qShort)".lowercased() : sortField)
//                                        Text(sortField)
                                            .font(REConstants.Fonts.baseFont)
                                        Spacer()
                                        Text("\(Image(systemName: "line.3.horizontal"))")
                                    }
                                    .tag(sortField)
                                    .listRowSeparator(.hidden)
                                    .frame(width: 200, height: 20)
                                }
                                .onMove { from, to in
                                    documentSelectionState.sortParameters.orderedSortFields.move(fromOffsets: from, toOffset: to)
                                }
                            }
                            .listStyle(.inset)
                            .frame(minHeight: mainListHeight)
                        }
                        .padding([.leading, .trailing])
                    }
                    .frame(width: mainFrameWidth)
                    Color.clear
                        .gridCellUnsizedAxes([.vertical, .horizontal])
                }
            }
    }
}

