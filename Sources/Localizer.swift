import Foundation

enum AppLanguage: String, CaseIterable {
    case automatic = "system"
    case simplifiedChinese = "zh-Hans"
    case traditionalChinese = "zh-Hant"
    case english = "en"
}

enum L10n {
    private static let preferenceKey = "appLanguage"

    static var selection: AppLanguage {
        AppLanguage(rawValue: UserDefaults.standard.string(forKey: preferenceKey) ?? "system") ?? .automatic
    }

    static func select(_ language: AppLanguage) {
        UserDefaults.standard.set(language.rawValue, forKey: preferenceKey)
    }

    static var resolvedCode: String {
        switch selection {
        case .simplifiedChinese: return "zh-Hans"
        case .traditionalChinese: return "zh-Hant"
        case .english: return "en"
        case .automatic:
            let preferred = Locale.preferredLanguages.first?.lowercased() ?? "en"
            if preferred.hasPrefix("zh-hant") || preferred.hasPrefix("zh-tw") ||
                preferred.hasPrefix("zh-hk") || preferred.hasPrefix("zh-mo") {
                return "zh-Hant"
            }
            return preferred.hasPrefix("zh") ? "zh-Hans" : "en"
        }
    }

    static var locale: Locale { Locale(identifier: resolvedCode) }

    static func text(_ key: String) -> String {
        guard let path = Bundle.main.path(forResource: resolvedCode, ofType: "lproj"),
              let localized = Bundle(path: path) else { return key }
        return localized.localizedString(forKey: key, value: key, table: nil)
    }

    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: text(key), locale: locale, arguments: arguments)
    }
}
