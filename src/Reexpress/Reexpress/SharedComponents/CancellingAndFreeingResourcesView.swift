//
//  CancellingAndFreeingResourcesView.swift
//  Alpha1
//
//  Created by A on 8/3/23.
//

import SwiftUI

struct CancellingAndFreeingResourcesView: View {
    @Binding var taskWasCancelled: Bool
    let freeResourceTimerDateRange = Date()...Date().addingTimeInterval(REConstants.ModelControl.defaultCancellingTimeToFreeResources)
    var body: some View {
        VStack {
            Text("Cancelled.")
                .opacity(1.0)
                .font(.title2)
                .padding()
            ProgressView(timerInterval: freeResourceTimerDateRange) {
                Text("Freeing resources...")
                    .opacity(1.0)
                    .font(.title3)
                    .foregroundStyle(.gray)
            }
            //.progressViewStyle(.circular)
//            Text("Freeing resources...")
//                .opacity(1.0)
//                .font(.title3)
//                .foregroundStyle(.gray)
//                .padding()
        }
        .padding()
        .frame(width: 300, height: 150)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(BackgroundStyle())
                .opacity(0.95)
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.gray)
        }
        .padding()
        
        .opacity(taskWasCancelled ? 1.0 : 0.0)
        .zIndex(taskWasCancelled ? 1.0 : 0.0)
    }
}

struct CancellingAndFreeingResourcesView_Previews: PreviewProvider {
    static var previews: some View {
        CancellingAndFreeingResourcesView(taskWasCancelled: .constant(true))
    }
}

