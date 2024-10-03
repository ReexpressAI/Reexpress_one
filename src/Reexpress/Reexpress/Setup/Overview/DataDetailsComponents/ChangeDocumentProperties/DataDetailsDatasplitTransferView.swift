//
//  DataDetailsDatasplitTransferView.swift
//  Alpha1
//
//  Created by A on 8/15/23.
//

import SwiftUI

struct DataDetailsDatasplitTransferView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var dataController: DataController
    
    @Binding var documentObject: Document?
    
//    @State private var labelDisplayNames: [LabelDisplayName] = []
//    var sortedLabels: [LabelDisplayName] {
//        dataController.labelToName.sorted(by: { $0.key < $1.key }).map { (label, displayName) in
//            LabelDisplayName(label: label, labelName: displayName)
//        }
//    }
//
//
//    @State private var selectedLabel: LabelDisplayName.ID? // ID is the underlying Int label
    @State private var isShowingCoreDataSaveError: Bool = false
    
//    var newLabelIsSelectedAndDiffersFromCurrent: Bool {
//        if let docObj = documentObject, let selectedLabel = selectedLabel, selectedLabel != docObj.label, DataController.isValidLabel(label: selectedLabel, numberOfClasses: dataController.numberOfClasses) {
//            return true
//        }
//        return false
//    }
    
//    func setCurrentLabelAsDefaultSelected() {
//        if let docObj = documentObject {
//            selectedLabel = docObj.label
//        }
//    }
  
    var newDatasplitIsSelectedAndDiffersFromCurrentAndSpaceAvailable: Bool {
        if let currentDatasplit = currentDatasplit, let selectedDatasetId = selectedDatasetId, selectedDatasetId != currentDatasplit, let dataset = dataController.inMemory_Datasets[selectedDatasetId], let currentCount = dataset.count {
            // check for space (here, assuming only 1 document will be added):
            return currentCount < REConstants.DatasetsConstraints.maxTotalLines
        }
        return false
    }
    
    var currentDatasplit: Int? {
        if let docObj = documentObject, let datasetId = docObj.dataset?.id {
            return datasetId
        }
        return nil
    }
    
    func setCurrentDatasplitAsDefaultSelected() {
        if let currentDatasplit = currentDatasplit {
            selectedDatasetId = currentDatasplit
        }
    }
    
    @State private var selectedDatasetId: Int?
    var body: some View {
        VStack {
            VStack {
                HStack {
                    Text("Select a new Datasplit for this document")
                        .font(REConstants.Fonts.baseFont)
                        //.font(.title)
                        .bold()
                    Spacer()
                }
                HStack {
                    Text("A maximum of \(REConstants.DatasetsConstraints.maxTotalLines) documents are allowed per Datasplit")
                        .font(.title3)
                        .foregroundStyle(.gray)
                    Spacer()
                }
            }
            .padding([.leading, .trailing, .bottom])
            
            if let docObj = documentObject, let datasetId = docObj.dataset?.id {
                HStack {
                    Text("Current:")
                        .font(.title3)
                        .foregroundStyle(.gray)
                    SingleDatasplitView(datasetId: datasetId)
                        .font(.title3)
                        .monospaced()
                    Spacer()
                }
                .padding([.leading, .trailing, .bottom])
            }
            HStack {
                DatasplitSelectorView(datasetId: $selectedDatasetId)
                    .monospaced()
                Spacer()
            }
            .padding([.leading, .trailing, .bottom])
        }
        .font(REConstants.Fonts.baseFont)
        .padding()
        .modifier(SimpleBaseBorderModifier())
        .padding()
        .onAppear {
            setCurrentDatasplitAsDefaultSelected()
        }
        .alert(REConstants.GeneralErrors.coreDataSaveMessage, isPresented: $isShowingCoreDataSaveError) {
            Button("OK") {
                dismiss()
            }
        }
        
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                        .frame(width: 100)
                }
                .controlSize(.large)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    do {
                        if newDatasplitIsSelectedAndDiffersFromCurrentAndSpaceAvailable, let newDatasplitId = selectedDatasetId {
                            try dataController.transferOneDocument(documentObject: documentObject, newDatasplitId: newDatasplitId, moc: moc)
                            Task {
                                try? await dataController.updateInMemoryDatasetStats(moc: moc, dataController: dataController)
                                dismiss()
                            }
                        }
                    } catch {
                        isShowingCoreDataSaveError = true
                    }
                } label: {
                    Text("Transfer")
                        .frame(width: 100)
                }
                .controlSize(.large)
                .disabled(!newDatasplitIsSelectedAndDiffersFromCurrentAndSpaceAvailable)
                
            }
        }
    }
}
