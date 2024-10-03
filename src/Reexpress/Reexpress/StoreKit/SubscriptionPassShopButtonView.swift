//
//  SubscriptionPassShopButtonView.swift
//  Reexpress
//
//  Created by A on 10/9/23.
//

/*
import SwiftUI
import StoreKit

// Typically, we auto present the shop, but we also provide this option to bring it back up after a cancel
struct SubscriptionPassShopButtonView: View {
    @State private var presentingStoreKitSheet: Bool = false
    @Environment(\.passStatus) private var passStatus
    @Environment(\.passStatusIsLoading) private var passStatusIsLoading
    
    @State private var errorWasEncountered: Bool = false
    
    //@State private var getSubscriptionDetailsTask: Task<Void, Error>?
    @State private var additionalDetails = ""
    var statusStringLabel: String {
        if passStatusIsLoading {
            return "Loading"
        }
        if passStatus == .fed_2023v1 {
            return "Active"
        } else {
            return "Inactive"
        }
        
    }
    func updateAdditionalDetails() async {
        Task {
            if let accessPassController = AccessPassController.shared {
                let renewalState = await accessPassController.additionalCurrentStateDetails
                await MainActor.run {
                    switch renewalState {
                    case .inGracePeriod:
                        additionalDetails = "**Billing update needed**"
                    case .inBillingRetryPeriod:
                        additionalDetails = "**Billing error**"
                    default:
                        additionalDetails = ""
                    }
                }
            }
        }
    }
    var body: some View {
        HStack {
            Button {
                presentingStoreKitSheet = true
            } label: {
                Text("View Subscription Store")
                    .font(REConstants.Fonts.baseFont.smallCaps())
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.borderless)
            .opacity(presentingStoreKitSheet ? 0.5 : 1.0)
            .disabled(presentingStoreKitSheet)
            .padding(.leading)
            Spacer()
            HStack(alignment: .lastTextBaseline) {
                Text("Account Status: \(statusStringLabel)")
                    .font(REConstants.Fonts.baseFont)
                    PopoverViewWithButtonLocalStateOptions(popoverViewText: additionalDetails, optionalSubText: REConstants.StoreKit.UserInstructions.billingErrorMessage)
                        .foregroundStyle(.reSemanticHighlight)
                    .opacity(additionalDetails.isEmpty ? 0.0 : 1.0)
            }
            .padding(.leading)
        }
        .sheet(isPresented: $presentingStoreKitSheet) {
            SubscriptionPassShop(errorWasEncountered: $errorWasEncountered)
        }
        .alert(REConstants.StoreKit.UserInstructions.errorAlertMain, isPresented: $errorWasEncountered) {
            Button {
            } label: {
                Text("OK")
            }
        } message: {
            Text(.init(REConstants.StoreKit.UserInstructions.errorAlertMainMessage))
        }
        .onChange(of: passStatus) {
            Task {
                await updateAdditionalDetails()
            }
        }
        .onChange(of: passStatusIsLoading, initial: true) { oldValue, newValue in
            Task {
                await updateAdditionalDetails()
            }
        }
    }
}

#Preview {
    SubscriptionPassShopButtonView()
}
*/
