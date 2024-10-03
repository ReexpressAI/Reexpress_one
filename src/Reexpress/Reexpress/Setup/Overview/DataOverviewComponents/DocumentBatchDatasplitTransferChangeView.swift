//
//  DocumentBatchDatasplitTransferChangeView.swift
//  Alpha1
//
//  Created by A on 8/28/23.
//

import SwiftUI


    
struct DocumentBatchDatasplitTransferChangeView: View {
    @EnvironmentObject var dataController: DataController
    
    @Binding var documentBatchChangeState: DocumentBatchChangeState
    var datasetId: Int?
    var documentCountInSelection: Int = REConstants.DatasetsConstraints.maxTotalLines

    var newDatasplitHasSpaceAvailable: Bool? {
        if let newDatasplitID = documentBatchChangeState.newDatasplitID, let dataset = dataController.inMemory_Datasets[newDatasplitID], let currentCount = dataset.count {
            // check for space:
            return currentCount + documentCountInSelection <= REConstants.DatasetsConstraints.maxTotalLines
        }
        return nil
    }
    
    var ifTransferringNewDatasplitDiffersFromExisting: Bool {
        if documentBatchChangeState.transferDatasplit {
            if let newDatasplitID = documentBatchChangeState.newDatasplitID {
                if let currentDatasetID = datasetId {
                    return currentDatasetID != newDatasplitID
                } else {
                    return false
                }
            } else {
                return false
            }
        }
        return true
    }
    
    var body: some View {
        
        VStack {
            VStack {
                HStack {
                    Text("All selected document(s) will be transferred to the following datasplit:")
                    Spacer()
                }
                VStack {
                    if documentBatchChangeState.transferDatasplit, let newDatasplitID = documentBatchChangeState.newDatasplitID {
                        if let spaceCheck = newDatasplitHasSpaceAvailable, spaceCheck, ifTransferringNewDatasplitDiffersFromExisting {
                            SingleDatasplitView(datasetId: newDatasplitID)
                                .monospaced()
                                .foregroundStyle(.orange)
                                .opacity(0.75)
                        } else {
                            if !ifTransferringNewDatasplitDiffersFromExisting {
                                Text("The chosen datasplit is the current datasplit. Choose another below.")
                                    .monospaced()
                                    .foregroundStyle(.red)
                                    .opacity(0.75)
                            } else {
                                Text("The chosen datasplit has insufficient space remaining. Choose another below.")
                                    .monospaced()
                                    .foregroundStyle(.red)
                                    .opacity(0.75)
                            }
                        }

                    } else {
                        Text("None selected. Choose a datasplit below.")
                            .italic()
                            .foregroundStyle(.gray)
                    }
                }
                .padding()
            }
            .padding([.bottom])
            
            HStack {
                DatasplitSelectorView(datasetId: $documentBatchChangeState.newDatasplitID, showLabelTitle: true)
                    .monospaced()
                Spacer()
            }
            .padding([.leading, .trailing, .bottom])
        }
        
        .font(REConstants.Fonts.baseFont)
        .padding()
        
    }
}

