//
//  UncertaintyGraphDatapointFocusView.swift
//  Alpha1
//
//  Created by A on 9/15/23.
//

import SwiftUI

struct UncertaintyGraphDatapointFocusView: View {
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var dataController: DataController
    
    var documentId: String = ""
    @State private var showingSelectedDocumentDetails: Bool = false
    @State var selectedDocumentObject: Document?
    var body: some View {
        Grid(alignment: .leadingFirstTextBaseline, verticalSpacing: 5) {
            GridRow {
                Text("Selected document")
                    .foregroundColor(.secondary)
                    .gridCellColumns(2)
            }
            GridRow {
                Text("ID")
                    .foregroundColor(.secondary)
                    .gridColumnAlignment(.trailing)
                Text(documentId.truncateUpToMaxWithEllipsis(maxLength: 36))
                    .monospaced()
                    .gridColumnAlignment(.leading)
            }
            GridRow {
                PopoverViewWithButtonLocalStateOptionsLocalizedString(popoverViewText: "Any change to the document (e.g., modification of the label) will not be reflected in the graph until the selection is rerun by clicking **\(REConstants.MenuNames.selectName)**.")
                    HStack(alignment: .lastTextBaseline) {
                        Image(systemName: "list.bullet.rectangle.portrait")
                            .foregroundStyle(.blue.gradient)
                        Text("Details")
                            .foregroundStyle(.blue)
                    }
                    .onTapGesture {
                        showingSelectedDocumentDetails.toggle()
                        selectedDocumentObject = try? dataController.retrieveOneDocument(documentId: documentId, moc: moc)
                    }
            }
        }
        .font(.system(size: 14))
        .padding()
        .modifier(SimpleBaseBorderModifier())
        .padding()
        .sheet(isPresented: $showingSelectedDocumentDetails,
               onDismiss: nil) {
            DataDetailsView(selectedDocument: .constant(Optional("")), documentObject: $selectedDocumentObject, searchParameters: nil, disableFeatureSearchViewAndDestructiveActions: false, calledFromTableThatNeedsUpdate: false, showDismissButton: true)
                .frame(
                    idealWidth: 1200, maxWidth: 1200,
                    idealHeight: 900, maxHeight: 900)
        }
    }
}
