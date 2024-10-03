//
//  AccessPassController.swift
//  Reexpress
//
//  Created by A on 10/5/23.
//

/* This and the rest of the StoreKit implementation is based on Apple's Backyard Birds demo code. */

/*
import StoreKit

actor AccessPassController {
   
    private var updatesTask: Task<Void, Never>?
    deinit {
        updatesTask?.cancel()
    }
    
    private(set) static var shared: AccessPassController!
    
    static func createSharedInstance() {
        shared = AccessPassController()
    }
    // We only use this as an FYI to the user to update billing and to notify of billing errors (i.e., .inGracePeriod and .inBillingRetryPeriod)
    var additionalCurrentStateDetails: Product.SubscriptionInfo.RenewalState = .revoked
    
//    func getAdditionalCurrentStateDetails() -> Product.SubscriptionInfo.RenewalState {
//        return additionalCurrentStateDetails
//    }
    func processState(state: Product.SubscriptionInfo.RenewalState) -> Bool {
        switch state {
        case .subscribed:
            additionalCurrentStateDetails = .subscribed
            return true
        case .inGracePeriod:
            additionalCurrentStateDetails = .inGracePeriod
            return true
        case .expired:
            additionalCurrentStateDetails = .expired
            return false
        case .inBillingRetryPeriod:
            additionalCurrentStateDetails = .inBillingRetryPeriod
            return false
        case .revoked:
            additionalCurrentStateDetails = .revoked
            return false
        default:  // benefit of the doubt for any future cases---for example, if in the future, inGracePeriod is given additional granularity, so we do not cut off users until we update
            additionalCurrentStateDetails = .subscribed
            return true
        }
    }
    func status(for statuses: [Product.SubscriptionInfo.Status], ids: PassIdentifiers) -> PassStatus {

        let effectiveStatus = statuses.max { lhs, rhs in
            let lhsStatus = PassStatus(
                productID: lhs.transaction.unsafePayloadValue.productID,
                ids: ids
            ) ?? .notSubscribed
            let rhsStatus = PassStatus(
                productID: rhs.transaction.unsafePayloadValue.productID,
                ids: ids
            ) ?? .notSubscribed
            return lhsStatus < rhsStatus
        }
        guard let effectiveStatus else {
            return .notSubscribed
        }

        var isCurrent: Bool = false
        let transaction: Transaction
        switch effectiveStatus.transaction {
        case .verified(let t):
            transaction = t
            isCurrent = processState(state: effectiveStatus.state)

            Task {
                await t.finish()
            }
        case .unverified(_, _): //(let t, let error):
            return .notSubscribed
        }
        
        // We currently rely on automatic validation from StoreKit.
        if let retrievedPassStatus = PassStatus(productID: transaction.productID, ids: ids) {
            if isCurrent {
                return retrievedPassStatus
            } else {
                return .notSubscribed
            }
        }
        return .notSubscribed
        //return PassStatus(productID: transaction.productID, ids: ids) ?? .notSubscribed
    }
    
    func process(transaction verificationResult: VerificationResult<Transaction>) async -> Bool {
//        do {
//            let unsafeTransaction = verificationResult.unsafePayloadValue
//            logger.log("""
//            Processing transaction ID \(unsafeTransaction.id) for \
//            \(unsafeTransaction.productID)
//            """)
//        }
        
        let transaction: Transaction
        switch verificationResult {
        case .verified(let t):
            transaction = t
        case .unverified(_, _): //(let t, let error):
            // ignore unverified transactions
            return false
        }

        switch transaction.productType {
        case .autoRenewable:
            if let availableSubscriptionStatus = await transaction.subscriptionStatus {
                let isCurrent = processState(state: availableSubscriptionStatus.state)
                return isCurrent
            }
        default:
            break
        }
        return false
    }
}


*/
