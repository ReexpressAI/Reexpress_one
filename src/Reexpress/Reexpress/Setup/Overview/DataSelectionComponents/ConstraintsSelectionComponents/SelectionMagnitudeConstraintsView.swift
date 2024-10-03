//
//  SelectionMagnitudeConstraintsView.swift
//  Reexpress
//
//  Created by A on 10/1/23.
//

import SwiftUI

struct SelectionMagnitudeConstraintsView: View {
    @Binding var documentSelectionState: DocumentSelectionState
    @State var minFString: String = "0"
    @State var maxFString: String = "1.0"

    var magnitudeConstraintsSummary: String {
        return "[\(minFFormattedForDisplay), \(maxFFormattedForDisplay)]"
    }
    var minFFormattedForDisplay: String {
        if let minF = documentSelectionState.magnitudeConstraints.minF {
            return String(minF)
        } else {
            return "0"
        }
    }
    var maxFFormattedForDisplay: String {
        if let maxF = documentSelectionState.magnitudeConstraints.maxF {
            return String(maxF)
        } else {
            return "1.0"
        }
    }
    func validateMagnitude(stringF: String, isMax: Bool) throws -> Float32 {
        if let f = Float32(stringF), f.isFinite, f >= 0.0, f <= 1.0 {
            if isMax {
                if let minF = documentSelectionState.magnitudeConstraints.minF, f < minF {
                    throw DataSelectionErrors.invalidMagnitdueConstraint
                }
            } else {
                if let maxF = documentSelectionState.magnitudeConstraints.maxF, f > maxF {
                    throw DataSelectionErrors.invalidMagnitdueConstraint
                }
            }
            return f
        }
        throw DataSelectionErrors.invalidMagnitdueConstraint
    }
    func reset() {
        documentSelectionState.magnitudeConstraints = MagnitudeConstraints()
        minFString = minFFormattedForDisplay
        maxFString = maxFFormattedForDisplay 
    }
    // Update both min and max together to keep them in sync:
    func validateAndUpdate(minFString: String, maxFString: String) {
            do {
                documentSelectionState.magnitudeConstraints.minF = try validateMagnitude(stringF: minFString, isMax: false)
            } catch {
                documentSelectionState.magnitudeConstraints.minF = nil
            }
            do {
                documentSelectionState.magnitudeConstraints.maxF = try validateMagnitude(stringF: maxFString, isMax: true)
            } catch {
                documentSelectionState.magnitudeConstraints.maxF = nil
            }
    }
    var body: some View {
        GridRow {
            HStack {
                Text("Show documents with \(REConstants.CategoryDisplayLabels.fFull) value:")
                PopoverViewWithButtonLocalStateOptions(popoverViewText: REConstants.HelpAssistanceInfo.fInfoString)
            }
            .gridCellColumns(3)
        }
        GridRow {
            HStack {
                Spacer()
                Text("\(REConstants.CategoryDisplayLabels.fVar) ∈ \(magnitudeConstraintsSummary):")
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
                    reset()
                } label: {
                    Text("Reset \(REConstants.CategoryDisplayLabels.fShort) constraints")
                        .font(REConstants.Fonts.baseFont.smallCaps())
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.borderless)
                Spacer()
            }
            .gridCellColumns(3)
        }
        GridRow {
            HStack(alignment: .center) {
                Spacer()
                Text("Lowest allowed \(REConstants.CategoryDisplayLabels.fShort):    ")
                    .foregroundStyle(.gray)
                VStack {
                    TextEditor(text: $minFString)
                        .font(REConstants.Fonts.baseFont)
                        .monospaced(true)
                        .frame(width: 250, height: 18)
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
                }
                .onChange(of: minFString) {
                    validateAndUpdate(minFString: minFString, maxFString: maxFString)
                    // Note this updates the *other* text string, to reset it if it is not valid. (On the other hand, we cannot update the current string because the behavior is then strange with no updates allowed while typing):
                    maxFString = maxFFormattedForDisplay
                }
            }
            .padding([.leading, .trailing])
            .gridCellColumns(3)
        }
        GridRow {
            HStack(alignment: .center) {
                Spacer()
                Text("Highest allowed \(REConstants.CategoryDisplayLabels.fShort):    ")
                    .foregroundStyle(.gray)
                VStack {
                    TextEditor(text: $maxFString)
                        .font(REConstants.Fonts.baseFont)
                        .monospaced(true)
                        .frame(width: 250, height: 18)
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
                }
                .onChange(of: maxFString) {
                    validateAndUpdate(minFString: minFString, maxFString: maxFString)
                    // Note this updates the *other* text string, to reset it if it is not valid. (On the other hand, we cannot update the current string because the behavior is then strange with no updates allowed while typing):
                    minFString = minFFormattedForDisplay
                }
            }
            .padding([.leading, .trailing])
            .gridCellColumns(3)
        }
        .onAppear {
            minFString = minFFormattedForDisplay
            maxFString = maxFFormattedForDisplay
        }
    }
}
