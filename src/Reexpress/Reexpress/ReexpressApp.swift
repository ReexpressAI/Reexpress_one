//
// All files in this Project are copyright Reexpress AI, Inc. (2022-) unless indicated otherwise. All 'Created by "A"' are 'Created by "Reexpress AI, Inc." unless indicated otherwise.
//  ReexpressApp.swift
//  Reexpress
//

//  Created by A on 1/20/23.
//

// NOTE (10/1/2024): In this version, we disable subscriptions. Note that CommandMenu("Account") has been commented out below, and other Storekit code has been disabled (e.g., in ProgramControlStateViewModifier) or given holder values. Be sure to check the Apple documentation for the most up to date guidelines for subscriptions if you plan to re-enable.

import SwiftUI

@main
struct ReexpressApp: App {
    @StateObject var initialSetupDataController = InitialSetupDataController()
    @StateObject var programModeController = ProgramModeController()
    var body: some Scene {
        Window(REConstants.ProgramIdentifiers.mainProgramName, id: "main") {
            
            MainEntryView()
                .environmentObject(initialSetupDataController)
                .environmentObject(programModeController)
            
                .frame(minWidth: 800, minHeight: 600)
                //.accessPassShop()
                .onAppear {
                    // To simplify, currently we always set to dark mode.
                    NSApp.appearance = NSAppearance(named: .darkAqua) //NSAppearance(named: .aqua)
                    // disable tabs:
                    NSWindow.allowsAutomaticWindowTabbing = false
                }
            
        }
        .commands {
            PrimaryAppCommands()
        }
    }
}

struct PrimaryAppCommands: Commands {

    @Environment(\.openURL) private var openURL

    var body: some Commands {
//        CommandMenu("Account") {
//            Button("Manage subscription at Apple.com") {
//                openURL(URL(string: "https://apps.apple.com/account/subscriptions")!)
//            }
//            RestoreSubscriptionButtonView()
//        }
        CommandGroup(replacing: .help) {
            Button("Documentation at re.express") {
                openURL(URL(string: "https://re.express/guide.html")!)
            }
        }
    }
}
