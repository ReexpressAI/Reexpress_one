//
//  TransientErrorView.swift
//  Alpha1
//
//  Created by A on 6/20/23.
//

import SwiftUI


struct TransientErrorView: View {
    @Binding var displayErrorView: Bool
    var errorMessage: String = "No matching documents found"
    var body: some View {
        VStack {
            Text(errorMessage)
                .opacity(1.0)
                .font(.title2)
                .padding()
                .frame(width: 300, height: 150)
                .background {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(BackgroundStyle())
                        .opacity(0.75)
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(.gray)
                }
                .padding()
        }
        .opacity(displayErrorView ? 1.0 : 0.0)
        .zIndex(displayErrorView ? 1.0 : 0.0)
    }
}

struct TransientErrorView_Previews: PreviewProvider {
    static var previews: some View {
        TransientErrorView(displayErrorView: .constant(true))
    }
}
