//
//  DataDetailsLocalFindView.swift
//  Alpha1
//
//  Created by A on 8/25/23.
//

import SwiftUI

struct DataDetailsLocalFindView: View {
    @Environment(\.dismiss) var dismiss
    //@Environment(\.managedObjectContext) var moc
    @EnvironmentObject var dataController: DataController
    
    @Binding var documentObject: Document?
    var searchParameters: SearchParameters?
    
    //    @AppStorage(REConstants.UserDefaults.showFeaturesInDocumentText) var showFeaturesInDocumentText: Bool = true
    @AppStorage(REConstants.UserDefaults.documentFontSize) var documentFontSize: Double = Double(REConstants.UserDefaults.defaultDocumentFontSize)
    
    //@AppStorage(REConstants.UserDefaults.showLeadingFeatureInconsistentWithDocumentLevelInDocumentText) var showLeadingFeatureInconsistentWithDocumentLevelInDocumentText: Bool = false
    
    
    var documentFont: Font {
        let fontCGFloat = CGFloat(documentFontSize)
        return Font.system(size: max( REConstants.UserDefaults.minDocumentFontSize, min(fontCGFloat, REConstants.UserDefaults.maxDocumentFontSize) ) )
    }
    
    var documentIsNotEmpty: Bool {
        if let docObj = documentObject, let docText = docObj.document {
            return !docText.isEmpty
        }
        return false
    }
    
    @AppStorage(REConstants.UserDefaults.documentFrameHeightStringKey) var documentFrameHeightStored: Double = 260
    var documentFrameHeight: CGFloat {
        return CGFloat(documentFrameHeightStored)
    }
    
    @State private var showingDisplayOptionsPopover: Bool = false
    @State private var localSearchParameters: SearchParameters = SearchParameters(search: true, searchField: "document")
    
    @State private var documentOnlyAttributedString: AttributedString = AttributedString("")
    func getDocumentOnlyAttributedStringWithLocalSearchHighlighted() -> AttributedString {
        if let docObj = documentObject {
            return dataController.highlightTextForInterpretabilityBinaryClassificationWithDocumentObject(documentObject: docObj, truncateToDocument: true, highlightFeatureInconsistentWithDocLevel: false, searchParameters: searchParameters, localSearchParameters: localSearchParameters, semanticSearchParameters: nil, highlightFeatureMatchesDocLevel: false, showSemanticSearchFocusInDocumentText: false).attributedString
        }
        return AttributedString("")
    }
    
    
    var body: some View {
        VStack {
            ScrollView {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Find")
                            .font(.title)
                        HStack {
                            Text("Keyword search within the document")
                                .foregroundStyle(.gray)
                            PopoverViewWithButtonLocalState(popoverViewText: "When there are multiple occurrences of the term in the document, only a subset may be highlighted.")
                        }
                        .font(REConstants.Fonts.baseSubheadlineFont)
                    }
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
                    .padding(.trailing)
                    
                }
                .padding([.bottom])
                VStack(alignment: .leading) {
                    HStack {
                        HStack {
                            Text("Search text")
                                .font(.title3)
                                .foregroundStyle(.gray)
                            Spacer()
                            HStack {
                                Image(systemName: "restart")
                                    .foregroundStyle(documentIsNotEmpty ? Color.blue.gradient : Color.gray.gradient)
                                Text("Reset")
                                    .font(.title3)
                                    .foregroundStyle(documentIsNotEmpty ? .blue : .gray)
                            }
                            .onTapGesture {
                                localSearchParameters.searchText = ""
                                documentOnlyAttributedString = getDocumentOnlyAttributedStringWithLocalSearchHighlighted()
                            }
                        }
                        .frame(width: 425)
                        Spacer()
                    }
                    Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 10, verticalSpacing: 10) {
                        GridRow {
                            VStack {
                                TextEditor(text:  $localSearchParameters.searchText)
                                    .font(REConstants.Fonts.baseFont)
                                    .monospaced(true)
                                    .frame(width: 400, height: 25)
                                    .foregroundColor(.white)
                                    .scrollContentBackground(.hidden)
                                    .opacity(0.75)
                                    .padding()
                                    .background {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(
                                                REConstants.REColors.reBackgroundDarker)
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(.gray)
                                            .opacity(0.5)
                                    }
                                Text("\(REConstants.KeywordSearch.maxAllowedCharacters - localSearchParameters.searchText.count) characters remaining")
                                    .italic()
                                    .font(REConstants.Fonts.baseSubheadlineFont)
                            }
                            .gridCellColumns(2)
                            .gridColumnAlignment(.leading)
                            .onChange(of: localSearchParameters.searchText) {
                                if localSearchParameters.searchText.count > REConstants.KeywordSearch.maxAllowedCharacters {
                                    localSearchParameters.searchText = String(localSearchParameters.searchText.prefix(REConstants.KeywordSearch.maxAllowedCharacters))
                                }
                            }
                        }
                        
                        GridRow {
                            Picker(selection: $localSearchParameters.caseSensitiveSearch) {
                                Text("Match case").tag(true)
                                Text("Ignore case").tag(false)
                            } label: {
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 250)
                            Color.clear
                                .gridCellUnsizedAxes([.vertical, .horizontal])
                        }
                    }
                }
                .padding([.leading, .trailing])
                HStack {
                    Text("Document")
                        .font(.title3)
                        .foregroundStyle(.gray)
                    Spacer()
                    
                    HStack {
                        Image(systemName: "arrow.up.left.and.down.right.and.arrow.up.right.and.down.left")
                            .foregroundStyle(documentIsNotEmpty ? Color.blue.gradient : Color.gray.gradient)
                        Text("Resize")
                            .font(.title3)
                            .foregroundStyle(documentIsNotEmpty ? .blue : .gray)
                    }
                    .onTapGesture {
                        if documentFrameHeightStored == REConstants.UserDefaults.documentFrameBaseHeight {
                            documentFrameHeightStored = REConstants.UserDefaults.documentFrameExpandedHeight
                        } else {
                            documentFrameHeightStored = REConstants.UserDefaults.documentFrameBaseHeight
                        }
                    }
                }
                .padding([.leading, .trailing])
                ScrollView {
                    VStack(alignment: .leading) {
                        // In this case, we always show highlights, so we ignore the stored showFeaturesInDocumentText and showLeadingFeatureInconsistentWithDocumentLevelInDocumentText
                        Text(documentOnlyAttributedString)
                            .textSelection(.enabled)
                            .monospaced()
                            .font(documentFont)
                            .lineSpacing(12.0)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    }
                }
                .frame(height: documentFrameHeight)
                .padding()
                .modifier(PrimaryComponentsViewModifier(useReBackgroundDarker: true))
                .padding([.leading, .trailing])
            }
        }
        .onAppear {
            documentOnlyAttributedString = getDocumentOnlyAttributedStringWithLocalSearchHighlighted()
        }
        .scrollBounceBehavior(.basedOnSize)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .frame(width: 100)
                }
                .controlSize(.large)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    documentOnlyAttributedString = getDocumentOnlyAttributedStringWithLocalSearchHighlighted()
                } label: {
                    Text("Find")
                        .frame(width: 100)
                }
                .controlSize(.large)
                .disabled(localSearchParameters.searchText.isEmpty)
            }
        }
    }
}


