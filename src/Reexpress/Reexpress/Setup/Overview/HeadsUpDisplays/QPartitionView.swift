//
//  QPartitionView.swift
//  Alpha1
//
//  Created by A on 8/13/23.
//

import SwiftUI
import Charts
import CoreData

struct QPartitionView: View {
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
    
    var body: some View {
        ScrollView {
            HStack {
                Text(REConstants.CategoryDisplayLabels.qFull)
                    .font(.title2)
                Divider()
                    .frame(width: 2, height: 25)
                    .overlay(.gray)
                
                HStack {
                    if let qCategoryLabel = qCategoryLabel {
                        Text(qCategoryLabel)
                            .modifier(CategoryLabelViewModifier())
                    } else {
                        // blank when there is no document selected
                        Text(documentObject != nil ? "" : "")
                            .modifier(CategoryLabelViewModifier())
                    }
                }
                Spacer()
                SimpleCloseButton()
            }
            HStack {
                Grid {
                    GridRow {
                        Text("This document's \(REConstants.CategoryDisplayLabels.qFull):")
                            .foregroundStyle(.gray)
                            .gridColumnAlignment(.trailing)
                        if let q = q {
                            Text(String(q))
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
                }
                .font(Font.system(size: 14))
                .padding()
                .modifier(SimpleBaseBorderModifier())
                Spacer()
            }
            .padding([.leading, .trailing])
            
            Chart {
                RectangleMark(
                    xStart: .value("Rect Start Width", -0.25),
                    xEnd: .value("Rect End Width", 0.25),
                    yStart: .value("Rect Start Height", REConstants.Uncertainty.defaultQMax),
                    yEnd: .value("Rect End Height", REConstants.Uncertainty.maxQAvailableFromIndexer)
                )
                .foregroundStyle(
                    REConstants.REColors.reLabelGreenLighter.gradient
                        .opacity(distanceCategoryColorOpacity)
                )
                .annotation(position: .leading) { //, alignment: .center) {
                    HStack {
                        Text(UncertaintyStatistics.getQCategoryLabel(qCategory: .qMax))
                            .modifier(CategoryLabelViewModifier())
                            .foregroundStyle(
                                REConstants.REColors.reLabelGreenLighter
                                    .opacity(categoryLabelColorOpacity)
                            )
                        Spacer()
                    }
                    .frame(width: 125)
                }
                
                RectangleMark(
                    xStart: .value("Rect Start Width", -0.25),
                    xEnd: .value("Rect End Width", 0.25),
                    yStart: .value("Rect Start Height", 0),
                    yEnd: .value("Rect End Height", REConstants.Uncertainty.defaultQMax)
                )
                .foregroundStyle(
                    REConstants.Visualization.medianDistanceLineD0Color
                        .opacity(distanceCategoryColorOpacity)
                )
                .annotation(position: .leading) { //, alignment: .center) {
                    HStack {
                        Text(UncertaintyStatistics.getQCategoryLabel(qCategory: .oneToQMax))
                            .modifier(CategoryLabelViewModifier())
                            .foregroundStyle(
                                REConstants.Visualization.medianDistanceLineD0Color
                                    .opacity(categoryLabelColorOpacity)
                            )
                        Spacer()
                    }
                    .frame(width: 125)
                }
                RuleMark(
                    xStart: .value("Rect Start Width", -1.0),
                    xEnd: .value("Rect End Width", 1.0),
                    y: .value("Label", 0)
                )
                .lineStyle(StrokeStyle(lineWidth: 4))
                .foregroundStyle(
                    .red.gradient
                        .opacity(distanceCategoryColorOpacity)
                )
                
                .annotation(position: .leading) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(UncertaintyStatistics.getQCategoryLabel(qCategory: .zero))
                                .modifier(CategoryLabelViewModifier())
                            Text("(q=0)")
                                .font(.title3)
                                .monospaced()
                        }
                        .foregroundStyle(
                            .red
                                .opacity(categoryLabelColorOpacity)
                        )
                        
                        Spacer()
                    }
                    .frame(width: 105)
                }
                
                // This is the distance line for the document itself.
                if let q = q {
                    RuleMark(
                        xStart: .value("Label", -0.4),
                        xEnd: .value("Label", 0.4),
                        y: .value("Distance", q)
                    )
                    .lineStyle(StrokeStyle(lineWidth: 4))
                    .foregroundStyle(
                        .white.gradient
                    )
                }
            }
            .chartYAxisLabel(position: .trailing, alignment: .center) {
                Text(REConstants.CategoryDisplayLabels.qFull)
                    .font(REConstants.Visualization.xAndYAxisFont)
            }
            .chartXAxis(.hidden)
            .chartXScale(domain: -1...1, range: .plotDimension(startPadding: 20, endPadding: 20))
            .chartYScale(domain: 0...100, range: .plotDimension(startPadding: 20, endPadding: 20))
            .frame(width: 150, height: 350)
            .padding()
            
            VStack {
                HStack {
                    Text("Details")
                        .font(.title2)
                        .foregroundStyle(.gray)
                    Spacer()
                }
                Text("The \(REConstants.CategoryDisplayLabels.qFull) is calculated as the number of consecutive nearest Training Set documents that are true-positive predictions with the same predicted label as the document being matched. We characterize the resulting q partition as follows:")
                    .padding()
                HStack {
                    Grid(horizontalSpacing: 20, verticalSpacing: 20) {
                        GridRow(alignment: .top) {
                            Text(UncertaintyStatistics.getQCategoryLabel(qCategory: .qMax))
                                .modifier(CategoryLabelViewModifier())
                                .gridColumnAlignment(.trailing)
                            Text("q ∈ {\(REConstants.Uncertainty.defaultQMax),...,\(REConstants.Uncertainty.maxQAvailableFromIndexer)} ") //[\(REConstants.Uncertainty.defaultQMax), \(REConstants.Uncertainty.maxQAvailableFromIndexer)]")
                                .monospaced()
                                .foregroundStyle(.gray)
                                .gridColumnAlignment(.leading)
                        }
                        GridRow(alignment: .top) {
                            Text(UncertaintyStatistics.getQCategoryLabel(qCategory: .oneToQMax))
                                .modifier(CategoryLabelViewModifier())
                                .gridColumnAlignment(.trailing)
                            Text("q ∈ {1,...,\(REConstants.Uncertainty.defaultQMax-1)}") //[1, \(REConstants.Uncertainty.defaultQMax))")
                                .monospaced()
                                .foregroundStyle(.gray)
                        }
                        GridRow(alignment: .top) {
                            Text(UncertaintyStatistics.getQCategoryLabel(qCategory: .zero))
                                .modifier(CategoryLabelViewModifier())
                            Text("q = 0")
                                .monospaced()
                                .foregroundStyle(.gray)
                        }
                    }
                    Spacer()
                }
                    .frame(maxWidth: .infinity)
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


