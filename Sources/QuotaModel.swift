import Foundation

struct QuotaWindow: Decodable {
    let usedPercent: Double
    let windowDurationMins: Int?
    let resetsAt: TimeInterval?

    var remainingPercent: Double {
        max(0, min(100, 100 - usedPercent))
    }

    var roundedRemaining: Int { Int(remainingPercent.rounded()) }
}

struct RateLimitSnapshot: Decodable {
    let planType: String?
    let primary: QuotaWindow?
    let secondary: QuotaWindow?
}

struct RateLimitsResponse: Decodable {
    let rateLimits: RateLimitSnapshot
    let rateLimitsByLimitId: [String: RateLimitSnapshot]?

    var codexLimit: RateLimitSnapshot {
        rateLimitsByLimitId?["codex"] ?? rateLimits
    }
}

struct AccountResponse: Decodable {
    struct Account: Decodable {
        let planType: String?
    }
    let account: Account?
}

struct QuotaState {
    let plan: String?
    let fiveHour: QuotaWindow?
    let weekly: QuotaWindow?
    let fetchedAt: Date

    init(rateLimits: RateLimitsResponse, accountPlan: String? = nil, fetchedAt: Date = Date()) {
        let limit = rateLimits.codexLimit
        plan = limit.planType ?? accountPlan

        let windows = [limit.primary, limit.secondary].compactMap { $0 }
        fiveHour = windows.first { $0.windowDurationMins == 300 }
        weekly = windows.first { $0.windowDurationMins == 10_080 }
        self.fetchedAt = fetchedAt
    }

    var isPlus: Bool { plan?.lowercased() == "plus" }
    var isPro: Bool { plan?.lowercased() == "pro" }
    var showsFiveHour: Bool { isPlus || (!isPro && fiveHour != nil) }
    var showsWeekly: Bool { isPlus || weekly != nil }

    var planLabel: String {
        guard let plan = plan else { return L10n.text("unknown_plan") }
        if plan.lowercased() == "prolite" { return "Pro Lite" }
        return plan.capitalized
    }
}

enum QuotaText {
    static func reset(_ window: QuotaWindow?, weekly: Bool) -> String {
        guard let timestamp = window?.resetsAt else { return L10n.text("reset_unknown") }
        let formatter = DateFormatter()
        formatter.locale = L10n.locale
        formatter.dateFormat = weekly ? "M/d HH:mm" : "HH:mm"
        return formatter.string(from: Date(timeIntervalSince1970: timestamp))
    }

    static func percent(_ window: QuotaWindow?) -> String {
        guard let window = window else { return L10n.text("no_data") }
        return L10n.format("remaining", window.roundedRemaining)
    }
}
