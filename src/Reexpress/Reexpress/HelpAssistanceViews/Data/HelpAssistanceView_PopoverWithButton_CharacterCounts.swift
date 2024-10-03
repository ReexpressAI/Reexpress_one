//
//  HelpAssistanceView_PopoverWithButton_CharacterCounts.swift
//  Alpha1
//
//  Created by A on 9/22/23.
//

import SwiftUI

struct HelpAssistanceView_PopoverWithButton_CharacterCounts: View { 
    @State var isShowingInfoPopover: Bool = false
    var popoverViewText: LocalizedStringKey = ""
    var optionalSubText: LocalizedStringKey? = nil
    var arrowEdge: Edge = .trailing
    var frameWidth: CGFloat = 750
    var body: some View {
        Button {
            isShowingInfoPopover.toggle()
        } label: {
            Image(systemName: "info.circle.fill")
        }
        .buttonStyle(.borderless)
        .popover(isPresented: $isShowingInfoPopover, arrowEdge: arrowEdge) {
            VStack(alignment: .leading) {
                Text("Character counts are determined as by the following Swift (version 5.9) code:")
                    .foregroundStyle(.gray)
                Text(REConstants.HelpAssistanceInfo.HelperReferenceCodeForUser.characterCountCodeString)
                    .textSelection(.enabled)
                    .foregroundStyle(REConstants.REColors.reLabelSlate)
                    .monospaced()
                    .padding()
                    .modifier(SimpleBaseBorderModifierWithColorOption(useReBackgroundDarker: true))
            }
            .padding()
            .frame(width: frameWidth)
        }
    }
}
