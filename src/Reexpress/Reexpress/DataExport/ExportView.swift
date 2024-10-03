//
//  ExportView.swift
//  Alpha1
//
//  Created by A on 6/17/23.
//

import SwiftUI


struct ExportView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var dataController: DataController
    
    @Binding var loadedDatasets: Bool
    @State private var dataExportState: DataExportState = DataExportState()
    
    enum Destinations {
        case options
        case retrieving
    }
    
    @State var dataTask: Task<Void, Error>?
    @State private var navPath = NavigationPath()
    
    //@State var taskWasCancelled: Bool = false
    //@State var errorAlert: Bool = false  // Errors are shown directly in the ExportRetrievalView view
    @State var exportSuccessfullySaved: Bool = false
    
    var body: some View {
        NavigationStack(path: $navPath) {
            ExportOptionsView(loadedDatasets: $loadedDatasets, dataExportState: $dataExportState)
                .navigationDestination(for: Destinations.self) { i in
                    switch i {
                    case Destinations.options:
                        ExportOptionsView(loadedDatasets: $loadedDatasets, dataExportState: $dataExportState)
                            .navigationBarBackButtonHidden()
                    case Destinations.retrieving:
                        ExportRetrievalView(loadedDatasets: $loadedDatasets, dataExportState: $dataExportState, dataTask: $dataTask, exportSuccessfullySaved: $exportSuccessfullySaved)
                            .navigationBarBackButtonHidden()
                    }
                }
        }
        .alert("Success!", isPresented: $exportSuccessfullySaved) {
            Button {
                dismiss()
            } label: {
                Text("OK")
            }
        } message: {
            Text("Export successfully saved.")
        }
//        .alert("An unexpected error was encountered.", isPresented: $errorAlert) {
//            Button {
//                dismiss()
//            } label: {
//                Text("OK")
//            }
//        } message: {
//            Text("Unable to export.")
//        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                // MARK: Note: This will also be called if the user taps ESC.
                
                Button("Cancel") {
                    // it may take some time to cancel, so need to show a screen
                    dataTask?.cancel()
                    dismiss()
//                    if navPath.count > 0 {
//                        taskWasCancelled = true
//                        //DispatchQueue.main.asyncAfter(deadline: .now() + REConstants.ModelControl.defaultCancellingTimeToFreeResources*0.1) {
//                            dismiss()
//                        //}
//                    } else {
//                        dismiss()
//                    }
                }
                //.disabled(taskWasCancelled)
            }
            ToolbarItem(placement: .confirmationAction) {
                if navPath.count == 0 {
                    Button("Next") {
                        navPath.append(Destinations.retrieving)
                    }
                    //.disabled(cacheToClearDatasetIds.isEmpty)
                }
            }
        }
        .onDisappear {
            // Typically, we disable ESC closing the modal, but here we just always check that the task was properly canceled to be safe.
            dataTask?.cancel()
        }
    }
}
