//
//  ProbabilityHeadsUpView.swift
//  Alpha1
//
//  Created by A on 8/13/23.
//

import SwiftUI
import Charts
import CoreData


struct ProbabilityHeadsUpView: View {
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var dataController: DataController
        
    @Binding var documentObject: Document?
    
    let categoryColorOpacity: Double = 0.5
    let categoryLabelColorOpacity: Double = 0.75
    
    @State private var isShowingInfoForCalibrationReliability: Bool = false
    
    @State var rawSelectedStringLabel: String?
    @AppStorage(REConstants.UserDefaults.statsFontSizeStringKey) var statsFontSize: Double = Double(REConstants.UserDefaults.defaultStatsFontSize)
    
    struct FSoftmaxCalibrated {
        let id: String = UUID().uuidString
        let label: Int
        let f_x: Float32
        var labelAsString: String {
            return String(label)
        }
        let isCalibrated: Bool
        var isCalibratedPlottable: String {
            return String(isCalibrated)
        }
    }
        
    var outputData: [FSoftmaxCalibrated] {
        var data: [FSoftmaxCalibrated] = []
        if let docObj = documentObject, let qdfCategory = documentQDFCategory, let calibratedOutput = dataController.uncertaintyStatistics?.vennADMITCategory_To_CalibratedOutput[qdfCategory], let minDistribution = calibratedOutput?.minDistribution, docObj.prediction < minDistribution.count, let uncertainty = docObj.uncertainty, let softmax = uncertainty.softmax?.toArray(type: Float32.self), docObj.prediction < softmax.count {
            for label in 0..<dataController.numberOfClasses {
                // Calibrated always appears first
                data.append(.init(label: label, f_x: minDistribution[label], isCalibrated: true))
                data.append(.init(label: label, f_x: softmax[label], isCalibrated: false))
            }
            
        }
        return data
    }

    var documentQDFCategory: UncertaintyStatistics.QDFCategory? {
        if let docObj = documentObject, docObj.uncertainty?.uncertaintyModelUUID != nil, let qdfCategoryID = docObj.uncertainty?.qdfCategoryID {
            return UncertaintyStatistics.QDFCategory.initQDFCategoryFromIdString(idString: qdfCategoryID)
        }
        return nil
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
    
    let barOpacity: Double = 0.5
    
    var body: some View {
        ScrollView {
            HStack {
                Text("Calibrated Probability")
                    .font(.title2)
                Spacer()
                SimpleCloseButton()
            }
            if outputData.count > 0 {
            VStack(alignment: .leading) {
                HStack {
                    BasicChartSymbolShape.square
                        .foregroundStyle(.brown.gradient)
                        .frame(width: 16, height: 16)
                        .opacity(categoryColorOpacity)
                    Text("Calibrated")
                        .foregroundStyle(.gray)
                    Spacer()
                }
                HStack {
                    BasicChartSymbolShape.square
                        .foregroundStyle(.blue.gradient)
                        .frame(width: 16, height: 16)
                        .opacity(categoryColorOpacity)
                    Text("Uncalibrated f(x)")
                        .foregroundStyle(.gray)
                    Spacer()
                }
            }
            .font(REConstants.Visualization.xAndYAxisFont)
            .padding([.leading, .trailing])
            
            
                Chart(outputData, id:\.id) { f_element in
                    if f_element.isCalibrated {
                        BarMark(
                            x: .value("Label", f_element.labelAsString),
                            y: .value("f_x", f_element.f_x)
                        )
                        .position(by: .value("Calibration Status", f_element.isCalibratedPlottable))
                        .foregroundStyle(
                            Color.brown.gradient
                                .opacity(
                                    rawSelectedStringLabel != nil ? (rawSelectedStringLabel == f_element.labelAsString ? barOpacity : barOpacity*0.5) : barOpacity
                                )
                        )
                    } else {
                        BarMark(
                            x: .value("Label", f_element.labelAsString),
                            y: .value("f_x", f_element.f_x)
                        )
                        .position(by: .value("Calibration Status", f_element.isCalibratedPlottable))
                        .foregroundStyle(
                            Color.blue.gradient
                                .opacity(
                                    rawSelectedStringLabel != nil ? (rawSelectedStringLabel == f_element.labelAsString ? barOpacity : barOpacity*0.5) : barOpacity
                                )
                        )
                    }
                    if let rawSelectedStringLabel = rawSelectedStringLabel, rawSelectedStringLabel == f_element.labelAsString {
                        RuleMark(
                            x: .value("Label", rawSelectedStringLabel)
                        )
                        .foregroundStyle(Color.gray.opacity(0.0))
                        .offset(yStart: 0)
                        .zIndex(-1)
                        .annotation(
                            position: .top, spacing: 0,
                            overflowResolution: .init(
                                x: .fit(to: .chart),
                                y: .disabled
                            )
                        ) {
                            if rawSelectedStringLabel == f_element.labelAsString {
                                VStack {
                                    Grid(verticalSpacing: REConstants.Visualization.popoverQuickViewGrid_VerticalSpacing) {
                                        GridRow {
                                            Text(REConstants.CategoryDisplayLabels.classLabelAxisLabel+":")
                                                .foregroundStyle(.gray)
                                                .gridColumnAlignment(.trailing)
                                            if let predictionDisplayName = dataController.labelToName[f_element.label] {
                                                Text(predictionDisplayName.truncateUpToMaxWithEllipsis(maxLength: 25))
                                                    .monospaced()
                                            } else {
                                                Text(String(f_element.label))
                                                    .monospaced()
                                            }
                                        }
                                    }
                                }
                                .font(.system(size: statsFontSize))
                                .padding()
                                .modifier(SimpleBaseBorderModifierWithColorOption())
                            }
                        }
                    }
                }
                .chartXSelection(value: $rawSelectedStringLabel)
                .chartXAxisLabel(position: .bottom, alignment: .center) {
                    Text(REConstants.CategoryDisplayLabels.classLabelAxisLabel)
                        .font(REConstants.Visualization.xAndYAxisFont)
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartYAxisLabel(position: .leading, alignment: .center) {
                    Text("(")
                        .tracking(2) +
                    Text("x")
                        .tracking(2)
                        .baselineOffset(1.0) +
                    Text(")")
                        .tracking(2) +
                    Text("ɟ")
                        .font(.custom(
                            "AmericanTypewriter",
                            fixedSize: 16))
                }
                .frame(height: 400)
                .padding()
            
                if let docQDFCategory = documentQDFCategory {
                    VStack {
                        HStack {
                            Text("Calibration Reliability")
                                .font(.title2)
                                .foregroundStyle(.gray)
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
                            Image(systemName: reliabilityLabel.reliabilityImageName)
                                .font(.title)
                                .foregroundStyle(reliabilityLabel.reliabilityColorGradient)
                                .opacity(reliabilityLabel.opacity)
                            Text(reliabilityLabel.reliabilityTextCaption)
                                .foregroundStyle(.gray)
                                .font(.title3)
                        }
                        
                        Text("The overall reliability of the calibration process (separate from the probability itself) was determined by membership to the following partitions and the associated partition size in the Calibration Set:")
                            .padding()
                        Grid(horizontalSpacing: 20, verticalSpacing: 20) {
                            GridRow(alignment: .top) {
                                Text(REConstants.CategoryDisplayLabels.qFull)
                                    .foregroundStyle(.gray)
                                    .gridColumnAlignment(.trailing)
                                Text(UncertaintyStatistics.getQCategoryLabel(qCategory: docQDFCategory.qCategory))
                                    .modifier(CategoryLabelViewModifier())
                                    .gridColumnAlignment(.leading)
                            }
                            GridRow(alignment: .top) {
                                Text(REConstants.CategoryDisplayLabels.dFull)
                                    .foregroundStyle(.gray)
                                Text(UncertaintyStatistics.getDistanceCategoryLabel(distanceCategory: docQDFCategory.distanceCategory, abbreviated: true))
                                    .modifier(CategoryLabelViewModifier())
                                
                            }
                            GridRow(alignment: .top) {
                                Text(REConstants.CategoryDisplayLabels.fFull)
                                    .foregroundStyle(.gray)
                                Text(UncertaintyStatistics.getCompositionCategoryLabel(compositionCategory: docQDFCategory.compositionCategory, abbreviated: true))
                                    .modifier(CategoryLabelViewModifier())
                                
                            }
                            GridRow(alignment: .top) {
                                Text(REConstants.CategoryDisplayLabels.sizeFull)
                                    .foregroundStyle(.gray)
                                Text(String(partitionSize))
                                    .modifier(CategoryLabelViewModifier())
                                
                            }
                        }
                        .padding()
                        .modifier(SimpleBaseBorderModifier())
                        .padding()
                    }
                    .font(REConstants.Fonts.baseFont)
                    .padding()
                    .modifier(SimpleBaseBorderModifier())
                    .padding()
                }
            } else {
                Text("Additional data is needed in order to estimate a calibrated probability.")
                    .italic()
                    .font(REConstants.Fonts.baseFont)
                    .foregroundStyle(.gray)
                    .padding()
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .padding()
        .modifier(SimpleBaseBorderModifier())
        .padding()
    }
}

