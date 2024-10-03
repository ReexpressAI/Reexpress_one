//
//  FMagnitudeWithThresholdsView.swift
//  Alpha1
//
//  Created by A on 8/12/23.
//

import SwiftUI
import Charts
import CoreData


struct FMagnitudeWithThresholdsView: View {
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var dataController: DataController
        
    @Binding var documentObject: Document?
    
    @State var rawSelectedStringLabel: String?
    @AppStorage(REConstants.UserDefaults.statsFontSizeStringKey) var statsFontSize: Double = Double(REConstants.UserDefaults.defaultStatsFontSize)
    
    var thresholds: [Float32]? {
        if let docObj = documentObject, let uncertainty = docObj.uncertainty {
            
            if let qCategory = dataController.uncertaintyStatistics?.getQCategory(q: uncertainty.q), let softmaxThresholds = dataController.uncertaintyStatistics?.qCategory_To_Thresholds[qCategory] {
                return softmaxThresholds
            }
        }
        return nil
    }
    
    struct FSoftmax {
        let label: Int
        let f_x: Float32
        var labelAsString: String {
            return String(label)
        }
    }
    
    var outputData: [FSoftmax] {
        var data: [FSoftmax] = []
        if let docObj = documentObject, let uncertainty = docObj.uncertainty, let softmax = uncertainty.softmax?.toArray(type: Float32.self) {
            for label in 0..<dataController.numberOfClasses {
                if label < softmax.count {
                    let f_x = softmax[label]
                    
                    data.append(.init(label: label, f_x: f_x))
                } else {
                    data.append(.init(label: label, f_x: 0.0))
                }
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
    let barOpacity: Double = 0.5
    
    var q: Int? {
        if let docObj = documentObject, let uncertainty = docObj.uncertainty {
            return uncertainty.q
        }
        return nil
    }
    
    var qCategoryLabel: String? {
        if let q = q, let qCategory = dataController.uncertaintyStatistics?.getQCategory(q: q) {
            return UncertaintyStatistics.getQCategoryLabel(qCategory: qCategory)
        }
        return nil
    }
    
    var qCategoryCharacterizationText: Text {
        return Text("given the \(REConstants.CategoryDisplayLabels.qFull) is \(Text(qCategoryLabel ?? "N/A").font(Font.system(size: 14).smallCaps().bold()))").italic()
    }
    var body: some View {
        ScrollView {
            HStack {
                Text(REConstants.CategoryDisplayLabels.fFull)
                    .font(.title2)
                Divider()
                    .frame(width: 2, height: 25)
                    .overlay(.gray)
                
                HStack {
                    if let docQDFCategory = documentQDFCategory {
                        let compositionCategoryAbbreviatedLabel = UncertaintyStatistics.getCompositionCategoryLabel(compositionCategory: docQDFCategory.compositionCategory, abbreviated: false)
                        
                        Text("\(compositionCategoryAbbreviatedLabel)")
                            .modifier(CategoryLabelViewModifier())
                    } else {
                        // blank when there is no document selected
                        Text(documentObject != nil ? "OOD" : "")
                            .modifier(CategoryLabelViewModifier())
                    }
                }
                Spacer()
                SimpleCloseButton()
            }

            HStack {
                Grid {
                    GridRow {
                        Text("Per-class output threshold [\(qCategoryCharacterizationText)]")
                            .foregroundStyle(.gray)
                            .gridColumnAlignment(.trailing)
                        TrainingProcessLine()
                            .stroke(style: StrokeStyle(lineWidth: 2, dash: [5, 10]))
                            .frame(width: 100, height: 1)
                            .foregroundStyle(
                                REConstants.Visualization.compositionThresholdLineColor
                            )
                            .padding()
                            .gridColumnAlignment(.leading)
                    }
                }
                .font(Font.system(size: 14))
                .padding()
                .modifier(SimpleBaseBorderModifier())
                Spacer()
            }
            .padding([.leading, .trailing])
            Chart(outputData, id:\.label) { f_element in
                BarMark(
                    x: .value("Label", f_element.labelAsString),
                    y: .value("Softmax", f_element.f_x)
                )
                .foregroundStyle(
                    Color.blue.gradient
                        .opacity(
                            rawSelectedStringLabel != nil ? (rawSelectedStringLabel == f_element.labelAsString ? barOpacity : barOpacity*0.5) : barOpacity
                        )
                )
                if let thresholds = thresholds, f_element.label < thresholds.count {
                    RuleMark(
                        xStart: .value("Label", f_element.labelAsString),
                        xEnd: .value("Label", f_element.labelAsString),
                        y: .value("Softmax", thresholds[f_element.label])
                    )
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 10]))
                    .foregroundStyle(
                        REConstants.Visualization.compositionThresholdLineColor
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
                                    
                                    GridRow {
                                        Text("Uncalibrated f(\(f_element.labelAsString)):")
                                            .foregroundStyle(.gray)
                                        Text("\(f_element.f_x)")
                                            .gridColumnAlignment(.leading)
                                            .monospaced()
                                    }
                                    
                                    GridRow {
                                        Text("Class \(f_element.labelAsString) threshold:")
                                            .foregroundStyle(.gray)
                                        if let thresholds = thresholds, f_element.label < thresholds.count {
                                            Text("\(thresholds[f_element.label])")
                                                .monospaced()
                                                .foregroundStyle(
                                                    REConstants.Visualization.compositionThresholdLineColor
                                                )
                                        } else {
                                            Text("N/A")
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
//            .chartYScale(domain: 0...1.0, range: .plotDimension(startPadding: 20, endPadding: 20))
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
            //.chartLegend(position: .top)
            .padding()
            
            VStack {
                HStack {
                    Text("Details")
                        .font(.title2)
                        .foregroundStyle(.gray)
                    Spacer()
                }
                Text("The uncalibrated output of the model is partitioned using thresholds at the 0.05 quantile of the per-class CDF of the documents in the corresponding \(REConstants.CategoryDisplayLabels.qFull) partition of the Calibration Set. We characterize the magnitude of f(x) via the resulting sets as follows:")
                    .padding()
                Grid(horizontalSpacing: 20, verticalSpacing: 20) {
                    GridRow(alignment: .top) {
                        Text(UncertaintyStatistics.getCompositionCategoryLabel(compositionCategory: .singleton, abbreviated: false))
                            .modifier(CategoryLabelViewModifier())
                            .gridColumnAlignment(.trailing)
                        Text("The thresholded set only includes the model prediction (i.e., the argmax of the output distribution).")
                            .foregroundStyle(.gray)
                            .gridColumnAlignment(.leading)
                    }
                    GridRow(alignment: .top) {
                        Text(UncertaintyStatistics.getCompositionCategoryLabel(compositionCategory: .multiple, abbreviated: false))
                            .modifier(CategoryLabelViewModifier())
                            .gridColumnAlignment(.trailing)
                        Text("The thresholded set includes the model prediction and one or more additional labels.")
                            .foregroundStyle(.gray)
                    }
                    GridRow(alignment: .top) {
                        Text(UncertaintyStatistics.getCompositionCategoryLabel(compositionCategory: .mismatch, abbreviated: false))
                            .modifier(CategoryLabelViewModifier())
                        Text("The thresholded set **does not** include the model prediction, but it does include one or more additional labels.")
                            .foregroundStyle(.gray)
                    }
                    GridRow(alignment: .top) {
                        Text(UncertaintyStatistics.getCompositionCategoryLabel(compositionCategory: .null, abbreviated: false))
                            .modifier(CategoryLabelViewModifier())
                        Text("The thresholded set does not include any labels (i.e., it is an empty set).")
                            .foregroundStyle(.gray)
                    }
                    GridRow(alignment: .top) {
                        Text("OOD")
                            .font(.title2)
                            .italic()
                            .foregroundStyle(.gray)
//                            .monospaced()
                        Text("There are no documents in the \(REConstants.CategoryDisplayLabels.qFull) partition of the Calibration Set, so a threshold cannot be calculated.")
                            .italic()
                            .foregroundStyle(.gray)
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
        .scrollBounceBehavior(.basedOnSize)
        .padding()
        .modifier(SimpleBaseBorderModifier())
        .padding()
    }
}

//struct FMagnitudeWithThresholdsView_Previews: PreviewProvider {
//    static var previews: some View {
//        FMagnitudeWithThresholdsView()
//    }
//}

