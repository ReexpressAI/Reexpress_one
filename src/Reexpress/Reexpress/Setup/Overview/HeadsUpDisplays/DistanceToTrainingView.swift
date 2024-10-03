//
//  DistanceToTrainingView.swift
//  Alpha1
//
//  Created by A on 8/12/23.
//

import SwiftUI
import Charts
import CoreData


struct DistanceToTrainingView: View {
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var dataController: DataController
    
    @Binding var documentObject: Document?
    
    let distanceCategoryColorOpacity: Double = 0.5
    let categoryLabelColorOpacity: Double = 0.75
    
    var documentQDFCategory: UncertaintyStatistics.QDFCategory? {
        if let docObj = documentObject, docObj.uncertainty?.uncertaintyModelUUID != nil, let qdfCategoryID = docObj.uncertainty?.qdfCategoryID {
            return UncertaintyStatistics.QDFCategory.initQDFCategoryFromIdString(idString: qdfCategoryID)
        }
        return nil
    }
    
    var d0Stats: (median: Float32, max: Float32)? {
        if let docObj = documentObject, DataController.isKnownValidLabel(label: docObj.prediction, numberOfClasses: dataController.numberOfClasses), let docQDFCategory = documentQDFCategory {
            return dataController.uncertaintyStatistics?.trueClass_To_QToD0Statistics[docObj.prediction]?[docQDFCategory.qCategory]
        }
        return nil
    }
    
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
    
    var predictedClassString: String {
        if let docObj = documentObject, DataController.isKnownValidLabel(label: docObj.prediction, numberOfClasses: dataController.numberOfClasses) {
            return String(docObj.prediction)
        }
        return "N/A"
    }
    var qCategoryCharacterizationText: Text {
        return Text("Given the \(REConstants.CategoryDisplayLabels.qFull) is \(Text(qCategoryLabel ?? "N/A").font(Font.system(size: 14).smallCaps().bold())) and the predicted class is \(predictedClassString)").italic()
    }
    
    var body: some View {
        ScrollView {
            HStack {
                Text(REConstants.CategoryDisplayLabels.dFull)
                    .font(.title2)
                Divider()
                    .frame(width: 2, height: 25)
                    .overlay(.gray)
                
                HStack {
                    if let docQDFCategory = documentQDFCategory {
                        let distanceCategoryAbbreviatedLabel = UncertaintyStatistics.getDistanceCategoryLabel(distanceCategory: docQDFCategory.distanceCategory, abbreviated: true)
                        Text("\(distanceCategoryAbbreviatedLabel)")
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
                        Text("This document's \(REConstants.CategoryDisplayLabels.dFull):")
                            .foregroundStyle(.gray)
                            .gridColumnAlignment(.trailing)
                        if let docObj = documentObject, let uncertainty = docObj.uncertainty {
                            Text(String(uncertainty.d0))
                                .monospaced()
                                .gridColumnAlignment(.leading)
                        } else {
                            Text("Unavailable")
                                .gridColumnAlignment(.leading)
                        }
                        TrainingProcessLine()
                            .stroke(style: StrokeStyle(lineWidth: 4))
                            .frame(width: 100, height: 1)
                            .foregroundStyle(
                                .white.gradient
                            )
                            .padding()
                            .gridColumnAlignment(.leading)
                    }
                    GridRow {
                        Divider()
                            .gridCellColumns(3)
                            .gridCellUnsizedAxes([.vertical, .horizontal])
                    }
                    GridRow {
                        Text("\(qCategoryCharacterizationText):")
                            .foregroundStyle(.gray)
                            .gridCellColumns(3)
                    }
                    GridRow {
                        Text("Median true-positive distance (𝜏)")
                            .foregroundStyle(.gray)
                        if let median = d0Stats?.median {
                            Text(String(median))
                                .monospaced()
                        } else {
                            Text("Unavailable")
                                .gridColumnAlignment(.leading)
                        }
                        TrainingProcessLine()
                            .stroke(style: StrokeStyle(lineWidth: 2, dash: [5, 10]))
                            .frame(width: 100, height: 1)
                            .foregroundStyle(
                                REConstants.Visualization.medianDistanceLineD0Color
                            )
                            .padding()
                    }
                    GridRow {
                        Text("OOD limit distance (𝜙)")
                            .foregroundStyle(.gray)
                        if let max = d0Stats?.max {
                            Text(String(max))
                                .monospaced()
                        } else {
                            Text("Unavailable")
                                .gridColumnAlignment(.leading)
                        }
                        TrainingProcessLine()
                            .stroke(style: StrokeStyle(lineWidth: 2, dash: [2, 4]))
                            .frame(width: 100, height: 1)
                            .foregroundStyle(
                                REConstants.Visualization.oodDistanceLineD0Color
                            )
                            .padding()
                    }
                }
                .font(Font.system(size: 14))
                .padding()
                .modifier(SimpleBaseBorderModifier())
                Spacer()
            }
            .padding([.leading, .trailing])
            
            if let docObj = documentObject, let uncertainty = docObj.uncertainty {
                Chart {
                    if DataController.isKnownValidLabel(label: docObj.prediction, numberOfClasses: dataController.numberOfClasses), let docQDFCategory = documentQDFCategory, let d0Stats = dataController.uncertaintyStatistics?.trueClass_To_QToD0Statistics[docObj.prediction]?[docQDFCategory.qCategory] {
                        
                        RectangleMark(
                            xStart: .value("Rect Start Width", 0.0),
                            xEnd: .value("Rect End Width", d0Stats.median),
                            yStart: .value("Rect Start Height", -0.25),
                            yEnd: .value("Rect End Height", 0.25)
                        )
                        .foregroundStyle(
                            REConstants.REColors.reLabelGreenLighter.gradient
                                .opacity(distanceCategoryColorOpacity)
                        )
                        .annotation {
                            VStack {
                                Text(UncertaintyStatistics.getDistanceCategoryLabel(distanceCategory: .lessThanOrEqualToMedian, abbreviated: true))
                                    .modifier(CategoryLabelViewModifier())
                                    .foregroundStyle(
                                        REConstants.REColors.reLabelGreenLighter
                                            .opacity(categoryLabelColorOpacity)
                                    )
                                Text("")
                                    .modifier(CategoryLabelViewModifier())
                                Text("")
                                    .modifier(CategoryLabelViewModifier())
                            }
                        }
                        RectangleMark(
                            xStart: .value("Rect Start Width", d0Stats.median),
                            xEnd: .value("Rect End Width", d0Stats.max),
                            yStart: .value("Rect Start Height", -0.25),
                            yEnd: .value("Rect End Height", 0.25)
                        )
                        .foregroundStyle(
                            REConstants.Visualization.medianDistanceLineD0Color
                                .opacity(distanceCategoryColorOpacity)
                        )
                        .annotation {
                            VStack {
                                Text(UncertaintyStatistics.getDistanceCategoryLabel(distanceCategory: .greaterThanMedianAndLessThanOrEqualToOOD, abbreviated: true))
                                    .modifier(CategoryLabelViewModifier())
                                    .foregroundStyle(
                                        REConstants.Visualization.medianDistanceLineD0Color
                                            .opacity(categoryLabelColorOpacity)
                                    )
                                Text("")
                                    .modifier(CategoryLabelViewModifier())
                                Text("")
                                    .modifier(CategoryLabelViewModifier())
                            }
                        }
                        
                        /* This could be confusing, as it suggests a max distance that doesn't exist, so we do not show a box for OOD (note opacity 0) and only use the label.*/
                        RectangleMark(
                            xStart: .value("Rect Start Width", d0Stats.max),
                            xEnd: .value("Rect End Width", max(uncertainty.d0, d0Stats.max+d0Stats.median)),
                            yStart: .value("Rect Start Height", -0.25),
                            yEnd: .value("Rect End Height", 0.25)
                        )
                        .foregroundStyle(
                            REConstants.Visualization.oodDistanceLineD0Color
                                .opacity(0.0)
                        )
                        .annotation {
                            VStack {
                                HStack {
                                    Text(UncertaintyStatistics.getDistanceCategoryLabel(distanceCategory: .greaterThanOOD, abbreviated: true))
                                        .foregroundStyle(
                                            REConstants.Visualization.oodDistanceLineD0Color
                                                .opacity(categoryLabelColorOpacity))
                                        .modifier(CategoryLabelViewModifier())
                                    Image(systemName: "arrow.right")
                                        .foregroundStyle(
                                            REConstants.Visualization.oodDistanceLineD0Color
                                        )
                                }
                                Text("")
                                    .modifier(CategoryLabelViewModifier())
                                Text("")
                                    .modifier(CategoryLabelViewModifier())
                            }
                        }
                        
                        RuleMark(
                            x: .value("Distance", d0Stats.median),
                            yStart: .value("Label", -0.75),
                            yEnd: .value("Label", 0.75)
                        )
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 10]))
                        .foregroundStyle(
                            REConstants.Visualization.medianDistanceLineD0Color
                        )
                        RuleMark(
                            x: .value("Distance", d0Stats.max),
                            yStart: .value("Label", -0.75),
                            yEnd: .value("Label", 0.75)
                        )
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [2, 4]))
                        .foregroundStyle(
                            REConstants.Visualization.oodDistanceLineD0Color
                        )
                        
                    }
                    // This is the distance line for the document itself.
                    RuleMark(
                        x: .value("Distance", uncertainty.d0),
                        yStart: .value("Label", -0.4),
                        yEnd: .value("Label", 0.4)
                    )
                    .lineStyle(StrokeStyle(lineWidth: 4))
                    .foregroundStyle(
                        .white.gradient
                    )
                    
                }
                .chartXAxisLabel(position: .bottom, alignment: .center) {
                    Text("L\u{00B2} Distance to Training")
                        .font(REConstants.Visualization.xAndYAxisFont)
                }
                .chartYAxis(.hidden)
                
                .frame(height: 250)
                .padding()
            }
            VStack {
                HStack {
                    Text("Details")
                        .font(.title2)
                        .foregroundStyle(.gray)
                    Spacer()
                }
                Text("The L\u{00B2} distance to the Training Set is partitioned based on the distances of the true-positive documents in the corresponding \(REConstants.CategoryDisplayLabels.qFull) partition of the Calibration Set for the predicted class. We characterize the distances as follows:")
                    .padding()
                
                Grid(horizontalSpacing: 20, verticalSpacing: 20) {
                    GridRow(alignment: .top) {
                        Text(UncertaintyStatistics.getDistanceCategoryLabel(distanceCategory: .lessThanOrEqualToMedian, abbreviated: true))
                            .modifier(CategoryLabelViewModifier())
                            .gridColumnAlignment(.trailing)
                        VStack { //}(spacing: 0) {
                            HStack {
                                Text("0 ≤ d ≤ 𝜏,")
                                    //.monospaced()
                                Spacer()
                            }
                            HStack {
                                Text("    ")
                                Text("where 𝜏 is the median distance of the true-positve predictions for this predicted class and q partition in the Calibration Set.")
                            }
                            //Text("The document's distance is greater than or equal to 0 (an exact match to training) and less than or equal to the median distance of the true-positve predictions for this predicted class and q partition in the Calibration Set.")
                                //.foregroundStyle(.gray)
                        }
                        .foregroundStyle(.gray)
                            .gridColumnAlignment(.leading)
                    }
                    GridRow(alignment: .top) {
                        Text(UncertaintyStatistics.getDistanceCategoryLabel(distanceCategory: .greaterThanMedianAndLessThanOrEqualToOOD, abbreviated: true))
                            .modifier(CategoryLabelViewModifier())
                            .gridColumnAlignment(.trailing)
                        
                        VStack {
                            HStack {
                                Text("𝜏 < d ≤ 𝜙,")
                                    //.monospaced()
                                Spacer()
                            }
                            HStack {
                                Text("    ")
                                Text("where 𝜙 is the maximum distance observed among the true-positve predictions for this predicted class and q partition in the Calibration Set.")
                            }
                        }
                        .foregroundStyle(.gray)
                            .gridColumnAlignment(.leading)
//                        Text("The document's distance is greater than the median distance and less than or equal to the maximum distance observed among the true-positve predictions for this predicted class and q partition in the Calibration Set.")
//                            .foregroundStyle(.gray)
                    }
                    GridRow(alignment: .top) {
                        Text(UncertaintyStatistics.getDistanceCategoryLabel(distanceCategory: .greaterThanOOD, abbreviated: true))
                            .modifier(CategoryLabelViewModifier())
                        VStack {
                            HStack {
                                Text("𝜙 < d.")
                                    //.monospaced()
                                Spacer()
                            }
                            HStack {
                                Text("    ")
                                Text("*We also assign this label in the event there are no documents in the q partition of the Calibration Set.*")
                            }
                        }
                        .foregroundStyle(.gray)
                            .gridColumnAlignment(.leading)
//                        Text("The document's distance is greater than the maximum distance observed among the true-positve predictions for this predicted class and q partition in the Calibration Set. In the event there are no documents in the q partition of the Calibration Set, we also assign this label.")
//                            .foregroundStyle(.gray)
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


