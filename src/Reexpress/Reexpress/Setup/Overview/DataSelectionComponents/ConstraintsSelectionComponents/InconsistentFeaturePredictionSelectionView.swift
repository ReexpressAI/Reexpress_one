//
//  InconsistentFeaturePredictionSelectionView.swift
//  Alpha1
//
//  Created by A on 8/29/23.
//

import SwiftUI

struct InconsistentFeaturePredictionSelectionView: View {
    @EnvironmentObject var dataController: DataController
    @Binding var documentSelectionState: DocumentSelectionState
   
    @State var showSelectionError: Bool = false
    var mainFrameWidth: CGFloat = 350
    
    var body: some View {
            VStack {
                VStack {
                    VStack {
                        VStack {
                            HStack {
                                Button {
                                    documentSelectionState.resetInconsistentFeaturesParametersClasses()
                                } label: {
                                    HStack(alignment: .lastTextBaseline) {
                                        Image(systemName: documentSelectionState.inconsistentFeaturesParametersAllSelected() ? "square.inset.filled" : "square")
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
                        
                        List(selection: $documentSelectionState.inconsistentFeaturesParameters.featureInconsistentWithDocLevelPredictedClasses) {
                            ForEach(0..<dataController.numberOfClasses, id:\.self) { label in
                                HStack(alignment: .firstTextBaseline) {
                                    Label("", systemImage: documentSelectionState.inconsistentFeaturesParameters.featureInconsistentWithDocLevelPredictedClasses.contains(label) ? "checkmark.square.fill" : "square")
                                        .font(.title2)
                                        .foregroundStyle(.blue.gradient)
                                        .labelStyle(.iconOnly)
                                    if let labelDisplayName = dataController.labelToName[label] {
                                        Text(labelDisplayName)
                                            .font(REConstants.Fonts.baseFont)
                                    } else { // for completeness, but this case should never occur
                                        Text("\(label)")
                                            .font(REConstants.Fonts.baseFont)
                                    }
                                }
                                .tag(label)
                                .frame(height: 20)
                                .listRowSeparator(.hidden)
                                .listRowBackground(
                                    Rectangle()
                                        .foregroundStyle(BackgroundStyle())
                                        .opacity(documentSelectionState.inconsistentFeaturesParameters.featureInconsistentWithDocLevelPredictedClasses.contains(label) ? 1.0 : 0.0)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                )
                            }
                        }
                        .listStyle(.inset)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 115)
                    }
//                    .padding()
//                    .modifier(SimpleBaseBorderModifier())
                    .padding([.leading, .trailing])
                    .onChange(of: documentSelectionState.inconsistentFeaturesParameters.featureInconsistentWithDocLevelPredictedClasses) {
                        if documentSelectionState.inconsistentFeaturesParameters.featureInconsistentWithDocLevelPredictedClasses.count == 0 {
                            documentSelectionState.resetInconsistentFeaturesParametersClasses()
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
                Text("At least one predicted class must be selected.")
                    .italic()
                    .foregroundStyle(.gray)
                    .opacity(showSelectionError ? 1.0 : 0.0)
                Spacer()
            }
    }
}


