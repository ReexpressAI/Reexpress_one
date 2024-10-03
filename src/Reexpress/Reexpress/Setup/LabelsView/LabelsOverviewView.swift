//
//  LabelsOverviewView.swift
//  Alpha1
//
//  Created by A on 7/16/23.
//

import SwiftUI

struct LabelDisplayName: Identifiable {
    var id: Int { label }
    
    let label: Int
    let labelName: String
    
    var labelAsString: String { String(label) }
}


struct LabelsOverviewView: View {
    @Environment(\.managedObjectContext) var moc
    @Binding var loadedDatasets: Bool
    @EnvironmentObject var dataController: DataController
    
//    var sortedLabels: [(key: Int, value: String)] {
//        dataController.labelToName.sorted(by: { $0.key < $1.key })  //.map(\.key)
//    }
    
    @State private var labelDisplayNames: [LabelDisplayName] = []
    var sortedLabels: [LabelDisplayName] {
        dataController.labelToName.sorted(by: { $0.key < $1.key }).map { (label, displayName) in
            LabelDisplayName(label: label, labelName: displayName)
        }
    }
    
    
    @State private var isDisplayingErrorsAlert: Bool = false
    @State private var errorMessage: String = ""
    @State private var isDisplayingSuccessAlert: Bool = false
    
    @AppStorage(REConstants.UserDefaults.documentTextOpacity) var documentTextOpacity: Double = REConstants.UserDefaults.documentTextDefaultOpacity
    
    func promptUserForFile() {
        if let documentURL = FileManagementUtils().showNSOpenPanelForSingleFileSelection() {
            //print(documentURL.description)
            
            let _ = Task {
                do {
                    let updatedLabelsToName = try await dataController.readLabelsFileAsyncWithPrompt(documentURL: documentURL)
                    
                    // Update in memory and update database
                    try await dataController.updateDatabaseWithLabelDisplayNames(updatedLabelsToName: updatedLabelsToName, moc: moc)
                    
                    isDisplayingSuccessAlert = true
                } catch GeneralFileErrors.duplicateLabelsEncountered(let errorIndexEstimate) {
                    isDisplayingErrorsAlert = true
                    errorMessage = "Duplicate label encountered at line \(errorIndexEstimate)."
                } catch GeneralFileErrors.labelDisplayNameIsTooLong(let errorIndexEstimate) {
                    isDisplayingErrorsAlert = true
                    errorMessage = "Label at line \(errorIndexEstimate) is greater than the maximum allowed \(REConstants.DataValidator.maxLabelDisplayNameCharacters) characters."
                } catch GeneralFileErrors.blankLabelDisplayName(let errorIndexEstimate) {
                       isDisplayingErrorsAlert = true
                    errorMessage = "Label at line \(errorIndexEstimate) is blank."
                } catch GeneralFileErrors.outOfRangeLabel(let errorIndexEstimate) {
                    isDisplayingErrorsAlert = true
                    errorMessage = "Document format error encountered at line \(errorIndexEstimate). Only display names for labels 0 to \(dataController.numberOfClasses-1) can be changed."
                } catch GeneralFileErrors.documentFileFormatAtIndexEstimate(let errorIndexEstimate) {
                    isDisplayingErrorsAlert = true
                    errorMessage = "Document format error encountered at line \(errorIndexEstimate)."
                } catch GeneralFileErrors.maxFileSize {
                    isDisplayingErrorsAlert = true
                    errorMessage = "File is too large. Reduce the file to be under \(REConstants.DatasetsConstraints.maxJSONLabelsFileSize) MB."
                } catch GeneralFileErrors.noFileFound {
                    isDisplayingErrorsAlert = true
                    errorMessage = "File not found."
                } catch CoreDataErrors.saveError {
                    isDisplayingErrorsAlert = true
                    errorMessage = "Unable to save changes. Check that the project file is in a writable directory with sufficient disk space."
                } catch {
                    isDisplayingErrorsAlert = true
                    errorMessage = "Format error"
                }
            }
            
        }
    }

    
    var body: some View {
        if loadedDatasets {

            VStack {

                HStack(alignment: .lastTextBaseline) {

                    Button {
                        promptUserForFile()
                    } label: {
                        HStack {
                            Image(systemName: "plus.app")
                                .foregroundStyle(.blue.gradient)
                            Text("Upload a JSON lines file to change the label display names")
                                .foregroundStyle(.blue)
                        }
                        .font(.title2)
                    }
                    .buttonStyle(.borderless)
                    
                    Group {
                        Spacer()
                        HelpAssistanceView_AddLabels()
//                        Button {
//                        } label: {
//                            UncertaintyGraphControlButtonLabelWithCaptionVStack(buttonImageName: "questionmark.circle", buttonTextCaption: "Help", buttonForegroundStyle: AnyShapeStyle(Color.gray.gradient))
//                        }
//                        .buttonStyle(.borderless)
                    }
                }
                .padding()
                .alert("Unable to upload the labels file: \(errorMessage)", isPresented: $isDisplayingErrorsAlert) {
                    Button("OK") {
                    }
                }
                .alert("Successfully uploaded the labels file", isPresented: $isDisplayingSuccessAlert) {
                    Button("OK") {
                    }
                }
                Table(sortedLabels) {
                    TableColumn("Label") { labelDisplayName in
                        Text(labelDisplayName.labelAsString)
                    }
                    .width(min: 60, ideal: 60, max: 60)
                    TableColumn("Color") { labelDisplayName in
                        if labelDisplayName.label == REConstants.DataValidator.oodLabel || labelDisplayName.label == REConstants.DataValidator.unlabeledLabel {
                            Text("N/A")
                        } else {
                            Text(dataController.highlightLabeledStringAndReturnAsAttributedString(textString: "          ", label: labelDisplayName.label))
//                            Text(dataController.highlightLabeledStringAndReturnAsAttributedString(textString: "     This is some text using this color.     ", label: labelDisplayName.label))
                        }
                    }
                    .width(min: 100, ideal: 100, max: 100)
                    TableColumn("Display Name") { labelDisplayName in
                        Text(labelDisplayName.labelName)
                    }
                }
                .monospaced()
                .opacity(documentTextOpacity)
                .tableStyle(.inset(alternatesRowBackgrounds: true))
                .scrollBounceBehavior(.basedOnSize)
            }
            .font(REConstants.Fonts.baseFont)
            .padding()

        }
    }
}

