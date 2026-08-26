import Foundation

enum L10n {
    static let key = "keyboarddrop.lang"
    static var isChinese: Bool = {
        let saved = UserDefaults.standard.string(forKey: key)
        if let s = saved { return s == "zh" }
        let preferred = Locale.preferredLanguages.first ?? "en"
        return preferred.hasPrefix("zh")
    }()

    static func toggle() {
        isChinese.toggle()
        UserDefaults.standard.set(isChinese ? "zh" : "en", forKey: key)
    }

    static func t(_ zh: String, _ en: String) -> String {
        isChinese ? zh : en
    }
}
