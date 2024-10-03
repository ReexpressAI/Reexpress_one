//
//  PartitionSizeSelectionView.swift
//  Alpha1
//
//  Created by A on 8/20/23.
//

import SwiftUI

struct PartitionSizeSelectionView: View {
    @EnvironmentObject var dataController: DataController
    @Binding var documentSelectionState: DocumentSelectionState
   
    @State var showSelectionError: Bool = false
    var mainFrameWidth: CGFloat = 300
    
    var body: some View {
            VStack {
                VStack {
                    HStack(alignment: .lastTextBaseline) {
                        Text("\(REConstants.CategoryDisplayLabels.sizeFull)")
                            .font(.title3)
                            .foregroundStyle(.gray)
                        Spacer()
                    }
                    .padding([.leading, .trailing])
                    VStack {
                        VStack {
                            HStack {
                                Button {
                                    documentSelectionState.resetQDFCategorySizeCharacterizations()
                                } label: {
                                    HStack(alignment: .lastTextBaseline) {
                                        Image(systemName: documentSelectionState.qDFCategorySizeCharacterizationsAllSelected() ? "square.inset.filled" : "square")
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
                        
                        List(selection: $documentSelectionState.qDFCategorySizeCharacterizations) {
                            ForEach(UncertaintyStatistics.QDFCategorySizeCharacterization.allCases, id:\.self) { category in
                                HStack(alignment: .firstTextBaseline) {
                                    Label("", systemImage: documentSelectionState.qDFCategorySizeCharacterizations.contains(category) ? "checkmark.square.fill" : "square")
                                        .font(.title2)
                                        .foregroundStyle(.blue.gradient)
                                        .labelStyle(.iconOnly)
                                    Text(UncertaintyStatistics.getQDFCategorySizeCharacterizationLabel(qDFCategorySizeCharacterization: category))
                                        .modifier(CategoryLabelViewModifier())
                                }
                                .tag(category)
                                .frame(height: 20)
                                .listRowSeparator(.hidden)
                                .listRowBackground(
                                    Rectangle()
                                        .foregroundStyle(BackgroundStyle())
                                        .opacity(documentSelectionState.qDFCategorySizeCharacterizations.contains(category) ? 1.0 : 0.0)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                )
                            }
                        }
                        .listStyle(.inset)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 105)
                    }
                    .padding()
                    .modifier(SimpleBaseBorderModifier())
                    .padding([.leading, .trailing])
                    .onChange(of: documentSelectionState.qDFCategorySizeCharacterizations) { 
                        if documentSelectionState.qDFCategorySizeCharacterizations.count == 0 {
                            documentSelectionState.resetQDFCategorySizeCharacterizations()
                            withAnimation {
                                showSelectionError = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                showSelectionError = false
                            }
                        }
                    }
                }
                .frame(width: mainFrameWidth)
                Text("At least one of the above must be selected.")
                    .italic()
                    .foregroundStyle(.gray)
                    .opacity(showSelectionError ? 1.0 : 0.0)
                Spacer()
            }
    }
}
