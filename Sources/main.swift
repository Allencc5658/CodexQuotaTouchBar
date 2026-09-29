import AppKit
import Foundation

if CommandLine.arguments.contains("--probe") {
    do {
        let quota = try CodexClient.fetch()
        print(L10n.format("plan", quota.planLabel))
        if quota.showsFiveHour {
            print(L10n.format("five_hour_line", QuotaText.percent(quota.fiveHour),
                              QuotaText.reset(quota.fiveHour, weekly: false)))
        }
        if quota.showsWeekly {
            print(L10n.format("weekly_line", QuotaText.percent(quota.weekly),
                              QuotaText.reset(quota.weekly, weekly: true)))
        }
    } catch {
        fputs("\(error.localizedDescription)\n", stderr)
        exit(1)
    }
} else {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.run()
}
