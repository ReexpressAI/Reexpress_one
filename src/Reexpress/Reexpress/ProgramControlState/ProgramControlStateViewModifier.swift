//
//  ProgramControlStateViewModifier.swift
//  Reexpress
//
//  Created by A on 10/9/23.
//

import SwiftUI

struct ProgramControlStateViewModifier: ViewModifier {
    // StoreKit
//    @State private var presentingStoreKitSheet: Bool = false
    @State private var presentingLoadingStateSheet: Bool = false
    @State private var presentingExperimentalModeNotice: Bool = false
//    @Environment(\.passStatus) private var passStatus
//    @Environment(\.passStatusIsLoading) private var passStatusIsLoading
//    @Environment(\.passIDs.group) private var passGroupID
    // Control of program mode:
    @EnvironmentObject var programModeController: ProgramModeController
//    @State private var currentPassStatus: PassStatus = .notSubscribed
    @State private var errorWasEncountered: Bool = false
    var modelStateAndOrSubscriptionStatusIsLoading: Bool {
//        return passStatusIsLoading || programModeController.programMode == .loading
        return programModeController.programMode == .loading
    }
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                // need this as an onAppear since this may re-appear after a cancel
                presentingLoadingStateSheet = true
//                currentPassStatus = passStatus
            }
            .sheet(isPresented: $presentingExperimentalModeNotice, onDismiss: {
//                switch passStatus {
//                case .notSubscribed:
//                    presentingStoreKitSheet = true // also need to check for isLoading
//                case .fed_2023v1:
//                    presentingStoreKitSheet = false
//                }
            }) {
                ExperimentalModeAlertView()
            }
            .sheet(isPresented: $presentingLoadingStateSheet, onDismiss: {
                if programModeController.isExperimentalMode {
                    presentingExperimentalModeNotice = true
                } /*else {
                    if case .notSubscribed = currentPassStatus {
                        presentingStoreKitSheet = true
                    }
                }*/
            }) {
                ProgramControlStateStatusLoadingView() //(currentPassStatus: $currentPassStatus)
            }
//            .sheet(isPresented: $presentingStoreKitSheet) {
//                SubscriptionPassShop(errorWasEncountered: $errorWasEncountered)
//            }
//            .alert(REConstants.StoreKit.UserInstructions.errorAlertMain, isPresented: $errorWasEncountered) {
//                Button {
//                } label: {
//                    Text("OK")
//                }
//            } message: {
//                Text(.init(REConstants.StoreKit.UserInstructions.errorAlertMainMessage))
//            }
    }
}

extension View {
    func programControlStateInitializer() -> some View {
        modifier(ProgramControlStateViewModifier())
    }
}

