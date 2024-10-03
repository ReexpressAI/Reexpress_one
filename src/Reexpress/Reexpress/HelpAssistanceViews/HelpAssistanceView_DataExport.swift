//
//  HelpAssistanceView_DataExport.swift
//  Alpha1
//
//  Created by A on 9/21/23.
//

import SwiftUI


struct HelpAssistanceView_DataExport_Content: View {
    struct ExportColorModifier: ViewModifier {
        func body(content: Content) -> some View {
            content
                .foregroundStyle(REConstants.REColors.reHighlightLight)
                .opacity(0.85)
        }
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        Text("Export ")
                            .bold()
                            .modifier(ExportColorModifier())
                        Text("the documents of a ")
                        Text("datasplit")
                            .bold()
                            .foregroundStyle(.gray)
                        Text(".")
                        Spacer()
                    }
                }
                .padding([.leading, .trailing, .top])
                
                VStack(alignment: .leading) {
                    Text("Each line of the exported JSON lines file is a well-formed JSON object with one or more of the following properties:")
                        .foregroundStyle(.gray)
                    HStack {
                        Spacer()
                        Grid(horizontalSpacing: 20, verticalSpacing: 20) {
                            GridRow {
                                Text("Property name")
                                    .gridColumnAlignment(.trailing)
                                Text("Data type")
                                    .gridColumnAlignment(.leading)
                            }
                            .foregroundStyle(.gray)
                            
                            GridRow {
                                Text("id")
                                    .monospaced()
                                    .modifier(ExportColorModifier())
                                Text("String")
                                    .monospaced()
                            }
                            GridRow {
                                Text("label")
                                    .monospaced()
                                    .modifier(ExportColorModifier())
                                Text("Number")
                                    .monospaced()
                            }
                            GridRow {
                                Text("prompt")
                                    .monospaced()
                                    .modifier(ExportColorModifier())
                                Text("String")
                                    .monospaced()
                            }
                            GridRow {
                                Text("document")
                                    .monospaced()
                                    .modifier(ExportColorModifier())
                                Text("String")
                                    .monospaced()
                            }
                            GridRow {
                                Text("info")
                                    .monospaced()
                                    .modifier(ExportColorModifier())
                                Text("String")
                                    .monospaced()
                            }
                            GridRow {
                                Text("group")
                                    .monospaced()
                                    .modifier(ExportColorModifier())
                                Text("String")
                                    .monospaced()
                            }
                            GridRow {
                                Text("attributes")
                                    .monospaced()
                                    .modifier(ExportColorModifier())
                                Text("Number Array")
                                    .monospaced()
                            }
                            GridRow {
                                Text("prediction")
                                    .monospaced()
                                    .modifier(ExportColorModifier())
                                Text("Number")
                                    .monospaced()
                            }
                            GridRow {
                                Text("probability")
                                    .monospaced()
                                    .modifier(ExportColorModifier())
                                Text("String")
                                    .monospaced()
                            }
                        }
                        .textSelection(.enabled)
                        .padding()
                        .modifier(SimpleBaseBorderModifier())
                        Spacer()
                    }
                    .padding()
                    Text("The JSON properties are not necessarily in the above order. Properties missing from the project file, and/or not chosen for export, are omitted from the exported file; consequently, not all documents necessarily have the same JSON properties in the exported file. Each line is separated by a standard newline character:")
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
                }
                .padding()
                
            }
            .fixedSize(horizontal: false, vertical: true)  // This will cause Text() to wrap.
            .font(REConstants.Fonts.baseFont)
        }
        .scrollBounceBehavior(.basedOnSize)
        .padding()
        .frame(width: 600)
    }
}

struct HelpAssistanceView_DataExport: View {
    @State private var showingHelpAssistanceView: Bool = false
    var body: some View {
        Button {
            showingHelpAssistanceView.toggle()
        } label: {
            UncertaintyGraphControlButtonLabelWithCaptionVStack(buttonImageName: "questionmark.circle", buttonTextCaption: "Help", buttonForegroundStyle: AnyShapeStyle(Color.gray.gradient))
        }
        .buttonStyle(.borderless)
        .popover(isPresented: $showingHelpAssistanceView) {
            HelpAssistanceView_DataExport_Content()
        }
    }
}
