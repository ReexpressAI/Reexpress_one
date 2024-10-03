//
//  PrimaryView.swift
//  Alpha1
//
//  Created by A on 1/28/23.
//

import SwiftUI


struct PrimaryView: View {
    
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var dataController: DataController
    @EnvironmentObject var initialSetupDataController: InitialSetupDataController
    @EnvironmentObject var programModeController: ProgramModeController
    
    var projectDirectoryURL: URL?
    @State private var mode: MainRoute = MainRoute.data
    @State private var loadedDatasets = false
    @State private var loadedDatasetsAlert = false
    @State private var presentingFatalErrorAlert = false
    @State private var fatalErrorStructure: FatalErrorStructure = FatalErrorStructure()
    
    @State private var showGlobalStatusPopoverView = false
    @State private var showExportModalView = false
    
    struct FatalErrorStructure {
        var fatalErrorMessage: String = "Unable to continue."
        var fatalErrorInstructionMessage: String = ""
    }
    
//    @Environment(\.passStatus) private var passStatus
//    @Environment(\.passStatusIsLoading) private var passStatusIsLoading
    var accountIsAvailable: Bool {
        return true
        /*switch passStatus {
        case .notSubscribed:
            return false
        case .fed_2023v1:
            return !passStatusIsLoading
        }*/
    }
    
    var body: some View {
        HStack {
            NavigationStack {
                ZStack {
                    if loadedDatasets {
                        switch mode {
                        case MainRoute.data:
                            SetupView(loadedDatasets: $loadedDatasets)
                                .opacity(loadedDatasets ? 1.0 : 0.0)
                        case MainRoute.learn:
                            LearningMainView(loadedDatasets: $loadedDatasets)
                        case MainRoute.explore:
                            DataOverviewView(numberOfClasses: dataController.numberOfClasses, loadedDatasets: $loadedDatasets)
                                .modifier(IntrospectViewPrimaryComponentsViewModifier(useShadow: true))
                        case MainRoute.compare:
                            IntrospectionMainViewGrid(numberOfClasses: dataController.numberOfClasses, loadedDatasets: $loadedDatasets)
                        case MainRoute.discover:
                            DiscoverViewMain(loadedDatasets: $loadedDatasets)
                        case MainRoute.compose:
                            LivePredictionView(loadedDatasets: $loadedDatasets)
                        }
                    }
                    
                }
                .sheet(isPresented: $showExportModalView) {
                    ExportView(loadedDatasets: $loadedDatasets)
                        .frame(width: 600, height: 450)
                }
                .toolbar {
                    ToolbarItem(placement: .secondaryAction) {
                        Button {
                            showGlobalStatusPopoverView.toggle()
                        } label: {
                            Image(systemName: "square.stack.3d.up.fill")
                        }
                        .popover(isPresented: $showGlobalStatusPopoverView, arrowEdge: .top) {
                            GlobalStatusView(loadedDatasets: $loadedDatasets)
                                .frame(width: 800)
                                //.frame(width: 800, height: 600)
                        }
                    }
                    
                    ToolbarItem(placement: .principal) {
                        Picker("Mode", selection: $mode) {
                            Text(REConstants.MenuNames.setupName).tag(MainRoute.data)
                            Text(REConstants.MenuNames.learnName).tag(MainRoute.learn)
                            Text(REConstants.MenuNames.exploreName).tag(MainRoute.explore)
                            Text(REConstants.MenuNames.compareName).tag(MainRoute.compare)
                            Text(REConstants.MenuNames.discoverName).tag(MainRoute.discover)
                            Text(REConstants.MenuNames.composeName).tag(MainRoute.compose)                            
                        }
                        .pickerStyle(.segmented)
                    }
                    ToolbarItem(placement: .status) {
                        Button {
                            showExportModalView.toggle()
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
//                        .popover(isPresented: $showExportModalView, arrowEdge: .top) {
//                            ExportView(loadedDatasets: $loadedDatasets)
//                                .frame(width: 500, height: 500)
//                        }
                        
                        
                    }
                }
            }
            .navigationTitle("\(dataController.projectURL?.lastPathComponent.description.truncateUpToMaxWithEllipsis(maxLength: 35) ?? "")") //.truncateUpToMaxWithEllipsis(maxLength: 25) ?? "")")
            .navigationSubtitle("\(dataController.modelTaskType.stringValue(numberOfClasses: dataController.numberOfClasses))")
            
        }
        .alert(fatalErrorStructure.fatalErrorMessage, isPresented: $presentingFatalErrorAlert) {
            Button {
            } label: {
                Text("OK")
            }
        } message: {
            Text(fatalErrorStructure.fatalErrorInstructionMessage)
        }
        .alert(initialSetupDataController.isNewProject ? "New project sucessfully created." : "Existing project sucessfully loaded.", isPresented: $loadedDatasetsAlert) {
            Button {
                moc.reset()
            } label: {
                Text("OK")
            }
        } message: {
            Text(initialSetupDataController.isNewProject ? "To get started, add data." : "Welcome back!")
        }
        .task {
            do {
                try await dataController.createInitialDatasetStructures(initialSetupDataController: initialSetupDataController, moc: moc)

                await MainActor.run {
                    // check program mode can handle the project file's model:
                    if !programModeController.isModelCompatibleWithCurrentProgramMode(modelGroup: dataController.modelGroup) {
                        fatalErrorStructure.fatalErrorInstructionMessage = "The model in the selected project file cannot be opened in \(REConstants.ExperimentalMode.experimentalModeFull). Please restart and choose another project file."
                        presentingFatalErrorAlert = true
                        loadedDatasets = false
                    } else if !accountIsAvailable { // check status of the Account:
                        fatalErrorStructure.fatalErrorInstructionMessage = "We were unable to verify your account subscription. Restart and subscribe to get started!"
                        presentingFatalErrorAlert = true
                        loadedDatasets = false
                    } else {
                        withAnimation {
                            loadedDatasets = true
                            loadedDatasetsAlert = true
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    loadedDatasets = false
                }
                //print("Error constructing initial dataset structures: \(error)")
            }
        }
        /* MARK: Deployment note: Only for testing on TestFlight, this is commented out. Uncomment for deployment. This block will disable the subscription for the user if the Account has lapsed, but the synthetic times in the TestFlight Sandbox are too short for people to be able to test without being interrupted.
        .onChange(of: accountIsAvailable) { oldValue, newValue in
            if !newValue && loadedDatasets {
                fatalErrorStructure.fatalErrorInstructionMessage = "We were unable to verify your account subscription. Restart and subscribe to get started!"
                presentingFatalErrorAlert = true
                loadedDatasets = false
            }
        }*/
    }
}



struct PrimaryView_Previews: PreviewProvider {
    static var previews: some View {
        PrimaryView()
    }
}
