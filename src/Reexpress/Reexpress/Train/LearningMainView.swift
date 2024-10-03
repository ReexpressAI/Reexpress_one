//
//  LearningMainView.swift
//  Alpha1
//
//  Created by A on 6/22/23.
//

import SwiftUI

//struct LearningMainView: View {
//    var body: some View {
//        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
//    }
//}

extension LearningMainView {
    @MainActor class ViewModel: ObservableObject {
        
        let displayColumnPickerFont = Font.system(size: 16)
        let displayColumnPaddingEdgeInsets = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        let displayColumnPickerMenuWidth: CGFloat = 250
        
        let gridColumnMinWidth: CGFloat = 750  // also needs to be set consistently in init of the state var columns
        let gridColumnSpacing: CGFloat = 5  // also needs to be set consistently in init of the state var columns
        
        
//        @Published var selectedElement: String?
//        @Published var isHovering = false
//
//        @Published var selectedTappedElement: String?
//
//        //@Published var searchParametersPopoverShowing: Bool = false
//
//        // For controls
//        let buttonDividerHeight: CGFloat = 40
        

    }
}


struct LearningMainView: View {
    @EnvironmentObject var dataController: DataController
//    @Environment(\.managedObjectContext) var moc
    @Binding var loadedDatasets: Bool
    @StateObject var viewModel = ViewModel()
    
        
    @State var showTrainingControlCenter: Bool = true
    @State var showModelCompressionControlCenter: Bool = false
//    @State var showTuningControlCenter: Bool = false
//    @State var showMetricDatabaseControlCenter: Bool = true
    
        
    @State var columns: [GridItem] =
    [GridItem(.flexible(minimum: 750, maximum: .infinity), spacing: 5)] //, GridItem(.flexible(minimum: 750, maximum: .infinity), spacing: 5)]

    var compressionCanStart: Bool {
        dataController.inMemory_KeyModelGlobalControl.trainingState != .Untrained
    }
    
    var body: some View {
        VStack {
            if loadedDatasets {
                //HStack {
                //Spacer()
                ZStack {
                    // MARK: Right column
                    Grid {
                        GridRow {
                            
                            Grid(alignment: .center, verticalSpacing: 0) {
                                
                                GridRow {
                                    HStack(alignment: .lastTextBaseline) {
                                        Button {
                                            withAnimation {
                                                showTrainingControlCenter = true
                                                showModelCompressionControlCenter = false
                                            }
                                        } label: {
                                            PrimaryHeaderControlButton(isSelected: $showTrainingControlCenter, exclusiveSelection: true, buttonImageName: "square.grid.3x3.square", buttonTextCaption: "Model") //laser.burst (not yet available) bolt.square"
                                        }
                                        .buttonStyle(.borderless)
                                        
                                        
                                        /*Button {
                                         withAnimation {
                                         showTuningControlCenter.toggle()
                                         }
                                         } label: {
                                         UncertaintyGraphControlButtonLabelWithCaptionVStack(buttonImageName: "tuningfork", buttonTextCaption: "Tune")
                                         }
                                         .buttonStyle(.borderless)*/
                                        Button {
                                            withAnimation {
                                                showTrainingControlCenter = false
                                                showModelCompressionControlCenter = true
                                            }
                                        } label: {
                                            PrimaryHeaderControlButton(isSelected: $showModelCompressionControlCenter, exclusiveSelection: true, buttonImageName: "rectangle.compress.vertical", buttonTextCaption: "Compress")
                                        }
                                        .buttonStyle(.borderless)
                                        .disabled(!compressionCanStart)
                                        /*Button {
                                         withAnimation {
                                         showMetricDatabaseControlCenter.toggle()
                                         }
                                         } label: {
                                         PrimaryHeaderControlButton(isSelected: $showMetricDatabaseControlCenter, buttonImageName: "dot.circle.viewfinder", buttonTextCaption: "Extract")
                                         }
                                         .buttonStyle(.borderless)
                                         
                                         Button {
                                         withAnimation {
                                         showMetricDatabaseControlCenter.toggle()
                                         }
                                         } label: {
                                         PrimaryHeaderControlButton(isSelected: $showMetricDatabaseControlCenter, buttonImageName: "dot.squareshape.split.2x2", buttonTextCaption: "Metric")
                                         }
                                         .buttonStyle(.borderless)*/
                                    }
                                }
                            }
                            .padding()
                            .modifier(SimpleBaseBorderModifierWithColorOption(useShadow: true))
//                            .background {
//                                RoundedRectangle(cornerRadius: 12, style: .continuous)
//                                    .fill(
//                                        AnyShapeStyle(BackgroundStyle()))
//                                RoundedRectangle(cornerRadius: 12, style: .continuous)
//                                    .stroke(.gray, lineWidth: 1)
//                                    .opacity(0.5)
//                            }
                            .gridColumnAlignment(.trailing)
                        }
                    }
                }
                .padding(EdgeInsets(top: 20, leading: 0, bottom: 0, trailing: 0))
                
                
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 5) {
                        
                        if showTrainingControlCenter {
                            TrainingControlCenterView(headerTitle: "Model Training Control Center", modelControlIdString: REConstants.ModelControl.keyModelId)
                                .padding(EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20))
                                .modifier(IntrospectViewPrimaryComponentsViewModifier(useShadow: true))
                                .frame(minHeight: 900, maxHeight: .infinity)
                        } else if showModelCompressionControlCenter {
                            TrainingControlCenterView(headerTitle: "Model Compression Control Center", modelControlIdString: REConstants.ModelControl.indexModelId)
                                .padding(EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20))
                                .modifier(IntrospectViewPrimaryComponentsViewModifier(useShadow: true))
                                .frame(minHeight: 900, maxHeight: .infinity)
                        }
                    }
                    //.scrollBounceBehavior(.basedOnSize)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
    }
}
