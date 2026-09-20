import Foundation

enum AppLanguage: String, Codable, CaseIterable, Identifiable {
    case japanese = "ja"
    case english = "en"
    case simplifiedChinese = "zh-Hans"
    case traditionalChinese = "zh-Hant"
    case korean = "ko"
    case spanish = "es"
    case portuguese = "pt"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .japanese: return "日本語"
        case .english: return "English"
        case .simplifiedChinese: return "简体中文"
        case .traditionalChinese: return "繁體中文"
        case .korean: return "한국어"
        case .spanish: return "Español"
        case .portuguese: return "Português"
        }
    }

    var appName: String {
        switch self {
        case .japanese: return "ワリカンジ"
        default: return "Warikanji"
        }
    }

    var tagline: String {
        switch self {
        case .japanese:
            return "いい幹事、いい感じ。"
        case .english:
            return "Good organizer, good vibes."
        case .simplifiedChinese:
            return "轻松组织，开心相聚。"
        case .traditionalChinese:
            return "輕鬆組織，開心相聚。"
        case .korean:
            return "좋은 총무, 좋은 분위기."
        case .spanish:
            return "Organiza fácil, disfruta más."
        case .portuguese:
            return "Organize fácil, aproveite mais."
        }
    }

    var localeIdentifier: String {
        rawValue
    }

    func text(
        ja: String,
        en: String,
        zhHans: String,
        zhHant: String,
        ko: String,
        es: String,
        pt: String
    ) -> String {
        switch self {
        case .japanese: return ja
        case .english: return en
        case .simplifiedChinese: return zhHans
        case .traditionalChinese: return zhHant
        case .korean: return ko
        case .spanish: return es
        case .portuguese: return pt
        }
    }

    static var deviceDefault: AppLanguage {
        let preferred = Locale.preferredLanguages.first?.lowercased() ?? "en"

        if preferred.hasPrefix("ja") {
            return .japanese
        }

        if preferred.hasPrefix("zh-hans") ||
            preferred.hasPrefix("zh-cn") ||
            preferred.hasPrefix("zh-sg") {
            return .simplifiedChinese
        }

        if preferred.hasPrefix("zh-hant") ||
            preferred.hasPrefix("zh-tw") ||
            preferred.hasPrefix("zh-hk") ||
            preferred.hasPrefix("zh-mo") {
            return .traditionalChinese
        }

        if preferred.hasPrefix("ko") {
            return .korean
        }

        if preferred.hasPrefix("es") {
            return .spanish
        }

        if preferred.hasPrefix("pt") {
            return .portuguese
        }

        return .english
    }
}
