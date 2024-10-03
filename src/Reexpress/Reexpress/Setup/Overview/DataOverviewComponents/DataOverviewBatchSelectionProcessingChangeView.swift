//
//  DataOverviewBatchSelectionProcessingChangeView.swift
//  Alpha1
//
//  Created by A on 8/27/23.
//

import SwiftUI

struct DataOverviewBatchSelectionProcessingChangeView: View {
    @Binding var changeProcessing: Bool
    @Binding var errorMessage: String
    var body: some View {
        //ScrollView {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                HStack(alignment: .firstTextBaseline) {
                    Text("")
                        .font(.title2.bold())
                    //                        Divider()
                    //                            .frame(width: 2, height: 25)
                    //                            .overlay(.gray)
                    //CurrentSelectionResultsView()
                    //                        SelectionResultsView()
                    Spacer()
                    //                        HStack(alignment: .lastTextBaseline) {
                    //
                    //                        }
                }
            }
            Spacer()
            
            if changeProcessing {
                VStack {
                    ProgressView()
                    HStack {
                        Spacer()
                        Text("Processing update")
                            .font(REConstants.Fonts.baseFont)
                            .foregroundStyle(.gray)
                        Spacer()
                    }
                }
            } else {
                VStack(alignment: .center) {
                    if !errorMessage.isEmpty {
                        HStack {
                            Spacer()
                            
                            Text(errorMessage)
                                .monospaced()
                                .foregroundStyle(.red)
                                .opacity(0.75)
                                .padding()
                                .modifier(SimpleBaseBorderModifier())
                                .padding()
                                .frame(width: 450)
                            Spacer()
                        }
                    } else {
                        HStack(spacing: 0) {
                            Spacer()
                            Text("Successfully processed the batch update.")
                                .monospaced()
                                .foregroundStyle(.orange)
                                .opacity(0.75)
                            Spacer()
                        }
                    }
                }
                .font(REConstants.Fonts.baseFont)
                
            }
            Spacer()
        }
        .padding([.leading, .trailing])
        //}
        //.scrollBounceBehavior(.basedOnSize)
        .padding()
        .modifier(SimpleBaseBorderModifier())
        .padding()
    }
}


