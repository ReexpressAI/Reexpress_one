//
//  GlobalTextDisplayOptionsView.swift
//  Alpha1
//
//  Created by A on 8/11/23.
//

import SwiftUI

struct GlobalTextDisplayOptionsView: View {
    var onlyDisplayFontSizeOption: Bool = false  // For the FeatureView, 'showing features' has a different intent, so we drop that in the display when called from FeatureView. If true, showFeaturesInDocumentText is not altered on pressing Reset. [Currently, this also shows opacity.]
    var hideSemanticSearchOption: Bool = false
    
    @AppStorage(REConstants.UserDefaults.showFeaturesInDocumentText) var showFeaturesInDocumentText: Bool = true
    @AppStorage(REConstants.UserDefaults.documentFontSize) var documentFontSize: Double = Double(REConstants.UserDefaults.defaultDocumentFontSize)
    @AppStorage(REConstants.UserDefaults.showLeadingFeatureInconsistentWithDocumentLevelInDocumentText) var showLeadingFeatureInconsistentWithDocumentLevelInDocumentText: Bool = false
    @AppStorage(REConstants.UserDefaults.showSemanticSearchFocusInDocumentText) var showSemanticSearchFocusInDocumentText: Bool = true
    
    @AppStorage(REConstants.UserDefaults.documentTextOpacity) var documentTextOpacity: Double = REConstants.UserDefaults.documentTextDefaultOpacity
        
    var documentFont: Font {
        let fontCGFloat = CGFloat(documentFontSize)
        return Font.system(size: max( REConstants.UserDefaults.minDocumentFontSize, min(fontCGFloat, REConstants.UserDefaults.maxDocumentFontSize) ) )
    }
    
    func updateFontSize(isIncrease: Bool) {
        var updatedFontSize = documentFontSize
        if isIncrease {
            updatedFontSize += 1
            documentFontSize = min(updatedFontSize, REConstants.UserDefaults.maxDocumentFontSize)
        } else {
            updatedFontSize -= 1
            documentFontSize = max(updatedFontSize, REConstants.UserDefaults.minDocumentFontSize)
        }
    }
     
    func updateBrightness(isIncrease: Bool) {
        var updatedDocumentTextOpacity = documentTextOpacity
        if isIncrease {
            updatedDocumentTextOpacity += 0.05
            documentTextOpacity = min(updatedDocumentTextOpacity, 1.0)
        } else {
            updatedDocumentTextOpacity -= 0.05
            documentTextOpacity = max(updatedDocumentTextOpacity, REConstants.UserDefaults.documentTextMinAllowedOpacity)
        }
    }
    func formatOpacityForDisplay(opacityDouble: Double) -> String {
        return String(format: "%.2f", opacityDouble)
    }
    
    func resetDefaults() {
        documentFontSize = Double(REConstants.UserDefaults.defaultDocumentFontSize)
        documentTextOpacity = REConstants.UserDefaults.documentTextDefaultOpacity
        if !onlyDisplayFontSizeOption {
            showFeaturesInDocumentText = true
            showSemanticSearchFocusInDocumentText = true
            showLeadingFeatureInconsistentWithDocumentLevelInDocumentText = false
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("Display options")
                    .font(.title2.bold())
                Spacer()
                
                Button {
                    resetDefaults()
                } label: {
                    VStack {
                        Image(systemName: "restart")
                            .font(.title)
                            .foregroundStyle(.blue.gradient)
                        Text("Reset")
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 50, height: 50)
                    .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5))
                }
                .buttonStyle(.borderless)
            }
            
            Grid(verticalSpacing: 10) {
                if !onlyDisplayFontSizeOption {
                    GridRow {
                        Text("Highlight features, if available, in documents.")
                            .font(REConstants.Fonts.baseFont)
                            .foregroundStyle(.gray)
                            .gridColumnAlignment(.trailing)
                        Text("     ")
                        Toggle(isOn: $showFeaturesInDocumentText.animation()) {
                        }
                        .toggleStyle(.switch)
                        .gridColumnAlignment(.leading)
                    }
                    GridRow {
                        Text("Additionally highlight leading feature differing from the global prediction.")
                            .italic()
                            .font(REConstants.Fonts.baseFont)
                            .foregroundStyle(.gray)
                            .opacity(showFeaturesInDocumentText ? 1.0 : 0.5)
                        Text("     ")
                        Toggle(isOn: $showLeadingFeatureInconsistentWithDocumentLevelInDocumentText.animation()) {
                        }
                        .toggleStyle(.switch)
                        .disabled(!showFeaturesInDocumentText)
                    }
                    .onChange(of: showFeaturesInDocumentText) {
                        if !showFeaturesInDocumentText {
                            showLeadingFeatureInconsistentWithDocumentLevelInDocumentText = false
                        }
                    }
                    if !hideSemanticSearchOption {
                        GridRow {
                            Text("Highlight focus of semantic search, if applicable.")
                                .font(REConstants.Fonts.baseFont)
                                .foregroundStyle(.gray)
                                .gridColumnAlignment(.trailing)
                            Text("     ")
                            Toggle(isOn: $showSemanticSearchFocusInDocumentText.animation()) {
                            }
                            .toggleStyle(.switch)
                            .gridColumnAlignment(.leading)
                        }
                    }
                }
                GridRow {
                    HStack(spacing: 0) {
                        Text("Prompt + Document font size:")
                            .font(REConstants.Fonts.baseFont)
                            .foregroundStyle(.gray)
                        Text(" \(Int(documentFontSize)) pt.")
                            .font(REConstants.Fonts.baseFont)
                    }
                    Text("     ")
                    HStack(alignment: .bottom) {
                        Button {
                            updateFontSize(isIncrease: false)
                        } label: {
                            Image(systemName: "textformat.size.smaller")
                                .font(.title)
                                .foregroundStyle(.blue.gradient)
                            
                        }
                        .buttonStyle(.borderless)
                        Button {
                            updateFontSize(isIncrease: true)
                        } label: {
                            Image(systemName: "textformat.size.larger")
                                .font(.title)
                                .foregroundStyle(.blue.gradient)
                        }
                        .buttonStyle(.borderless)
                    }
                }
                GridRow {
                    HStack(spacing: 0) {
                        Text("Text and highlight brightness:")
                            .font(REConstants.Fonts.baseFont)
                        Text(" \(formatOpacityForDisplay(opacityDouble: documentTextOpacity))")
                            .font(REConstants.Fonts.baseFont)
                    }
                    .opacity(documentTextOpacity)
                    Text("     ")
                    HStack(alignment: .bottom) {
                        Button {
                            updateBrightness(isIncrease: false)
                        } label: {
                            Image(systemName: "sun.min")
                                //.font(.title)
                                .foregroundStyle(.blue.gradient)
                            
                        }
                        .buttonStyle(.borderless)
                        Button {
                            updateBrightness(isIncrease: true)
                        } label: {
                            Image(systemName: "sun.max")
                                //.font(.title)
                                .foregroundStyle(.blue.gradient)
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
            .padding()
            .modifier(SimpleBaseBorderModifier())
        }
        .frame(maxWidth: 650)
        .padding([.leading, .trailing, .bottom])
    }
}

struct GlobalTextDisplayOptionsView_Previews: PreviewProvider {
    static var previews: some View {
        GlobalTextDisplayOptionsView()
    }
}
