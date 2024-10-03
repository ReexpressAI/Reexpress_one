//
//  HelpAssistanceView_AddLabels.swift
//  Alpha1
//
//  Created by A on 9/22/23.
//

import SwiftUI

struct HelpAssistanceView_AddLabels_Content: View {
    @EnvironmentObject var dataController: DataController
    enum ColorModifierType: Int, CaseIterable {
        case primary, requiredEmphasis, optionalEmphasis
    }
    struct HelpAssistanceColorModifier: ViewModifier {
        var modifierType: ColorModifierType = .primary
        func getForegroundStyle(from modifierType: ColorModifierType) -> some ShapeStyle {
            switch modifierType {
            case .primary:
                return REConstants.REColors.reLabelGreenLighter.opacity(0.75)
            case .requiredEmphasis:
                return Color.orange.opacity(0.75)
            case .optionalEmphasis:
                return REConstants.REColors.reHighlightLight.opacity(0.85)
            }
        }
        func body(content: Content) -> some View {
            content
                .foregroundStyle(
                    getForegroundStyle(from: modifierType)
                )
        }
    }
    
    let gridWidth: CGFloat = 575
    let overallWidth: CGFloat = 650
    
    @AppStorage(REConstants.UserDefaults.addDataInstructions_showingFieldDetailsStringKey) var showingPropertyDetails: Bool = REConstants.UserDefaults.addDataInstructions_showingFieldDetailsDefault
    
    var mainLabelsForTaskStringSet: String {
        if dataController.numberOfClasses == 2 {
            return "{0,\(dataController.numberOfClasses-1)}"
        } else {
            return "{0,...,\(dataController.numberOfClasses-1)}"
        }
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        Text("Optionally ")
                        Text("add label display names ")
                            .bold()
                            .modifier(HelpAssistanceColorModifier())
                        Text("via a simple JSON lines format.")
                        Spacer()
                    }
                }
                .padding([.leading, .trailing, .top])
                HStack {
                    Spacer()
                    HelpAssistanceView_LabelData_DownloadExample()
                    Spacer()
                }
                .padding([.leading, .trailing])
                
                VStack(alignment: .leading) {
                    //                    Text("Each line of an imported JSON lines file must be a well-formed JSON object with at least the following required properties:")
                    //                        .foregroundStyle(.gray)
                    Text("Each line of the label JSON lines file (file extension: ").foregroundStyle(.gray) + Text(".jsonl").bold().monospaced().foregroundStyle(Color.orange.opacity(0.75)) + Text(") must be a well-formed JSON object with the following ").foregroundStyle(.gray) + Text("required properties").foregroundStyle(REConstants.REColors.reLabelGreenLighter.opacity(0.75))+Text(":").foregroundStyle(.gray)
                    HStack {
                        Spacer()
                        Button {
                            showingPropertyDetails.toggle()
                        } label: {
                            Text(showingPropertyDetails ? "Hide Details" : "Show Details")
                                .font(.system(size: 14).smallCaps())
                                .foregroundStyle(.blue)
                        }
                        .buttonStyle(.borderless)
                        Spacer()
                    }
                    .padding([.leading, .trailing])
                    HStack {
                        Spacer()
                        VStack {
                            Grid(horizontalSpacing: 20, verticalSpacing: 20) {
                                GridRow {
                                    Text("Property name")
                                        .gridColumnAlignment(.trailing)
                                    Text("Data type")
                                        .gridColumnAlignment(.leading)
                                    Text("Requirement")
                                        .gridColumnAlignment(.leading)
                                }
                                .foregroundStyle(.gray)
                                
                                GridRow {
                                    Text("label")
                                        .monospaced()
                                        .modifier(HelpAssistanceColorModifier())
                                    Text("Number")
                                        .monospaced()
                                    HStack {
                                        if dataController.numberOfClasses == 2 {
                                            Text("label ∈ {0, \(dataController.numberOfClasses-1)}")
                                                .monospaced()
                                        } else {
                                            Text("label ∈ {0,...,\(dataController.numberOfClasses-1)}")
                                                .monospaced()
                                        }
                                        
                                    }
                                }
                                if showingPropertyDetails {
                                    GridRow {
                                        Text("")
                                        VStack(alignment: .leading) {
                                            Text("Only display names for the main labels for the task can be modified. The \(REConstants.DataValidator.getDefaultLabelName(label: REConstants.DataValidator.oodLabel, abbreviated: false)) label, \(REConstants.DataValidator.oodLabel), and the placeholder label for \(REConstants.DataValidator.getDefaultLabelName(label: REConstants.DataValidator.unlabeledLabel, abbreviated: false)) documents, \(REConstants.DataValidator.unlabeledLabel), cannot be modified.")
                                        }
                                        .foregroundStyle(.gray)
                                        .gridCellColumns(2)
                                    }
                                }
                                GridRow {
                                    Text("name")
                                        .monospaced()
                                        .modifier(HelpAssistanceColorModifier())
                                    Text("String")
                                        .monospaced()
                                    Text("> 0 characters and ≤ \(REConstants.DataValidator.maxLabelDisplayNameCharacters) characters")
                                        .monospaced()
                                }
                                if showingPropertyDetails {
                                    GridRow {
                                        Text("")
                                        VStack(alignment: .leading) {
                                            Text("Not every available label needs to be present in the file, but if present, the label display name cannot be blank.")
                                            Text("\nThe label text is only used for display purposes and is not used by the model. Although the label can be up to \(REConstants.DataValidator.maxLabelDisplayNameCharacters) characters, it is generally recommended to keep the labels concise—less than about 50 characters—to avoid truncation in the visual displays.")
                                        }
                                        .foregroundStyle(.gray)
                                        .gridCellColumns(2)
                                    }
                                }
                            }
                            .textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding()
                            .modifier(SimpleBaseBorderModifier())
                            .frame(maxWidth: .infinity)
                        }
                        .frame(width: gridWidth)
                        Spacer()
                    }
                    .padding([.leading, .trailing, .bottom])
                    
                    
                    Text("The JSON properties need not be in the above order. Each line must be separated by a standard newline character:")
                        .foregroundStyle(.gray)
                    HStack {
                        Spacer()
                        Text(#"\n"#)
                            .monospaced()
                            .italic()
                            .foregroundStyle(.gray)
                            .padding()
                            .frame(width: 100)
                            .modifier(SimpleBaseBorderModifier())
                        Spacer()
                    }
                    .padding([.bottom])
                    HStack {
                        Text("The above character counts are determined by a simple String count in Swift.")
                            .foregroundStyle(.gray)
                        HelpAssistanceView_PopoverWithButton_CharacterCounts()
                    }
                    .padding(.bottom)
                    HStack {
                        Text("As is clear from the above, the JSON lines format for the label display names is different than the JSON lines format used for uploading documents. See **\(REConstants.MenuNames.setupName)**->**Add**->**Help** for the document JSON lines format.")
                    }
                }
                .padding([.leading, .trailing, .bottom])
                
            }
            .fixedSize(horizontal: false, vertical: true)  // This will cause Text() to wrap.
            .font(REConstants.Fonts.baseFont)
        }
        .scrollBounceBehavior(.basedOnSize)
        .frame(width: overallWidth)
        .padding()
        
    }
}



struct HelpAssistanceView_AddLabels: View {
    @State private var showingHelpAssistanceView: Bool = false
    var body: some View {
        Button {
            showingHelpAssistanceView.toggle()
        } label: {
            UncertaintyGraphControlButtonLabelWithCaptionVStack(buttonImageName: "questionmark.circle", buttonTextCaption: "Help", buttonForegroundStyle: AnyShapeStyle(Color.gray.gradient))
        }
        .buttonStyle(.borderless)
        .popover(isPresented: $showingHelpAssistanceView) {
            HelpAssistanceView_AddLabels_Content()
        }
        
    }
}
