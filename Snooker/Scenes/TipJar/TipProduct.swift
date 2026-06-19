//
//  TipProduct.swift
//  Snooker
//
//  Product identifiers for the tip jar. These strings must match EXACTLY the
//  product IDs created in App Store Connect (and in Snooker.storekit for local
//  testing). Prices/display names/descriptions are configured on Apple's side
//  and read back at runtime via StoreKit — never hard-code prices here.
//

import Foundation

enum TipProduct {

    /// One-time tips → App Store **Consumable** products, cheapest first.
    static let oneTimeIDs: [String] = [
        "coders35.Snooker.tip.small",
        "coders35.Snooker.tip.medium",
        "coders35.Snooker.tip.large"
    ]

    /// Monthly support → App Store **Auto-Renewable Subscriptions** in a single
    /// subscription group, cheapest first.
    static let subscriptionIDs: [String] = [
        "coders35.Snooker.support.monthly.small",
        "coders35.Snooker.support.monthly.medium",
        "coders35.Snooker.support.monthly.large"
    ]

    static var allIDs: [String] { oneTimeIDs + subscriptionIDs }
}
