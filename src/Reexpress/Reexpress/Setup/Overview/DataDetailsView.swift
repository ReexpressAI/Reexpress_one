//
//  DataDetailsView.swift
//  Alpha1
//
//  Created by A on 8/10/23.
//

import SwiftUI
import Accelerate


struct DataDetailsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var dataController: DataController
    
    @Binding var selectedDocument: Document.ID?  // We directly access the Managed Object via documentObject, but we use this to refresh the view.
    //@Binding var datasetId: Int?
    @Binding var documentObject: Document?
    var searchParameters: SearchParameters?  // these are needed in order to highlight any keywords, as applicable
    var semanticSearchParameters: SemanticSearchParameters?
    
    var disableFeatureSearchViewAndDestructiveActions: Bool = false // can disable to prevent infinite depth modals+popover's
    var calledFromTableThatNeedsUpdate: Bool = true
    var showDismissButton: Bool = false  // if call on pop-up, easier to close the window
    @State private var showingFeatureSearchView: Bool = false
    @State private var showingHighlightAdditionalInfoView: Bool = false
    
    @State private var showingMatchingView: Bool = false
    
    @State private var locked: Bool = true
    @State private var isShowingLastModifiedInfoPopover: Bool = false
    @State private var showingDisplayOptionsPopover: Bool = false
    
    @State private var isShowingCoreDataSaveError: Bool = false
    @State private var isShowingLabelChangeView: Bool = false
    @State private var isShowingDatasplitTransferView: Bool = false
    
    @State private var showingDeletionAlert: Bool = false
    
    @State var showingEditGroupFieldView: Bool = false
    @State var showingEditInfoFieldView: Bool = false
    
    func refreshInterface() {
        // MARK: This works to update the view, but it is a bit hacky. This is necessary so that the changes in the ManagedObject get propagated to the view (e.g., the selected row in the table without having to change rows). Note that currently there is a failure case if the main table (i.e., the table on the left) is put into a separate view -- in that case the table view does not get updated, so we have in-lined that table in DataOverviewView.
        if calledFromTableThatNeedsUpdate {
            // When table is on left, need to use this to ensure that the table is concurrently updated.
//            let tempDocID = selectedDocument
//            selectedDocument = nil
//            selectedDocument = tempDocID
            
            let tempDoc = documentObject
            documentObject = nil
            documentObject = tempDoc
            
            let tempDocID = selectedDocument
            selectedDocument = nil
            selectedDocument = tempDocID
            
            
        } else {  // if selectedDocument is called with a constant:
            let tempDoc = documentObject
            documentObject = nil
            documentObject = tempDoc
        }
    }
    var body: some View {
        VStack {
            ScrollView {
                HStack {
                    Text("Details")
                        .foregroundStyle(.gray)
                        .font(.title)
                    //.bold()
                    //                        .font(REConstants.Fonts.baseFont)
                    Spacer()
                    
                    Button {
                        showingDisplayOptionsPopover.toggle()
                    } label: {
                        Image(systemName: "gear")
                            .foregroundStyle(.blue.gradient)
                            .font(REConstants.Fonts.baseFont)
                    }
                    .buttonStyle(.borderless)
                    .popover(isPresented: $showingDisplayOptionsPopover, arrowEdge: .top) {
                        GlobalTextDisplayOptionsView()
                    }
                    .padding(.trailing)
                    if showDismissButton {
                        SimpleCloseButton()
                        /*Button {
                            dismiss()
                        } label: {
                            Text("Close")
                                .font(REConstants.Fonts.baseFont.smallCaps())
                        }
                        .buttonStyle(.borderless)
                        .padding(.trailing)*/
                    }
                }
                .padding([.bottom])
                
                Group {
                    HStack {
                        VStack {
                            HStack(alignment: .lastTextBaseline) {
                                Text("Last Viewed")
                                    .font(.title3)
                                    .foregroundStyle(.gray)
                                Spacer()
                            }
                            .padding([.leading, .trailing])
                            
                            HStack(alignment: .top) {
                                
                                if let docObj = documentObject {
                                    if docObj.viewed, let lastViewedDate = docObj.lastViewed {
                                        Label("", systemImage: "eye")
                                            .foregroundStyle(.blue.gradient)
                                        Text(lastViewedDate, formatter: REConstants.dateFormatter)
//                                            .foregroundColor(.blue)
                                            .foregroundColor(.gray)
                                            .font(REConstants.Fonts.baseFont)
                                    } else {
                                        Label("", systemImage: "eye.slash")
                                            .foregroundStyle(.blue.gradient)
                                        Text("Unviewed")
                                            .foregroundColor(.gray)
//                                            .foregroundColor(.blue)
                                            .font(REConstants.Fonts.baseFont)
                                    }
                                    Spacer()
                                } else {
                                    Text("")
                                }
                            }
                            .frame(minHeight: 20, maxHeight: 20)
                            .padding()
                            .modifier(PrimaryComponentsViewModifier(useReBackgroundDarker: false, viewBoxScaling: 4))
                            .padding([.leading, .trailing])
                            .onTapGesture {
                                do {
                                    try dataController.toggleViewPropertyForOneDocument(documentObject: documentObject, moc: moc)
                                    refreshInterface()
                                } catch {
                                    isShowingCoreDataSaveError = true
                                }
                                
                            }
                        }
                        VStack {
                            HStack(alignment: .lastTextBaseline) {
                                Text("Last Modified")
                                    .font(.title3)
                                    .foregroundStyle(.gray)
                                PopoverViewWithButton(isShowingInfoPopover: $isShowingLastModifiedInfoPopover, popoverViewText: REConstants.HelpAssistanceInfo.lastModifiedInfoString)
                                Spacer()
                            }
                            .padding([.leading, .trailing])
                            
                            HStack(alignment: .top) {
                                
                                if let docObj = documentObject {
                                    if docObj.modified, let lastModifiedDate = docObj.lastModified {
                                        Text(lastModifiedDate, formatter: REConstants.dateFormatter)
                                            .foregroundColor(.gray)
                                            .font(REConstants.Fonts.baseFont)
                                    } else {
                                        Text("Unmodified")
                                            .foregroundColor(.gray)
                                            .font(REConstants.Fonts.baseFont)
                                    }
                                    Spacer()
                                } else {
                                    Text("")
                                }
                            }
                            .frame(minHeight: 20, maxHeight: 20)
                            .padding()
                            .modifier(PrimaryComponentsViewModifier(useReBackgroundDarker: false, viewBoxScaling: 4))
                            .padding([.leading, .trailing])
                        }
                    }
                }
                Group {
                    HStack {
                        VStack {
                            HStack(alignment: .lastTextBaseline) {
                                Text(REConstants.CategoryDisplayLabels.labelFull)
                                    .font(.title3)
                                    .foregroundStyle(.gray)
                                Spacer()
                            }
                            .padding([.leading, .trailing])
                            HStack(alignment: .top) {
                                if let docObj = documentObject {
                                    Label("", systemImage: "rectangle.and.pencil.and.ellipsis")
                                        .foregroundStyle(.blue.gradient)
                                    
                                    if let labelDisplayName = dataController.labelToName[docObj.label] {
                                        Text(labelDisplayName)
                                            //.foregroundColor(.white)
//                                            .foregroundColor(.blue)
                                        //.textSelection(.enabled)
                                            .monospaced()
                                            .font(REConstants.Fonts.baseFont)
                                            .lineSpacing(12.0)
                                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                                    } else {
                                        //                                    HStack {
                                        Text("N/A")
                                            .foregroundColor(.gray)
                                        //.textSelection(.enabled)
                                            .monospaced()
                                            .font(REConstants.Fonts.baseFont)
                                            .lineSpacing(12.0)
                                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                                    }
                                    //                                }
                                    //                            }
                                } else {
                                    Text("")
                                }
                                //                    }
                            }
                            .frame(minHeight: 20, maxHeight: 20) //.infinity)
                            .padding()
                            .modifier(PrimaryComponentsViewModifier(useReBackgroundDarker: false, viewBoxScaling: 4))
                            //                    .padding([.leading, .trailing])
                            //                    Spacer()
                            .padding([.leading, .trailing])
                            .onTapGesture {
                                if documentObject != nil {
                                    isShowingLabelChangeView.toggle()
                                }
                            }
                        }
                        VStack {
                            HStack(alignment: .lastTextBaseline) {
                                Text(REConstants.CategoryDisplayLabels.predictedFull)
                                    .font(.title3)
                                    .foregroundStyle(.gray)
                                Spacer()
                            }
                            .padding([.leading, .trailing])
                            
                            HStack(alignment: .top) {
                                
                                if let docObj = documentObject {
                                    if docObj.prediction >= 0, let labelDisplayName = dataController.labelToName[docObj.prediction] {
                                        if DataController.isKnownValidLabel(label: docObj.label, numberOfClasses: dataController.numberOfClasses) {
                                            if docObj.prediction == docObj.label {
                                                Image(systemName: "checkmark")
                                                    .font(REConstants.Fonts.baseFont)
                                                    .foregroundStyle(.green.gradient)
                                                    .opacity(0.5)
                                            } else {
                                                Image(systemName: "minus.diamond")
                                                    .font(REConstants.Fonts.baseFont)
                                                    .foregroundStyle(.red.gradient)
                                                    .opacity(0.5)
                                            }
                                        }
                                        Text(labelDisplayName)
                                            .monospaced()
                                            .font(REConstants.Fonts.baseFont)
                                    } else {
                                        Text("N/A")
                                            .monospaced()
                                            .font(REConstants.Fonts.baseFont)
                                    }
                                    Spacer()
                                } else {
                                    Text("")
                                }
                            }
                            .frame(minHeight: 20, maxHeight: 20)
                            .padding()
                            .modifier(PrimaryComponentsViewModifier(useReBackgroundDarker: true, viewBoxScaling: 4))
                            .padding([.leading, .trailing])
                        }
                    }
                }
                
                
                Group {
                    DataDetailsUncertaintyView(documentObject: $documentObject)
                    DataDetailsPromptAndDocumentView(documentObject: $documentObject, showingFeatureSearchView: $showingFeatureSearchView, showingHighlightAdditionalInfoView: $showingHighlightAdditionalInfoView, showingMatchingView: $showingMatchingView, disableFeatureSearchViewAndDestructiveActions: disableFeatureSearchViewAndDestructiveActions, searchParameters: searchParameters, semanticSearchParameters: semanticSearchParameters)
                    DataDetailsAttributesView(documentObject: $documentObject)
                    DataDetailsAdditionalPropertiesView(documentObject: $documentObject, showingEditGroupFieldView: $showingEditGroupFieldView, showingEditInfoFieldView: $showingEditInfoFieldView)
                   // if !disableFeatureSearchViewAndDestructiveActions {
                        DataDetailsDatasplitView(documentObject: $documentObject, isShowingDatasplitTransferView: $isShowingDatasplitTransferView, allowTransfers: !disableFeatureSearchViewAndDestructiveActions)
                   // }
                    
                    
                    
                    if documentObject != nil && !disableFeatureSearchViewAndDestructiveActions {
                        VStack {
                            HStack(alignment: .lastTextBaseline) {
                                Text("Delete")
                                    .font(.title3)
                                    .foregroundStyle(.gray)
                                Spacer()
                            }
                            .padding([.leading, .trailing])
                            
                            HStack {
                                VStack(alignment: .leading) {
                                    Button {
                                        locked.toggle()
                                    } label: {
                                        if locked {
                                            HStack {
                                                Image(systemName: "lock")
                                                    .foregroundStyle(.yellow.gradient)
                                                Text("Locked")
                                                    .foregroundStyle(.gray)
                                                Spacer()
                                            }
                                            .font(REConstants.Fonts.baseSubheadlineFont)
                                        } else {
                                            HStack {
                                                Image(systemName: "lock.open")
                                                    .foregroundStyle(.blue.gradient)
                                                Text("Unlocked")
                                                    .foregroundStyle(.gray)
                                                Spacer()
                                            }
                                            .font(REConstants.Fonts.baseSubheadlineFont)
                                        }
                                    }
                                    .buttonStyle(.borderless)
                                    
                                    if !locked {
                                        Button(role: .destructive) {
                                            showingDeletionAlert.toggle()
                                        } label: {
                                            HStack {
                                                Label("Delete document", systemImage: "trash")
                                                Spacer()
                                            }
                                        }
                                        .buttonStyle(.borderless)
                                        .foregroundStyle(.red)
                                    }
                                }
                                .padding()
                                .frame(width: 200)
                                .modifier(SimpleBaseBorderModifier())
                                Spacer()
                            }
                            .padding([.leading, .trailing])
                        }
                    }
                }
                
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .padding()
        .modifier(PrimaryComponentsViewModifier(useReBackgroundDarker: false))
        .alert(REConstants.GeneralErrors.coreDataSaveMessage, isPresented: $isShowingCoreDataSaveError) {
            Button("OK") {
            }
        }
            .sheet(isPresented: $showingHighlightAdditionalInfoView,
                   onDismiss: nil) {
                // A guide to what the highlighting means:
                DataDetailsFeatureHighlightView(documentObject: $documentObject, searchParameters: searchParameters, semanticSearchParameters: semanticSearchParameters)
                    //.interactiveDismissDisabled(true)
                    .padding()
                    .frame(
                        minWidth: 900, maxWidth: 900,
                        minHeight: 600, maxHeight: 900) //900)
            }
        .sheet(isPresented: $showingFeatureSearchView,
               onDismiss: nil) {
            FeatureSearchView(selectedDocument: $selectedDocument, documentObject: $documentObject, searchParameters: searchParameters)
                .interactiveDismissDisabled(true)
                .padding()
//                .frame(
//                    minWidth: 1200, maxWidth: 1200,
//                    minHeight: 900, maxHeight: 900)
                .frame(
                    minWidth: 900,
                    maxWidth: 1200,
                    minHeight: 600) //, maxHeight: 600)
        }
               .sheet(isPresented: $showingMatchingView,
                      onDismiss: nil) {
                   DataMatchingView(selectedDocument: $selectedDocument, documentObject: $documentObject, searchParameters: searchParameters)
                       .interactiveDismissDisabled(true)
                       .padding()
                       .frame(
                           minWidth: 900,
                           maxWidth: 1200,
                           minHeight: 600) //, maxHeight: 600)
               }
        
        
               .sheet(isPresented: $isShowingLabelChangeView,
                      onDismiss: {
                   refreshInterface()
               }) {
                   DataDetailsLabelChangeView(documentObject: $documentObject)
                       .padding()
                       .frame(
                        minWidth: 600, maxWidth: 800,
                        minHeight: 400, maxHeight: 400)
               }
               .sheet(isPresented: $isShowingDatasplitTransferView,
                      onDismiss: {
                   refreshInterface()
               }) {
                   DataDetailsDatasplitTransferView(documentObject: $documentObject)
                       .padding()
                       .frame(
                        minWidth: 600, maxWidth: 800,
                        minHeight: 250, maxHeight: 250)
               }
               .sheet(isPresented: $showingEditGroupFieldView,
                      onDismiss: {
                   refreshInterface()
               }) {
                   DataDetailsChangeGroupFieldView(documentObject: $documentObject)
                       .padding()
                       .frame(
                        minWidth: 600, maxWidth: 800,
                        minHeight: 250, maxHeight: 250)
               }
               .sheet(isPresented: $showingEditInfoFieldView,
                      onDismiss: {
                   refreshInterface()
               }) {
                   DataDetailsChangeInfoFieldView(documentObject: $documentObject)
                       .padding()
                       .frame(
                        minWidth: 600, maxWidth: 800,
                        minHeight: 250, maxHeight: 250)
               }
        
               .alert("Delete this document?", isPresented: $showingDeletionAlert) {
                   Button("Delete", role: .destructive) {
                       do {
                           try dataController.deleteOneDocument(documentObject: documentObject, moc: moc)
                           
                           Task {
                               try? await dataController.updateInMemoryDatasetStats(moc: moc, dataController: dataController)
                               await MainActor.run {
                                   refreshInterface()
                               }
                           }
                       } catch {
                           isShowingCoreDataSaveError = true
                       }
                   }
                   Button("Cancel", role: .cancel) { }
               } message: {
                   Text("WARNING: This operation cannot be undone and will remove all data associated with this document.")
               }
    }
}

