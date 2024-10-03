//
//  ConstraintsSelectionView.swift
//  Alpha1
//
//  Created by A on 8/16/23.
//

import SwiftUI

struct ConstraintsSelectionView: View {
    @EnvironmentObject var dataController: DataController
    @Binding var documentSelectionState: DocumentSelectionState
       
    let labelConstraintChoiceFrameWidth: CGFloat = 200

    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                Text("Additional display constraints")
                    .font(.title2.bold())
                Text("These constraints are independent of the chosen partition(s).")
                    .font(REConstants.Fonts.baseSubheadlineFont)
                    .foregroundStyle(.gray)
                Divider()
                    .padding(.bottom)
                HStack {
                    Spacer()
                    Grid(alignment: .leadingFirstTextBaseline) {
                        GridRow {
                            Text("For documents with known labels, show:")
                                .gridCellColumns(3)
                                .gridCellAnchor(.leading)
                        }
                        GridRow {
                            Color.clear
                                .gridCellUnsizedAxes([.vertical, .horizontal])
                            Picker(selection: $documentSelectionState.currentLabelConstraint) {
//                                ForEach(UncertaintyStatistics.DatasetUncertaintyCoordinator.LabelConstraint.allCases, id:\.self) { labelConstraint in
                                ForEach(DocumentSelectionState.LabelConstraint.allCases, id:\.self) { labelConstraint in
                                    switch labelConstraint {
                                    case .allPoints:
                                        VStack {
                                            HStack {
                                                Image(systemName: "circle.fill")
                                                    .foregroundStyle(.red.gradient)
                                                Image(systemName: "circle.fill")
                                                    .foregroundStyle(.green.gradient)
                                            }
                                            Text("All predictions")
                                                .foregroundStyle(.secondary)
                                        }
                                        .opacity(documentSelectionState.currentLabelConstraint == .allPoints ? 1.0 : 0.5)
                                        .padding(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 10))
                                        .frame(width: labelConstraintChoiceFrameWidth)
                                        .offset(CGSize(width: 0, height: -10))
                                        .tag(labelConstraint)
                                    case .onlyCorrectPoints:
                                        VStack {
                                            HStack {
                                                Image(systemName: "circle.fill")
                                                    .foregroundStyle(.green.gradient)
                                            }
                                            Text("Correct predictions")
                                                .foregroundStyle(.secondary)
                                        }
                                        .opacity(documentSelectionState.currentLabelConstraint == .onlyCorrectPoints ? 1.0 : 0.5)
                                        //.padding(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 10))
                                        .frame(width: labelConstraintChoiceFrameWidth)
                                        .offset(CGSize(width: 0, height: -10))
                                        .tag(labelConstraint)
                                    case .onlyWrongPoints:
                                        VStack {
                                            HStack {
                                                Image(systemName: "circle.fill")
                                                    .foregroundStyle(.red.gradient)
                                            }
                                            Text("Wrong predictions")
                                                .foregroundStyle(.secondary)
                                        }
                                        .opacity(documentSelectionState.currentLabelConstraint == .onlyWrongPoints ? 1.0 : 0.5)
                                        //.padding(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 10))
                                        .frame(width: labelConstraintChoiceFrameWidth)
                                        .offset(CGSize(width: 0, height: -10))
                                        .tag(labelConstraint)
                                    }
                                }
                            } label: {
                            }
                            .pickerStyle(.radioGroup)
                        }
                        
                        GridRow {
                            Text("Show documents with the following ground-truth labels:")
                                .gridCellColumns(3)
                                .gridCellAnchor(.leading)
                        }
                        GridRow {
                            Color.clear
                                .gridCellUnsizedAxes([.vertical, .horizontal])
                            GroundTruthLabelsSelectionView(documentSelectionState: $documentSelectionState)
                            Color.clear
                                .gridCellUnsizedAxes([.vertical, .horizontal])
                        }
                        
                        
//                        GridRow {
//                            HStack {
//                                Text("Show documents with \(REConstants.CategoryDisplayLabels.qFull) value \(Text(" ∈ [\(documentSelectionState.lowerQConstraint), \(documentSelectionState.upperQConstraint)]").monospaced()):")
//                                PopoverViewWithButtonLocalStateOptions(popoverViewText: REConstants.HelpAssistanceInfo.qInfoString)
//                            }
//                                .gridCellColumns(3)
//                                .gridCellAnchor(.leading)
//                        }
//                        
//                        
//                        GridRow {
//                            HStack {
//                                Spacer()
//                                Text("\(REConstants.CategoryDisplayLabels.qVar) ∈ \(distanceConstraintsSummary):")
//                                    .monospaced()
//                                    .font(REConstants.Fonts.baseFont)
//                                Spacer()
//                            }
//                            .gridCellColumns(3)
//                        }
//                        
//                        
//                        GridRow {
//                            HStack {
//                                Spacer()
//                                Button {
//                                    documentSelectionState.lowerQConstraint = 0
//                                    documentSelectionState.upperQConstraint = REConstants.Uncertainty.maxQAvailableFromIndexer
//                                } label: {
//                                    Text("Reset \(REConstants.CategoryDisplayLabels.qShort) constraints")
//                                        .font(REConstants.Fonts.baseFont.smallCaps())
//                                        .foregroundStyle(.blue)
//                                }
//                                .buttonStyle(.borderless)
//                                Spacer()
//                            }
//                            .gridCellColumns(3)
//                        }
//                        GridRow {
//                            Color.clear
//                                .gridCellUnsizedAxes([.vertical, .horizontal])
//                                .frame(width: firstColumnSpacerFrameWidth)
//                            Text("Lowest allowed \(REConstants.CategoryDisplayLabels.qShort) value")
//                                .foregroundStyle(.secondary)
//                            //                    VStack {
//                            Picker(selection: $documentSelectionState.lowerQConstraint) {
//                                ForEach(0...documentSelectionState.upperQConstraint, id:\.self) { qValue in
//                                    Text("\(qValue)").tag(qValue)
//                                }
//                            } label: {
//                            }
//                            .pickerStyle(.menu)
//                            //.padding()
//                            .frame(width: qConstraintFrameWidth)
//                        }
//                        GridRow {
//                            Color.clear
//                                .gridCellUnsizedAxes([.vertical, .horizontal])
//                                .frame(width: firstColumnSpacerFrameWidth)
//                            Text("Highest allowed \(REConstants.CategoryDisplayLabels.qShort) value")
//                                .foregroundStyle(.secondary)
//                            //                    VStack {
//                            Picker(selection: $documentSelectionState.upperQConstraint) {
//                                ForEach(documentSelectionState.lowerQConstraint...qGlobalMax, id:\.self) { qValue in
//                                    Text("\(qValue)").tag(qValue)
//                                }
//                            } label: {
//                            }
//                            .pickerStyle(.menu)
//                            //.padding()
//                            .frame(width: qConstraintFrameWidth)
//                            .padding(.bottom)
//                        }
                        SelectionSimilarityConstraintsView(documentSelectionState: $documentSelectionState)
                        SelectionDistanceConstraintsView(documentSelectionState: $documentSelectionState)
                        SelectionMagnitudeConstraintsView(documentSelectionState: $documentSelectionState)
                        GridRow {
                            Text("")
                                .gridCellColumns(3)
                                .gridCellAnchor(.leading)
                        }
                        
                        GridRow {
                            Text("Only show documents marked as **Viewed**")
                                .gridCellColumns(2)
                                .gridCellAnchor(.leading)
                            Toggle(isOn: $documentSelectionState.changedDocumentsParameters.onlyShowViewedDocuments) {
                            }
                            .toggleStyle(.switch)
                        }
                        GridRow {
                            HStack {
                                Text("Only show documents marked as **Modified**")
                                PopoverViewWithButtonLocalState(popoverViewText: "Documents are automatically marked as Modified when the label is changed.")
                            }
                            .gridCellColumns(2)
                            Toggle(isOn: $documentSelectionState.changedDocumentsParameters.onlyShowModifiedDocuments) {
                            }
                            .toggleStyle(.switch)
                        }
                        Group {
                            GridRow {
                                Divider()
                                    .gridCellColumns(3)
                            }
                            GridRow {
                                Text("Only show documents with a feature-level prediction that disagrees with the document-level prediction")
                                    .gridCellColumns(2)
                                Toggle(isOn: $documentSelectionState.inconsistentFeaturesParameters.onlyShowDocumentsWithFeaturesInconsistentWithDocLevelPredictedClass) {
                                }
                                .toggleStyle(.switch)
                            }
                            GridRow {
                                Color.clear
                                    .gridCellUnsizedAxes([.vertical, .horizontal])
                                HStack {
                                    Text("Inconsistent feature-level prediction:")
                                        .opacity(documentSelectionState.inconsistentFeaturesParameters.onlyShowDocumentsWithFeaturesInconsistentWithDocLevelPredictedClass ? 1.0 : 0.5)
                                    PopoverViewWithButtonLocalState(popoverViewText: "This is the class label associated with the inconsistent feature. A feature that agrees with the document-level prediction may also exist and be highlighted in the document.")
                                }
                                    .gridCellColumns(2)
                            }
                            GridRow {
                                Color.clear
                                    .gridCellUnsizedAxes([.vertical, .horizontal])
                                InconsistentFeaturePredictionSelectionView(documentSelectionState: $documentSelectionState)
                                    .disabled(!documentSelectionState.inconsistentFeaturesParameters.onlyShowDocumentsWithFeaturesInconsistentWithDocLevelPredictedClass)
                                    .opacity(documentSelectionState.inconsistentFeaturesParameters.onlyShowDocumentsWithFeaturesInconsistentWithDocLevelPredictedClass ? 1.0 : 0.5)
                                Color.clear
                                    .gridCellUnsizedAxes([.vertical, .horizontal])
                            }
                        }
                        Group {
                            GridRow {
                                Divider()
                                    .gridCellColumns(3)
                            }
                        }
                        SelectionPartitionSizeConstraintsView(documentSelectionState: $documentSelectionState)
                    }
                    Spacer()
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
