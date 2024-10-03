//
//  SimpleCloseButton.swift
//  Alpha1
//
//  Created by A on 8/20/23.
//

import SwiftUI

struct SimpleCloseButton: View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
        Button {
            dismiss()
        } label: {
            Text("Close")
                .font(REConstants.Fonts.baseFont.smallCaps())
        }
        .buttonStyle(.borderless)
        .padding(.trailing)
    }
}

struct SimpleCloseButton_Previews: PreviewProvider {
    static var previews: some View {
        SimpleCloseButton()
    }
}
