//
//  DocumentBatchLabelChangeView.swift
//  Alpha1
//
//  Created by A on 8/28/23.
//

import SwiftUI


struct DocumentBatchLabelChangeView: View {

    @EnvironmentObject var dataController: DataController
    
    @Binding var documentBatchChangeState: DocumentBatchChangeState
    
    @State private var labelDisplayNames: [LabelDisplayName] = []
    var sortedLabels: [LabelDisplayName] {
        dataController.labelToName.sorted(by: { $0.key < $1.key }).map { (label, displayName) in
            LabelDisplayName(label: label, labelName: displayName)
        }
    }
      
    @State private var selectedLabel: LabelDisplayName.ID? // ID is the underlying Int label

    
    func setCurrentLabelAsDefaultSelected() {
        selectedLabel = documentBatchChangeState.newLabelID
    }
    var body: some View {
        VStack {
            VStack {
                HStack {
                    Text("All selected document(s) will be assigned the following label:")
                    Spacer()
                }
                VStack {
                    if documentBatchChangeState.changeLabel, let newLabelID = documentBatchChangeState.newLabelID, let labelDisplayName = dataController.labelToName[newLabelID] {
                        Text(labelDisplayName)
                            .monospaced()
                            .foregroundStyle(.orange)
                            .opacity(0.75)
                    } else {
                        Text("None selected. Choose a label below.")
                            .italic()
                            .foregroundStyle(.gray)
                    }
                }
                .padding()
                
            }
            .padding([.bottom])
            
            Divider()
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
            .frame(minHeight: 250, idealHeight: 300)
            .onChange(of: selectedLabel) { 
                documentBatchChangeState.newLabelID = selectedLabel
            }
        }
        
        .font(REConstants.Fonts.baseFont)
        .padding()
        .onAppear {
            setCurrentLabelAsDefaultSelected()
        }

        
    }
}
