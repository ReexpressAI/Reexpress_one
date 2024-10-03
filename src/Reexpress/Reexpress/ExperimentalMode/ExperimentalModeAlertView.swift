//
//  ExperimentalModeAlertView.swift
//  Reexpress
//
//  Created by A on 10/7/23.
//

import SwiftUI

struct ExperimentalModeAlertView: View {
    @Environment(\.dismiss) private var dismiss
    //@Environment(\.passStatusIsLoading) private var passStatusIsLoading
    
    var body: some View {
        VStack {
            ExperimentalModeAlertViewContent()
                .padding()
        }
        .frame(width: 500, height: 550)
        .background(
            REExperimentalModeBackground()
        )
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("OK") {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    ExperimentalModeAlertView()
}

private struct ExperimentalModeAlertViewContent: View {
    
    var body: some View {
        VStack(spacing: 10) {
            VStack(spacing: 3) {
                Text("\(Text("Welcome to")) \(Text(REConstants.ProgramIdentifiers.mainProgramName).foregroundStyle(.orange.gradient))!")
                    .font(.title.bold())
            }
            .padding()
            HStack {
//                Text("\(Text("**\(REConstants.ExperimentalMode.experimentalModeFull)**").foregroundStyle(.rePurpleGradientStart)) is enabled.")
                Text("\(Text("**\(REConstants.ExperimentalMode.experimentalModeFull)**").foregroundStyle(.reRedGradientStart)) is enabled.")
                    .font(.title2.weight(.medium))
                Spacer()
            }
            .padding()
            .modifier(SimpleBaseBorderModifier())
//            .padding(.horizontal)
            .padding([.bottom, .horizontal])
            ScrollView {

//                .padding(5)
//                .modifier(SimpleBaseBorderModifier())
//                .padding([.bottom, .horizontal])
                VStack(alignment: .leading) {
                    Text(.init(REConstants.ExperimentalMode.noticeToEnableExperimentalMode))
                    .multilineTextAlignment(.leading)
                    .lineSpacing(6.0)
                }
                .font(REConstants.Fonts.baseFont)
                //.fixedSize(horizontal: false, vertical: true)
                //.padding([.bottom, .horizontal])
            }
            .frame(maxWidth: 350)
        }
        .padding()
        .modifier(SimpleBaseBorderModifier(useShadow: true))
        .padding()
        //        .padding(.vertical)
        //        .padding(.top, 40)
        .multilineTextAlignment(.center)
    }
    
}

private struct REExperimentalModeBackground: View {
    var body: some View {
        Rectangle()
            .fill(
                .reBackgroundDarker
            )
            .overlay(alignment: .bottom) {
                ZStack {
                    Circle()
                        .fill(REConstants.REColors.sphereGradient_Purple.shadow(.drop(color: Color.black, radius: 2, y: 3)))
                        .frame(width: 300, height: 300)
                        .offset(x: 210, y: -415)
                    
                    Circle()
                        .fill(REConstants.REColors.sphereGradient_Purple.shadow(.drop(color: Color.black, radius: 2, y: 3)))
                        .frame(width: 300, height: 300)
                        .offset(x: -210, y: 0)
                }
            }
    }
}
