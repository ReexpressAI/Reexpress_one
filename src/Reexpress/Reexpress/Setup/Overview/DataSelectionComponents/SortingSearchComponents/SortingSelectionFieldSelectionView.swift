//
//  SortingSelectionFieldSelectionView.swift
//  Alpha1
//
//  Created by A on 8/18/23.
//

import SwiftUI

struct SortingSelectionFieldSelectionView: View {
    @EnvironmentObject var dataController: DataController
    @Binding var documentSelectionState: DocumentSelectionState
    @State private var showSelectionError: Bool = false
    var mainFrameWidth: CGFloat = 300
    var mainListHeight: CGFloat = 220+25
    
    var body: some View {
        VStack {
            VStack {
                VStack {
                    VStack {
                        HStack {
                            Button {
                                documentSelectionState.sortParameters.selectAllSortFields()
                            } label: {
                                HStack(alignment: .lastTextBaseline) {
                                    Image(systemName: documentSelectionState.sortParameters.sortFieldsAllSelected() ? "square.inset.filled" : "square")
                                        .foregroundStyle(.blue.gradient)
                                    Text("Select All")
                                }
                                .italic()
                                .font(REConstants.Fonts.baseFont.smallCaps())
                            }
                            .buttonStyle(.borderless)
                            PopoverViewWithButtonLocalState(popoverViewText: REConstants.HelpAssistanceInfo.selectionInfoString)
                            Spacer()
                        }
                        .padding([.leading, .trailing])
                        Divider()
                    }
                    .offset(CGSize(width: 0, height: 10))
                    
                    List(selection: $documentSelectionState.sortParameters.sortFields) {
                        ForEach(documentSelectionState.sortParameters.availableSortFields, id:\.self) { sortField in
                            HStack(alignment: .firstTextBaseline) {
                                Label("", systemImage: documentSelectionState.sortParameters.sortFields.contains(sortField) ? "checkmark.square.fill" : "square")
                                    .font(.title2)
                                    .foregroundStyle(.blue.gradient)
                                    .labelStyle(.iconOnly)
                                Text(sortField == REConstants.CategoryDisplayLabels.qVar ? "\(REConstants.CategoryDisplayLabels.qShort)".lowercased() : sortField)
                                //Text(sortField)
                                    .font(REConstants.Fonts.baseFont)
                            }
                            .tag(sortField)
                            .frame(height: 20)
                            .listRowSeparator(.hidden)
                            .listRowBackground(
                                Rectangle()
                                    .foregroundStyle(BackgroundStyle())
                                    .opacity(documentSelectionState.sortParameters.sortFields.contains(sortField) ? 1.0 : 0.0)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            )
                        }
                    }
                    .listStyle(.inset)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: mainListHeight)
                }

                .padding([.leading, .trailing])
                .onChange(of: documentSelectionState.sortParameters.sortFields) {
                    if documentSelectionState.sortParameters.sortFields.count == 0 {
                        documentSelectionState.sortParameters = SortParameters()
                        withAnimation {
                            showSelectionError = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            showSelectionError = false
                        }
                    } else {
                        documentSelectionState.sortParameters.updateSortFieldSelection()
                    }
                }
            }
            .frame(width: mainFrameWidth)
            Text("At least one field must be selected.")
                .italic()
                .foregroundStyle(.gray)
                .opacity(showSelectionError ? 1.0 : 0.0)
            Spacer()
        }
    }
}


