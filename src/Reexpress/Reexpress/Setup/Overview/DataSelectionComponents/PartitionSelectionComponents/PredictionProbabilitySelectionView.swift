//
//  PredictionProbabilitySelectionView.swift
//  Alpha1
//
//  Created by A on 8/20/23.
//

import SwiftUI

struct PredictionProbabilitySelectionView: View {
    @Binding var documentSelectionState: DocumentSelectionState
    @State private var isShowingCalibrationDisclaimerInfoPopover: Bool = false
    
    let frameWidth: CGFloat = 100
    let firstColumnSpacerFrameWidth: CGFloat = 100
    
    var lowerProbabilityString: String {
        return documentSelectionState.probabilityConstraint.getDisplayProbabilityStringWithSignificantDigits(probabilityInt: documentSelectionState.probabilityConstraint.lowerProbabilityInt)
    }
    var upperProbabilityString: String {
        return documentSelectionState.probabilityConstraint.getDisplayProbabilityStringWithSignificantDigits(probabilityInt: documentSelectionState.probabilityConstraint.upperProbabilityInt)
    }
    var body: some View {
//        Text(String(documentSelectionState.probabilityConstraint.lowerProbability))
//        Text(String(documentSelectionState.probabilityConstraint.upperProbability))
        VStack {
            VStack(alignment: .leading) {
                HStack(alignment: .lastTextBaseline) {
                    Text("Calibrated Probability of Prediction ∈ [\(lowerProbabilityString), \(upperProbabilityString)]: ")
                        .font(.title2)
                    Button {
                        isShowingCalibrationDisclaimerInfoPopover.toggle()
                    } label: {
                        Image(systemName: "info.circle.fill")
                    }
                    .buttonStyle(.borderless)
                    .popover(isPresented: $isShowingCalibrationDisclaimerInfoPopover) {
                        CalibrationReliabilityDisclaimerView()
                            .frame(width: 450)
                    }
                    Spacer()
                }
                .frame(width: 450)
                .padding([.leading, .trailing])
                Grid(alignment: .leadingFirstTextBaseline) {
//                    GridRow {
//                        Text("Show documents with prediction probability ∈ [\(lowerProbabilityString), \(upperProbabilityString)]:")
//                            .gridCellColumns(3)
//                            .gridCellAnchor(.leading)
//                    }
                    GridRow {
                        Color.clear
                            .gridCellUnsizedAxes([.vertical, .horizontal])
                            .frame(width: firstColumnSpacerFrameWidth)
                        Text("Lower bound")
                            .foregroundStyle(.secondary)
                        //                    VStack {
                        Picker(selection: $documentSelectionState.probabilityConstraint.lowerProbabilityInt) {
                            ForEach(Array(stride(from: REConstants.Uncertainty.minProbabilityPrecisionForDisplayAsInt, through: documentSelectionState.probabilityConstraint.upperProbabilityInt, by: REConstants.Uncertainty.probabilityPrecisionStrideAsInt) ), id:\.self) { intProb in
                                
                                Text(documentSelectionState.probabilityConstraint.getDisplayProbabilityStringWithSignificantDigits(probabilityInt: intProb)).tag(intProb)
                            }
                        } label: {
                        }
                        .pickerStyle(.menu)
                        //.padding()
                        .frame(width: frameWidth)
                    }
                    GridRow {
                        Color.clear
                            .gridCellUnsizedAxes([.vertical, .horizontal])
                            .frame(width: firstColumnSpacerFrameWidth)
                        Text("Upper bound")
                            .foregroundStyle(.secondary)
                        //                    VStack {
                        Picker(selection: $documentSelectionState.probabilityConstraint.upperProbabilityInt) {
                            ForEach(Array(stride(from: documentSelectionState.probabilityConstraint.lowerProbabilityInt, through: REConstants.Uncertainty.maxProbabilityPrecisionForDisplayAsInt, by: REConstants.Uncertainty.probabilityPrecisionStrideAsInt) ), id:\.self) { intProb in
                                Text(documentSelectionState.probabilityConstraint.getDisplayProbabilityStringWithSignificantDigits(probabilityInt: intProb)).tag(intProb)
                            }
                        } label: {
                        }
                        .pickerStyle(.menu)
                        //.padding()
                        .frame(width: frameWidth)
                    }
                }
            }
        }
    }
}

