//
//  PassStatus.swift
//  Reexpress
//
//  Created by A on 10/5/23.
//

/*
import StoreKit
import SwiftUI


enum PassStatus: Comparable, Hashable {
    case notSubscribed
    case fed_2023v1
    
    init(levelOfService: Int) {
        self = switch levelOfService {
        case 1: .fed_2023v1
        default: .notSubscribed
        }
    }
    
    init?(productID: Product.ID, ids: PassIdentifiers) {
        switch productID {
        case ids.fed_2023v1: self = .fed_2023v1
        default: return nil
        }
    }
    
        
}

extension PassStatus: CustomStringConvertible {
    
    var description: String {
        switch self {
        case .notSubscribed: REConstants.StoreKit.Labels.notSubscribedLabel // "Not Subscribed")
        case .fed_2023v1: REConstants.StoreKit.Labels.fedLabel //String(localized: "Founder's Edition Access")
        }
    }
    
}

extension EnvironmentValues {
    
    private enum PassStatusEnvironmentKey: EnvironmentKey {
        static var defaultValue: PassStatus = .notSubscribed
    }
    
    private enum PassStatusLoadingEnvironmentKey: EnvironmentKey {
        static var defaultValue = true
    }
    
    fileprivate(set) var passStatus: PassStatus {
        get { self[PassStatusEnvironmentKey.self] }
        set { self[PassStatusEnvironmentKey.self] = newValue }
    }
    
    fileprivate(set) var passStatusIsLoading: Bool {
        get { self[PassStatusLoadingEnvironmentKey.self] }
        set { self[PassStatusLoadingEnvironmentKey.self] = newValue }
    }

}

private struct PassStatusTaskModifier: ViewModifier {
    @Environment(\.passIDs) private var passIDs

    @State private var state: EntitlementTaskState<PassStatus> = .loading
    
    private var isLoading: Bool {
        if case .loading = state { true } else { false }
    }
    
    @State private var subscriptionListenerTask: Task<Void, Error>?
    
    @State private var passStatusForEnvironmentVariable: PassStatus  = .notSubscribed
 
    func body(content: Content) -> some View {
        content
            .subscriptionStatusTask(for: passIDs.group) { state in
                guard let accessPassController = AccessPassController.shared else { fatalError("AccessPassController was nil.") }
                self.state = await state.map { statuses in
                    await accessPassController.status(
                        for: statuses,
                        ids: passIDs
                    )
                }

                switch self.state {
                case .failure(_):
                    break
                case .success(_):
                    passStatusForEnvironmentVariable = self.state.value ?? .notSubscribed
                    break
                case .loading:
                    break
                @unknown default: break
                }
            }
            .task {
                subscriptionListenerTask = Task {
                    for await update in Transaction.updates {
                        guard let accessPassController = AccessPassController.shared else { fatalError("AccessPassController was nil.") }
                        let isCurrent = await accessPassController.process(transaction: update)
                        if isCurrent {
                            await MainActor.run {
                                passStatusForEnvironmentVariable = .fed_2023v1
                            }
                        }
                    }
                }
            }
//            .environment(\.passStatus, state.value ?? .notSubscribed)
            .environment(\.passStatus, passStatusForEnvironmentVariable)
            .environment(\.passStatusIsLoading, isLoading)
            .onDisappear {
                subscriptionListenerTask?.cancel()
            }
    }
}

extension View {
    
    func subscriptionPassStatusTask() -> some View {
        modifier(PassStatusTaskModifier())
    }
    
}

*/
