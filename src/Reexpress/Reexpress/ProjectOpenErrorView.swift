//
//  ProjectOpenErrorView.swift
//  Alpha1
//
//  Created by A on 1/27/23.
//

import SwiftUI

struct ProjectOpenErrorView: View {
    @Binding var showingProjectDirectoryChooser: Bool
    var body: some View {
        VStack {
            HStack {
                //                Text("Error message:")
                //                    .font(.system(size: 18.0).smallCaps())
                Text("Select a valid project file to continue.")
                //            }
                    .monospaced()
                    //.italic()
                    .font(.system(size: 18.0))
                    .foregroundStyle(.white)
                    .opacity(0.75)
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 10))
                Divider()
                    .frame(width: 3, height: 70)
                    .overlay(.gray)
                //Spacer()
                Button {
                    showingProjectDirectoryChooser = true
                } label: {
                    UncertaintyGraphControlButtonLabelWithCaptionVStack(buttonImageName: "entry.lever.keypad", buttonTextCaption: "Retry")
                }
                .buttonStyle(.borderless)
                .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 0))
                //Spacer()
            }
        }
        .padding()
    }
}

struct ProjectOpenErrorView_Previews: PreviewProvider {
    static var previews: some View {
        ProjectOpenErrorView(showingProjectDirectoryChooser: .constant(false))
    }
}
