//
//  DataDetailsUncertaintyView.swift
//  Alpha1
//
//  Created by A on 8/14/23.
//

import SwiftUI

struct DataDetailsUncertaintyView: View {
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var dataController: DataController
        
    @Binding var documentObject: Document?
    
    @State private var isShowingFCalibratedInfoPopover: Bool = false
    @State private var isShowingQInfoPopover: Bool = false
    @State private var isShowingd0InfoPopover: Bool = false
    @State private var isShowingfInfoPopover: Bool = false
    
    @State private var isShowingHeadsUpDisplayForFMagnitude: Bool = false
    @State private var isShowingHeadsUpDisplayForDistance: Bool = false
    @State private var isShowingHeadsUpDisplayForQ: Bool = false
    
    @State private var isShowingHeadsUpDisplayForProbability: Bool = false
    @State private var isShowingInfoForCalibrationReliability: Bool = false
    
    var f_of_x_argmax_formatted: String {
        if let docObj = documentObject, let softmax = docObj.uncertainty?.softmax?.toArray(type: Float32.self) {
            //let predictionArgmax = Int(vDSP.indexOfMaximum(softmax).0)
            return REConstants.floatProbToDisplaySignificantDigits(floatProb: softmax[docObj.prediction])
        } else {
            return ""
        }
    }
    
    var uncertaintyIsCurrentIfCalculated: Bool {  // Note that this is true if the uncertainty estimate does not exist
        if let docObj = documentObject, let documentUncertaintyModelUUID = docObj.uncertainty?.uncertaintyModelUUID, docObj.uncertainty?.qdfCategoryID != nil {
            return dataController.isPredictionUncertaintyCurrent(documentUncertaintyModelUUID: documentUncertaintyModelUUID)
//            let currentUncertaintyModelUUID = dataController.uncertaintyStatistics?.uncertaintyModelUUID ?? ""
//            let indexModelUUIDOwnedByUncertaintyModel = dataController.uncertaintyStatistics?.indexModelUUID ?? ""
//            let indexModelUUID = dataController.inMemory_KeyModelGlobalControl.indexModelUUID
//            return documentUncertaintyModelUUID == currentUncertaintyModelUUID && currentUncertaintyModelUUID != REConstants.ModelControl.defaultUncertaintyModelUUID && indexModelUUIDOwnedByUncertaintyModel == indexModelUUID
        }
        return true
    }
    
    
    var documentQDFCategory: UncertaintyStatistics.QDFCategory? {
        if let docObj = documentObject, docObj.uncertainty?.uncertaintyModelUUID != nil, let qdfCategoryID = docObj.uncertainty?.qdfCategoryID {
            return UncertaintyStatistics.QDFCategory.initQDFCategoryFromIdString(idString: qdfCategoryID)
        }
        return nil
    }
    
    var calibratedProbabilityString: String {
        if let docObj = documentObject, let qdfCategory = documentQDFCategory, let calibratedOutput = dataController.uncertaintyStatistics?.vennADMITCategory_To_CalibratedOutput[qdfCategory], let minDistribution = calibratedOutput?.minDistribution, docObj.prediction < minDistribution.count {
            return REConstants.floatProbToDisplaySignificantDigits(floatProb: minDistribution[docObj.prediction])
        }
        return "N/A"
    }
    
    var partitionSize: Int {
        if documentObject != nil, let qdfCategory = documentQDFCategory, let calibratedOutput = dataController.uncertaintyStatistics?.vennADMITCategory_To_CalibratedOutput[qdfCategory], let sizeOfCategory = calibratedOutput?.sizeOfCategory, sizeOfCategory >= 0 {
            return Int(sizeOfCategory)
        }
        return 0
    }
        
    var reliabilityLabel: (reliabilityImageName: String, reliabilityTextCaption: String, reliabilityColorGradient: AnyShapeStyle, opacity: Double) {
        if documentObject != nil, let qdfCategory = documentQDFCategory {
            return UncertaintyStatistics.formatReliabilityLabel(dataPoint: nil, qdfCategory: qdfCategory, sizeOfCategory: partitionSize)
        }
        return UncertaintyStatistics.formatReliabilityLabel(dataPoint: nil, qdfCategory: nil, sizeOfCategory: partitionSize)
    }
    
    var inferenceHasBeenRun: Bool {
        if let docObj = documentObject {
            return DataController.isKnownValidLabel(label: docObj.prediction, numberOfClasses: dataController.numberOfClasses)
        }
        return false
    }
    
    var body: some View {
        HStack {
            Text("Uncertainty")
                .font(.title3)
                .foregroundStyle(.gray)
            if !uncertaintyIsCurrentIfCalculated {
                Text("WARNING: Estimates are out-of-date with the current model. Re-run prediction.")
                    .font(.title3)
                    .foregroundStyle(.red)
            }
            Spacer()
        }
        .padding([.leading, .trailing])
        
        
        VStack {
            HStack {
                VStack {
                    HStack {
                        if documentObject?.uncertainty != nil {
                            Image(systemName: "chart.bar.doc.horizontal")
                                .font(.title3)
                                .foregroundStyle(.blue.gradient)
                        }
                        Text(REConstants.CategoryDisplayLabels.calibratedProbabilityFull)
                            .font(.title3)
                            .foregroundStyle(.gray)
                            .help(REConstants.CategoryDisplayLabels.calibratedProbabilityFull)
                        PopoverViewWithButton(isShowingInfoPopover: $isShowingFCalibratedInfoPopover, popoverViewText: REConstants.HelpAssistanceInfo.fCalibratedInfoString)
                        Spacer()
                    }
                    .popover(isPresented: $isShowingHeadsUpDisplayForProbability, arrowEdge: .top) {
                        if documentObject?.uncertainty != nil {
                            ProbabilityHeadsUpView(documentObject: $documentObject)
                                .frame(width: 800)
                        }
                    }
                    VStack {
                        HStack {
                            if documentObject != nil {
                                Text(calibratedProbabilityString)
                                    .monospaced()
                                    .font(.title3)
                            } else {
                                Text("")
                            }
                            Spacer()
                        }
                    }
                    .frame(minHeight: 20, maxHeight: 20)
                    .padding()
                    .modifier(PrimaryComponentsViewModifier(useReBackgroundDarker: true, viewBoxScaling: 8))
                }
                .onTapGesture {
                    isShowingHeadsUpDisplayForProbability.toggle()
                }
                
                VStack {
                    HStack {
                        Text(REConstants.CategoryDisplayLabels.calibrationReliabilityFull)
                            .font(.title3)
                            .foregroundStyle(.gray)
                            .help(REConstants.CategoryDisplayLabels.calibrationReliabilityFull)
                        Button {
                            isShowingInfoForCalibrationReliability.toggle()
                        } label: {
                            Image(systemName: "info.circle.fill")
                        }
                        .buttonStyle(.borderless)
                        .popover(isPresented: $isShowingInfoForCalibrationReliability) {
                            CalibrationReliabilityView()
                                .frame(width: 800)
                        }
                        Spacer()
                    }
                    VStack {
                        HStack {
                            if documentObject != nil && inferenceHasBeenRun {
                                Image(systemName: reliabilityLabel.reliabilityImageName)
                                    .font(.title)
                                    .foregroundStyle(reliabilityLabel.reliabilityColorGradient)
                                    .opacity(reliabilityLabel.opacity)
                                Text(reliabilityLabel.reliabilityTextCaption)
                                    .foregroundStyle(.gray)
                                    .font(.title3)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)
                                
                            } else {
                                Text("")
                                    .monospaced()
                                    .font(.title3)
                            }
                            Spacer()
                        }
                    }
                    .frame(minHeight: 20, maxHeight: 20)
                    .padding()
                    .modifier(PrimaryComponentsViewModifier(useReBackgroundDarker: true, viewBoxScaling: 8))
                }
                .padding([.leading]) //, .trailing])
                VStack {
                    HStack {
                        Text(REConstants.CategoryDisplayLabels.sizeFull)
                            .font(.title3)
                            .foregroundStyle(.gray)
                            .help(REConstants.CategoryDisplayLabels.sizeFull)
                        Spacer()
                    }
                    VStack {
                        HStack {
                            if documentObject != nil && inferenceHasBeenRun {
                                let partitionSizeString = String(partitionSize)
                                if partitionSize < REConstants.Uncertainty.minReliablePartitionSize {
                                    Text("Insufficient:")
                                        .modifier(CategoryLabelInLineSmallerViewModifier())
                                        .foregroundStyle(.gray)
                                        .help("Insufficient")
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.75)
                                    Text(partitionSizeString)
                                        .monospaced()
                                        .font(.title3)
                                        .help(partitionSizeString)
                                } else {
                                    Text(partitionSizeString)
                                        .monospaced()
                                        .font(.title3)
                                        .help(partitionSizeString)
                                }
                            } else {
                                Text("")
                            }
                            Spacer()
                        }
                    }
                    .frame(minHeight: 20, maxHeight: 20)
                    .padding()
                    .modifier(PrimaryComponentsViewModifier(useReBackgroundDarker: true, viewBoxScaling: 8))
                }
                .padding([.leading])
            }
            
            // Row 2
            HStack {
                VStack {
                    HStack {
                        HStack {
                            if documentObject?.uncertainty != nil {
                                Image(systemName: "chart.bar.doc.horizontal")
                                    .font(.title3)
                                    .foregroundStyle(.blue.gradient)
                            }
                            Text(REConstants.CategoryDisplayLabels.qFull)
                                .font(.title3)
                                .foregroundStyle(.gray)
                                .help(REConstants.CategoryDisplayLabels.qFull)
                            PopoverViewWithButton(isShowingInfoPopover: $isShowingQInfoPopover, popoverViewText: REConstants.HelpAssistanceInfo.qInfoString, optionalSubText: REConstants.HelpAssistanceInfo.qdfInfoString)
                            Spacer()
                        }
                        .onTapGesture {
                            isShowingHeadsUpDisplayForQ.toggle()
                        }
                        .popover(isPresented: $isShowingHeadsUpDisplayForQ, arrowEdge: .top) {
                            if documentObject?.uncertainty != nil {
                                QPartitionView(documentObject: $documentObject)
                                    .frame(width: 800)
                            }
                        }
                    }
                    VStack {
                        HStack {
                            if let docObj = documentObject, let uncertainty = docObj.uncertainty, let qCategory = dataController.uncertaintyStatistics?.getQCategory(q: uncertainty.q) {
                                let qCategoryLabel = UncertaintyStatistics.getQCategoryLabel(qCategory: qCategory)
                                Text("\(qCategoryLabel):")
                                    .modifier(CategoryLabelInLineSmallerViewModifier())
                                    .foregroundStyle(.gray)
                                Text("\(uncertainty.q)")
                                    .monospaced()
                                    .font(.title3)
                            } else {
                                Text("")
                                    .monospaced()
                                    .font(.title3)
                            }
                            Spacer()
                        }
                    }
                    .frame(minHeight: 20, maxHeight: 20)
                    .padding()
                    .modifier(PrimaryComponentsViewModifier(useReBackgroundDarker: false, viewBoxScaling: 8))
                    .onTapGesture {
                        isShowingHeadsUpDisplayForQ.toggle()
                    }
                }
                
                VStack {
                    HStack {
                        HStack {
                            if documentObject?.uncertainty != nil {
                                Image(systemName: "chart.bar.doc.horizontal")
                                    .font(.title3)
                                    .foregroundStyle(.blue.gradient)
                            }
                            Text(REConstants.CategoryDisplayLabels.dFull)
                                .font(.title3)
                                .foregroundStyle(.gray)
                                .help(REConstants.CategoryDisplayLabels.dFull)
                            PopoverViewWithButton(isShowingInfoPopover: $isShowingd0InfoPopover, popoverViewText: REConstants.HelpAssistanceInfo.d0InfoString, optionalSubText: REConstants.HelpAssistanceInfo.qdfInfoString)
                            Spacer()
                        }
                        .onTapGesture {
                            isShowingHeadsUpDisplayForDistance.toggle()
                        }
                        .popover(isPresented: $isShowingHeadsUpDisplayForDistance, arrowEdge: .top) {
                            if documentObject?.uncertainty != nil {
                                DistanceToTrainingView(documentObject: $documentObject)
                                    .frame(width: 800)
                            }
                        }
                    }
                    VStack {
                        HStack {
                            if let docQDFCategory = documentQDFCategory {
                                let distanceCategoryAbbreviatedLabel = UncertaintyStatistics.getDistanceCategoryLabel(distanceCategory: docQDFCategory.distanceCategory, abbreviated: true)
                                
                                Text("\(distanceCategoryAbbreviatedLabel):")
                                    .modifier(CategoryLabelInLineSmallerViewModifier())
                                    .foregroundStyle(.gray)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)
                            } else {
                                // blank when there is no document selected
                                Text((documentObject != nil && inferenceHasBeenRun) ? "OOD:" : "")
                                    .modifier(CategoryLabelInLineSmallerViewModifier())
                                    .foregroundStyle(.gray)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)
                            }
                            if let docObj = documentObject, let uncertainty = docObj.uncertainty {
                                Text(String(uncertainty.d0))
                                    .monospaced()
                                    .font(.title3)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)
                            } else {
                                Text("")
                                    .monospaced()
                                    .font(.title3)
                            }
                            Spacer()
                        }
                    }
                    .frame(minHeight: 20, maxHeight: 20)
                    .padding()
                    .modifier(PrimaryComponentsViewModifier(useReBackgroundDarker: false, viewBoxScaling: 8))
                    .onTapGesture {
                        isShowingHeadsUpDisplayForDistance.toggle()
                    }
                }
                .padding([.leading]) //, .trailing])
                VStack {
                    HStack {
                        if let docObj = documentObject, let _ = docObj.uncertainty?.softmax?.toArray(type: Float32.self) {
                            Image(systemName: "chart.bar.doc.horizontal")
                                .font(.title3)
                                .foregroundStyle(.blue.gradient)
                        }
                        Text(REConstants.CategoryDisplayLabels.fFull)
                            .font(.title3)
                            .foregroundStyle(.gray)
                            .help(REConstants.CategoryDisplayLabels.fFull)
                        PopoverViewWithButton(isShowingInfoPopover: $isShowingfInfoPopover, popoverViewText: REConstants.HelpAssistanceInfo.fInfoString, optionalSubText: REConstants.HelpAssistanceInfo.qdfInfoString)
                        Spacer()
                    }
                    .onTapGesture {
                        isShowingHeadsUpDisplayForFMagnitude.toggle()
                    }
                    .popover(isPresented: $isShowingHeadsUpDisplayForFMagnitude, arrowEdge: .top) {
                        if documentObject?.uncertainty != nil {
                            FMagnitudeWithThresholdsView(documentObject: $documentObject)
                                .frame(width: 800)
                        }
                    }
                    
                    VStack {
                        HStack {
                            if let docQDFCategory = documentQDFCategory {
                                let compositionCategoryAbbreviatedLabel = UncertaintyStatistics.getCompositionCategoryLabel(compositionCategory: docQDFCategory.compositionCategory, abbreviated: true)
                                
                                Text("\(compositionCategoryAbbreviatedLabel):")
                                    .modifier(CategoryLabelInLineSmallerViewModifier())
                                    .foregroundStyle(.gray)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)
                            } else {
                                // blank when there is no document selected
                                Text((documentObject != nil && inferenceHasBeenRun) ? "OOD" : "")
                                    .modifier(CategoryLabelInLineSmallerViewModifier())
                                    .foregroundStyle(.gray)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)
                            }
                                Text(f_of_x_argmax_formatted)
                                    .monospaced()
                                    .font(.title3)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)
                            //}
                            Spacer()
                        }
                    }
                    .frame(minHeight: 20, maxHeight: 20)
                    .padding()
                    .modifier(PrimaryComponentsViewModifier(useReBackgroundDarker: false, viewBoxScaling: 8))
                    .onTapGesture {
                        isShowingHeadsUpDisplayForFMagnitude.toggle()
                    }
                }
                .padding([.leading])
                
            }
            //.padding(.bottom)
        }
        .frame(minHeight: 180, maxHeight: 180)
        .padding()
        .modifier(PrimaryComponentsViewModifier(useReBackgroundDarker: false))
        .padding([.leading, .trailing])
    }
}

