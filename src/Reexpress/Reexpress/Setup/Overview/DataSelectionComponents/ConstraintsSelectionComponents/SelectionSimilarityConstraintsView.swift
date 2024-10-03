//
//  SelectionSimilarityConstraintsView.swift
//  Reexpress
//
//  Created by A on 10/2/23.
//

import SwiftUI

struct SelectionSimilarityConstraintsView: View {
    @Binding var documentSelectionState: DocumentSelectionState
    
    let qConstraintFrameWidth: CGFloat = 100
    let qGlobalMax: Int = REConstants.Uncertainty.maxQAvailableFromIndexer
    let firstColumnSpacerFrameWidth: CGFloat = 100
    var similarityConstraintsSummary: String {
        return "[\(documentSelectionState.lowerQConstraint), \(documentSelectionState.upperQConstraint)]"
    }
    var body: some View {
        GridRow {
            HStack {
                Text("Show documents with \(REConstants.CategoryDisplayLabels.qFull) value:")
                PopoverViewWithButtonLocalStateOptions(popoverViewText: REConstants.HelpAssistanceInfo.qInfoString)
            }
                .gridCellColumns(3)
                .gridCellAnchor(.leading)
        }
        
        
        GridRow {
            HStack {
                Spacer()
                Text("\(REConstants.CategoryDisplayLabels.qVar) ∈ \(similarityConstraintsSummary):")
                    .monospaced()
                    .font(REConstants.Fonts.baseFont)
                Spacer()
            }
            .gridCellColumns(3)
        }
        
        
        GridRow {
            HStack {
                Spacer()
                Button {
                    documentSelectionState.lowerQConstraint = 0
                    documentSelectionState.upperQConstraint = REConstants.Uncertainty.maxQAvailableFromIndexer
                } label: {
                    Text("Reset \(REConstants.CategoryDisplayLabels.qShort) constraints")
                        .font(REConstants.Fonts.baseFont.smallCaps())
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.borderless)
                Spacer()
            }
            .gridCellColumns(3)
        }
        GridRow {
            Color.clear
                .gridCellUnsizedAxes([.vertical, .horizontal])
                .frame(width: firstColumnSpacerFrameWidth)
            Text("Lowest allowed \(REConstants.CategoryDisplayLabels.qShort) value")
                .foregroundStyle(.secondary)
            //                    VStack {
            Picker(selection: $documentSelectionState.lowerQConstraint) {
                ForEach(0...documentSelectionState.upperQConstraint, id:\.self) { qValue in
                    Text("\(qValue)").tag(qValue)
                }
            } label: {
            }
            .pickerStyle(.menu)
            //.padding()
            .frame(width: qConstraintFrameWidth)
        }
        GridRow {
            Color.clear
                .gridCellUnsizedAxes([.vertical, .horizontal])
                .frame(width: firstColumnSpacerFrameWidth)
            Text("Highest allowed \(REConstants.CategoryDisplayLabels.qShort) value")
                .foregroundStyle(.secondary)
            //                    VStack {
            Picker(selection: $documentSelectionState.upperQConstraint) {
                ForEach(documentSelectionState.lowerQConstraint...qGlobalMax, id:\.self) { qValue in
                    Text("\(qValue)").tag(qValue)
                }
            } label: {
            }
            .pickerStyle(.menu)
            //.padding()
            .frame(width: qConstraintFrameWidth)
            .padding(.bottom)
        }
    }
}
