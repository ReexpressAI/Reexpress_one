//
//  TrainingCompleteView.swift
//  Alpha1
//
//  Created by A on 9/3/23.
//

import SwiftUI

struct TrainingCompleteView: View {

    @Binding var totalElapsedTime: String
    @Binding var taskWasCancelled: Bool
    var existingProcessStartTime: Date?
    var body: some View {
        ZStack {
            CancellingAndFreeingResourcesView(taskWasCancelled: $taskWasCancelled)
            
            ScrollView {
                VStack {
                    HStack(alignment: .top) {
                        Text("Process Concluded")
                            .font(.title)
                            .bold()
                            .foregroundColor(.gray)
                            .opacity(0.75)
                            .padding([.leading, .trailing, .top])
                        Spacer()
                    }
                    HStack {
                        Spacer()
                        VStack {
                            Spacer()
                            if !totalElapsedTime.isEmpty {
                                HStack(spacing: 0) {
                                    Text("Training runtime:  ")
                                        .foregroundStyle(.gray)
                                    Text(totalElapsedTime)
                                        .monospaced()
                                }
                                .font(REConstants.Fonts.baseFont)
                                .padding()
                            }
                            Spacer()
                        }
                        Spacer()
                    }
                    .padding()
                    .modifier(SimpleBaseBorderModifier())
                    .padding()
                }
                .padding()
                .frame(minHeight: 800, idealHeight: 800)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            if let processStartTime = existingProcessStartTime {  // takes an existing time as argument
                let processDuration = Date().timeIntervalSince(processStartTime)
                if let processDurationString = REConstants.durationFormatter.string(from: processDuration) {
                    totalElapsedTime = processDurationString
                }
            }
        }
    }
}
