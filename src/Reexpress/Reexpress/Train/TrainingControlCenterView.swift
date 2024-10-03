//
//  TrainingControlCenterView.swift
//  Alpha1
//
//  Created by A on 6/22/23.
//

import SwiftUI

extension TrainingControlCenterView {
    @MainActor class ViewModel: ObservableObject {
        @Published var showingTrainingProcessModal = false
        //        @Published var showingIndexProcessModal = false
        //        let viewBoxScaling: CGFloat = 2
    }
}

struct TrainingControlCenterView: View {
    @EnvironmentObject var dataController: DataController
    @StateObject private var viewModel = ViewModel()
    
    var headerTitle: String = "Model Training Control Center"
    @State var statusSubtitle: String = ""
    
    //@State private var showingHelpAssistanceView: Bool = false
    
    var modelControlIdString: String = REConstants.ModelControl.keyModelId
    var isKeyModel: Bool {
        return modelControlIdString == REConstants.ModelControl.keyModelId
    }
    var highlightColor: Color {
        if isKeyModel {
            return REConstants.REColors.trainingHighlightColor
        } else {
            return REConstants.REColors.indexTrainingHighlightColor
        }
    }
    
    /// The status subtitle is updated onAppear and on dismissal of the training view.
    func updateStatusSubtitle() {
        if isKeyModel {
            statusSubtitle = "\(dataController.inMemory_KeyModelGlobalControl.getTrainingStateString(abbreviated: true))"
        } else {
            statusSubtitle = "\(dataController.inMemory_KeyModelGlobalControl.getIndexStateString(abbreviated: true))"
        }
    }
    
    var preventIndexTrainingUntilAKeyModelUpdateDueToRefreshNeeded: Bool {
        if !isKeyModel {
            return dataController.inMemory_KeyModelGlobalControl.trainingState == .Stale
        }
        return false
    }
    @State private var runKeyModelFirstAlert: Bool = false
    var body: some View {
        VStack {
            VStack {
                HStack { //}(alignment: .firstTextBaseline) {
                    HeaderTitleView(headerTitle: headerTitle, headerTitleColor: highlightColor, statusSubtitle: $statusSubtitle, viewWidth: 500)
                        .onAppear {
                            updateStatusSubtitle()
                        }
                    Spacer()
                    Button {
                        if preventIndexTrainingUntilAKeyModelUpdateDueToRefreshNeeded {
                            runKeyModelFirstAlert.toggle()
                        } else {
                            viewModel.showingTrainingProcessModal.toggle()
                        }
                    } label: {
                        UncertaintyGraphControlButtonLabelWithCaptionVStack(buttonImageName: "play", buttonTextCaption: "Train", buttonForegroundStyle: AnyShapeStyle(Color.blue.gradient))
                    }
                    .buttonStyle(.borderless)
                    .alert("A model refresh is needed. Retrain the primary model before proceeding.", isPresented: $runKeyModelFirstAlert) {
                        Button("OK") {
                        }
                    }
                    .sheet(isPresented: $viewModel.showingTrainingProcessModal,
                           onDismiss: updateStatusSubtitle) {
                        if isKeyModel {
                            TrainingProcessView(modelControlIdString: modelControlIdString)
                                .frame(
                                    minWidth: 800, maxWidth: 800, idealHeight: 800, maxHeight: 800)
                        } else {
                            IndexProcessTrainingMainView(modelControlIdString: modelControlIdString)
                                .frame(
                                    minWidth: 800, maxWidth: 800, idealHeight: 800, maxHeight: 800) 
                        }
                        //.interactiveDismissDisabled(true)
                        // does not work: .interactiveDismissDisabled(true)
                        //                            .onExitCommand {
                        //                            }
                        //                            .frame(
                        //                                minWidth: 800, maxWidth: 800,
                        //                                minHeight: 800, maxHeight: 800) //.infinity)
                        //                                .frame(
                        //                                    minWidth: 800, maxWidth: 800, idealHeight: 600, maxHeight: 600)
//.infinity)
                    }
                    HelpAssistanceView_Learn_Training()
                    /*Button {
                     showingHelpAssistanceView.toggle()
                     } label: {
                     UncertaintyGraphControlButtonLabelWithCaptionVStack(buttonImageName: "questionmark.circle", buttonTextCaption: "Help", buttonForegroundStyle: AnyShapeStyle(Color.gray.gradient))
                     }
                     .buttonStyle(.borderless)
                     .popover(isPresented: $showingHelpAssistanceView) {
                     HelpAssistanceView_Learn_Training()
                     }*/
                }
                
                // MARK: Status view
                HStack {
                    TrainingExplanationView(isKeyModel: isKeyModel)
                        .padding()
                    Spacer()
                    if isKeyModel {
                        TrainingControlCenterStatusView()
                            .padding(EdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 20))
                    } else {
                        IndexTrainingControlCenterStatusView()
                            .padding(EdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 20))
                    }
                }
                
            }
            VStack {
                if isKeyModel {
                    TrainingProcessDetails(modelControlIdString: modelControlIdString, metricStringName: "\(dataController.inMemory_KeyModelGlobalControl.trainingMaxMetric.description)", data: dataController.inMemory_KeyModelGlobalControl.trainingProcessDataStorageMetric.trainingProcessData)
                    TrainingProcessDetails(modelControlIdString: modelControlIdString, data: dataController.inMemory_KeyModelGlobalControl.trainingProcessDataStorageLoss.trainingProcessData)
                } else {  // index model
                    TrainingProcessDetails(modelControlIdString: modelControlIdString, metricStringName: "\(dataController.inMemory_KeyModelGlobalControl.indexMaxMetric.description)", data: dataController.inMemory_KeyModelGlobalControl.indexProcessDataStorageMetric.trainingProcessData)
                    TrainingProcessDetails(modelControlIdString: modelControlIdString, data: dataController.inMemory_KeyModelGlobalControl.indexProcessDataStorageLoss.trainingProcessData)
                }
                /*
                 var indexProcessDataStorageLoss = TrainingProcessDataStorage()
                 var indexProcessDataStorageMetric = TrainingProcessDataStorage()
                 */
            }
            .padding()
            .modifier(IntrospectViewPrimaryComponentsViewModifier())
        }
    }
}

//struct TrainingControlCenterView_Previews: PreviewProvider {
//    static var previews: some View {
//        TrainingControlCenterView()
//    }
//}
