//
//  AddDocumentsView.swift
//  Alpha1
//
//  Created by A on 6/18/23.
//

/*
 This handles uploading of the documents (JSON lines files). The high-level structure and behavior is as follows:
 - This view is expected to be presented as a modal.
 - A user can upload multiple files at a time. Each file is associated with a single dataset.
 - Choosing multiple files with the same URL is not allowed. However, multiple documents with the same id can be uploaded, with the most recent upload taking precedence and overwritting the database file for the id.
 - Once the files are selected, a user clicks "Upload". Successful file uploads are marked as such with a note in the List row for the file. Failure cases can be replaced with a new file and uploaded, removed from consideration, or the user can click "Done" and not re-try to upload.
 - Once a file has been selected, a user can click the "Edit" button in order to select one or more files that have not yet been succesfully uploaded and then clear those selected files if they click "Clear". Note that this only removes the files from those that can be uploaded, and is distinct from deleting a file, which is possible after a file has been uploaded by clicking "Delete" on the main cards screen.
 - Uploading is generally fast (since no tokenization nor forward passes are run). In typical file sizes, the only lag tends to occur if a file is replaced (i.e., identical document id's). Currently, replacement may temporarily block the main thread.
 - We do not currently allow cancellation of the upload task. As implied above, the only noticable delay is on moc.save(), which is not cancellable in a straightforward manner (without moving the Core Data operations to a background thread), so at the moment, we simply do not implement Task cancelation and navigation when an upload is started. Note that hitting the ESC key to dismiss the modal is disabled in the caller to this view via .onExitCommand{}.
 - The current structure assumes that typically only at most a handful of files will be selected at a time, since each file must be selected one at a time and the destination datasplit selected. (That is, multiple selection is disabled in the File Open window.) If users have one instance per file/etc., they are advised to group them together into batched files, which is quite natural and easy given the JSON lines format.
 */

import SwiftUI

extension AddDocumentsView {
    enum GlobalBatchDocumentUploadStatus: Int, CaseIterable {
        case base
        case uploading
    }
    /// Status for an individual document file
    enum DocumentUploadStatus: Int, CaseIterable {
        case stagedForUpload // initial case when a file is chosen
        case uploading
        case success
        case failed
        
        static func availableForEdit(status: DocumentUploadStatus) -> Bool {
            return status == DocumentUploadStatus.stagedForUpload || status == DocumentUploadStatus.failed
        }
    }
    
    struct DocumentUploadItem: Identifiable {
        var id: URL
        var datasplitDestination: Int
        var uploadStatus: DocumentUploadStatus = .stagedForUpload
        var isSelected: Bool = false
        var uploadErrorMessage: String = ""
    }
    
    @MainActor class ViewModel: ObservableObject {
        @Published var uploadItems: [DocumentUploadItem] = []
        var uploadItemIdsSet = Set<URL>()  // used internally to ensure duplicate files are not added
        @Published var displayErrorView: Bool = false
        
        let errorMessage = "File already selected"
        
        func stageAnUploadItem(url: URL, datasplitDestination: Int, isAReplacementAtIndex: Int? = nil) throws {
            if uploadItemIdsSet.contains(url) {
                throw DocumentUploadErrors.fileAlreadySelected
            }
            var documentUploadItem = DocumentUploadItem(id: url, datasplitDestination: datasplitDestination, uploadStatus: .stagedForUpload, isSelected: false)
            if let replacementIndex = isAReplacementAtIndex {
                if replacementIndex < uploadItems.count {
                    // update destination to current selection
                    documentUploadItem.datasplitDestination = uploadItems[replacementIndex].datasplitDestination
                    uploadItems[replacementIndex] = documentUploadItem
                    uploadItemIdsSet.insert(url)
                } else {
                    throw DocumentUploadErrors.indexError
                }
            } else {
                uploadItems.append(documentUploadItem)
                uploadItemIdsSet.insert(url)
            }
        }
        /// Deletion by recreating the structures. (Kept simple since this array will always be small.)
        func deleteSelectedItems() {
            var newUploadItems: [DocumentUploadItem] = []
            var newUploadItemIdsSet = Set<URL>()
            for uploadItemIndex in 0..<uploadItems.count {
                if !uploadItems[uploadItemIndex].isSelected {
                    newUploadItems.append(uploadItems[uploadItemIndex])
                    newUploadItemIdsSet.insert(uploadItems[uploadItemIndex].id)
                }
            }
            uploadItems = newUploadItems
            uploadItemIdsSet = newUploadItemIdsSet
        }
        
        func displayUploadErrorView() async {
            await MainActor.run {
                displayErrorView = false
                withAnimation {
                    displayErrorView = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.displayErrorView = false
                }
            }
        }
        
        func promptUserForFile(datasetId: Int, isAReplacementAtIndex: Int? = nil) {
            if let documentURL = FileManagementUtils().showNSOpenPanelForSingleFileSelection() {
                do {
                    try stageAnUploadItem(url: documentURL, datasplitDestination: datasetId, isAReplacementAtIndex: isAReplacementAtIndex)
                } catch {
                    Task {
                        await displayUploadErrorView()
                    }
                }
            }
        }
        
    }
}

struct AddDocumentsView: View {
    @Environment(\.managedObjectContext) var moc
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var dataController: DataController
    
    var datasetId: Int
    
    @StateObject var viewModel = ViewModel()
    
    func getDatatsplitNameForDisplay(localDatasetId: Int) -> String {
        if let dataset = dataController.inMemory_Datasets[localDatasetId] {
            if let datasetName = dataset.userSpecifiedName {
                return datasetName
            } else {
                return "\(dataset.internalName) (\(dataset.id)"
            }
        }
        return ""
    }
    
    @State var selectAll: Bool = false
    @State var inEditMode: Bool = false
    
    @State var dataLoadTask: Task<Void, Error>?
//    @State var dataLoadTask: Task<Void, Never>?
    
    let displayColumnPickerMenuWidth: CGFloat = 250
    
    @State var globalBatchDocumentUploadStatus: GlobalBatchDocumentUploadStatus = .base
    
    func atLeastOneSelection() -> Bool {
        for uploadItemIndex in 0..<viewModel.uploadItems.count {
            if viewModel.uploadItems[uploadItemIndex].isSelected {
                return true
            }
        }
        return false
    }
    func resetSelection() {
        selectAll = false
        for uploadItemIndex in 0..<viewModel.uploadItems.count {
            viewModel.uploadItems[uploadItemIndex].isSelected = false
        }
    }
    
    func atLeastOneStagedDocument() -> Bool {
        for uploadItemIndex in 0..<viewModel.uploadItems.count {
            if viewModel.uploadItems[uploadItemIndex].uploadStatus == .stagedForUpload {
                return true
            }
        }
        return false
    }
    func atLeastOneSucessfullyUploadedDocument() -> Bool {
        for uploadItemIndex in 0..<viewModel.uploadItems.count {
            if viewModel.uploadItems[uploadItemIndex].uploadStatus == .success {
                return true
            }
        }
        return false
    }
    func atLeastOneDocumentAvailableForEdit() -> Bool {
        for uploadItemIndex in 0..<viewModel.uploadItems.count {
            if DocumentUploadStatus.availableForEdit(status: viewModel.uploadItems[uploadItemIndex].uploadStatus) {
                return true
            }
        }
        return false
    }

    var body: some View {
        ZStack {
            TransientErrorView(displayErrorView: $viewModel.displayErrorView, errorMessage: viewModel.errorMessage)
            
            VStack(alignment: .leading) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Upload documents")
                            .font(.title2.bold())
                        Text("JSON Lines format")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    Spacer()
                    HStack(alignment: .firstTextBaseline) {
                        Spacer()
                        Button {
                            withAnimation {
                                viewModel.deleteSelectedItems()
                                resetSelection()
                                inEditMode = false
                            }
                            
                        } label: {
                            UncertaintyGraphControlButtonLabelWithCaptionVStack(buttonImageName: "clear", buttonTextCaption: "Clear", buttonForegroundStyle: AnyShapeStyle(Color.red.gradient))
                        }
                        .buttonStyle(.borderless)
                        .opacity(inEditMode && atLeastOneSelection() ? 1.0 : 0.0)
                        Button {
                            withAnimation {
                                resetSelection()
                                inEditMode.toggle()
                            }
                        } label: {
                            UncertaintyGraphControlButtonLabelWithCaptionVStack(buttonImageName: inEditMode ? "app.badge.checkmark.fill" : "app.badge.checkmark", buttonTextCaption: "Edit")
                        }
                        .buttonStyle(.borderless)
                        .opacity(atLeastOneDocumentAvailableForEdit() ? 1.0 : 0.0)
                        
                        HelpAssistanceView_AddData()
                        /*Button {
                        } label: {
                            UncertaintyGraphControlButtonLabelWithCaptionVStack(buttonImageName: "questionmark.circle", buttonTextCaption: "Help", buttonForegroundStyle: AnyShapeStyle(Color.gray.gradient))
                        }
                        .buttonStyle(.borderless)*/
                    }
                }
                
                
                List {
                    Label("", systemImage: selectAll ? "checkmark.square.fill" : "square")
                        .font(.title2)
                        .foregroundStyle(.blue.gradient)
                        .labelStyle(.iconOnly)
                        .onTapGesture {
                            selectAll.toggle()
                            for uploadItemIndex in 0..<viewModel.uploadItems.count {
                                if DocumentUploadStatus.availableForEdit(status: viewModel.uploadItems[uploadItemIndex].uploadStatus) {
                                    viewModel.uploadItems[uploadItemIndex].isSelected = selectAll
                                } else {
                                    viewModel.uploadItems[uploadItemIndex].isSelected = false
                                }
                            }
                        }
                        .opacity(inEditMode ? 1.0 : 0.0)
                        .listRowSeparator(.hidden)
                    Divider()
                    ForEach(0..<viewModel.uploadItems.count, id:\.self) { uploadItemIndex in
                        HStack(alignment: .center) {
                            if inEditMode && DocumentUploadStatus.availableForEdit(status: viewModel.uploadItems[uploadItemIndex].uploadStatus) {
                                
                                Label("", systemImage: viewModel.uploadItems[uploadItemIndex].isSelected ? "checkmark.square.fill" : "square")
                                    .font(.title2)
                                    .foregroundStyle(.blue.gradient)
                                    .labelStyle(.iconOnly)
                                    .onTapGesture {
                                        viewModel.uploadItems[uploadItemIndex].isSelected.toggle()
                                        
                                        var nowAllSelected = true
                                        for uploadItemIndex in 0..<viewModel.uploadItems.count {
                                            if !viewModel.uploadItems[uploadItemIndex].isSelected {
                                                nowAllSelected = false
                                                break
                                            }
                                        }
                                        selectAll = nowAllSelected
                                    }
                            }
                            Grid {
                                GridRow {
                                    Text("File:")
                                        .gridColumnAlignment(.trailing)
                                        .foregroundStyle(.secondary)
                                    Text(viewModel.uploadItems[uploadItemIndex].id.lastPathComponent)
                                        .lineLimit(1)
                                        .monospaced(true)
                                        .gridColumnAlignment(.leading)
                                }
                                .font(.title2)
                                .onTapGesture {
                                    inEditMode = false
                                    viewModel.promptUserForFile(datasetId: datasetId, isAReplacementAtIndex: uploadItemIndex)
                                }
                                switch viewModel.uploadItems[uploadItemIndex].uploadStatus {
                                case .stagedForUpload:
                                    GridRow {
                                        Text("Destination datasplit:")
                                            .font(.title2)
                                            .foregroundStyle(.secondary)
                                        
                                        Picker(selection: $viewModel.uploadItems[uploadItemIndex].datasplitDestination ) {
                                            ForEach(Array(dataController.inMemory_Datasets.keys.sorted()), id: \.self) { datasetId in
                                                
                                                if (datasetId != REConstants.Datasets.placeholderDatasetId) {
                                                    if let dataset = dataController.inMemory_Datasets[datasetId] {
                                                        if let datasetName = dataset.userSpecifiedName {
                                                            Text("\(datasetName)").tag(datasetId)
                                                        } else {
                                                            Text("\(dataset.internalName) (\(dataset.id)").tag(datasetId)
                                                        }
                                                    }
                                                }
                                            }
                                        } label: {
                                        }
                                        .frame(width: displayColumnPickerMenuWidth)
                                    }
                                case .uploading:
                                    GridRow {
                                        ProgressView()
                                            .gridCellColumns(2)
                                    }
                                case .success:
                                    GridRow {
                                        Text("Succesfully uploaded to:")
                                            .font(.title2)
                                            .foregroundStyle(.green.gradient)
                                            .opacity(0.75)
                                        Text("\(getDatatsplitNameForDisplay(localDatasetId: viewModel.uploadItems[uploadItemIndex].datasplitDestination))")
                                            .font(.title2.lowercaseSmallCaps())
                                    }
                                case .failed:
                                    GridRow {
                                        if viewModel.uploadItems[uploadItemIndex].uploadErrorMessage != "" {
                                            Text("Upload failed.")
                                                .font(.title2)
                                                .foregroundStyle(.red.gradient)
                                                .opacity(0.75)
                                            Text(viewModel.uploadItems[uploadItemIndex].uploadErrorMessage)
                                                .font(.title2)
                                                .foregroundStyle(.red.gradient)
                                                .opacity(0.75)
                                        } else {
                                            Text("Upload failed.")
                                                .font(.title2)
                                                .foregroundStyle(.red.gradient)
                                                .opacity(0.75)
                                                .gridCellColumns(2)
                                        }
                                    }
                                }
                                
                            }
                            .padding(.leading, 20)
                        }
                        Divider()
                    }
                    .listRowSeparator(.hidden)
                    HStack {
                        Label(viewModel.uploadItems.count == 0 ? "Choose a file" : "Choose an additional file" , systemImage: "plus.app")
                            .font(.title2)
                            .opacity(globalBatchDocumentUploadStatus == .uploading ? 0.5 : 1.0)
                        Spacer()
                        Rectangle()  // This is to make the entire row selectable
                            .fill(BackgroundStyle())
                            .frame(maxWidth: .infinity)
                        
                    }
                    .listRowSeparator(.hidden)
                    .onTapGesture {
                        if globalBatchDocumentUploadStatus != .uploading {
                            inEditMode = false
                            viewModel.promptUserForFile(datasetId: datasetId)
                        }
                    }
                    Divider()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                if atLeastOneSucessfullyUploadedDocument() {
                    Button("Done") {
                        dismiss()
                    }
                    .disabled(globalBatchDocumentUploadStatus == .uploading)
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Cancel") {
                        /// MARK: Note: We disabled cancelation of the task since the actual reading of the file is typically quite fast. The only typically noticable delay is with moc.save(); however, that cannot be canceled and can cause a hang if it is processing while the parent task is canceled (even though moc.save() is on the main thread).
                        //                    dataLoadTask?.cancel()
                        dismiss()
                    }
                    .disabled(globalBatchDocumentUploadStatus == .uploading)
                }
                
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Upload") {
                    dataLoadTask = Task { //[weak viewModel] in //[viewModel, dataController] in //[self, viewModel, dataController] in
//                        guard let thisViewModel = viewModel else { return }
//                        let url = thisViewModel.uploadItems[0].id
//                        //let msc =
////                        try await MyServiceClass(url: url).runAsync()
//                        await MyServiceClass().runAsync(thisURL: url)
//
//                        /*var jsonDocumentArray = [JSONDocument]()
//                        //var documentTextArray = [String]()
//                        var counter = 0
//                        for try await line in url.lines {
//                            counter += 1
//                            if let lineAsData = line.data(using: .utf8) {
//                                if Task.isCancelled {
//                                    break
//                                }
//                                //            let oneActor = try JSONDecoder().decode(Actor.self, from: lineAsData)
//                                do {
//                                    var oneDocument = try? JSONDecoder().decode(JSONDocument.self, from: lineAsData)
//                                    if let oneD = oneDocument {
//                                        jsonDocumentArray.append(oneD)
//                                    }
//                                    //try validateJSONDocument(aJSONDocument: oneDocument)
//                                }
//                            }
//                        }*/
                        
                        
                        //var jsonDocumentArray = try await dataController.readAsyncWithPrompt(documentURL: url, defaultPrompt: dataController.defaultPrompt)
                        //print(jsonDocumentArray.count)
                        
                        globalBatchDocumentUploadStatus = .uploading
                        
                        for uploadItemIndex in 0..<viewModel.uploadItems.count {
                            if viewModel.uploadItems[uploadItemIndex].uploadStatus == .stagedForUpload {
                                let url = viewModel.uploadItems[uploadItemIndex].id
                                let destinationDatasetId = viewModel.uploadItems[uploadItemIndex].datasplitDestination
//                                print("Index: \(uploadItemIndex)")
//                                print("URL: \(url)")
//                                print("destinationDatasetId: \(destinationDatasetId)")
                                viewModel.uploadItems[uploadItemIndex].uploadStatus = .uploading
                                do {
                                    
                                    //let prompt = "Please classify the sentiment of the following movie review:"
                                    //        let prompt = "Does the answer correctly address the question? Please answer yes or no and explain your reasoning step-by-step."
                                    //        let prompt = "Please answer the following question and explain your reasoning step-by-step."
                                    var jsonDocumentArray = try await dataController.readAsyncWithPrompt(documentURL: url, defaultPrompt: dataController.defaultPrompt)
//                                    let jsonDocumentsStructure = try await dataController.readAsync(documentURL: url)
                                    //print("done reading: \(jsonDocumentArray.count)")
                                    //if !Task.isCancelled {
                                    try await dataController.addPreTokenizationDocumentsForDataset(jsonDocumentArray: jsonDocumentArray, datasetId: destinationDatasetId, moc: moc)
                                    //print("done adding")
                                    // MARK: Todo: Memory is getting retained
                                    jsonDocumentArray = []
                                    try await dataController.updateInMemoryDatasetStats(moc: moc, dataController: dataController)
                                    //print("done updating")
                                    viewModel.uploadItems[uploadItemIndex].uploadStatus = .success
                                    
                                } catch GeneralFileErrors.documentMaxIDRawCharacterLength(let errorIndexEstimate) {
                                    viewModel.uploadItems[uploadItemIndex].uploadStatus = .failed
                                    viewModel.uploadItems[uploadItemIndex].uploadErrorMessage = "Document format error encountered at line \(errorIndexEstimate). The id field must be no more than \(REConstants.DataValidator.maxIDRawCharacterLength) characters."
                                } catch GeneralFileErrors.documentLabelFormat(let errorIndexEstimate) {
                                    viewModel.uploadItems[uploadItemIndex].uploadStatus = .failed
                                    viewModel.uploadItems[uploadItemIndex].uploadErrorMessage = "Document format error encountered at line \(errorIndexEstimate). The label field's value is invalid."
                                } catch GeneralFileErrors.documentMaxDocumentRawCharacterLength(let errorIndexEstimate) {
                                    viewModel.uploadItems[uploadItemIndex].uploadStatus = .failed
                                    viewModel.uploadItems[uploadItemIndex].uploadErrorMessage = "Document format error encountered at line \(errorIndexEstimate). The document field must be no more than \(REConstants.DataValidator.maxDocumentRawCharacterLength) characters."
                                } catch GeneralFileErrors.documentMaxInfoRawCharacterLength(let errorIndexEstimate) {
                                    viewModel.uploadItems[uploadItemIndex].uploadStatus = .failed
                                    viewModel.uploadItems[uploadItemIndex].uploadErrorMessage = "Document format error encountered at line \(errorIndexEstimate). The info field (if provided) must be no more than \(REConstants.DataValidator.maxInfoRawCharacterLength) characters."
                                } catch GeneralFileErrors.documentMaxInputAttributeSize(let errorIndexEstimate) {
                                    viewModel.uploadItems[uploadItemIndex].uploadStatus = .failed
                                    viewModel.uploadItems[uploadItemIndex].uploadErrorMessage = "Document format error encountered at line \(errorIndexEstimate). The attributes field (if provided) must be an array of numbers. The array can be any length between 0 and \(REConstants.DataValidator.maxInputAttributeSize)."
                                } catch GeneralFileErrors.documentMaxPromptRawCharacterLength(let errorIndexEstimate) {
                                    viewModel.uploadItems[uploadItemIndex].uploadStatus = .failed
                                    viewModel.uploadItems[uploadItemIndex].uploadErrorMessage = "Document format error encountered at line \(errorIndexEstimate). The prompt field (if provided) must be no more than \(REConstants.DataValidator.maxPromptRawCharacterLength) characters."
                                } catch GeneralFileErrors.documentMaxGroupRawCharacterLength(let errorIndexEstimate) {
                                    viewModel.uploadItems[uploadItemIndex].uploadStatus = .failed
                                    viewModel.uploadItems[uploadItemIndex].uploadErrorMessage = "Document format error encountered at line \(errorIndexEstimate). The group field (if provided) must be no more than \(REConstants.DataValidator.maxGroupRawCharacterLength) characters."
                                } catch GeneralFileErrors.documentFileFormatAtIndexEstimate(let errorIndexEstimate) {
                                    viewModel.uploadItems[uploadItemIndex].uploadStatus = .failed
                                    viewModel.uploadItems[uploadItemIndex].uploadErrorMessage = "Document format error encountered at line \(errorIndexEstimate)."
                                } catch GeneralFileErrors.maxFileSize {
                                    viewModel.uploadItems[uploadItemIndex].uploadStatus = .failed
                                    viewModel.uploadItems[uploadItemIndex].uploadErrorMessage = "File is too large. Each individual file must be less than \(REConstants.DatasetsConstraints.maxFileSize) MB."
                                } catch GeneralFileErrors.noFileFound {
                                    viewModel.uploadItems[uploadItemIndex].uploadStatus = .failed
                                    viewModel.uploadItems[uploadItemIndex].uploadErrorMessage = "File not found."
                                } catch GeneralFileErrors.maxTotalLinesInASingleJSONLinesFileLimit {
                                    viewModel.uploadItems[uploadItemIndex].uploadStatus = .failed
                                    viewModel.uploadItems[uploadItemIndex].uploadErrorMessage = "Each individual file can have no more than \(REConstants.DatasetsConstraints.maxTotalLines) lines."
                                } catch {
                                    viewModel.uploadItems[uploadItemIndex].uploadStatus = .failed
                                    viewModel.uploadItems[uploadItemIndex].uploadErrorMessage = ""
                                }
                            }
                        }
                        globalBatchDocumentUploadStatus = .base
                        //dataLoadTask = nil
                        
                    }
                }
                .disabled(inEditMode || globalBatchDocumentUploadStatus == .uploading || !atLeastOneStagedDocument())
                .buttonStyle(.borderedProminent)
            }
        }
        .onDisappear {
//                print("did onDisappear add view")
//            print("\(dataLoadTask?.isCancelled ?? false ? "cancelled" : "not cancelled")")
            dataLoadTask?.cancel()
            
//            print("\(dataLoadTask?.isCancelled ?? false ? "cancelled" : "not cancelled")")
            dataLoadTask = nil
        }
//        .interactiveDismissDisabled(true) NOTE: This is overridden with the presence of ToolbarItem(placement: .cancellationAction)
    }
}

struct AddDocumentsView_Previews: PreviewProvider {
    static var previews: some View {
        AddDocumentsView(datasetId: 0)
    }
}

