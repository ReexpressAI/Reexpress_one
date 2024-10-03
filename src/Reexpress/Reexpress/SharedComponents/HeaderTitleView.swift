//
//  HeaderTitleView.swift
//  Alpha1
//
//  Created by A on 6/23/23.
//

import SwiftUI

struct HeaderTitleView: View {
    var headerTitle: String
    var headerTitleColor: Color = .orange
    @Binding var statusSubtitle: String
    
    let buttonPadding = EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5)
    let buttonDividerHeight: CGFloat = 40
    var viewWidth: CGFloat = 450
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                HStack(alignment: .center) {
                    Text(headerTitle) //Text("New document prediction")
                        .foregroundStyle(headerTitleColor)
                        .opacity(0.75)
                        .lineLimit(1)
                        .font(.system(size: 18))
                        .padding(buttonPadding)
                    Divider()
                        .frame(width: 2, height: buttonDividerHeight)
                        .overlay(.gray)
                    HStack {
                        Text(statusSubtitle) //Text("Unsaved")
                            .lineLimit(1)
                            .foregroundColor(.gray)
                            .font(.system(size: 18))
                            .italic()
                            .padding(buttonPadding)
                    }
                    Spacer()
                }
                .frame(width: viewWidth)
                Spacer()
            }
        }
        .padding(EdgeInsets(top: 0, leading: 15, bottom: 0, trailing: 0))
    }
}

struct HeaderTitleView_Previews: PreviewProvider {
    static var previews: some View {
        HeaderTitleView(headerTitle: "New document prediction", statusSubtitle: .constant("Unsaved"))
    }
}
