//
//  VisualPartitionSelection.swift
//  Alpha1
//
//  Created by A on 8/20/23.
//

import SwiftUI

extension VisualPartitionSelection {
    @MainActor class ViewModel: ObservableObject {
        
        //        var widthReductionFactor: CGFloat {
        //            return 2.0
        //        }
        //@Published var showConfusionMatrixPopover: Bool = false
        
        // -------------------------- New
        //@Published var selectedPredictedLabel: Int? //nil means show all classes
        let predictedLabelsFrameSize = CGSize(width: 900/2.0, height: 700/2.0)
        let predictedLabelsOffsetFrameSize1 = CGSize(width: 30/2.0, height: 30/2.0)
        let predictedLabelsOffsetFrameSize2 = CGSize(width: 60/2.0, height: 60/2.0)
        let predictedLabelsOpacity = 0.7
        let predictedLabelsColorGradient = REConstants.Visualization.predictedLabelsColorGradient
        var predictedLabelsOffset: CGFloat {
            CGFloat( ((predictedLabelsFrameSize.width - compositionCategoryFrameSize.width) / 2) + 100)
        }
        
        //@Published var selectedQCategory: UncertaintyStatistics.QCategory? // = UncertaintyStatistics.QCategory.qMax
        let qCategoryFrameSize = CGSize(width: 740/2.0, height: 500/2.0)
        let qCategoryOffsetFrameSize1 = CGSize(width: 30/2.0, height: 30/2.0)
        let qCategoryOffsetFrameSize2 = CGSize(width: 60/2.0, height: 60/2.0)
        let qCategoryOpacity = 0.7
        let qCategoryOffset = CGSize(width: -40/2.0, height: -60/2.0)
        let qCategoryColorGradient = REConstants.Visualization.qCategoryColorGradient
        var qCategoryLabelOffset: CGFloat {
            CGFloat( ((qCategoryFrameSize.width - compositionCategoryFrameSize.width) / 2) + 60)
        }
        
        //@Published var selectedDistanceCategory: UncertaintyStatistics.DistanceCategory? // = UncertaintyStatistics.DistanceCategory.lessThanOrEqualToMedian
        let distanceCategoryFrameSize = CGSize(width: 580/2.0, height: 310/2.0)  //310
        let distanceCategoryOffsetFrameSize1 = CGSize(width: 30/2.0, height: 30/2.0)
        let distanceCategoryOffsetFrameSize2 = CGSize(width: 60/2.0, height: 60/2.0)
        let distanceCategoryOpacity = 0.6
        let distanceCategoryOffset = CGSize(width: -80/2.0, height: -120/2.0)
        let distanceColorGradient = REConstants.Visualization.distanceColorGradient
        var distanceCategoryLabelOffset: CGFloat {
            CGFloat( ((distanceCategoryFrameSize.width - compositionCategoryFrameSize.width) / 2) + 20)
        }
        
        //@Published var selectedCompositionCategory: UncertaintyStatistics.CompositionCategory?
        let compositionCategoryFrameSize = CGSize(width: 190.0, height: (100-5)/2.0) //(450-20)/2.0, height: (100-5)/2.0) //(130-5)/2.0)
        let compositionCategoryOffsetFrameSize0 = CGSize(width: -30/2.0, height: -30/2.0)
        let compositionCategoryOffsetFrameSize1 = CGSize(width: 30/2.0, height: 30/2.0)
        let compositionCategoryOffsetFrameSize2 = CGSize(width: 60/2.0, height: 60/2.0)
        let compositionCategoryOpacity = 1.0
        let compositionCategoryOffset = CGSize(width: (-100-10)/2.0, height: (-170-5)/2.0+10)
        let compositionColorGradient = REConstants.Visualization.compositionColorGradient
    }
}

struct VisualPartitionSelectionPopoverView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var documentSelectionState: DocumentSelectionState
    var visualPartitionSelectionStratificationType: VisualPartitionSelectionStratificationType = .predictedLabel
    var body: some View {
        VStack {
            VStack {
                switch visualPartitionSelectionStratificationType {
                case .predictedLabel:
                    PredictedClassSelection(documentSelectionState: $documentSelectionState)
                case .qCategory:
                    QSelectionView(documentSelectionState: $documentSelectionState)
                case .distanceCategory:
                    DistanceSelectionView(documentSelectionState: $documentSelectionState)
                case .compositionCategory:
                    CompositionSelectionView(documentSelectionState: $documentSelectionState)
                }
            }
            .padding()
            Grid { //}(alignment: .trailing) {
                GridRow {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(REConstants.Fonts.baseSubheadlineFont)
                        //.frame(width: 100)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    //.padding(EdgeInsets(top: 70, leading: 0, bottom: 50, trailing: 60))
                }
            }
        }
        .padding()
        .modifier(SimpleBaseBorderModifier())
        .padding()
        
    }
}

enum VisualPartitionSelectionStratificationType: Int, CaseIterable {
    case predictedLabel
    case qCategory
    case distanceCategory
    case compositionCategory
}

struct VisualPartitionSelectionLabelView: View {
    @Binding var documentSelectionState: DocumentSelectionState
    var labelString: String {
        switch visualPartitionSelectionStratificationType {
        case .predictedLabel:
            return REConstants.CategoryDisplayLabels.predictedFull
        case .qCategory:
            return REConstants.CategoryDisplayLabels.qFull
        case .distanceCategory:
            return REConstants.CategoryDisplayLabels.dFull
        case .compositionCategory:
            return REConstants.CategoryDisplayLabels.fFull
        }
    }
    var visualPartitionSelectionStratificationType: VisualPartitionSelectionStratificationType = .predictedLabel
    @State private var isShowingSelectionPopover: Bool = false
    var leadingPaddingOnLabel: CGFloat {
        switch visualPartitionSelectionStratificationType {
        case .predictedLabel:
            return 135
        case .qCategory:
            return 35
        case .distanceCategory:
            return 0
        case .compositionCategory:
            return 25
        }
    }
    var body: some View {
        HStack(alignment: .lastTextBaseline) {
            //Spacer()
            Button {
                isShowingSelectionPopover.toggle()
            } label: {
                HStack(alignment: .lastTextBaseline) {
                    Image(systemName: "square.on.square.intersection.dashed")
                        .foregroundStyle(.blue.gradient)
                        .font(.title3)
                    Text(labelString)
                        .font(.title3)
                        .foregroundStyle(.gray)
                }
                .padding(.trailing, leadingPaddingOnLabel)
                .padding(.bottom, visualPartitionSelectionStratificationType == .compositionCategory ? 10 : 0)
            }
            .buttonStyle(.borderless)
            .popover(isPresented: $isShowingSelectionPopover) {
                VisualPartitionSelectionPopoverView(documentSelectionState: $documentSelectionState, visualPartitionSelectionStratificationType: visualPartitionSelectionStratificationType)
            }
        }
        .padding()
    }
}

struct VisualPartitionSelection: View {
    @StateObject var viewModel = ViewModel()
    @Binding var documentSelectionState: DocumentSelectionState
    
    func getQCategoryLineStroke(lineStackId: Int) -> StrokeStyle {
        if lineStackId == 0 {
            if documentSelectionState.qCategories.contains(.qMax) {
                return StrokeStyle(lineWidth: 3)
            } else {
                return StrokeStyle(lineWidth: 2, dash: [5, 10])
            }
        } else if lineStackId == 1 {
            if documentSelectionState.qCategories.contains(.oneToQMax) {
                return StrokeStyle(lineWidth: 3)
            } else {
                return StrokeStyle(lineWidth: 2, dash: [5, 10])
            }
        } else if lineStackId == 2 {
            if documentSelectionState.qCategories.contains(.zero) {
                return StrokeStyle(lineWidth: 3)
            } else {
                return StrokeStyle(lineWidth: 2, dash: [5, 10])
            }
        }
        return StrokeStyle(lineWidth: 0)
    }
    func getDistanceCategoryLineStroke(lineStackId: Int) -> StrokeStyle {
        if lineStackId == 0 {
            if documentSelectionState.distanceCategories.contains(.lessThanOrEqualToMedian) {
                return StrokeStyle(lineWidth: 3)
            } else {
                return StrokeStyle(lineWidth: 2, dash: [5, 10])
            }
        } else if lineStackId == 1 {
            if documentSelectionState.distanceCategories.contains(.greaterThanMedianAndLessThanOrEqualToOOD) {
                return StrokeStyle(lineWidth: 3)
            } else {
                return StrokeStyle(lineWidth: 2, dash: [5, 10])
            }
        } else if lineStackId == 2 {
            if documentSelectionState.distanceCategories.contains(.greaterThanOOD) {
                return StrokeStyle(lineWidth: 3)
            } else {
                return StrokeStyle(lineWidth: 2, dash: [5, 10])
            }
        }
        return StrokeStyle(lineWidth: 0)
    }
    func getCompositionCategoryLineStroke(lineStackId: Int) -> StrokeStyle {
        if lineStackId == 0 {
            if documentSelectionState.compositionCategories.contains(.singleton) {
                return StrokeStyle(lineWidth: 3)
            } else {
                return StrokeStyle(lineWidth: 2, dash: [5, 10])
            }
        } else if lineStackId == 1 {
            if documentSelectionState.compositionCategories.contains(.multiple) {
                return StrokeStyle(lineWidth: 3)
            } else {
                return StrokeStyle(lineWidth: 2, dash: [5, 10])
            }
        } else if lineStackId == 2 {
            if documentSelectionState.compositionCategories.contains(.mismatch) {
                return StrokeStyle(lineWidth: 3)
            } else {
                return StrokeStyle(lineWidth: 2, dash: [5, 10])
            }
        } else if lineStackId == 3 {
            if documentSelectionState.compositionCategories.contains(.null) {
                return StrokeStyle(lineWidth: 3)
            } else {
                return StrokeStyle(lineWidth: 2, dash: [5, 10])
            }
        }
        return StrokeStyle(lineWidth: 0)
    }
    func getPredictedClassesLineStroke(lineStackId: Int) -> StrokeStyle {
        if lineStackId == 0 {
            if documentSelectionState.predictedClasses.contains(0) {
                return StrokeStyle(lineWidth: 3)
            } else {
                return StrokeStyle(lineWidth: 2, dash: [5, 10])
            }
        } else if lineStackId == 1 {
            if documentSelectionState.predictedClasses.contains(1) {
                return StrokeStyle(lineWidth: 3)
            } else {
                return StrokeStyle(lineWidth: 2, dash: [5, 10])
            }
        } else if lineStackId == 2 {
            // here, we show additional classes via width
            if let maxLabel = documentSelectionState.predictedClasses.max(), maxLabel > 1 {
                let maxLabelOffset = min(10, maxLabel)-2
                return StrokeStyle(lineWidth: 3+CGFloat(maxLabelOffset))
            } else {
                return StrokeStyle(lineWidth: 2, dash: [5, 10])
            }
        }
        return StrokeStyle(lineWidth: 0)
    }
    var body: some View {
        VStack(alignment: .leading) {
            
            ZStack {
                
                ZStack {  // Start of CompositionCategory
                    ZStack {
                        Rectangle()
                            .strokeBorder(viewModel.compositionColorGradient, style: getCompositionCategoryLineStroke(lineStackId: 0))
                        //getCompositionCategoryLineStroke(lineStackId: Int)
                        //.strokeBorder(viewModel.compositionColorGradient, style: documentSelectionState.compositionCategories.count != 1 ? StrokeStyle(lineWidth: 2, dash: [5, 10]) : StrokeStyle(lineWidth: 4))
                            .opacity(viewModel.compositionCategoryOpacity)
                            .background(Rectangle().fill(.background))
                            .frame(width: viewModel.compositionCategoryFrameSize.width, height: viewModel.compositionCategoryFrameSize.height)
                            .offset(viewModel.compositionCategoryOffsetFrameSize0)
                            .overlay(
                                VisualPartitionSelectionLabelView(documentSelectionState: $documentSelectionState, visualPartitionSelectionStratificationType: .compositionCategory)
                                , alignment: .bottom)
                    }
                    .zIndex(1)
                    //if documentSelectionState.compositionCategories.count != 1 {
                    Rectangle()
                        .strokeBorder(viewModel.compositionColorGradient, style: getCompositionCategoryLineStroke(lineStackId: 1))
                        .opacity(viewModel.compositionCategoryOpacity)
                        .background(Rectangle().fill(.background))
                        .frame(width: viewModel.compositionCategoryFrameSize.width, height: viewModel.compositionCategoryFrameSize.height)
                    //                            .offset(viewModel.compositionCategoryOffsetFrameSize1)
                        .zIndex(0.75)
                    
                    Rectangle()
                        .strokeBorder(viewModel.compositionColorGradient, style: getCompositionCategoryLineStroke(lineStackId: 2))
                        .opacity(viewModel.compositionCategoryOpacity)
                        .background(Rectangle().fill(.background))
                        .frame(width: viewModel.compositionCategoryFrameSize.width, height: viewModel.compositionCategoryFrameSize.height)
                        .offset(viewModel.compositionCategoryOffsetFrameSize1)
                        .zIndex(0.5)
                    
                    Rectangle()
                        .strokeBorder(viewModel.compositionColorGradient, style: getCompositionCategoryLineStroke(lineStackId: 3))
                        .opacity(viewModel.compositionCategoryOpacity)
                        .background(Rectangle().fill(.background))
                        .frame(width: viewModel.compositionCategoryFrameSize.width, height: viewModel.compositionCategoryFrameSize.height)
                        .offset(viewModel.compositionCategoryOffsetFrameSize2)
                    //}
                }
                .offset(viewModel.compositionCategoryOffset)
                
                .zIndex(0.95)
                // -----------------
                ZStack {  // Start of DistanceCategory
                    ZStack {
                        Rectangle()
                            .strokeBorder(viewModel.distanceColorGradient, style: getDistanceCategoryLineStroke(lineStackId: 0))
                        //                                .strokeBorder(viewModel.distanceColorGradient, style: documentSelectionState.distanceCategories.count != 1 ? StrokeStyle(lineWidth: 2, dash: [5, 10]) : StrokeStyle(lineWidth: 4))
                            .opacity(viewModel.distanceCategoryOpacity)
                            .background(Rectangle().fill(.background))
                            .frame(width: viewModel.distanceCategoryFrameSize.width, height: viewModel.distanceCategoryFrameSize.height)
                            .overlay(
                                VisualPartitionSelectionLabelView(documentSelectionState: $documentSelectionState, visualPartitionSelectionStratificationType: .distanceCategory)
                                //                                    SelectionLabelView(viewModel: viewModel, singleColorGradient: viewModel.distanceColorGradient, stratificaitonType: .distanceCategory)
                                , alignment: .bottom)
                    }
                    .zIndex(1)
                    //if documentSelectionState.distanceCategories.count != 1 {
                    Rectangle()
                        .strokeBorder(viewModel.distanceColorGradient, style: getDistanceCategoryLineStroke(lineStackId: 1))
                    //                                .strokeBorder(viewModel.distanceColorGradient, style: StrokeStyle(lineWidth: 2, dash: [5, 10]))
                        .opacity(viewModel.distanceCategoryOpacity)
                        .background(Rectangle().fill(.background))
                        .frame(width: viewModel.distanceCategoryFrameSize.width, height: viewModel.distanceCategoryFrameSize.height)
                        .offset(viewModel.distanceCategoryOffsetFrameSize1)
                        .zIndex(0.5)
                    
                    Rectangle()
                        .strokeBorder(viewModel.distanceColorGradient, style: getDistanceCategoryLineStroke(lineStackId: 2))
                    //                                .strokeBorder(viewModel.distanceColorGradient, style: StrokeStyle(lineWidth: 2, dash: [5, 10]))
                        .opacity(viewModel.distanceCategoryOpacity)
                        .background(Rectangle().fill(.background))
                        .frame(width: viewModel.distanceCategoryFrameSize.width, height: viewModel.distanceCategoryFrameSize.height)
                        .offset(viewModel.distanceCategoryOffsetFrameSize2)
                    //                        }
                    
                }
                .offset(viewModel.distanceCategoryOffset)
                .zIndex(0.9)
                /// ---------
                ZStack {  // Start of QCategory
                    ZStack {
                        Rectangle()
                            .strokeBorder(viewModel.qCategoryColorGradient, style: getQCategoryLineStroke(lineStackId: 0))
                        //.strokeBorder(viewModel.qCategoryColorGradient, style: documentSelectionState.qCategories.count != 1 ? StrokeStyle(lineWidth: 2, dash: [5, 10]) : StrokeStyle(lineWidth: 4))
                            .opacity(viewModel.qCategoryOpacity)
                            .background(Rectangle().fill(.background))
                            .frame(width: viewModel.qCategoryFrameSize.width, height: viewModel.qCategoryFrameSize.height)
                            .overlay(
                                VisualPartitionSelectionLabelView(documentSelectionState: $documentSelectionState, visualPartitionSelectionStratificationType: .qCategory)
                                //SelectionLabelView(viewModel: viewModel, singleColorGradient: viewModel.qCategoryColorGradient, stratificaitonType: .qCategory)
                                , alignment: .bottom)
                    }
                    .zIndex(1)
                    //if documentSelectionState.qCategories.count != 1 {
                    Rectangle()
                        .strokeBorder(viewModel.qCategoryColorGradient, style: getQCategoryLineStroke(lineStackId: 1))
                    //                                .strokeBorder(viewModel.qCategoryColorGradient, style: StrokeStyle(lineWidth: 2, dash: [5, 10]))
                        .opacity(viewModel.qCategoryOpacity)
                        .background(Rectangle().fill(.background))
                        .frame(width: viewModel.qCategoryFrameSize.width, height: viewModel.qCategoryFrameSize.height)
                        .offset(viewModel.qCategoryOffsetFrameSize1)
                        .zIndex(0.5)
                    
                    Rectangle()
                        .strokeBorder(viewModel.qCategoryColorGradient, style: getQCategoryLineStroke(lineStackId: 2))
                    //                                .strokeBorder(viewModel.qCategoryColorGradient, style: StrokeStyle(lineWidth: 2, dash: [5, 10]))
                        .opacity(viewModel.qCategoryOpacity)
                        .background(Rectangle().fill(.background))
                        .frame(width: viewModel.qCategoryFrameSize.width, height: viewModel.qCategoryFrameSize.height)
                        .offset(viewModel.qCategoryOffsetFrameSize2)
                    // }
                    
                }
                .offset(viewModel.qCategoryOffset)
                .zIndex(0.8)// end of QCategory
                ZStack {  // start of predicted label
                    ZStack {
                        Rectangle()
                            .strokeBorder(viewModel.predictedLabelsColorGradient, style: getPredictedClassesLineStroke(lineStackId: 0))
                        //.strokeBorder(viewModel.predictedLabelsColorGradient, style: documentSelectionState.predictedClasses.count != 1 ? StrokeStyle(lineWidth: 2, dash: [5, 10]) : StrokeStyle(lineWidth: 4))
                            .opacity(viewModel.predictedLabelsOpacity)
                            .background(Rectangle().fill(.background))
                            .frame(width: viewModel.predictedLabelsFrameSize.width, height: viewModel.predictedLabelsFrameSize.height)
                            .overlay(
                                VisualPartitionSelectionLabelView(documentSelectionState: $documentSelectionState, visualPartitionSelectionStratificationType: .predictedLabel)
                                //SelectionLabelView(viewModel: viewModel, singleColorGradient: viewModel.predictedLabelsColorGradient, stratificaitonType: .predictedLabel)
                                , alignment: .bottom)
                    }
                    .zIndex(1)
                    //if documentSelectionState.predictedClasses.count != 1 {
                    Rectangle()
                        .strokeBorder(viewModel.predictedLabelsColorGradient, style: getPredictedClassesLineStroke(lineStackId: 1))
                    //.strokeBorder(viewModel.predictedLabelsColorGradient, style: StrokeStyle(lineWidth: 2, dash: [5, 10]))
                        .opacity(viewModel.predictedLabelsOpacity)
                        .background(Rectangle().fill(.background))
                        .frame(width: viewModel.predictedLabelsFrameSize.width, height: viewModel.predictedLabelsFrameSize.height)
                        .offset(viewModel.predictedLabelsOffsetFrameSize1)
                        .zIndex(0.5)
                    if documentSelectionState.numberOfClasses > 2 {
                        Rectangle()
                            .strokeBorder(viewModel.predictedLabelsColorGradient, style: getPredictedClassesLineStroke(lineStackId: 2))
                        //.strokeBorder(viewModel.predictedLabelsColorGradient, style: StrokeStyle(lineWidth: 2, dash: [5, 10]))
                            .opacity(viewModel.predictedLabelsOpacity)
                            .background(Rectangle().fill(.background))
                            .frame(width: viewModel.predictedLabelsFrameSize.width, height: viewModel.predictedLabelsFrameSize.height)
                            .offset(viewModel.predictedLabelsOffsetFrameSize2)
                    }
                    
                }
                .zIndex(0.5) // end of predicted label
            }
            
        }
    }
}
