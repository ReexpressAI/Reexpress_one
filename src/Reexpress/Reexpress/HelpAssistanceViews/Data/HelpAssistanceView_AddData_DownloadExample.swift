//
//  HelpAssistanceView_AddData_DownloadExample.swift
//  Alpha1
//
//  Created by A on 9/22/23.
//

import SwiftUI

struct HelpAssistanceView_AddData_DownloadExample: View {
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
            .fileExporter(isPresented: $showingExportSave, document: documentForExport, contentType: .jsonlType, defaultFilename: "example_JSON_lines_file.jsonl") { result in
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
            let jsonExportDocument = DataExportJSONDocument(id: UUID().uuidString, label: 0, document: "This is an example document with the minimal properties. The id of this document is a randomly generated UUID, which ensures that the document will have a unique id. Such ids can be generated in Swift with 'UUID().uuidString' and in Python with 'import uuid; str(uuid.uuid4())'. This file must have the ending .jsonl to be read as input by \(REConstants.ProgramIdentifiers.mainProgramName). Special characters must be properly escaped, as done by standard JSON parsers. Swift's 'JSONEncoder().encode()' method will handle this for you, and you can typically get similar behavior with Python's 'json.dumps()' method using the argument 'ensure_ascii=True'.")
            
            let jsonExportDocument2 = DataExportJSONDocument(id: UUID().uuidString, label: 1, document: "This is another example document, but with all of the optional properties. Note that a newline separates the JSON for these two example documents. As a result, the entire file is not valid JSON, but each line is independently valid JSON. This type of 'JSON lines' file is preferable to a regular JSON file because it can be read in a streaming (line-by-line) fashion with standard text editors and utilities.", info: "The info property can be used as a memo field.", attributes: [0.01, 0.02], prompt: "Prompts should be short and concise. See the examples in the project creation menu for possible structures.", group: "The group property can be used as a memo field.")
            
            var documentExportStrings: [String] = []
            do {
                let exportedDocumentAsString = try dataController.exportJSONToStringLine(dataExportJSONDocument: jsonExportDocument)
                documentExportStrings.append(exportedDocumentAsString)
                let exportedDocumentAsString2 = try dataController.exportJSONToStringLine(dataExportJSONDocument: jsonExportDocument2)
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

