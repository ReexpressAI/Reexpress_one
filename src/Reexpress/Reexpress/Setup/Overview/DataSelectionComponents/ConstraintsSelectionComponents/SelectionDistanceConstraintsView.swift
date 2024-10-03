//
//  SelectionDistanceConstraintsView.swift
//  Reexpress
//
//  Created by A on 10/1/23.
//

import SwiftUI

struct SelectionDistanceConstraintsView: View {
    @Binding var documentSelectionState: DocumentSelectionState
    @State var minDistanceString: String = "0"
    @State var maxDistanceString: String = "infinity"

    var distanceConstraintsSummary: String {
        return "[\(minDistanceFormattedForDisplay), \(maxDistanceFormattedForDisplay)]"
    }
    var minDistanceFormattedForDisplay: String {
        if let minDistance = documentSelectionState.distanceConstraints.minDistance {
            return String(minDistance)
        } else {
            return "0"
        }
    }
    var maxDistanceFormattedForDisplay: String {
        if let maxDistance = documentSelectionState.distanceConstraints.maxDistance {
            return String(maxDistance)
        } else {
            return "infinity"
        }
    }
    func validateDistance(stringDistance: String, isMax: Bool) throws -> Float32 {
        if let d0 = Float32(stringDistance), d0.isFinite, d0 >= 0.0 {
            if isMax {
                if let minDistance = documentSelectionState.distanceConstraints.minDistance, d0 < minDistance {
                    throw DataSelectionErrors.invalidDistanceConstraint
                }
            } else {
                if let maxDistance = documentSelectionState.distanceConstraints.maxDistance, d0 > maxDistance {
                    throw DataSelectionErrors.invalidDistanceConstraint
                }
            }
            return d0
        }
        throw DataSelectionErrors.invalidDistanceConstraint
    }
    func reset() {
        documentSelectionState.distanceConstraints = DistanceConstraints()
        minDistanceString = minDistanceFormattedForDisplay //"0"
        maxDistanceString = maxDistanceFormattedForDisplay //"infinity"
    }
    // Update both min and max together to keep them in sync:
    func validateAndUpdate(minDistanceString: String, maxDistanceString: String) {
            do {
                documentSelectionState.distanceConstraints.minDistance = try validateDistance(stringDistance: minDistanceString, isMax: false)
            } catch {
                documentSelectionState.distanceConstraints.minDistance = nil
            }
            do {
                documentSelectionState.distanceConstraints.maxDistance = try validateDistance(stringDistance: maxDistanceString, isMax: true)
            } catch {
                documentSelectionState.distanceConstraints.maxDistance = nil
            }
    }
    var body: some View {
        GridRow {
            HStack {
                Text("Show documents with \(REConstants.CategoryDisplayLabels.dFull) value:")
                PopoverViewWithButtonLocalStateOptions(popoverViewText: REConstants.HelpAssistanceInfo.d0InfoString)
            }
            .gridCellColumns(3)
        }
        GridRow {
            HStack {
                Spacer()
                Text("\(REConstants.CategoryDisplayLabels.dVar) ∈ \(distanceConstraintsSummary):")
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
                    Text("Reset \(REConstants.CategoryDisplayLabels.dShort) constraints")
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
                Text("Lowest allowed \(REConstants.CategoryDisplayLabels.dShort):    ")
                    .foregroundStyle(.gray)
                VStack {
                    TextEditor(text: $minDistanceString)
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
                .onChange(of: minDistanceString) {
                    validateAndUpdate(minDistanceString: minDistanceString, maxDistanceString: maxDistanceString)
                    // Note this updates the *other* text string, to reset it if it is not valid. (On the other hand, we cannot update the current string because the behavior is then strange with no updates allowed while typing):
                    maxDistanceString = maxDistanceFormattedForDisplay
                }
            }
            .padding([.leading, .trailing])
            .gridCellColumns(3)
        }
        GridRow {
            HStack(alignment: .center) {
                Spacer()
                Text("Highest allowed \(REConstants.CategoryDisplayLabels.dShort):    ")
                    .foregroundStyle(.gray)
                VStack {
                    TextEditor(text: $maxDistanceString)
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
                .onChange(of: maxDistanceString) {
                    validateAndUpdate(minDistanceString: minDistanceString, maxDistanceString: maxDistanceString)
                    // Note this updates the *other* text string, to reset it if it is not valid. (On the other hand, we cannot update the current string because the behavior is then strange with no updates allowed while typing):
                    minDistanceString = minDistanceFormattedForDisplay
                }
            }
            .padding([.leading, .trailing])
            .gridCellColumns(3)
        }
        .onAppear {
            minDistanceString = minDistanceFormattedForDisplay //"0"
            maxDistanceString = maxDistanceFormattedForDisplay //"infinity"
        }
    }
}
