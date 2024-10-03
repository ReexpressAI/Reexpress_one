//
//  SubscriptionPassShop.swift
//  Reexpress
//
//  Created by A on 10/7/23.
//

import SwiftUI
/*import StoreKit


struct SubscriptionPassShop: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.passIDs.group) private var passGroupID
    @Environment(\.passStatus) private var passStatus
    
    @Binding var errorWasEncountered: Bool
    var body: some View {
        SubscriptionStoreView(
            groupID: passGroupID,
            visibleRelationships: .all
        ) {
            PassMarketingContent()
                .containerBackground(for: .subscriptionStoreFullHeight) {
                    REStoreKitBackground()
                }
        }
        
        .storeButton(.visible, for: .policies, .restorePurchases)
        .subscriptionStorePolicyForegroundStyle(
            Color.white
        )
//        .subscriptionStorePolicyDestination(for: .privacyPolicy) {
//            PrivacyTermsView()
//        }
//        .subscriptionStorePolicyDestination(for: .termsOfService) {
//            TermsOfServiceView()
//        }
        .subscriptionStorePolicyDestination(url: REConstants.StoreKit.Terms.privacyURL, for: .privacyPolicy)
        .subscriptionStorePolicyDestination(url: REConstants.StoreKit.Terms.termsOfServiceURL, for: .termsOfService)
        
        //#else
        .frame(width: 400, height: 550)
        //#endif
        //        .subscriptionStoreControlIcon { _, subscriptionInfo in
        //            Group {
        //                switch PassStatus(levelOfService: subscriptionInfo.groupLevel) {
        //                case .premium:
        //                    Image(systemName: "bird")
        //                case .family:
        //                    Image(systemName: "person.3.sequence")
        //                default:
        //                    Image(systemName: "wallet.pass")
        //                }
        //            }
        //            .foregroundStyle(.accent)
        //            .symbolVariant(.fill)
        //        }
        
        //        .backgroundStyle(.clear)
        //.background(BackgroundStyle())
        .subscriptionStoreButtonLabel(.multiline)
        //        .subscriptionStorePickerItemBackground(.ultraThickMaterial)
        //.subscriptionStorePickerItemBackground(.red)
        //.subscriptionStoreControlStyle(.prominentPicker)
        .subscriptionStorePickerItemBackground(.thinMaterial)
        /*.onInAppPurchaseStart { product in
         print("User has started buying \(product.id)")
         }
         .onInAppPurchaseCompletion { product, result in
         if case .success(.success(let transaction)) = result {
         print("Purchased successfully: \(transaction.signedDate)")
         } else {
         print("Something else happened")
         }
         }*/
        .onInAppPurchaseCompletion { product, result in
//            if case .success(.success(let transaction)) = result {
            if case .success(.success(_)) = result {
                //await AccessPassController.shared.process(transaction: transaction)
                dismiss()
            } else {
                errorWasEncountered = true
                dismiss()
            }
            
            //            if case .success(.success(_)) = result {
            //                dismiss()
            //            }
        }
    }
    
}

*/
private struct PassMarketingContent: View {
    
    var body: some View {
        VStack(spacing: 10) {
            VStack(spacing: 3) {
                Text(REConstants.StoreKit.Labels.fedLabel).foregroundStyle(.orange.gradient)
                    .font(.largeTitle.bold())
                //.foregroundStyle(.bar)
            }
            //            description
            REConstants.StoreKit.Marketing.storeKitDescription0Text
                .fixedSize(horizontal: false, vertical: true)
                .font(.title3.weight(.medium))
                .padding([.bottom, .horizontal])
                .frame(maxWidth: 350)
        }
        .padding()
        .modifier(SimpleBaseBorderModifier(useShadow: true))
        .padding(.vertical)
        .padding(.top, 40)
        .multilineTextAlignment(.center)
    }
    
    //    @ViewBuilder
    //    private var subscriptionName: some View {
    //        Text(REConstants.StoreKit.Labels.fedLabel).foregroundStyle(.orange.gradient)
    //    }
    //
    //    @ViewBuilder
    //    private var title: some View {
    //        subscriptionName
    //    }
    
    
}

struct REStoreKitBackground: View {
    //    let sphereGradient = LinearGradient(
    //        colors: [
    //            .reBlueGradientStart,
    //            .reBlueGradientEnd
    //        ],
    //        startPoint: .top,
    //        endPoint: .bottom
    //    )
    var body: some View {
        Rectangle()
            .fill(
                .reBackgroundDarker
            )
            .overlay(alignment: .bottom) {
                ZStack {
                    Circle()
                        .fill(REConstants.REColors.sphereGradient_Green.shadow(.drop(color: Color.black, radius: 2, y: 3)))
                        .frame(width: 300, height: 300)
                        .offset(x: 210, y: -415)
                    
                    Circle()
                        .fill(REConstants.REColors.sphereGradient_Blue.shadow(.drop(color: Color.black, radius: 2, y: 3)))
                        .frame(width: 275, height: 275)
                        .offset(x: 210, y: -415)
                    
                    
                    Circle()
                        .fill(REConstants.REColors.sphereGradient_Green.shadow(.drop(color: Color.black, radius: 2, y: 3)))
                        .frame(width: 300, height: 300)
                        .offset(x: -210, y: 0)
                    Circle()
                        .fill(REConstants.REColors.sphereGradient_Blue.shadow(.drop(color: Color.black, radius: 2, y: 3)))
                        .frame(width: 275, height: 275)
                        .offset(x: -210, y: 0)
                }
            }
    }
}
