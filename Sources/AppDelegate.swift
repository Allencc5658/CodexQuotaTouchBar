import AppKit
import ServiceManagement

@_silgen_name("CQTouchBarAvailable") private func CQTouchBarAvailable() -> Bool
@_silgen_name("CQAddTrayItem") private func CQAddTrayItem(_ item: NSTouchBarItem) -> Bool
@_silgen_name("CQPresentTouchBar") private func CQPresentTouchBar(_ bar: NSTouchBar, _ identifier: NSString) -> Bool
@_silgen_name("CQDismissTouchBar") private func CQDismissTouchBar(_ bar: NSTouchBar)
@_silgen_name("CQRemoveTrayItem") private func CQRemoveTrayItem(_ item: NSTouchBarItem)

final class AppDelegate: NSObject, NSApplicationDelegate, NSTouchBarDelegate {
    private let quotaIdentifier = NSTouchBarItem.Identifier("local.codex.quota.touchbar.quota")
    private let trayIdentifier = NSTouchBarItem.Identifier("local.codex.quota.touchbar.tray")
    private let touchBar = NSTouchBar()
    private let touchView = QuotaTouchBarView(frame: NSRect(x: 0, y: 0, width: 470, height: 30))
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let menu = NSMenu()
    private let settingsMenu = NSMenu()
    private let languageMenu = NSMenu()
    private var trayItem: NSCustomTouchBarItem?
    private var barProblemKey: String?
    private var quota: QuotaState?
    private var lastError: Error?
    private var refreshing = false
    private var refreshPending = false
    private var timer: Timer?

    private let planItem = NSMenuItem()
    private let fiveHourItem = NSMenuItem()
    private let weeklyItem = NSMenuItem()
    private let statusLine = NSMenuItem()
    private let refreshItem = NSMenuItem()
    private let showBarItem = NSMenuItem()
    private let settingsItem = NSMenuItem()
    private let languageItem = NSMenuItem()
    private let chooseCodexItem = NSMenuItem()
    private let automaticCodexItem = NSMenuItem()
    private let loginItem = NSMenuItem()
    private let quitItem = NSMenuItem()
    private var languageItems: [AppLanguage: NSMenuItem] = [:]

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        statusItem.button?.image = Self.makeStatusIcon()
        statusItem.button?.imagePosition = .imageLeading
        buildMenu()
        installTouchBar()
        localizeMenu()
        updateDisplay()
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 120, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        timer?.invalidate()
        if let trayItem = trayItem {
            CQDismissTouchBar(touchBar)
            CQRemoveTrayItem(trayItem)
        }
    }

    private func buildMenu() {
        menu.autoenablesItems = false
        for item in [planItem, fiveHourItem, weeklyItem, statusLine] {
            item.isEnabled = false
            menu.addItem(item)
        }
        menu.addItem(.separator())
        refreshItem.target = self
        refreshItem.action = #selector(refreshAction)
        refreshItem.keyEquivalent = "r"
        menu.addItem(refreshItem)
        showBarItem.target = self
        showBarItem.action = #selector(showTouchBar)
        menu.addItem(showBarItem)
        menu.addItem(.separator())

        for language in AppLanguage.allCases {
            let item = NSMenuItem()
            item.target = self
            item.action = #selector(changeLanguage(_:))
            item.representedObject = language.rawValue
            languageMenu.addItem(item)
            languageItems[language] = item
        }
        languageItem.submenu = languageMenu
        settingsMenu.addItem(languageItem)
        settingsMenu.addItem(.separator())
        chooseCodexItem.target = self
        chooseCodexItem.action = #selector(chooseCodex)
        settingsMenu.addItem(chooseCodexItem)
        automaticCodexItem.target = self
        automaticCodexItem.action = #selector(findCodexAutomatically)
        settingsMenu.addItem(automaticCodexItem)
        settingsMenu.addItem(.separator())
        loginItem.target = self
        loginItem.action = #selector(toggleLogin)
        settingsMenu.addItem(loginItem)
        settingsItem.submenu = settingsMenu
        menu.addItem(settingsItem)
        menu.addItem(.separator())
        quitItem.target = self
        quitItem.action = #selector(quitAction)
        quitItem.keyEquivalent = "q"
        menu.addItem(quitItem)
        statusItem.menu = menu
    }

    private func localizeMenu() {
        refreshItem.title = L10n.text("refresh")
        showBarItem.title = L10n.text(barProblemKey ?? "show_touch_bar")
        showBarItem.isEnabled = barProblemKey == nil && trayItem != nil
        settingsItem.title = L10n.text("settings")
        languageItem.title = L10n.text("language")
        languageItems[.automatic]?.title = L10n.text("language_system")
        languageItems[.simplifiedChinese]?.title = L10n.text("language_chinese")
        languageItems[.traditionalChinese]?.title = L10n.text("language_traditional")
        languageItems[.english]?.title = L10n.text("language_english")
        for (language, item) in languageItems {
            item.state = language == L10n.selection ? .on : .off
        }
        chooseCodexItem.title = L10n.text("choose_codex")
        automaticCodexItem.title = L10n.text("automatic_codex")
        automaticCodexItem.isEnabled = UserDefaults.standard.string(forKey: "codexExecutablePath") != nil
        loginItem.title = L10n.text("launch_at_login")
        updateLoginItem()
        quitItem.title = L10n.text("quit")
        statusItem.button?.toolTip = "Codex Quota"
    }

    private func updateLoginItem() {
        if #available(macOS 13.0, *) {
            loginItem.isEnabled = true
            loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        } else {
            loginItem.isEnabled = false
            loginItem.toolTip = L10n.text("login_unavailable")
        }
    }

    private func installTouchBar() {
        touchBar.delegate = self
        touchBar.defaultItemIdentifiers = [quotaIdentifier]
        guard CQTouchBarAvailable() else {
            barProblemKey = "touch_bar_unavailable"
            return
        }
        let tray = NSCustomTouchBarItem(identifier: trayIdentifier)
        let button = NSButton(image: Self.makeStatusIcon(), target: self, action: #selector(showTouchBar))
        button.bezelStyle = .rounded
        button.frame = NSRect(x: 0, y: 0, width: 30, height: 30)
        tray.view = button
        guard CQAddTrayItem(tray) else {
            barProblemKey = "touch_bar_tray_failed"
            return
        }
        trayItem = tray
        _ = CQPresentTouchBar(touchBar, trayIdentifier.rawValue as NSString)
    }

    func touchBar(_ touchBar: NSTouchBar,
                  makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        guard identifier == quotaIdentifier else { return nil }
        let item = NSCustomTouchBarItem(identifier: quotaIdentifier)
        item.view = touchView
        return item
    }

    @objc private func showTouchBar() {
        guard trayItem != nil else { return }
        _ = CQPresentTouchBar(touchBar, trayIdentifier.rawValue as NSString)
    }

    @objc private func refreshAction() { refresh() }
    @objc private func quitAction() { NSApp.terminate(nil) }

    @objc private func changeLanguage(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let language = AppLanguage(rawValue: raw) else { return }
        L10n.select(language)
        localizeMenu()
        updateDisplay()
        touchView.needsDisplay = true
    }

    @objc private func chooseCodex() {
        let panel = NSOpenPanel()
        panel.message = L10n.text("choose_codex")
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.treatsFilePackagesAsDirectories = true
        NSApp.activate(ignoringOtherApps: true)
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            let path = url.pathExtension == "app"
                ? url.appendingPathComponent("Contents/Resources/codex").path
                : url.path
            UserDefaults.standard.set(path, forKey: "codexExecutablePath")
            self?.localizeMenu()
            self?.refresh()
        }
    }

    @objc private func findCodexAutomatically() {
        UserDefaults.standard.removeObject(forKey: "codexExecutablePath")
        localizeMenu()
        refresh()
    }

    @objc private func toggleLogin() {
        guard #available(macOS 13.0, *) else { return }
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
            updateLoginItem()
        } catch {
            let alert = NSAlert()
            alert.messageText = L10n.format("login_error", error.localizedDescription)
            alert.runModal()
        }
    }

    private func refresh() {
        if refreshing {
            refreshPending = true
            return
        }
        refreshing = true
        refreshItem.isEnabled = false
        statusLine.title = L10n.text(quota == nil ? "connecting" : "refreshing")
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let result = Result { try CodexClient.fetch() }
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.refreshing = false
                self.refreshItem.isEnabled = true
                switch result {
                case .success(let quota):
                    self.quota = quota
                    self.lastError = nil
                    self.touchView.quota = quota
                case .failure(let error):
                    self.lastError = error
                }
                self.updateDisplay()
                if self.refreshPending {
                    self.refreshPending = false
                    self.refresh()
                }
            }
        }
    }

    private func updateDisplay() {
        guard let quota = quota else {
            statusItem.button?.title = "—"
            planItem.title = L10n.format("plan", L10n.text("unknown_plan"))
            fiveHourItem.isHidden = true
            weeklyItem.isHidden = true
            statusLine.title = lastError?.localizedDescription ??
                L10n.text(refreshing ? "connecting" : "waiting")
            touchView.message = lastError?.localizedDescription
            return
        }

        planItem.title = L10n.format("plan", quota.planLabel)
        fiveHourItem.isHidden = !quota.showsFiveHour
        weeklyItem.isHidden = !quota.showsWeekly
        fiveHourItem.title = L10n.format("five_hour_line", QuotaText.percent(quota.fiveHour),
                                         QuotaText.reset(quota.fiveHour, weekly: false))
        weeklyItem.title = L10n.format("weekly_line", QuotaText.percent(quota.weekly),
                                       QuotaText.reset(quota.weekly, weekly: true))
        let values = [
            quota.showsFiveHour ? quota.fiveHour.map { "5h \($0.roundedRemaining)%" } : nil,
            quota.showsWeekly ? quota.weekly.map { "\(L10n.text("week_short")) \($0.roundedRemaining)%" } : nil
        ].compactMap { $0 }
        statusItem.button?.title = values.isEmpty ? "—" : values.joined(separator: " · ")

        if let lastError = lastError {
            statusLine.title = L10n.format("last_error", lastError.localizedDescription)
        } else if refreshing {
            statusLine.title = L10n.text("refreshing")
        } else {
            let formatter = DateFormatter()
            formatter.locale = L10n.locale
            formatter.dateFormat = "M/d HH:mm:ss"
            statusLine.title = L10n.format("updated_at", formatter.string(from: quota.fetchedAt))
        }
        touchView.message = nil
        touchView.needsDisplay = true
    }

    private static func makeStatusIcon() -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18))
        image.lockFocus()
        NSColor.black.setStroke()
        let ring = NSBezierPath(ovalIn: NSRect(x: 2.5, y: 3.5, width: 11, height: 11))
        ring.lineWidth = 2
        ring.stroke()
        let tail = NSBezierPath()
        tail.move(to: NSPoint(x: 12, y: 5))
        tail.line(to: NSPoint(x: 16, y: 1))
        tail.lineWidth = 2
        tail.lineCapStyle = .round
        tail.stroke()
        image.unlockFocus()
        image.isTemplate = true
        return image
    }
}
