//
//  GridPatternView.swift
//  Components
//
//  Created by A on 1/19/23.
//

import SwiftUI

// We pre-screen, rather than allowing it to be truly random.
struct GridPatternView: View {
    /*let colorChoiceIndexes0 = [1, 1, 1, 0, 2, 2, 0, 2, 0, 1, 1, 2, 0, 1, 1, 2, 0, 1, 1, 1, 2, 0, 2, 2, 1, 1, 0, 2, 2, 1, 0, 0, 1, 0, 2, 2, 1, 1, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 2, 2, 0, 0, 0, 1, 2, 1, 2, 0, 0, 2, 2, 1, 0, 0, 0, 1, 2, 1, 2, 1, 2, 0, 2, 1, 2, 2, 1, 0, 0, 1, 0, 2, 2, 2, 0, 2, 2, 0, 1, 0, 2, 2, 1, 2, 1, 2, 2, 0, 2, 2, 2, 1, 0, 2, 2, 2, 2, 2, 0, 2, 2, 1, 2, 2, 2, 1, 0, 1, 0, 1, 1, 0, 0, 2, 1, 0, 1, 2, 0, 2, 1, 2, 2, 2, 1, 2, 0, 0, 1, 1, 1, 1, 2, 2, 0, 1, 1, 1, 1, 2, 1, 2, 1, 1, 2, 0, 0, 1, 2, 1, 1, 2, 0, 1, 2, 2, 1, 1, 2, 1, 2, 0, 2, 2, 0, 1, 0, 2, 0, 1, 1, 2, 2, 0, 2, 2, 2, 1, 0, 1, 0, 0, 0, 2, 1, 0, 1, 0, 0, 2, 0, 1, 0, 1, 2, 1, 1, 1, 0, 1, 2, 2, 0, 0, 0, 2, 0, 0, 0, 2, 0, 2, 0, 1, 0, 2, 1, 2, 0, 2, 2, 1, 0, 1, 0, 2, 2, 0, 2, 0, 2, 1, 2, 1, 2, 1, 2, 0, 0, 1, 1, 2, 1, 2, 1, 2, 0, 1, 2, 1, 2, 2, 2, 2, 0, 0, 2, 2, 1, 1, 1, 2, 2, 0, 0, 0, 1, 0, 1, 0, 2, 0, 0, 2, 2, 0, 2, 0, 2, 1, 0, 1, 0, 2, 2, 2, 0, 0, 0, 2, 1, 0, 1, 0, 1, 1, 2, 1, 2, 2, 2, 2, 2, 2, 1, 2, 2, 2, 1, 1, 2, 1, 2, 1, 0, 1, 2, 1, 2, 2, 2, 0, 1, 1, 2, 0, 2, 1, 1, 2, 0, 1, 2, 0, 1, 2, 0, 2, 0, 1, 0, 1, 2, 1, 0, 2, 0, 0, 0, 1, 1, 2, 1, 1, 2, 2, 0, 0, 1, 2, 0, 0, 0, 0, 2, 1, 0, 1, 2, 0, 0, 2, 1, 0, 1, 0, 2, 1, 0, 1, 2, 2, 1, 2, 1, 1, 1, 1, 0, 1, 1, 2, 0, 0, 1, 1, 1, 2, 1, 0, 2, 1, 2, 0, 1, 0, 0, 1, 1, 1, 2, 2, 1, 1, 1, 1, 1, 2, 0, 2, 2, 0, 2, 2, 1, 0, 0, 1, 0, 1, 0, 2, 1, 0, 2, 2, 1, 0, 0, 0, 0, 2, 0, 2, 2, 1, 2, 1, 1, 1, 2, 1, 1, 2, 1, 1, 2, 0, 2, 1, 1, 2, 1, 1, 1, 1, 0, 2, 1, 2, 0, 2, 1, 2, 1, 2, 0, 1, 0, 2, 2, 0, 0, 1, 1, 2, 2, 0, 1, 1, 2, 1, 0, 0, 1, 2, 2, 1, 0, 2, 1, 0, 1, 1, 1, 1, 1, 1, 1, 2, 1, 0, 2, 1, 0, 1, 0, 1, 1, 1, 1, 2, 0, 1, 0, 1, 0, 2, 2, 1, 1, 2, 2, 1, 2, 1, 1, 0, 1, 0, 2, 2, 0, 2, 1, 2, 1, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 2, 0, 0, 2, 2, 2, 1, 1, 0, 0, 1, 1, 1, 1, 1, 0, 1, 2, 1, 2, 0, 2, 1, 0, 0, 1, 0, 0, 1, 1, 1, 1, 1, 2, 2, 0, 1, 1, 2, 1, 2, 0, 2, 0, 0, 2, 2, 0, 1, 1, 1, 1, 2]
    let colorChoiceIndexes1 = [0, 0, 2, 2, 0, 0, 1, 0, 0, 0, 0, 0, 2, 2, 1, 0, 2, 1, 0, 0, 2, 1, 2, 0, 2, 0, 1, 1, 2, 2, 0, 2, 1, 2, 1, 1, 1, 2, 0, 2, 2, 1, 1, 2, 0, 0, 1, 0, 1, 0, 2, 1, 1, 2, 1, 0, 0, 2, 1, 1, 2, 0, 2, 0, 0, 1, 2, 2, 2, 0, 0, 2, 0, 0, 1, 0, 1, 2, 1, 0, 2, 0, 1, 1, 1, 0, 0, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 0, 0, 1, 2, 1, 2, 1, 0, 2, 2, 2, 1, 2, 2, 2, 1, 0, 0, 0, 2, 0, 1, 0, 2, 0, 2, 0, 1, 2, 1, 2, 0, 2, 1, 0, 0, 1, 2, 2, 1, 2, 1, 2, 0, 0, 0, 0, 2, 0, 1, 2, 2, 1, 1, 2, 2, 0, 2, 1, 1, 0, 1, 0, 1, 2, 0, 1, 2, 0, 0, 1, 1, 0, 0, 2, 0, 0, 1, 2, 1, 2, 0, 0, 2, 0, 1, 0, 2, 2, 0, 2, 1, 1, 0, 0, 0, 2, 1, 2, 2, 1, 1, 2, 0, 2, 0, 1, 0, 2, 2, 2, 0, 1, 2, 0, 2, 2, 2, 0, 1, 0, 2, 1, 1, 1, 0, 0, 0, 1, 1, 2, 2, 0, 2, 0, 0, 0, 1, 1, 0, 2, 1, 2, 2, 2, 0, 1, 1, 0, 0, 0, 2, 2, 1, 0, 2, 1, 2, 0, 0, 2, 2, 0, 2, 0, 1, 1, 1, 2, 2, 1, 0, 1, 0, 0, 1, 2, 0, 1, 0, 2, 1, 0, 2, 1, 1, 2, 0, 1, 0, 1, 2, 0, 1, 0, 2, 2, 1, 0, 0, 0, 0, 2, 2, 0, 1, 0, 2, 0, 2, 0, 0, 0, 2, 0, 1, 2, 0, 2, 0, 1, 0, 1, 0, 0, 1, 1, 1, 0, 1, 1, 1, 1, 2, 0, 2, 1, 2, 0, 0, 2, 2, 1, 2, 0, 0, 0, 1, 0, 0, 2, 0, 2, 2, 1, 1, 1, 1, 1, 0, 1, 2, 2, 2, 0, 2, 1, 0, 1, 0, 2, 0, 0, 1, 0, 2, 2, 2, 2, 0, 0, 2, 1, 2, 1, 2, 0, 1, 0, 1, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 2, 1, 2, 1, 2, 2, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 2, 2, 2, 0, 0, 2, 0, 2, 0, 0, 0, 2, 0, 1, 2, 2, 0, 0, 2, 2, 1, 0, 0, 0, 1, 2, 0, 2, 0, 0, 0, 2, 1, 2, 1, 0, 1, 0, 0, 1, 0, 2, 0, 2, 0, 0, 1, 1, 1, 0, 2, 0, 1, 0, 2, 0, 0, 1, 2, 0, 1, 0, 2, 1, 2, 1, 0, 2, 2, 1, 1, 0, 0, 2, 2, 0, 2, 2, 0, 2, 0, 0, 0, 0, 0, 1, 1, 0, 2, 2, 1, 2, 1, 2, 0, 2, 2, 1, 1, 0, 0, 2, 2, 1, 1, 1, 1, 2, 0, 0, 2, 2, 1, 0, 2, 0, 2, 2, 2, 2, 2, 0, 2, 2, 1, 2, 0, 2, 1, 0, 0, 0, 1, 0, 1, 0, 2, 2, 1, 0, 0, 1, 0, 0, 0, 2, 0, 1, 1, 0, 2, 1, 0, 0, 0, 1, 0, 1, 0, 1, 1, 0, 2, 1, 0, 1, 1, 0, 2, 2, 2, 1, 0, 1, 1, 2, 0, 2, 0, 0, 2, 0, 1, 0, 0, 0, 1, 2, 2, 1, 0, 1, 0, 0, 0, 1, 0, 1, 2, 0, 1, 1, 1, 0, 0]
    let colorChoiceIndexes2 = [1, 2, 1, 0, 1, 2, 1, 2, 0, 2, 2, 1, 1, 2, 0, 2, 1, 0, 0, 0, 1, 0, 2, 1, 1, 2, 2, 1, 2, 2, 1, 1, 1, 1, 2, 1, 2, 1, 1, 2, 1, 0, 1, 1, 0, 1, 1, 2, 0, 1, 2, 1, 1, 2, 0, 0, 1, 1, 0, 2, 0, 0, 2, 1, 0, 1, 1, 2, 2, 1, 2, 0, 0, 2, 2, 0, 1, 1, 1, 1, 2, 2, 0, 2, 0, 1, 0, 0, 0, 2, 2, 0, 0, 2, 1, 1, 1, 2, 2, 1, 2, 0, 1, 0, 2, 2, 2, 0, 2, 0, 1, 0, 1, 1, 0, 2, 1, 1, 0, 2, 1, 0, 1, 0, 2, 0, 2, 0, 2, 1, 0, 2, 2, 0, 0, 2, 1, 0, 1, 1, 2, 2, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 0, 2, 2, 2, 1, 1, 0, 1, 2, 1, 0, 1, 0, 0, 2, 0, 0, 2, 1, 2, 1, 2, 0, 0, 0, 1, 0, 0, 1, 0, 2, 2, 2, 0, 2, 2, 2, 0, 0, 1, 2, 2, 1, 1, 0, 2, 2, 2, 1, 1, 2, 1, 1, 1, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1, 0, 2, 0, 1, 1, 2, 1, 0, 2, 2, 1, 0, 0, 2, 0, 2, 1, 2, 2, 0, 1, 2, 0, 2, 2, 2, 1, 0, 0, 1, 2, 1, 2, 2, 2, 2, 1, 0, 2, 1, 0, 0, 1, 1, 2, 0, 1, 1, 2, 2, 0, 2, 0, 2, 0, 0, 1, 2, 1, 1, 2, 2, 0, 0, 1, 1, 2, 0, 2, 1, 0, 0, 0, 2, 1, 0, 1, 1, 0, 0, 2, 1, 0, 1, 2, 0, 2, 1, 1, 1, 1, 1, 1, 2, 2, 1, 1, 0, 2, 0, 1, 1, 0, 2, 0, 1, 2, 0, 2, 0, 0, 2, 2, 2, 0, 0, 1, 1, 1, 1, 1, 1, 2, 1, 2, 1, 0, 0, 2, 0, 0, 0, 2, 1, 0, 1, 0, 0, 0, 0, 2, 2, 1, 2, 2, 0, 0, 2, 1, 0, 2, 2, 2, 1, 2, 1, 1, 1, 2, 2, 2, 1, 1, 0, 1, 2, 2, 0, 0, 0, 1, 0, 0, 2, 2, 0, 2, 1, 0, 1, 0, 1, 0, 2, 1, 0, 1, 2, 0, 1, 0, 1, 2, 1, 0, 1, 2, 0, 2, 2, 0, 2, 1, 2, 1, 1, 2, 0, 0, 2, 0, 0, 1, 1, 2, 0, 0, 2, 1, 2, 0, 1, 0, 1, 0, 2, 2, 0, 1, 2, 0, 1, 2, 0, 0, 1, 1, 1, 2, 1, 1, 0, 0, 1, 2, 0, 1, 1, 1, 2, 0, 2, 0, 2, 0, 1, 1, 1, 2, 1, 2, 0, 2, 0, 1, 0, 1, 2, 2, 0, 0, 0, 1, 0, 0, 1, 1, 1, 0, 0, 1, 1, 1, 2, 2, 1, 1, 2, 0, 1, 2, 1, 2, 1, 1, 1, 2, 1, 0, 0, 2, 0, 1, 0, 0, 0, 0, 0, 0, 1, 2, 1, 2, 1, 2, 2, 0, 2, 0, 0, 1, 2, 2, 0, 0, 0, 2, 0, 0, 0, 2, 0, 2, 1, 0, 2, 2, 2, 2, 1, 1, 2, 0, 0, 1, 0, 1, 2, 1, 2, 2, 1, 2, 2, 1, 0, 0, 2, 0, 1, 2, 0, 1, 1, 0, 0, 0, 1, 0, 1, 2, 2, 1, 2, 0, 1, 2, 2, 0, 0, 1, 0, 1, 2, 2, 0, 0, 2, 2, 1, 0, 1, 2, 0, 1, 0, 2, 0, 2, 1, 2, 0, 0, 1, 1, 2]*/
    
    //let colorChoices = [REConstants.REColors.reBlue.gradient, REConstants.REColors.reRed.gradient, REConstants.REColors.reGrey.gradient]

    //let sphereStyles = [REConstants.REColors.sphereGradient_Red, REConstants.REColors.sphereGradient_Blue, REConstants.REColors.sphereGradient_Green, REConstants.REColors.sphereGradient_Purple, REConstants.REColors.sphereGradient_Yellow]
    //@State private var experimentalMode: Bool = ProgramModeController.shared.programMode == .minAvailable
    
    @EnvironmentObject var programModeController: ProgramModeController
    
    var body: some View {
        if !programModeController.isExperimentalMode {
            Rectangle()
                .fill(
                    .reBackgroundDarker
                )
                .overlay(alignment: .bottom) {
                    VStack {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(REConstants.REColors.sphereGradient_Green.shadow(.drop(color: Color.black, radius: 2, y: 3)))
                                    .frame(width: 300, height: 300)
                                    .padding()
                                    .offset(x: -150, y: -150)
                                Circle()
                                    .fill(REConstants.REColors.sphereGradient_Blue.shadow(.drop(color: Color.black, radius: 2, y: 3)))
                                    .frame(width: 275, height: 275)
                                    .padding()
                                    .offset(x: -150, y: -150)
                            }
                            Spacer()
                            Circle()
                                .fill(REConstants.REColors.sphereGradient_Green.shadow(.drop(color: Color.black, radius: 2, y: 3)))
                                .frame(width: 300, height: 300)
                                .padding()
                                .offset(x: 150, y: -150)
                        }
                        Spacer()
                        HStack {
                            Circle()
                                .fill(REConstants.REColors.sphereGradient_Green.shadow(.drop(color: Color.black, radius: 2, y: 3)))
                                .frame(width: 300, height: 300)
                                .padding()
                                .offset(x: -150, y: 150)
                            Spacer()
                        }
                    }
                }
                .opacity(0.5)

        } else {
            ZStack {
                VStack {
                    Spacer()
                    HStack(alignment: .lastTextBaseline) {
                        Spacer()
                        Text(REConstants.ExperimentalMode.experimentalModeFull)
                            .font(.system(size: 16).smallCaps())
                            .bold()
                            .foregroundStyle(.reRedGradientStart) // REConstants.REColors.sphereGradient_Red)
                            //.padding()
                        PopoverViewWithButtonLocalStateOptions(popoverViewText: REConstants.ExperimentalMode.experimentalModeDisclaimer, optionalSubText: REConstants.ExperimentalMode.experimentalModeDisableDisclaimer)
                    }
                    .padding()
                }
                Rectangle()
                    .fill(
                        .reBackgroundDarker
                    )
                    .overlay(alignment: .bottom) {
                        VStack {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(REConstants.REColors.sphereGradient_Red.shadow(.drop(color: Color.black, radius: 2, y: 3)))
                                        .frame(width: 300, height: 300)
                                        .padding()
                                        .offset(x: -150, y: -150)
                                }
                                Spacer()
                                Circle()
                                    .fill(REConstants.REColors.sphereGradient_Purple.shadow(.drop(color: Color.black, radius: 2, y: 3)))
                                    .frame(width: 300, height: 300)
                                    .padding()
                                    .offset(x: 150, y: -150)
                            }
                            Spacer()
                            HStack {
                                Circle()
                                    .fill(REConstants.REColors.sphereGradient_Purple.shadow(.drop(color: Color.black, radius: 2, y: 3)))
                                    .frame(width: 300, height: 300)
                                    .padding()
                                    .offset(x: -150, y: 150)
                                Spacer()
                            }
                        }
                    }
                    .opacity(0.5)
            }
//            ZStack {
//                Rectangle().fill(REConstants.REColors.sphereGradient_Purple)
//                VStack {
//                    HStack(alignment: .lastTextBaseline) {
//                        Text(REConstants.ExperimentalMode.experimentalModeFull)
//                            .font(.system(size: 10).smallCaps())
//                            .bold()
//                            .foregroundStyle(REConstants.REColors.sphereGradient_Yellow)
//                            .padding([.top], 1)
//                            .padding(.leading)
//                        PopoverViewWithButtonLocalStateOptions(popoverViewText: REConstants.ExperimentalMode.experimentalModeDisclaimer)
//                        Spacer()
//                    }
//                    Spacer()
//                }
//            }
        }
    }
}
