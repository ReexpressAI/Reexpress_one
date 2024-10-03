//
//  DocumentCardView.swift
//  Alpha1
//
//  Created by A on 6/18/23.
//

import SwiftUI

extension DocumentCardView {
    @MainActor class ViewModel: ObservableObject {
//
//        @Published var isShowingPredictionModal = false
//        @Published var isShowingUncertaintyModal = false
        @Published var isShowingAddDocumentsModal = false
        @Published var isShowingPostTrainingPredictionModal = false
        @Published var isShowingUncacheTrainingModal = false
        @Published var isShowingSummaryModal = false
        //@Published var isEditingUserSpecifiedNameField = false
        
        //@Published var userSpecifiedNameField = ""
    }
}

struct DocumentCardView: View {
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var dataController: DataController
    
    @StateObject private var viewModel = ViewModel()
    
    @State private var userSpecifiedNameField = ""
    @State private var isEditingUserSpecifiedNameField = false
    
    var dataset: InMemory_Dataset
    
    var shouldEmphasizeDataset: Bool {
        return isTraining || isCalibration
    }
    
    var isTraining: Bool {
        return dataset.id == REConstants.DatasetsEnum.train.rawValue
    }
    var isCalibration: Bool {
        return dataset.id == REConstants.DatasetsEnum.calibration.rawValue
    }
    var numberOfDocuments: Int {
        return dataset.count ?? 0
    }
    
    var datasplitFontSize: CGFloat = 14
    var datasplitMainNameFontSize: CGFloat = 16
    
    @State private var showingDeletionAlert = false
    @State private var showingDeletionProgress = false
    
    @State var isShowingCoreDataSaveError: Bool = false
    
    var body: some View {

        VStack {
            ZStack {
                TableRetrievalInProgressView(documentRetrievalInProgress: $showingDeletionProgress, progressText: "Deleting datasplit ...")
                    .frame(width: 100)
                VStack {
                    if dataset.id == REConstants.Datasets.placeholderDatasetId {
                        Spacer()
                        if dataController.numberOfEvalSets == REConstants.Datasets.maxEvalDatasets {
                            Text("To add an additional evaluation set, remove one of the existing evaluation sets.")
                                .italic()
                                .foregroundStyle(.gray)
                                .font(.system(size: 16))
                        } else {
                            Button {
                                try? dataController.addANewEvaluationSet(moc: moc)
                            } label: {
                                VStack(alignment: .center) {
                                    Image(systemName: "plus.app")
                                        .font(.title)
                                        .padding()
                                    Text("Add a new evaluation set")
                                }
                            }
                            .buttonStyle(.link)
                            .padding()
                            .background {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(
                                        AnyShapeStyle(BackgroundStyle()))
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.accentColor)
                            }
                        }
                        Spacer()
                    } else {
                        HStack {
                            Text("\(dataset.internalName)")
                                .foregroundStyle(shouldEmphasizeDataset ? .orange : .gray)
                                .opacity(shouldEmphasizeDataset ? 0.85 : 1.0)
                                .font(.system(size: datasplitFontSize).smallCaps())
                                .lineLimit(1)
                            Spacer()
                            Text("(id: \(dataset.id))")
                                .monospaced(true)
                                .foregroundStyle(.gray)
                                .font(.system(size: datasplitFontSize))
                        }
                        Text(userSpecifiedNameField)
                            .font(.system(size: datasplitMainNameFontSize))
                            .lineLimit(1)
                            .padding()
                        HStack(alignment: .lastTextBaseline) {
                            Button {
                                viewModel.isShowingAddDocumentsModal.toggle()
                            } label: {
                                UncertaintyGraphControlButtonLabelWithCaptionVStack(buttonImageName: "doc.badge.plus", buttonTextCaption: "Add")
                            }
                            .buttonStyle(.borderless)
                            .sheet(isPresented: $viewModel.isShowingAddDocumentsModal,
                                   onDismiss: nil) {
                                AddDocumentsView(datasetId: dataset.id)
                                    .padding()
                                    .frame(
                                        minWidth: 800, maxWidth: 800,
                                        minHeight: 600, maxHeight: 600)
                                    .onExitCommand { // disables user ESC action from the modal
                                    }
                            }
                            
                            Button {
                                isEditingUserSpecifiedNameField.toggle()
                            } label: {
                                UncertaintyGraphControlButtonLabelWithCaptionVStack(buttonImageName: "square.and.pencil", buttonTextCaption: "Rename", buttonForegroundStyle: (isTraining || isCalibration) ? AnyShapeStyle(Color.gray.gradient) : AnyShapeStyle(Color.blue.gradient))
                            }
                            .buttonStyle(.borderless)
                            .disabled(isTraining || isCalibration)  // It'll just be confusing for users if the Training or Calibration names are changed, so we disable that here
                            .onAppear {
                                // Default value for the TextField in the edit name alert
                                userSpecifiedNameField = dataset.userSpecifiedName ?? ""
                            }
                            .sheet(isPresented: $isEditingUserSpecifiedNameField,
                                   onDismiss: nil) {
                                RenameDatasplitNameView(userSpecifiedNameField: $userSpecifiedNameField, datasetId: dataset.id)
                                    .padding()
                                    .frame(
                                     minWidth: 600, maxWidth: 800,
                                     minHeight: 250, maxHeight: 250)
                            }
                        }
                        HStack(alignment: .lastTextBaseline) {
                            Button {
                                //
                                viewModel.isShowingPostTrainingPredictionModal.toggle()
                            } label: {
                                UncertaintyGraphControlButtonLabelWithCaptionVStack(buttonImageName: "baseball.diamond.bases", buttonTextCaption: "Predict")
                            }
                            .buttonStyle(.borderless)
                            .sheet(isPresented: $viewModel.isShowingPostTrainingPredictionModal,
                                   onDismiss: nil) {

                                SetupMainForwardView(datasetId: dataset.id)
//                                SetupMainForwardAfterTrainingView(datasetId: dataset.id) //PostTrainingPredictionView(datasetId: dataset.id)
//                                    .onExitCommand { // disables user ESC action from the modal
//                                    }
                                    .interactiveDismissDisabled(true)
                                    .padding()
                                    .frame(
                                        minWidth: 800, maxWidth: 800,
                                        minHeight: 600, idealHeight: 800, maxHeight: 800)

                            }
                            
                            Button {
                                // Mark all as unviewed
                                viewModel.isShowingSummaryModal.toggle()
                            } label: {
                                UncertaintyGraphControlButtonLabelWithCaptionVStack(buttonImageName: "rectangle.and.text.magnifyingglass", buttonTextCaption: "Summary")
                            }
                            .buttonStyle(.borderless)
                            .popover(isPresented: $viewModel.isShowingSummaryModal) {
                                DocumentSummaryView(datasetId: dataset.id)
                                    .padding()
                                    .modifier(SimpleBaseBorderModifier())
                                    .padding()
                                    .frame(width: 600, height: 450)
                            }
                            //=== AttributeGraph: cycle detected through attribute
//                            .sheet(isPresented: $viewModel.isShowingSummaryModal,
//                                   onDismiss: nil) {
//                                DocumentSummaryView(datasetId: dataset.id)
//                                    .padding()
//                                    .modifier(SimpleBaseBorderModifier())
//                                    .padding()
//                                    .frame(width: 600, height: 450)
//                            }
                            
                        }
                        HStack(alignment: .lastTextBaseline) {
                            Button {
                                viewModel.isShowingUncacheTrainingModal.toggle()
                            } label: {
                                UncertaintyGraphControlButtonLabelWithCaptionVStack(buttonImageName: "minus.diamond", buttonTextCaption: "Uncache")
                            }
                            .buttonStyle(.borderless)
                            .sheet(isPresented: $viewModel.isShowingUncacheTrainingModal,
                                   onDismiss: nil) {

                                UncacheEmbeddingsView(datasetId: dataset.id)
                                    .padding()
                                    .frame(
                                        minWidth: 800, maxWidth: 800,
                                        minHeight: 600, idealHeight: 600, maxHeight: 650)
                            }
                            
                            Button {
                                showingDeletionAlert = true
                                //                        try? dataController.deleteDataset(datasetIdInt: dataset.id, moc: moc)
                            } label: {
                                UncertaintyGraphControlButtonLabelWithCaptionVStack(buttonImageName: "clear", buttonTextCaption: "Delete")
                            }
                            .buttonStyle(.borderless)
                            .alert("Delete this datasplit?", isPresented: $showingDeletionAlert) {
                                Button("Delete", role: .destructive) {
                                    Task {
                                        await MainActor.run {
                                            showingDeletionProgress = true
                                        }
                                        do {
                                            try await dataController.deleteDataset(datasetIdInt: dataset.id, moc: moc)
                                        } catch {
                                            isShowingCoreDataSaveError = true
                                        }
                                        await MainActor.run {
                                            // refresh name for display (this is a bit hacky, but we need to revert to the datasplit name from the defaults. The correct value is in the database, but will otherwise not be updated in the view until a forced refresh):
                                            if let datasetEnum = REConstants.DatasetsEnum(rawValue: dataset.id) {
                                                userSpecifiedNameField = REConstants.Datasets.getUserSpecifiedName(datasetId: datasetEnum)
                                            }
//                                            userSpecifiedNameField = dataset.userSpecifiedName ?? ""
                                            showingDeletionProgress = false
                                        }
                                    }
                                }
                                Button("Cancel", role: .cancel) { }
                            } message: {
                                Text("WARNING: This operation cannot be undone and will remove all data associated with this datasplit.")
                            }
                            .alert(REConstants.GeneralErrors.coreDataSaveMessage, isPresented: $isShowingCoreDataSaveError) {
                                Button("OK") {
                                }
                            }
                        }
                        Spacer()
                        Divider()
                        Spacer()
                        Grid(alignment: .leadingFirstTextBaseline, verticalSpacing: 10) {
                            GridRow {
                                Text("Document count:")
                                    .foregroundStyle(.gray)
                                    .gridCellAnchor(.trailing)
                                Text("\(numberOfDocuments)")
                                    .monospaced(true)
                                    .gridCellAnchor(.leading)
                            }
 
                        }
                        Spacer()
                    }
                }
            }
        }
    }
}


