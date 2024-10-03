//
//  HelpAssistanceView_PopoverWithButton_StarterCode.swift
//  Alpha1
//
//  Created by A on 9/22/23.
//

import SwiftUI

struct HelpAssistanceView_PopoverWithButton_StarterCode: View {
    @State var isShowingInfoPopover: Bool = false
    var isSwift: Bool = true
    var arrowEdge: Edge = .trailing
    var frameWidth: CGFloat = 900
    var body: some View {
        Button {
            isShowingInfoPopover.toggle()
        } label: {
            Text(isSwift ? "Starter Swift code" : "Starter Python code")
                .foregroundStyle(.blue)
        }
        .buttonStyle(.borderless)
        .popover(isPresented: $isShowingInfoPopover, arrowEdge: arrowEdge) {
            ScrollView {
                VStack(alignment: .leading) {
                    if isSwift {
                        HStack {
                            Text("The following Swift (version 5.9) code demonstrates saving a JSON lines file with the proper format:")
                                .foregroundStyle(.gray)
                            PopoverViewWithButtonLocalStateOptions(popoverViewText: "Pro-tip: Copy and paste this text into an editor (e.g., Xcode) for easier readability.")
                        }
                    } else {
                        HStack {
                            Text("The following Python (version 3.10) code demonstrates saving a JSON lines file with the proper format:")
                                .foregroundStyle(.gray)
                            PopoverViewWithButtonLocalStateOptions(popoverViewText: "Pro-tip: Copy and paste this text into an editor (e.g., Xcode) for easier readability.")
                        }
                    }
                    
                    Text(isSwift ? REConstants.StarterCodeString.swiftStarterInputCode : REConstants.StarterCodeString.pythonStarterInputCode)
                        .textSelection(.enabled)
                        .foregroundStyle(REConstants.REColors.reLabelSlate)
                        .monospaced()
                        .padding()
                        .modifier(SimpleBaseBorderModifierWithColorOption(useReBackgroundDarker: true))
                }
                .padding()
            }
            .frame(width: frameWidth, height: 600)
        }
    }
}
