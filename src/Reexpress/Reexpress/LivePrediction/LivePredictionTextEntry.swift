//
//  LivePredictionTextEntry.swift
//  Alpha1
//
//  Created by A on 6/10/23.
//

import SwiftUI

struct LivePredictionTextEntryPredictButtonViewModifier: ViewModifier {
    var isTrailingButton: Bool = true
    func body(content: Content) -> some View {
        content
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(EdgeInsets(top: 20, leading: 0, bottom: 0, trailing: 15))
    }
}


enum LivePredictionStatus: Int, CaseIterable {
    case noDocumentText = 0
    case documentTextStarted = 1
    case documentTextSubmitted = 2
    case documentTextPredictionComplete = 3
}

struct LivePredictionTextEntry: View {
    
    @EnvironmentObject var dataController: DataController
    @Environment(\.managedObjectContext) var moc
    
    @Binding var predictionStatus: LivePredictionStatus // = .noDocumentText
    
    @State var currrentLiveDocumentId: String?  // may be in temporary cache, so could disappear at any moment
    @State var selectedDocumentObject: Document?
    @State var showingSelectedDocumentDetails: Bool = false
    
    @State var liveDocumentState: LiveDocumentState = LiveDocumentState()
    
    @State var dataLoaded: Bool = false
    
    var headerTitle: String = "New document prediction"
    @State var statusSubtitle: String = "Unsaved"
    
    @AppStorage(REConstants.UserDefaults.documentTextOpacity) var documentTextOpacity: Double = REConstants.UserDefaults.documentTextDefaultOpacity
    
    @AppStorage(REConstants.UserDefaults.documentFontSize) var documentFontSize: Double = Double(REConstants.UserDefaults.defaultDocumentFontSize)
    
    var documentFont: Font {
        let fontCGFloat = CGFloat(documentFontSize)
        return Font.system(size: max( REConstants.UserDefaults.minDocumentFontSize, min(fontCGFloat, REConstants.UserDefaults.maxDocumentFontSize) ) )
    }
    
    @State var showingDisplayOptionsPopover: Bool = false
    @State var showPredictionForwardView: Bool = false
    
    var predictionDidCompleteAndIsPresent: Bool {
        return currrentLiveDocumentId != nil && selectedDocumentObject != nil
    }
    func resetPrediction() {
        // Note that we do not reset liveDocumentState unless the user clicks "Cancel". The reason is that live prediction might be used to check small changes to one document, so it's more convenient to not have to retype/etc.
        currrentLiveDocumentId = nil
        selectedDocumentObject = nil
    }
    
    var body: some View {
        VStack {
            HStack(alignment: .lastTextBaseline) {
                HStack(alignment: .center) {
                    Text(headerTitle)
                        .foregroundStyle(.orange)
                        .opacity(0.75)
                        .lineLimit(1)
                        .font(.system(size: 18))
                        .padding(5)
                    Divider()
                        .frame(width: 2, height: 40)
                        .overlay(.gray)
                }
                
                HStack(alignment: .lastTextBaseline) {
                    Image(systemName: "list.bullet.rectangle.portrait")
                        .foregroundStyle(currrentLiveDocumentId != nil ? Color.blue.gradient : Color.gray.gradient)
                    Text("Details")
                        .foregroundStyle(currrentLiveDocumentId != nil ? .blue : .gray)
                }
                .font(REConstants.Fonts.baseFont)
                .onTapGesture {
                    if let documentId = currrentLiveDocumentId {
                        selectedDocumentObject = try? dataController.retrieveOneDocument(documentId: documentId, moc: moc)
                        showingSelectedDocumentDetails.toggle()
                    }
                }
                PopoverViewWithButtonLocalStateOptions(popoverViewText: "New documents are saved to a temporary cache after prediction has successfully completed. To permanently save, transfer the new document to one of the existing datasplits via the Details panel.", frameWidth: 350)
                    .padding(.trailing)
                Spacer()
            }
            
            
            HStack(alignment: .lastTextBaseline) {
                Text("Prompt")
                    .font(.title3)
                    .foregroundStyle(.gray)
                Spacer()
                Text("Default")
                    .font(.title3.smallCaps())
                    .monospaced()
                    .foregroundStyle(.blue)
                    .onTapGesture {
                        liveDocumentState.prompt = dataController.defaultPrompt
                    }
            }
            .padding([.leading, .trailing])
            
            VStack {
                TextEditor(text: predictionDidCompleteAndIsPresent ? .constant(liveDocumentState.prompt) : $liveDocumentState.prompt)
                //                TextEditor(text:  $liveDocumentState.prompt)
                    .font(.system(size: documentFontSize))
                    .lineSpacing(12.0)
                    .monospaced(true)
                    .frame(height: 100)
                    .foregroundColor(.white)
                    .scrollContentBackground(.hidden)
                //.opacity(0.75)
                    .opacity(documentTextOpacity)
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(REConstants.REColors.reBackgroundDarker)
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(.gray)
                            .opacity(0.5)
                    }
                Text("\(REConstants.DataValidator.maxPromptRawCharacterLength - liveDocumentState.prompt.count) characters remaining")
                    .italic()
                    .font(REConstants.Fonts.baseSubheadlineFont)
                    .foregroundStyle(.gray)
            }
            .padding([.leading, .trailing])
            .onChange(of: liveDocumentState.prompt) {
                if liveDocumentState.prompt.count > REConstants.DataValidator.maxPromptRawCharacterLength {
                    liveDocumentState.prompt = String(liveDocumentState.prompt.prefix(REConstants.DataValidator.maxPromptRawCharacterLength))
                }
            }
            .font(REConstants.Fonts.baseFont)
            
            HStack {
                Text("Document")
                    .font(.title3)
                    .foregroundStyle(.gray)
                PopoverViewWithButtonLocalStateOptions(popoverViewText: REConstants.HelpAssistanceInfo.UserInput.documentTextInput, frameWidth: 300)
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
                    GlobalTextDisplayOptionsView(onlyDisplayFontSizeOption: true)
                }
            }
            .padding([.leading, .trailing])
            
            if predictionStatus != .documentTextPredictionComplete {
                VStack {
                    TextEditor(text: predictionDidCompleteAndIsPresent ? .constant(liveDocumentState.documentText) : $liveDocumentState.documentText)
                    //.lineLimit(25)
                        .font(.system(size: documentFontSize))
                        .lineSpacing(12.0)
                        .monospaced(true)
                        .frame(minHeight: 350, maxHeight: 350)
                        .foregroundColor(.white)
                        .scrollContentBackground(.hidden)
                    //.opacity(0.75)
                        .opacity(documentTextOpacity)
                        .padding()
                        .background {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(
                                    REConstants.REColors.reBackgroundDarker)
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(.gray)
                                .opacity(0.5)
                        }
                        .padding([.leading, .trailing])
                    HStack {
                        Spacer()
                        Text("\(REConstants.DataValidator.maxDocumentRawCharacterLength - liveDocumentState.documentText.count) characters remaining")
                            .italic()
                            .font(REConstants.Fonts.baseSubheadlineFont)
                            .foregroundStyle(.gray)
                        PopoverViewWithButtonLocalStateOptions(popoverViewText: REConstants.HelpAssistanceInfo.UserInput.documentTextInputMaxCharacterStorageNote, frameWidth: 300)
                        Spacer()
                    }
                }
                .onChange(of: liveDocumentState.documentText) {
                    if liveDocumentState.documentText.count > REConstants.DataValidator.maxDocumentRawCharacterLength {
                        liveDocumentState.documentText = String(liveDocumentState.documentText.prefix(REConstants.DataValidator.maxDocumentRawCharacterLength))
                    }
                }
            }
            
            LivePredictionAttributesView(liveDocumentState: $liveDocumentState)
            
            Grid {
                GridRow {
                    Spacer()
                    
                    Button {
                        liveDocumentState = LiveDocumentState()
                        predictionStatus = .documentTextStarted
                    } label: {
                        Text("Clear")
                            .frame(width: 100)
                    }
                    .controlSize(.large)
                    .disabled(predictionDidCompleteAndIsPresent)
                    .padding(EdgeInsets(top: 20, leading: 0, bottom: 0, trailing: 10))
                    
                    if predictionDidCompleteAndIsPresent {
                        Button {
                            resetPrediction()
                        } label: {
                            Text("New")
                                .frame(width: 100)
                        }
                        .modifier(LivePredictionTextEntryPredictButtonViewModifier())
                    } else {
                        Button {
                            showPredictionForwardView.toggle()
                        } label: {
                            Text("Predict")
                                .frame(width: 100)
                        }
                        .modifier(LivePredictionTextEntryPredictButtonViewModifier())
                        .disabled(liveDocumentState.documentText.isEmpty)
                    }
                    
                }
            }
            
        }
        .padding()
        .sheet(isPresented: $showPredictionForwardView) {
            LivePredictionForwardView(liveDocumentState: $liveDocumentState, currrentLiveDocumentId: $currrentLiveDocumentId, selectedDocumentObject: $selectedDocumentObject, showingSelectedDocumentDetails: $showingSelectedDocumentDetails)
            
                .padding()
                .frame(
                    minWidth: 800, maxWidth: 800,
                    minHeight: 600, maxHeight: 600)
        }
        .sheet(isPresented: $showingSelectedDocumentDetails,
               onDismiss: nil) {
            DataDetailsView(selectedDocument: .constant(Optional("")), documentObject: $selectedDocumentObject, searchParameters: nil, disableFeatureSearchViewAndDestructiveActions: false, calledFromTableThatNeedsUpdate: false, showDismissButton: true)
                .frame(
                    idealWidth: 1200, maxWidth: 1200,
                    idealHeight: 900, maxHeight: 900)
        }
        
    }
}

