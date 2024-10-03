//
//  DataDetailsLabelChangeView.swift
//  Alpha1
//
//  Created by A on 8/14/23.
//

import SwiftUI

struct DataDetailsLabelChangeView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var dataController: DataController
    
    @Binding var documentObject: Document?
    
    @State private var labelDisplayNames: [LabelDisplayName] = []
    var sortedLabels: [LabelDisplayName] {
        dataController.labelToName.sorted(by: { $0.key < $1.key }).map { (label, displayName) in
            LabelDisplayName(label: label, labelName: displayName)
        }
    }
      
    
    @State private var selectedLabel: LabelDisplayName.ID? // ID is the underlying Int label
    @State private var isShowingCoreDataSaveError: Bool = false
    
    var newLabelIsSelectedAndDiffersFromCurrent: Bool {
        if let docObj = documentObject, let selectedLabel = selectedLabel, selectedLabel != docObj.label, DataController.isValidLabel(label: selectedLabel, numberOfClasses: dataController.numberOfClasses) {
            return true
        }
        return false
    }
    
    func setCurrentLabelAsDefaultSelected() {
        if let docObj = documentObject {
            selectedLabel = docObj.label
        }
    }
    var body: some View {
        VStack {
            HStack {
                Text("Select a new document label")
                    .font(REConstants.Fonts.baseFont)
                    //.font(.title)
                    .bold()
                //                Divider()
                //                    .frame(width: 2, height: 25)
                //                    .overlay(.gray)
                Spacer()
            }
            .padding([.leading, .trailing, .bottom])
            if let docObj = documentObject, let labelDisplayName = dataController.labelToName[docObj.label] {
                HStack {
                    Text("Current:")
                        .font(.title3)
                        .foregroundStyle(.gray)
                    Text(labelDisplayName)
                        .font(.title3)
                        .monospaced()
                    Spacer()
                }
                .padding([.leading, .trailing, .bottom])
            }
            
            Table(sortedLabels, selection: $selectedLabel) {
                TableColumn("Label") { labelDisplayName in
                    Text(labelDisplayName.labelAsString)
                }
                .width(min: 60, ideal: 60, max: 60)
                TableColumn("Display Name") { labelDisplayName in
                    Text(labelDisplayName.labelName)
                }
            }
            .monospaced()
            .tableStyle(.inset(alternatesRowBackgrounds: true))
            .scrollBounceBehavior(.basedOnSize)
        }
        
        .font(REConstants.Fonts.baseFont)
        .padding()
        .modifier(SimpleBaseBorderModifier())
        .padding()
        .onAppear {
            setCurrentLabelAsDefaultSelected()
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
                        if newLabelIsSelectedAndDiffersFromCurrent, let newLabel = selectedLabel {
                            try dataController.updateLabelForOneDocument(documentObject: documentObject, newLabel: newLabel, moc: moc)
                            dismiss()
                        }
                    } catch {
                        isShowingCoreDataSaveError = true
                    }
                } label: {
                    Text("Update label")
                        .frame(width: 100)
                }
                .controlSize(.large)
                .disabled(!newLabelIsSelectedAndDiffersFromCurrent)
                
            }
        }
    }
}
