//
//  HelpAssistanceView_Selection.swift
//  Alpha1
//
//  Created by A on 8/18/23.
//

import SwiftUI

struct HelpAssistanceView_Selection_Content: View {
    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 0) {
                Text("Select subsets of the data to ")
                Text("focus your data analysis")
                    .bold()
                    .foregroundStyle(REConstants.REColors.reLabelGreenLighter)
                    .opacity(0.75)
                Text(".")
                Spacer()
            }
            .padding()
            Text("The default settings will return all documents in the specified datasplit.")
                .foregroundStyle(.gray)
                .padding([.leading, .trailing, .bottom])
        }
        .font(REConstants.Fonts.baseFont)
        .padding()
        .frame(width: 500)
    }
}

struct HelpAssistanceView_Selection: View {
    @State private var showingHelpAssistanceView: Bool = false
    var body: some View {
        Button {
            showingHelpAssistanceView.toggle()
        } label: {
            UncertaintyGraphControlButtonLabelWithCaptionVStack(buttonImageName: "questionmark.circle", buttonTextCaption: "Help", buttonForegroundStyle: AnyShapeStyle(Color.gray.gradient))
        }
        .buttonStyle(.borderless)
        .popover(isPresented: $showingHelpAssistanceView) {
            HelpAssistanceView_Selection_Content()
        }

    }
}

//struct HelpAssistanceView_Selection_Previews: PreviewProvider {
//    static var previews: some View {
//        HelpAssistanceView_Selection()
//    }
//}
