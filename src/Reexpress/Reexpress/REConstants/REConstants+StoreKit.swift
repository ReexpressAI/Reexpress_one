//
//  REConstants+StoreKit.swift
//  Reexpress
//
//  Created by A on 10/7/23.
//

import Foundation
import SwiftUI

extension REConstants {
    struct StoreKit {
        struct Labels {
            static let notSubscribedLabel: String = "Not Subscribed"
            static let fedLabel: String = "TODO some string id of subscription"
        }
        struct Marketing {
            static let storeKitDescription0Text: Text = Text("Unlock access to \(Text("**\(REConstants.ProgramIdentifiers.mainProgramName)**").foregroundStyle(.orange.gradient)) and get in on the ground floor of reliable, on-device A.I.")
        }
        struct UserInstructions {
            static let errorAlertMain = "Unable to complete purchase."
            static let errorAlertMainMessage = "The Account menu has additional options, including a link to Apple.com's subscription management page."
            
            static let billingErrorMessage = "Please go to https://apps.apple.com/account/billing to update the billing information for your subscription."
        }
        struct Terms {
            static let privacyURL: URL = URL(string: "TODO: url to your privacy policy")!
            static let termsOfServiceURL: URL = URL(string: "TODO: url to your terms of service")!
        }
    }
}
