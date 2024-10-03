//
//  KeywordSelectionView.swift
//  Alpha1
//
//  Created by A on 8/16/23.
//

import SwiftUI

struct KeywordSelectionView: View {
    
    @EnvironmentObject var dataController: DataController
    @Binding var documentSelectionState: DocumentSelectionState
    
    var body: some View {
        
        VStack {
            VStack(alignment: .leading) {
                Text("Keyword search options")
                    .font(.title2.bold())
                Divider()
                    .padding(.bottom)
            }
            .padding([.leading, .trailing])
            
            HStack {
                Toggle(isOn: $documentSelectionState.searchParameters.search) {
                    Text("Keyword search")
                }
                .toggleStyle(.switch)
                Spacer()
            }
            .padding([.leading, .trailing, .top])
            /*HStack {
                Picker("", selection: $documentSelectionState.searchParameters.search) {
                    Text("No search").tag(false)
                    Text("Keyword search").tag(true)
                }
                .pickerStyle(.radioGroup)
                Spacer()
            }
            .padding([.leading, .trailing, .top])*/
            VStack(alignment: .center) {
                Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 10, verticalSpacing: 10) {
                    GridRow {
                        Text("Datasplit to search:")
                            .font(.title3)
                            .foregroundStyle(.gray)
                            .gridCellAnchor(.leading)
                        SingleDatasplitView(datasetId: documentSelectionState.datasetId)
                            .monospaced()
                            .gridCellAnchor(.leading)
                    }
                    GridRow {
                        Text("Search text:")
                            .font(.title3)
                            .foregroundStyle(.gray)
                            .gridCellColumns(2)
                    }
                    GridRow {
                        Color.clear
                            .gridCellUnsizedAxes([.vertical, .horizontal])
                        VStack {
                            TextEditor(text:  $documentSelectionState.searchParameters.searchText)
                            //                            .lineLimit(2)
                                .font(REConstants.Fonts.baseFont)
                                .monospaced(true)
                                .frame(width: 400, height: 25)
                                .foregroundColor(.white)
                                .scrollContentBackground(.hidden)
                                .opacity(0.75)
                                .padding()
                                .background {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(
                                            REConstants.REColors.reBackgroundDarker)
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(.gray)
                                        .opacity(0.5)
                                }
                            Text("\(REConstants.KeywordSearch.maxAllowedCharacters - documentSelectionState.searchParameters.searchText.count) characters remaining")
                                .italic()
                                .font(REConstants.Fonts.baseSubheadlineFont)
                        }
                        .onChange(of: documentSelectionState.searchParameters.searchText) {
                            if documentSelectionState.searchParameters.searchText.count > REConstants.KeywordSearch.maxAllowedCharacters {
                                documentSelectionState.searchParameters.searchText = String(documentSelectionState.searchParameters.searchText.prefix(REConstants.KeywordSearch.maxAllowedCharacters))
                            }
                        }
                    }
                    
                    GridRow {
                        Text("Field to search:")
                            .font(.title3)
                            .foregroundStyle(.gray)
                            .gridCellColumns(2)
                    }
                    GridRow {
                        Color.clear
                            .gridCellUnsizedAxes([.vertical, .horizontal])
                        VStack {
                            Picker(selection: $documentSelectionState.searchParameters.searchField) {
                                Text("prompt").tag("prompt")
                                Text("document").tag("document")
                                Text("group").tag("group")
                                Text("info").tag("info")
                                Text("id").tag("id")
                            } label: {
                            }
                            .pickerStyle(.radioGroup)
                        }
                    }
                    GridRow {
                        Text("Additional options:")
                            .font(.title3)
                            .foregroundStyle(.gray)
                            .gridCellColumns(2)
                    }
                    GridRow {
                        Color.clear
                            .gridCellUnsizedAxes([.vertical, .horizontal])
                        Picker(selection: $documentSelectionState.searchParameters.caseSensitiveSearch) {
                            Text("Match case").tag(true)
                            Text("Ignore case").tag(false)
                        } label: {
                        }
                        .pickerStyle(.radioGroup)
                    }
                }
                Spacer()
            }
            .disabled(!documentSelectionState.searchParameters.search)
            .opacity(!documentSelectionState.searchParameters.search ? 0.25 : 1.0)
            
        }
        .frame(height: 595)
        .font(REConstants.Fonts.baseFont)
        .padding()
        .modifier(SimpleBaseBorderModifier())
        .padding()
    }
    
}
