//
//  ExportRetrievalView.swift
//  Alpha1
//
//  Created by A on 9/21/23.
//

import SwiftUI

struct ExportRetrievalView: View {
    @EnvironmentObject var dataController: DataController
    @Binding var loadedDatasets: Bool
    @Binding var dataExportState: DataExportState
    @Binding var dataTask: Task<Void, Error>?
    @Binding var exportSuccessfullySaved: Bool
    
    @State private var errorEncountered: Bool = false
    @State private var exportAvailable: Bool = false
    @State private var showingExportSave: Bool = false
    @State private var documentForExport: JSONLinesExportDatasetFile?
    var body: some View {
        if loadedDatasets {
            VStack(alignment: .leading) {
                
                Text("Data Export")
                    .font(.title)
                    .foregroundStyle(.gray)
                Spacer()
                ScrollView {
                    VStack {
                        HStack {
                            SingleDatasplitView(datasetId: dataExportState.datasetId)
                                .font(REConstants.Fonts.baseFont)
                                .monospaced()
                            Spacer()
                        }
                        VStack(alignment: .leading) {
                            if !exportAvailable {
                                VStack {
                                    Spacer()
                                    if !errorEncountered {
                                        HStack {
                                            Spacer()
                                            ProgressView()
                                            Spacer()
                                        }
                                        Text("Preparing export")
                                            .font(REConstants.Fonts.baseFont)
                                            .foregroundStyle(.gray)
                                    } else {
                                        HStack {
                                            Spacer()
                                            Text("Unable to retrieve requested data")
                                                .font(REConstants.Fonts.baseFont)
                                                .foregroundStyle(.gray)
                                                .italic()
                                            Spacer()
                                        }
                                    }
                                    Spacer()
                                }
                                .padding()
                                .modifier(SimpleBaseBorderModifier())
                            } else {
                                Button("Choose a file destination") {
                                    showingExportSave = true
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.large)
                                .fileExporter(isPresented: $showingExportSave, document: documentForExport, contentType: .jsonlType, defaultFilename: "exported_JSON_lines_file.jsonl") { result in
                                        switch result {
                                        case .success: //(let url):
                                            exportSuccessfullySaved = true
                                        case .failure: //(let error):
                                            errorEncountered = true
                                        }
                                    }
                            }
                        }
                        .padding()
                    }
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            .padding()
            .modifier(SimpleBaseBorderModifier())
            .padding()
            .onAppear {
                if loadedDatasets {
                    dataTask = Task {
                        do {
                            let documentJSONAsString = try await dataController.getDataForExport(dataExportState: dataExportState)
                            
                            await MainActor.run {
                                documentForExport = JSONLinesExportDatasetFile(jsonLinesExportString: documentJSONAsString)
                                exportAvailable = true
                            }
                        } catch {
                            await MainActor.run {
                                errorEncountered = true
                            }
                        }
                    }
                }
            }
            .onDisappear {
                dataTask?.cancel()
            }
        }
    }
}

