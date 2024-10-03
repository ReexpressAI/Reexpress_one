//
//  ProgramControlStateStatusLoadingView.swift
//  Reexpress
//
//  Created by A on 10/9/23.
//

import SwiftUI

struct ProgramControlStateStatusLoadingView: View {
    //@Binding var currentPassStatus: PassStatus
    
    @Environment(\.dismiss) private var dismiss
//    @Environment(\.passStatusIsLoading) private var passStatusIsLoading
//    @Environment(\.passStatus) private var passStatus
    @EnvironmentObject var programModeController: ProgramModeController
    var modelStateAndOrSubscriptionStatusIsLoading: Bool {
//        return passStatusIsLoading || programModeController.programMode == .loading
        return programModeController.programMode == .loading
    }
    var body: some View {
        VStack {
            ProgramControlStateStatusLoadingViewContent()
        }
        .frame(width: 400, height: 550)
        .background(
            REStoreKitBackground()
        )
        .onChange(of: modelStateAndOrSubscriptionStatusIsLoading, initial: true) { oldValue, newValue in
            if !newValue {
                //currentPassStatus = passStatus
                dismiss()
            }
        }
        .onAppear {
            programModeController.determineProgramMode()
        }
    }
}

private struct ProgramControlStateStatusLoadingViewContent: View {
    
    var body: some View {
        VStack(spacing: 10) {
            VStack(spacing: 3) {
                Text(REConstants.ProgramIdentifiers.mainProgramName).foregroundStyle(.orange.gradient)
                    .font(.largeTitle.bold())
            }
            ProgressView()
            
            HStack(alignment: .lastTextBaseline) {
//                Text("Checking account status and availability of required Apple silicon device ...")
                Text("Checking availability of required Apple silicon device ...")
                    .fixedSize(horizontal: false, vertical: true)
                    .font(.title3.weight(.medium))
                    .padding([.bottom, .horizontal])
                    .frame(maxWidth: 350)
                //                    PopoverViewWithButtonLocalStateOptions(popoverViewText: "If the program does not advance beyond this screen, it means that this device is not capable of running \(REConstants.ProgramIdentifiers.mainProgramName), even in the reduced functionality **\(REConstants.ExperimentalMode.experimentalModeFull)**, or the Account status cannot be accessed.")
            }
        }
        .padding()
        .modifier(SimpleBaseBorderModifier(useShadow: true))
        .padding()
        .multilineTextAlignment(.center)
    }
    
}
