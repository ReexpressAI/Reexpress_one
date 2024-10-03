//
//  SortingSelectionSortAscendingView.swift
//  Alpha1
//
//  Created by A on 8/18/23.
//

import SwiftUI

struct SortingSelectionSortAscendingView: View {
    @EnvironmentObject var dataController: DataController
    @Binding var documentSelectionState: DocumentSelectionState
    
    var mainFrameWidth: CGFloat = 300
    var mainListHeight: CGFloat = 220+25
    
    var body: some View {
        Grid(alignment: .leadingFirstTextBaseline) {
            GridRow {
                Text("Ascending or descending:")
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
//                                    Text(sortField)
                                        .font(REConstants.Fonts.baseFont)
                                    Spacer()
                                    HStack {
                                        if let sortAscending = documentSelectionState.sortParameters.sortFieldToIsAscending[sortField], sortAscending {
                                            Text("\(Image(systemName: "arrow.up"))")
                                                .foregroundStyle(.blue.gradient)
                                            Text("Ascending")
                                                .font(.title3.smallCaps())
                                                .foregroundStyle(.blue)
                                        } else {
                                            Text("\(Image(systemName: "arrow.down"))")
                                                .foregroundStyle(.blue.gradient)
                                            Text("Descending")
                                                .font(.title3.smallCaps())
                                                .foregroundStyle(.blue)
                                        }
                                    }
                                }
                                .tag(sortField)
                                .listRowSeparator(.hidden)
                                .frame(width: 220, height: 20)
                                .onTapGesture {
                                    documentSelectionState.sortParameters.updatedSortFieldOrderDictionary(sortField: sortField)
                                }
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

