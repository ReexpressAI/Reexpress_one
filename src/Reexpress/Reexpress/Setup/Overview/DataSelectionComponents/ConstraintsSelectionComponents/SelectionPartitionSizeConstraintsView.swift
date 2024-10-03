//
//  SelectionPartitionSizeConstraintsView.swift
//  Reexpress
//
//  Created by A on 10/2/23.
//

import SwiftUI

struct SelectionPartitionSizeConstraintsView: View {
    @Binding var documentSelectionState: DocumentSelectionState
    
    @State var minPartitionSizeString: String = "\(REConstants.Uncertainty.minReliablePartitionSize)"
    @State var maxPartitionSizeString: String = "infinity"
    
    var partitionSizeConstraintsSummary: String {
        return "[\(minPartitionSizeFormattedForDisplay), \(maxPartitionSizeFormattedForDisplay)]"
    }
    var minPartitionSizeFormattedForDisplay: String {
        if let minPartitionSize = documentSelectionState.partitionSizeConstraints.minPartitionSize {
            return String(minPartitionSize)
        } else {
            return "\(REConstants.Uncertainty.minReliablePartitionSize)"
        }
    }
    var maxPartitionSizeFormattedForDisplay: String {
        if let maxPartitionSize = documentSelectionState.partitionSizeConstraints.maxPartitionSize {
            return String(maxPartitionSize)
        } else {
            return "infinity"
        }
    }
    func validateDistance(stringDistance: String, isMax: Bool) throws -> Int {
        if let size = Int(stringDistance), size >= REConstants.Uncertainty.minReliablePartitionSize {
            if isMax {
                if let minPartitionSize = documentSelectionState.partitionSizeConstraints.minPartitionSize, size < minPartitionSize {
                    throw DataSelectionErrors.invalidPartitionSizeConstraint
                }
            } else {
                if let maxPartitionSize = documentSelectionState.partitionSizeConstraints.maxPartitionSize, size > maxPartitionSize {
                    throw DataSelectionErrors.invalidPartitionSizeConstraint
                }
            }
            return size
        }
        throw DataSelectionErrors.invalidPartitionSizeConstraint
    }
    func reset() {
        documentSelectionState.partitionSizeConstraints = PartitionSizeConstraints()
        minPartitionSizeString = minPartitionSizeFormattedForDisplay
        maxPartitionSizeString = maxPartitionSizeFormattedForDisplay
    }
    // Update both min and max together to keep them in sync:
    func validateAndUpdate(minPartitionSizeString: String, maxPartitionSizeString: String) {
        do {
            documentSelectionState.partitionSizeConstraints.minPartitionSize = try validateDistance(stringDistance: minPartitionSizeString, isMax: false)
        } catch {
            documentSelectionState.partitionSizeConstraints.minPartitionSize = nil
        }
        do {
            documentSelectionState.partitionSizeConstraints.maxPartitionSize = try validateDistance(stringDistance: maxPartitionSizeString, isMax: true)
        } catch {
            documentSelectionState.partitionSizeConstraints.maxPartitionSize = nil
        }
    }
    var additionalConstraintsCanBeApplied: Bool {
        return documentSelectionState.partitionSizeConstraints.restrictPartitionSize && !documentSelectionState.includeAllPartitions
    }
    var body: some View {
        GridRow {
            HStack {
                Text("Apply additional \(REConstants.CategoryDisplayLabels.sizeShort) constraints")
                PopoverViewWithButtonLocalStateOptions(popoverViewText: "**\(REConstants.SelectionDisplayLabels.dataPartitionSelectionTab)**->**\(REConstants.SelectionDisplayLabels.showAllPartitionsLabel)** must be *disabled* to further constrain the partition size above \(REConstants.Uncertainty.minReliablePartitionSize). If this option is selected, the size constraints below will override  those in **\(REConstants.SelectionDisplayLabels.dataPartitionSelectionTab)**->**Partition**->**\(REConstants.CategoryDisplayLabels.sizeFull)**.")
            }
            .gridCellColumns(2)
            Toggle(isOn: $documentSelectionState.partitionSizeConstraints.restrictPartitionSize) {
            }
            .toggleStyle(.switch)
            .disabled(documentSelectionState.includeAllPartitions)
            .onChange(of: documentSelectionState.partitionSizeConstraints.restrictPartitionSize) { oldValue, newValue in
                // refresh display:
                minPartitionSizeString = minPartitionSizeFormattedForDisplay
                maxPartitionSizeString = maxPartitionSizeFormattedForDisplay
                if newValue {
                    // set the min size to reflect the default shown in the interface:
                    documentSelectionState.partitionSizeConstraints.minPartitionSize = REConstants.Uncertainty.minReliablePartitionSize
                }
            }
        }
        Group {
            GridRow {
                HStack {
                    Text("Show documents with \(REConstants.CategoryDisplayLabels.sizeFull) value:")
                    //PopoverViewWithButtonLocalStateOptions(popoverViewText: "**\(REConstants.SelectionDisplayLabels.dataPartitionSelectionTab)**->**\(REConstants.SelectionDisplayLabels.showAllPartitionsLabel)** must be *disabled* to further constrain the partition size above \(REConstants.Uncertainty.minReliablePartitionSize).")
                }
                .gridCellColumns(3)
            }
            GridRow {
                HStack {
                    Spacer()
                    Text("\(REConstants.CategoryDisplayLabels.sizeVar) ∈ \(partitionSizeConstraintsSummary):")
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
                        Text("Reset \(REConstants.CategoryDisplayLabels.sizeShort) constraints")
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
                    Text("Lowest allowed \(REConstants.CategoryDisplayLabels.sizeShort):    ")
                        .foregroundStyle(.gray)
                    VStack {
                        TextEditor(text: additionalConstraintsCanBeApplied ? $minPartitionSizeString : .constant(minPartitionSizeString))
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
                    .onChange(of: minPartitionSizeString) {
                        validateAndUpdate(minPartitionSizeString: minPartitionSizeString, maxPartitionSizeString: maxPartitionSizeString)
                        // Note this updates the *other* text string, to reset it if it is not valid. (On the other hand, we cannot update the current string because the behavior is then strange with no updates allowed while typing):
                        maxPartitionSizeString = maxPartitionSizeFormattedForDisplay
                    }
                }
                .padding([.leading, .trailing])
                .gridCellColumns(3)
            }
            GridRow {
                HStack(alignment: .center) {
                    Spacer()
                    Text("Highest allowed \(REConstants.CategoryDisplayLabels.sizeShort):    ")
                        .foregroundStyle(.gray)
                    VStack {
                        TextEditor(text: additionalConstraintsCanBeApplied ? $maxPartitionSizeString : .constant(maxPartitionSizeString))
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
                    .onChange(of: maxPartitionSizeString) {
                        validateAndUpdate(minPartitionSizeString: minPartitionSizeString, maxPartitionSizeString: maxPartitionSizeString)
                        // Note this updates the *other* text string, to reset it if it is not valid. (On the other hand, we cannot update the current string because the behavior is then strange with no updates allowed while typing):
                        minPartitionSizeString = minPartitionSizeFormattedForDisplay
                    }
                }
                .padding([.leading, .trailing])
                .gridCellColumns(3)
            }
            .onAppear {
                minPartitionSizeString = minPartitionSizeFormattedForDisplay
                maxPartitionSizeString = maxPartitionSizeFormattedForDisplay
            }
        }
        .opacity(additionalConstraintsCanBeApplied ? 1.0 : 0.5)
    }
}
