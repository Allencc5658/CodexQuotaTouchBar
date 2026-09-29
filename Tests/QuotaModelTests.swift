import Foundation

func parse(_ json: String, accountPlan: String? = nil) -> QuotaState {
    let limits = try! JSONDecoder().decode(RateLimitsResponse.self, from: Data(json.utf8))
    return QuotaState(rateLimits: limits, accountPlan: accountPlan)
}

let plus = parse("""
{"rateLimits":{"planType":"plus","primary":{"usedPercent":20,"windowDurationMins":10080,"resetsAt":2000000000},"secondary":{"usedPercent":35,"windowDurationMins":300,"resetsAt":1900000000}}}
""")
assert(plus.showsFiveHour && plus.showsWeekly)
assert(plus.fiveHour?.roundedRemaining == 65)
assert(plus.weekly?.roundedRemaining == 80)

let pro = parse("""
{"rateLimits":{"planType":"pro","primary":{"usedPercent":12,"windowDurationMins":10080,"resetsAt":2000000000},"secondary":null}}
""")
assert(!pro.showsFiveHour && pro.showsWeekly)
assert(pro.weekly?.roundedRemaining == 88)

let missingFiveHour = parse("""
{"rateLimits":{"planType":"plus","primary":{"usedPercent":31,"windowDurationMins":10080,"resetsAt":2000000000},"secondary":null}}
""")
assert(missingFiveHour.showsFiveHour && missingFiveHour.fiveHour == nil)

let multiBucket = parse("""
{"rateLimits":{"planType":"plus","primary":{"usedPercent":99,"windowDurationMins":300}},"rateLimitsByLimitId":{"codex":{"planType":"plus","primary":{"usedPercent":3,"windowDurationMins":300},"secondary":{"usedPercent":9,"windowDurationMins":10080}}}}
""")
assert(multiBucket.fiveHour?.roundedRemaining == 97)
assert(multiBucket.weekly?.roundedRemaining == 91)

let negativeUsage = QuotaWindow(usedPercent: -5, windowDurationMins: 300, resetsAt: nil)
let excessUsage = QuotaWindow(usedPercent: 120, windowDurationMins: 300, resetsAt: nil)
assert(negativeUsage.remainingPercent == 100)
assert(excessUsage.remainingPercent == 0)

print("QuotaModelTests passed")
