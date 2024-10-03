//
//  HelpAssistanceView_LabelData_DownloadExample.swift
//  Alpha1
//
//  Created by A on 9/23/23.
//

import SwiftUI

struct HelpAssistanceView_LabelData_DownloadExample: View {
    @EnvironmentObject var dataController: DataController
    
    @State var exportSuccessfullySaved: Bool = false
    
    @State private var errorEncountered: Bool = false
    @State private var exportAvailable: Bool = false
    @State private var showingExportSave: Bool = false
    @State private var documentForExport: JSONLinesExportDatasetFile?
    var body: some View {
        VStack {
            Button {
                showingExportSave = true
            } label: {
                HStack(alignment: .lastTextBaseline) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(Color.blue.gradient)
                    Text("Save an example template to disk")
                        .foregroundStyle(.blue)
                }
                .font(REConstants.Fonts.baseFont)
            }
            .buttonStyle(.borderless)
            .fileExporter(isPresented: $showingExportSave, document: documentForExport, contentType: .jsonlType, defaultFilename: "example_JSON_lines_file_for_label_display_names.jsonl") { result in
                switch result {
                case .success: //(let url):
                    exportSuccessfullySaved = true
                case .failure: //(let error):
                    errorEncountered = true
                }
            }
            .fileExporterFilenameLabel("Save Input Template As:")
            .fileDialogConfirmationLabel("Save Template")
            .padding()
            .modifier(SimpleBaseBorderModifier())
            .padding()
            if errorEncountered {
                Text("Unable to save the template. Please try again.")
                    .foregroundStyle(.red)
                    .italic()
            }
        }
        .onAppear {
            let jsonExportDocument = JSONLabels(label: 0, name: "negative")
            
            let jsonExportDocument2 = JSONLabels(label: 1, name: "positive")
            
            var documentExportStrings: [String] = []
            do {
                let exportedDocumentAsString = try dataController.exportJSONLabelsToStringLine(dataExportJSONDocument: jsonExportDocument)
                documentExportStrings.append(exportedDocumentAsString)
                let exportedDocumentAsString2 = try dataController.exportJSONLabelsToStringLine(dataExportJSONDocument: jsonExportDocument2)
                documentExportStrings.append(exportedDocumentAsString2)
                let documentJSONAsString = documentExportStrings.joined(separator: "\n")
                documentForExport = JSONLinesExportDatasetFile(jsonLinesExportString: documentJSONAsString)
                exportAvailable = true
            } catch {
                errorEncountered = true
            }
        }
    }
}


