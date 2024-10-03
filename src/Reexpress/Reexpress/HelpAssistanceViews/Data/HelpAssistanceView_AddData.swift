//
//  HelpAssistanceView_AddData.swift
//  Alpha1
//
//  Created by A on 9/2/23.
//

import SwiftUI


struct HelpAssistanceView_AddData_Content: View {
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
                        Text("Add data ")
                            .bold()
                            .modifier(HelpAssistanceColorModifier())
                        Text("via a simple JSON lines format.")
                        Spacer()
                    }
                }
                .padding([.leading, .trailing, .top])
                HStack {
                    Spacer()
                    HelpAssistanceView_AddData_DownloadExample()
                    Spacer()
                }
                .padding([.leading, .trailing])
                
                VStack(alignment: .leading) {
                    //                    Text("Each line of an imported JSON lines file must be a well-formed JSON object with at least the following required properties:")
                    //                        .foregroundStyle(.gray)
                    Text("Each line of an imported JSON lines file (file extension: ").foregroundStyle(.gray) + Text(".jsonl").bold().monospaced().foregroundStyle(Color.orange.opacity(0.75)) + Text(") must be a well-formed JSON object with at least the following ").foregroundStyle(.gray) + Text("required properties").foregroundStyle(REConstants.REColors.reLabelGreenLighter.opacity(0.75))+Text(":").foregroundStyle(.gray)
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
                                    Text("id")
                                        .monospaced()
                                        .modifier(HelpAssistanceColorModifier())
                                    Text("String")
                                        .monospaced()
                                    HStack {
                                        Text("≤ \(REConstants.DataValidator.maxIDRawCharacterLength) characters")
                                            .monospaced()
                                    }
                                }
                                if showingPropertyDetails {
                                    GridRow {
                                        Text("")
                                        VStack(alignment: .leading) {
                                            Text("*Important*: The id defines the uniqueness of a document. Each document must have a distinct id. We recommend using a Universally Unique Identifier (UUID) as the id string. Re-uploading a document with the same id will delete any data previously associated with that document and will automatically transfer it to the datasplit chosen when re-uploading.")
                                        }
                                        .foregroundStyle(.gray)
                                        .gridCellColumns(2)
                                    }
                                }
                                GridRow {
                                    Text("label")
                                        .monospaced()
                                        .modifier(HelpAssistanceColorModifier())
                                    Text("Number")
                                        .monospaced()
                                    HStack {
                                        if dataController.numberOfClasses == 2 {
                                            Text("label ∈ {\(REConstants.DataValidator.oodLabel), \(REConstants.DataValidator.unlabeledLabel), 0, \(dataController.numberOfClasses-1)}")
                                                .monospaced()
                                        } else {
                                            Text("label ∈ {\(REConstants.DataValidator.oodLabel), \(REConstants.DataValidator.unlabeledLabel), 0,...,\(dataController.numberOfClasses-1)}")
                                                .monospaced()
                                        }
                                        
                                    }
                                }
                                if showingPropertyDetails {
                                    GridRow {
                                        Text("")
                                        VStack(alignment: .leading) {
                                            Text("The value -1 is a required placeholder for documents that lack labels.\n")
                                            
                                            Text("The values \(mainLabelsForTaskStringSet) are the main labels for the task. The number of values available depends on the task specified at project creation and cannot be subsequently changed. For example, a binary classification task uses the values {0,1}, whereas a 3-class classification task uses the values {0,1,2}. String label names can be uploaded for display purposes: Go to **\(REConstants.MenuNames.setupName)**->**\(REConstants.MenuNames.labelsName)**.\n")
                                            Text("At least two examples for each class must be uploaded to the Training and Calibration sets to begin training.") +
                                            Text(" However, we generally recommend having at least 1000 examples per class in both the Training and Calibration sets to get reliable uncertainty estimates.").bold().italic()
                                            Text("\nThe value \(REConstants.DataValidator.oodLabel), the \(REConstants.DataValidator.getDefaultLabelName(label: REConstants.DataValidator.oodLabel, abbreviated: false)) label, is less commonly used. The model does not directly predict this value, and documents with this label are effectively treated the same as unlabeled documents, but it can be useful in some settings to have a distinct label for analysis purposes. Documents with this label do not directly participate in setting the parameters of the model, but are taken into consideration when determining **\(REConstants.CategoryDisplayLabels.qFull)**. Use this label for any documents that may be seen in practice at test-time but are effectively unrelated to the task. Including such a document in Training with the \(REConstants.DataValidator.oodLabel) value (as opposed to simply deleting the document) will ensure that any matches at test time to the unusual document will have a correspondingly low q value. (The model cannot predict \(REConstants.DataValidator.oodLabel), so q cannot exceed the rank of the match to the unusual document.)")
                                        }
                                        .foregroundStyle(.gray)
                                        .gridCellColumns(2)
                                    }
                                }
                                GridRow {
                                    Text("document")
                                        .monospaced()
                                        .modifier(HelpAssistanceColorModifier())
                                    Text("String")
                                        .monospaced()
                                    Text("≤ \(REConstants.DataValidator.maxDocumentRawCharacterLength) characters")
                                        .monospaced()
                                }
                                if showingPropertyDetails {
                                    GridRow {
                                        Text("")
                                        VStack(alignment: .leading) {
                                            Text(.init(REConstants.HelpAssistanceInfo.UserInput.documentTextInputMaxCharacterStorageNote))
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
                    
                    Text("The following are ").foregroundStyle(.gray)+Text("optional properties").foregroundStyle(REConstants.REColors.reHighlightLight.opacity(0.85))+Text(":").foregroundStyle(.gray)
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
                                    Text("prompt")
                                        .monospaced()
                                        .modifier(HelpAssistanceColorModifier(modifierType: .optionalEmphasis))
                                    Text("String")
                                        .monospaced()
                                    HStack {
                                        Text("≤ \(REConstants.DataValidator.maxPromptRawCharacterLength) characters")
                                            .monospaced()
                                    }
                                }
                                if showingPropertyDetails {
                                    GridRow {
                                        Text("")
                                        VStack(alignment: .leading) {
                                            Text("The default prompt (chosen at project creation) is only used if this optional prompt property is not present in the JSON. (As a result, if the prompt property *is* present and has an empty string value, the document will have an empty string as the prompt.)")
                                        }
                                        .foregroundStyle(.gray)
                                        .gridCellColumns(2)
                                    }
                                }
                                GridRow {
                                    Text("info")
                                        .monospaced()
                                        .modifier(HelpAssistanceColorModifier(modifierType: .optionalEmphasis))
                                    Text("String")
                                        .monospaced()
                                    HStack {
                                        Text("≤ \(REConstants.DataValidator.maxInfoRawCharacterLength) characters")
                                            .monospaced()
                                    }
                                }
                                if showingPropertyDetails {
                                    GridRow {
                                        Text("")
                                        VStack(alignment: .leading) {
                                            Text("As with the group property, this text is not seen by the model, but it can be searched via keywords (as in **\(REConstants.MenuNames.exploreName)**) to subset the data. It can be edited directly in the document details navigator and can be used as a memo field.")
                                        }
                                        .foregroundStyle(.gray)
                                        .gridCellColumns(2)
                                    }
                                }
                                GridRow {
                                    Text("group")
                                        .monospaced()
                                        .modifier(HelpAssistanceColorModifier(modifierType: .optionalEmphasis))
                                    Text("String")
                                        .monospaced()
                                    HStack {
                                        Text("≤ \(REConstants.DataValidator.maxGroupRawCharacterLength) characters")
                                            .monospaced()
                                    }
                                }
                                if showingPropertyDetails {
                                    GridRow {
                                        Text("")
                                        VStack(alignment: .leading) {
                                            Text("As with the info property, this text is not seen by the model, but it can be searched via keywords (as in **\(REConstants.MenuNames.exploreName)**) to subset the data. It can be edited directly in the document details navigator and can be used as a memo field.")
                                        }
                                        .foregroundStyle(.gray)
                                        .gridCellColumns(2)
                                    }
                                }
                                GridRow {
                                    Text("attributes")
                                        .monospaced()
                                        .modifier(HelpAssistanceColorModifier(modifierType: .optionalEmphasis))
                                    Text("Number Array")
                                        .monospaced()
                                    HStack {
                                        Text("≤ \(REConstants.DataValidator.maxInputAttributeSize) values")
                                            .monospaced()
                                    }
                                }
                                if showingPropertyDetails {
                                    GridRow {
                                        Text("")
                                        VStack(alignment: .leading) {
                                            Text(REConstants.PropertyDisplayLabel.attributesFull)
                                                .bold()
                                            Text(.init(REConstants.HelpAssistanceInfo.UserInput.attributes))
                                            Text("")
                                            Text(REConstants.HelpAssistanceInfo.UserInput.attributesAdditionalInfo)
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
                        Text("Each individual file can have no more than \(REConstants.DatasetsConstraints.maxTotalLines) lines, and each individual file must be less than \(Int(REConstants.DatasetsConstraints.maxFileSize)) MB.")
                            .foregroundStyle(.gray)
                    }
                    .padding(.bottom)
                    HStack {
                        Text("(Each datasplit can have no more than \(REConstants.DatasetsConstraints.maxTotalLines) documents. A total of \(REConstants.Datasets.maxTotalDatasets) datasplits can be present in a single project file.)")
                            .foregroundStyle(.gray)
                    }
                    .padding(.bottom)
                    HStack {
                        Text("The above character counts are determined by a simple String count in Swift.")
                            .foregroundStyle(.gray)
                        HelpAssistanceView_PopoverWithButton_CharacterCounts()
                    }
                    .padding(.bottom)
                    HStack {
                        Text("It is important to properly escape any special characters in uploaded strings. The following are helper functions to get started with the standard JSON parsers in Swift and Python, demonstrating saving a properly formatted JSON object per line:")
                            .foregroundStyle(.gray)
                    }
                    HStack {
                        Spacer()
                        HelpAssistanceView_PopoverWithButton_StarterCode()
                        Spacer()
                    }
                    .padding([.leading, .trailing, .top, .bottom])
                    HStack {
                        Spacer()
                        HelpAssistanceView_PopoverWithButton_StarterCode(isSwift: false)
                        Spacer()
                    }
                    .padding([.leading, .trailing])
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



struct HelpAssistanceView_AddData: View {
    @State private var showingHelpAssistanceView: Bool = false
    var body: some View {
        Button {
            showingHelpAssistanceView.toggle()
        } label: {
            UncertaintyGraphControlButtonLabelWithCaptionVStack(buttonImageName: "questionmark.circle", buttonTextCaption: "Help", buttonForegroundStyle: AnyShapeStyle(Color.gray.gradient))
        }
        .buttonStyle(.borderless)
        .popover(isPresented: $showingHelpAssistanceView) {
            HelpAssistanceView_AddData_Content()
        }
        
    }
}
