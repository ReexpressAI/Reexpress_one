//
//  DataDetailsFeatureHighlightView.swift
//  Alpha1
//
//  Created by A on 8/21/23.
//

import SwiftUI

struct HighlightStructure {
    var docLevelPredictionLabelString: String?
    var featureMatchesAttributedString: AttributedString?
    var featureMatchesDocLevelSoftmaxValString: String?  // truncated to significant digits for dispaly
    var featureInconsistentAttributedString: AttributedString?
    var featureInconsistentWithDocLevelPredictedClassLabelString: String?
    var featureInconsistentWithDocLevelSoftmaxValString: String?
    var truncatedTextAttributedString: AttributedString?
    var keywordSearchAttributedString: AttributedString?
    var semanticSearchAttributedString: AttributedString?
    var documentLevelSearchDistance: String?
}

struct DataDetailsFeatureHighlightView: View {
    @Environment(\.dismiss) var dismiss
    //@Environment(\.managedObjectContext) var moc
    @EnvironmentObject var dataController: DataController
    
    @Binding var documentObject: Document?
    var searchParameters: SearchParameters?
    var semanticSearchParameters: SemanticSearchParameters?
    
    @State private var featureMatchesDocLevelFrameHeight: CGFloat = 60
    @State private var featureInconsistentWithDocLevelFrameHeight: CGFloat = 60
    @State private var semanticSearchFrameHeight: CGFloat = 60
    @State private var truncatedWordsFrameHeight: CGFloat = 60
    @State private var keywordSearchFrameHeight: CGFloat = 60
    
    enum FrameHeightType: Int {
        case featureMatchesDocLevel
        case featureInconsistentWithDocLevel
        case truncatedWords
        case keywordSearch
        case semanticSearch
    }
    let frameBaseHeight: CGFloat = 60
    let frameExpandedHeight: CGFloat = 260
    func updateFrameHeight(frameHeightType: FrameHeightType) {
        var updatedFrameHeight: CGFloat
        switch frameHeightType {
        case .featureMatchesDocLevel:
            updatedFrameHeight = featureMatchesDocLevelFrameHeight
        case .featureInconsistentWithDocLevel:
            updatedFrameHeight = featureInconsistentWithDocLevelFrameHeight
        case .truncatedWords:
            updatedFrameHeight = truncatedWordsFrameHeight
        case .keywordSearch:
            updatedFrameHeight = keywordSearchFrameHeight
        case .semanticSearch:
            updatedFrameHeight = semanticSearchFrameHeight
        }
        if updatedFrameHeight == frameBaseHeight {
            updatedFrameHeight = frameExpandedHeight
        } else {
            updatedFrameHeight = frameBaseHeight
        }
        switch frameHeightType {
        case .featureMatchesDocLevel:
            featureMatchesDocLevelFrameHeight = updatedFrameHeight
        case .featureInconsistentWithDocLevel:
            featureInconsistentWithDocLevelFrameHeight = updatedFrameHeight
        case .truncatedWords:
            truncatedWordsFrameHeight = updatedFrameHeight
        case .keywordSearch:
            keywordSearchFrameHeight = updatedFrameHeight
        case .semanticSearch:
            semanticSearchFrameHeight = updatedFrameHeight
        }
    }
    
    @AppStorage(REConstants.UserDefaults.documentFontSize) var documentFontSize: Double = Double(REConstants.UserDefaults.defaultDocumentFontSize)
    
    var documentFont: Font {
        let fontCGFloat = CGFloat(documentFontSize)
        return Font.system(size: max( REConstants.UserDefaults.minDocumentFontSize, min(fontCGFloat, REConstants.UserDefaults.maxDocumentFontSize) ) )
    }
    @State private var showingDisplayOptionsPopover: Bool = false
    

    @State var highlightStructure: HighlightStructure? = nil
    

    var body: some View {

        VStack {
            ScrollView {
                HStack {
                    Text("Highlighting guide")
                        .font(.title)
                    Spacer()
                    
                    
                    //SimpleCloseButton()
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
                    .padding(.trailing)
                    
                }
                .padding([.bottom])
                if documentObject != nil {
                    Group {
                        HStack {
                            Text("Max feature matching document-level prediction")
                                .font(.title3)
                                .foregroundStyle(.gray)
                            PopoverViewWithButtonLocalState(popoverViewText: REConstants.HelpAssistanceInfo.HighlightGuide.featureScore)
                            Spacer()
                            HStack {
                                Image(systemName: "arrow.up.left.and.down.right.and.arrow.up.right.and.down.left")
                                    .foregroundStyle(Color.blue.gradient)
                                Text("Resize")
                                    .font(.title3)
                                    .foregroundStyle(.blue)
                            }
                            .onTapGesture {
                                updateFrameHeight(frameHeightType: .featureMatchesDocLevel)
                            }
                            //                        .disabled(!promptIsNotEmpty)
                        }
                        .padding([.leading, .trailing])
                        
                        
                        ScrollView {
                            if let highlightStructureForDocument = highlightStructure {
                                HStack {
                                    HStack(alignment: .bottom, spacing: 0.0) {
                                        Group {
                                            
                                            Text("Feature Score: ")
                                                .foregroundStyle(.gray)
                                            Text(highlightStructureForDocument.featureMatchesDocLevelSoftmaxValString ?? "")
                                                .monospaced()
                                            
                                            Divider()
                                                .frame(width: 2, height: 16.0)
                                                .overlay(.gray)
                                                .padding([.leading, .trailing])
                                            
                                            Text("Associated **Document-Level** Prediction: ")
                                            Text(highlightStructureForDocument.docLevelPredictionLabelString ?? "")
                                                .monospaced()
                                        }
                                    }
                                    Spacer()
                                    
                                }
                                
                                Divider()
                                Text(highlightStructureForDocument.featureMatchesAttributedString ?? "")
                                    .textSelection(.enabled)
                                    .environment(\.openURL, OpenURLAction { url in
                                        // Need this to prevent an attempt to open the marked URL's.
                                        return .handled
                                    })
                                    .monospaced()
                                    .font(documentFont)
                                    .lineSpacing(12.0)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                            }
                        }
                        .frame(height: featureMatchesDocLevelFrameHeight)
                        .padding()
                        .modifier(PrimaryComponentsViewModifier(useReBackgroundDarker: true, viewBoxScaling: 8))
                        .padding([.leading, .trailing])
                    }
                    Group {
                        HStack {
                            Text("Max feature inconsistent with document-level prediction")
                                .font(.title3)
                                .foregroundStyle(.gray)
                            PopoverViewWithButtonLocalState(popoverViewText: REConstants.HelpAssistanceInfo.HighlightGuide.featureScore)
                            Spacer()
                            HStack {
                                Image(systemName: "arrow.up.left.and.down.right.and.arrow.up.right.and.down.left")
                                    .foregroundStyle(Color.blue.gradient)
                                Text("Resize")
                                    .font(.title3)
                                    .foregroundStyle(.blue)
                            }
                            .onTapGesture {
                                updateFrameHeight(frameHeightType: .featureInconsistentWithDocLevel)
                            }
                        }
                        .padding([.leading, .trailing])
                        
                        
                        ScrollView {
                            if let highlightStructureForDocument = highlightStructure {
                                HStack {
                                    HStack(alignment: .bottom, spacing: 0.0) {
                                        Group {
                                            
                                            Text("Feature Score: ")
                                                .foregroundStyle(.gray)
                                            Text(highlightStructureForDocument.featureInconsistentWithDocLevelSoftmaxValString ?? "")
                                                .monospaced()
                                            
                                            Divider()
                                                .frame(width: 2, height: 16.0)
                                                .overlay(.gray)
                                                .padding([.leading, .trailing])
                                            
                                            Text("Associated **Document-Level** Prediction: ")
                                            Text(highlightStructureForDocument.featureInconsistentWithDocLevelPredictedClassLabelString ?? "")
                                                .monospaced()
                                        }
                                    }
                                    Spacer()
                                    
                                }
                                
                                Divider()
                                Text(highlightStructureForDocument.featureInconsistentAttributedString ?? "")
                                    .textSelection(.enabled)
                                    .environment(\.openURL, OpenURLAction { url in
                                        // Need this to prevent an attempt to open the marked URL's.
                                        return .handled
                                    })
                                    .monospaced()
                                    .font(documentFont)
                                    .lineSpacing(12.0)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                            }
                        }
                        .frame(height: featureInconsistentWithDocLevelFrameHeight)
                        .padding()
                        .modifier(PrimaryComponentsViewModifier(useReBackgroundDarker: true, viewBoxScaling: 8))
                        .padding([.leading, .trailing])
                    }
                    Group {
                        HStack {
                            Text("Focus of semantic search")
                                .font(.title3)
                                .foregroundStyle(.gray)
                            PopoverViewWithButtonLocalState(popoverViewText: REConstants.HelpAssistanceInfo.HighlightGuide.semanticSearch)
                            Spacer()
                            HStack {
                                Image(systemName: "arrow.up.left.and.down.right.and.arrow.up.right.and.down.left")
                                    .foregroundStyle(Color.blue.gradient)
                                Text("Resize")
                                    .font(.title3)
                                    .foregroundStyle(.blue)
                            }
                            .onTapGesture {
                                updateFrameHeight(frameHeightType: .semanticSearch)
                            }
                        }
                        .padding([.leading, .trailing])
                        
                        
                        ScrollView {
                            if let highlightStructureForDocument = highlightStructure {
                                HStack {
                                    HStack(alignment: .bottom, spacing: 0.0) {
                                        Group {
                                            
                                            Text("Semantic Search Distance: ")
                                                .foregroundStyle(.gray)
                                            Text(highlightStructureForDocument.documentLevelSearchDistance ?? "")
                                                .monospaced()
                                        }
                                    }
                                    Spacer()
                                    
                                }
                                Divider()
                                Text(highlightStructureForDocument.semanticSearchAttributedString ?? "")
                                    .textSelection(.enabled)
                                    .environment(\.openURL, OpenURLAction { url in
                                        // Need this to prevent an attempt to open the marked URL's.
                                        return .handled
                                    })
                                    .monospaced()
                                    .font(documentFont)
                                    .lineSpacing(12.0)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                            }
                        }
                        .frame(height: semanticSearchFrameHeight)
                        .padding()
                        .modifier(PrimaryComponentsViewModifier(useReBackgroundDarker: true, viewBoxScaling: 8))
                        .padding([.leading, .trailing])
                    }
                    Group {
                        HStack {
                            Text("Truncated words")
                                .font(.title3)
                                .foregroundStyle(.gray)
                            PopoverViewWithButtonLocalState(popoverViewText: REConstants.HelpAssistanceInfo.HighlightGuide.truncation)
                            Spacer()
                            HStack {
                                Image(systemName: "arrow.up.left.and.down.right.and.arrow.up.right.and.down.left")
                                    .foregroundStyle(Color.blue.gradient)
                                Text("Resize")
                                    .font(.title3)
                                    .foregroundStyle(.blue)
                            }
                            .onTapGesture {
                                updateFrameHeight(frameHeightType: .truncatedWords)
                            }
                        }
                        .padding([.leading, .trailing])
                        
                        
                        ScrollView {
                            if let highlightStructureForDocument = highlightStructure {
                                Text(highlightStructureForDocument.truncatedTextAttributedString ?? "")
                                    .textSelection(.enabled)
                                    .environment(\.openURL, OpenURLAction { url in
                                        // Need this to prevent an attempt to open the marked URL's.
                                        return .handled
                                    })
                                    .monospaced()
                                    .font(documentFont)
                                    .lineSpacing(12.0)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                            }
                        }
                        .frame(height: truncatedWordsFrameHeight)
                        .padding()
                        .modifier(PrimaryComponentsViewModifier(useReBackgroundDarker: true, viewBoxScaling: 8))
                        .padding([.leading, .trailing])
                    }
                    Group {
                        HStack {
                            Text("Keyword search")
                                .font(.title3)
                                .foregroundStyle(.gray)
                            PopoverViewWithButtonLocalState(popoverViewText: "The first occurrence of the keyword is highlighted. (Additional occurrences can be highlighted in Find.)")
                            Spacer()
                            HStack {
                                Image(systemName: "arrow.up.left.and.down.right.and.arrow.up.right.and.down.left")
                                    .foregroundStyle(Color.blue.gradient)
                                Text("Resize")
                                    .font(.title3)
                                    .foregroundStyle(.blue)
                            }
                            .onTapGesture {
                                updateFrameHeight(frameHeightType: .keywordSearch)
                            }
                        }
                        .padding([.leading, .trailing])
                        
                        
                        ScrollView {
                            if let highlightStructureForDocument = highlightStructure {
                                Text(highlightStructureForDocument.keywordSearchAttributedString ?? "")
                                    .textSelection(.enabled)
                                    .environment(\.openURL, OpenURLAction { url in
                                        // Need this to prevent an attempt to open the marked URL's.
                                        return .handled
                                    })
                                    .monospaced()
                                    .font(documentFont)
                                    .lineSpacing(12.0)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                            }
                        }
                        .frame(height: keywordSearchFrameHeight)
                        .padding()
                        .modifier(PrimaryComponentsViewModifier(useReBackgroundDarker: true, viewBoxScaling: 8))
                        .padding([.leading, .trailing])
                    }
                }
            }
        }
        .padding()
        .modifier(SimpleBaseBorderModifier())
        .padding()
        .onAppear {
            if let docObj = documentObject {
                highlightStructure = dataController.highlightTextForInterpretabilityBinaryClassificationWithDocumentObjectReturnAsGuideStructure(documentObject: docObj, searchParameters: searchParameters, semanticSearchParameters: semanticSearchParameters)
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .frame(width: 100)
                }
                .controlSize(.large)
            }
        }
    }
}
