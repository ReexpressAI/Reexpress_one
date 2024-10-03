//
//  DataDetailsPromptAndDocumentView.swift
//  Alpha1
//
//  Created by A on 8/14/23.
//

import SwiftUI

struct DataDetailsPromptAndDocumentView: View {
    
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var dataController: DataController
    
    @Binding var documentObject: Document?
    @Binding var showingFeatureSearchView: Bool
    @Binding var showingHighlightAdditionalInfoView: Bool
    
    @Binding var showingMatchingView: Bool
    
    var disableFeatureSearchViewAndDestructiveActions: Bool = false // can disable to prevent infinite depth modals+popover's AND transfers or deletions during popover
    var searchParameters: SearchParameters?
    var semanticSearchParameters: SemanticSearchParameters?
    
    @State private var showingLocalFindView: Bool = false
    
    @AppStorage(REConstants.UserDefaults.showFeaturesInDocumentText) var showFeaturesInDocumentText: Bool = true
    @AppStorage(REConstants.UserDefaults.documentFontSize) var documentFontSize: Double = Double(REConstants.UserDefaults.defaultDocumentFontSize)
    
    @AppStorage(REConstants.UserDefaults.showLeadingFeatureInconsistentWithDocumentLevelInDocumentText) var showLeadingFeatureInconsistentWithDocumentLevelInDocumentText: Bool = false
    @AppStorage(REConstants.UserDefaults.showSemanticSearchFocusInDocumentText) var showSemanticSearchFocusInDocumentText: Bool = true
    
    var documentFont: Font {
        let fontCGFloat = CGFloat(documentFontSize)
        return Font.system(size: max( REConstants.UserDefaults.minDocumentFontSize, min(fontCGFloat, REConstants.UserDefaults.maxDocumentFontSize) ) )
    }
    
    var featuresAreAvailable: Bool {
        return (documentObject?.features?.sentenceRangeStartVector) != nil && !disableFeatureSearchViewAndDestructiveActions
    }
    
    var highlightsAreAvailable: Bool {
        if let docObj = documentObject {
            let predictedClassFeaturesPresent = docObj.featureMatchesDocLevelSentenceRangeStart != -1 && docObj.featureMatchesDocLevelSentenceRangeEnd != -1
            let inconsistentClassFeaturePresent = docObj.featureInconsistentWithDocLevelSentenceRangeStart != -1 && docObj.featureInconsistentWithDocLevelSentenceRangeEnd != -1
            let tokenizationCutoff = docObj.tokenizationCutoffRangeStart != -1
            return predictedClassFeaturesPresent || inconsistentClassFeaturePresent || tokenizationCutoff
        }
        return false
    }
    
    var promptIsNotEmpty: Bool {
        if let docObj = documentObject, let prompt = docObj.prompt {
            return !prompt.isEmpty
        }
        return false
    }
    
    var documentIsNotEmpty: Bool {
        if let docObj = documentObject, let docText = docObj.document {
            return !docText.isEmpty
        }
        return false
    }
    var textFindIsAvailable: Bool {
        // Currently we simply disable if full prediction has not been run (hence, !highlightsAreAvailable) since the current find is an overlay over feature highlights.
        return documentIsNotEmpty && highlightsAreAvailable
    }
    
    @AppStorage(REConstants.UserDefaults.promptFrameHeightStringKey) var promptFrameHeightStored: Double = 60
    
    var promptFrameHeight: CGFloat {
        return CGFloat(promptFrameHeightStored)
    }
    
    @AppStorage(REConstants.UserDefaults.documentFrameHeightStringKey) var documentFrameHeightStored: Double = 260
    var documentFrameHeight: CGFloat {
        return CGFloat(documentFrameHeightStored)
    }
    
    @AppStorage(REConstants.UserDefaults.documentTextOpacity) var documentTextOpacity: Double = REConstants.UserDefaults.documentTextDefaultOpacity
    
    let baseScaleFactor: CGFloat = 1.0
    var body: some View {
        Group {
            //Spacer()
            HStack {
                Text("Prompt")
                    .font(.title3)
                    .foregroundStyle(.gray)
                Spacer()
                HStack {
                    Image(systemName: "arrow.up.left.and.down.right.and.arrow.up.right.and.down.left")
                        .foregroundStyle(promptIsNotEmpty ? Color.blue.gradient : Color.gray.gradient)
                    Text("Resize")
                        .font(.title3)
                        .foregroundStyle(promptIsNotEmpty ? .blue : .gray)
                }
                .onTapGesture {
                    if promptFrameHeight == REConstants.UserDefaults.promptFrameBaseHeight {
                        promptFrameHeightStored = REConstants.UserDefaults.promptFrameExpandedHeight
                    } else {
                        promptFrameHeightStored = REConstants.UserDefaults.promptFrameBaseHeight
                    }
                }
                //.disabled(!promptIsNotEmpty)
            }
            .padding([.leading, .trailing])
            
            ScrollView {
                if let docObj = documentObject {
                    VStack(alignment: .leading) {
                        Text("\(docObj.prompt ?? "")")
                            .textSelection(.enabled)
                            .monospaced()
                            .font(documentFont)
                            .lineSpacing(12.0)
                            .opacity(documentTextOpacity)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    }
                } else {
                    Text("")
                }
            }
            .frame(height: promptFrameHeight)
            //.frame(minHeight: 50, maxHeight: 60) //.infinity)
            .padding()
            .modifier(PrimaryComponentsViewModifier(useReBackgroundDarker: true))
            .padding([.leading, .trailing])
        }
        Group {
            HStack {
                Text("Document")
                    .font(.title3)
                    .foregroundStyle(.gray)
                    .lineLimit(1)
                    .minimumScaleFactor(baseScaleFactor)
                    .help("Document")
                Spacer()
                
                HStack {
                    Image(systemName: "highlighter")
                        .foregroundStyle(highlightsAreAvailable ? Color.blue.gradient : Color.gray.gradient)
                    Text("Highlights")
                        .font(.title3)
                        .foregroundStyle(highlightsAreAvailable ? .blue : .gray)
                        .lineLimit(1)
                        .minimumScaleFactor(baseScaleFactor)
                        .help("Highlights")
                }
                .onTapGesture {
                    showingHighlightAdditionalInfoView = highlightsAreAvailable //true
                }
                .disabled(!highlightsAreAvailable)
                Divider()
                    .frame(width: 2, height: 16)
                    .overlay(.gray)
                
                HStack {
                    Image(systemName: "text.viewfinder")
                        .foregroundStyle(textFindIsAvailable ? Color.blue.gradient : Color.gray.gradient)
                    Text("Find")
                        .font(.title3)
                        .foregroundStyle(textFindIsAvailable ? .blue : .gray)
                        .lineLimit(1)
                        .minimumScaleFactor(baseScaleFactor)
                        .help("Find")
                }
                .onTapGesture {
                    showingLocalFindView = textFindIsAvailable //documentIsNotEmpty //true
                }
                .disabled(!textFindIsAvailable)
                
                Group {
                    Divider()
                        .frame(width: 2, height: 16)
                        .overlay(.gray)
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(featuresAreAvailable ? Color.blue.gradient : Color.gray.gradient)
                        Text("Document-Level")
                            .font(.title3)
                            .foregroundStyle(featuresAreAvailable ? .blue : .gray)
                            .lineLimit(1)
                            .minimumScaleFactor(baseScaleFactor)
                            .help("Document-Level")
                    }
                    .onTapGesture {
                        showingMatchingView = featuresAreAvailable //true
                    }
                    .disabled(!featuresAreAvailable)
                    
                    Divider()
                        .frame(width: 2, height: 16)
                        .overlay(.gray)
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(featuresAreAvailable ? Color.blue.gradient : Color.gray.gradient)
                        Text("Feature-Level")
//                        Text("Feature-Level Matching")
                            .font(.title3)
                            .foregroundStyle(featuresAreAvailable ? .blue : .gray)
                            .lineLimit(1)
                            .minimumScaleFactor(baseScaleFactor)
                            .help("Feature-Level")
                    }
                    .onTapGesture {
                        showingFeatureSearchView = featuresAreAvailable //true
                    }
                    .disabled(!featuresAreAvailable)
                }
                Divider()
                    .frame(width: 2, height: 16)
                    .overlay(.gray)
                HStack {
                    Image(systemName: "arrow.up.left.and.down.right.and.arrow.up.right.and.down.left")
                        .foregroundStyle(documentIsNotEmpty ? Color.blue.gradient : Color.gray.gradient)
                    Text("Resize")
                        .font(.title3)
                        .foregroundStyle(documentIsNotEmpty ? .blue : .gray)
                        .lineLimit(1)
                        .minimumScaleFactor(baseScaleFactor)
                        .help("Resize")
                }
                .onTapGesture {
                    if documentFrameHeightStored == REConstants.UserDefaults.documentFrameBaseHeight {
                        documentFrameHeightStored = REConstants.UserDefaults.documentFrameExpandedHeight
                    } else {
                        documentFrameHeightStored = REConstants.UserDefaults.documentFrameBaseHeight
                    }
                }
                //.disabled(!documentIsNotEmpty)
            }
            .padding([.leading, .trailing])
            
            ScrollView {
                if let docObj = documentObject {
                    VStack(alignment: .leading) {

                        let documentOnlyAttributedString = dataController.highlightTextForInterpretabilityBinaryClassificationWithDocumentObject(documentObject: docObj, truncateToDocument: true, highlightFeatureInconsistentWithDocLevel: showLeadingFeatureInconsistentWithDocumentLevelInDocumentText, searchParameters: searchParameters, semanticSearchParameters: semanticSearchParameters, highlightFeatureMatchesDocLevel: showFeaturesInDocumentText, showSemanticSearchFocusInDocumentText: showSemanticSearchFocusInDocumentText).attributedString

                            Text(documentOnlyAttributedString)
                                .textSelection(.enabled)
                                .monospaced()
                                .font(documentFont)
                                .lineSpacing(12.0)
                                .opacity(documentTextOpacity)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    }
                } else {
                    Text("")
                }
            }
            .frame(height: documentFrameHeight)
            .padding()
            .modifier(PrimaryComponentsViewModifier(useReBackgroundDarker: true))
            .padding([.leading, .trailing])
            
        }
        .sheet(isPresented: $showingLocalFindView,
               onDismiss: nil) {
            // A guide to what the highlighting means:
            DataDetailsLocalFindView(documentObject: $documentObject, searchParameters: searchParameters)
            //.interactiveDismissDisabled(true)
                .padding()
                .frame(
                    minWidth: 900, maxWidth: 900,
                    minHeight: 600, maxHeight: 900)
        }
        
        //        showingHighlightAdditionalInfoView
    }
}


