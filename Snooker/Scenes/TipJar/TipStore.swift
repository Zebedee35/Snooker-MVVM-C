//
//  TipStore.swift
//  Snooker
//
//  Thin StoreKit 2 wrapper for the tip jar. Loads products, runs purchases,
//  restores, and tracks which (if any) monthly support subscription is active.
//
//  A pure consumable tip needs no server: StoreKit verifies the transaction
//  on-device and we just `finish()` it. Subscription status is read from
//  `Transaction.currentEntitlements` so it survives reinstalls / new devices.
//

import Foundation
import StoreKit

@MainActor
final class TipStore {

    private(set) var oneTimeProducts: [Product] = []
    private(set) var subscriptionProducts: [Product] = []

    /// Product IDs of currently-active monthly support subscriptions.
    private(set) var activeSubscriptionIDs: Set<String> = []

    /// Long-running listener for transactions that arrive outside an explicit
    /// purchase (Ask to Buy approvals, renewals, purchases on another device).
    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = listenForTransactionUpdates()
    }

    deinit {
        updatesTask?.cancel()
    }

    // MARK: - Loading

    func loadProducts() async throws {
        let products = try await Product.products(for: TipProduct.allIDs)

        let consumables: [Product] = products.filter { $0.type == .consumable }
        let subscriptions: [Product] = products.filter { $0.type == .autoRenewable }

        oneTimeProducts = consumables.sorted { (lhs: Product, rhs: Product) in lhs.price < rhs.price }
        subscriptionProducts = subscriptions.sorted { (lhs: Product, rhs: Product) in lhs.price < rhs.price }

        await refreshSubscriptionStatus()
    }

    // MARK: - Purchase

    enum PurchaseOutcome {
        case success
        case cancelled
        case pending      // e.g. Ask to Buy / parental approval
    }

    func purchase(_ product: Product) async throws -> PurchaseOutcome {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await refreshSubscriptionStatus()
            return .success
        case .userCancelled:
            return .cancelled
        case .pending:
            return .pending
        @unknown default:
            return .cancelled
        }
    }

    /// Re-sync with the App Store (required "Restore Purchases" action).
    func restore() async {
        try? await AppStore.sync()
        await refreshSubscriptionStatus()
    }

    // MARK: - Subscription status

    private func refreshSubscriptionStatus() async {
        var active: Set<String> = []
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            if transaction.productType == .autoRenewable, transaction.revocationDate == nil {
                active.insert(transaction.productID)
            }
        }
        activeSubscriptionIDs = active
    }

    private func listenForTransactionUpdates() -> Task<Void, Never> {
        Task(priority: .background) { [weak self] in
            for await result in Transaction.updates {
                guard let transaction = try? Self.verify(result) else { continue }
                await transaction.finish()
                await self?.refreshSubscriptionStatus()
            }
        }
    }

    // MARK: - Verification

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        try Self.verify(result)
    }

    /// `nonisolated` so the background updates listener can call it without
    /// hopping to the main actor for every transaction.
    nonisolated private static func verify<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw TipStoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}

enum TipStoreError: LocalizedError {
    case failedVerification

    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "We couldn't verify your purchase with the App Store."
        }
    }
}
