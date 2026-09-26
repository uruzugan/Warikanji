import Foundation

enum AppCurrency: String, Codable, CaseIterable, Identifiable, Sendable {
    case jpy = "JPY"
    case usd = "USD"
    case eur = "EUR"
    case gbp = "GBP"
    case krw = "KRW"
    case cny = "CNY"
    case twd = "TWD"
    case hkd = "HKD"
    case mop = "MOP"
    case thb = "THB"
    case sgd = "SGD"
    case aud = "AUD"
    case cad = "CAD"
    case brl = "BRL"
    case mxn = "MXN"

    var id: String { rawValue }
    var code: String { rawValue }

    var symbol: String {
        switch self {
        case .jpy: return "¥"
        case .usd: return "US$"
        case .eur: return "€"
        case .gbp: return "£"
        case .krw: return "₩"
        case .cny: return "CN¥"
        case .twd: return "NT$"
        case .hkd: return "HK$"
        case .mop: return "MOP$"
        case .thb: return "฿"
        case .sgd: return "S$"
        case .aud: return "A$"
        case .cad: return "CA$"
        case .brl: return "R$"
        case .mxn: return "MX$"
        }
    }

    var fractionDigits: Int {
        switch self {
        case .jpy, .krw: return 0
        default: return 2
        }
    }

    var minorUnitScale: Int {
        fractionDigits == 0 ? 1 : 100
    }

    func name(for language: AppLanguage) -> String {
        switch language {
        case .japanese:
            switch self {
            case .jpy: return "日本円"
            case .usd: return "米ドル"
            case .eur: return "ユーロ"
            case .gbp: return "英ポンド"
            case .krw: return "韓国ウォン"
            case .cny: return "中国人民元"
            case .twd: return "台湾ドル"
            case .hkd: return "香港ドル"
            case .mop: return "マカオ・パタカ"
            case .thb: return "タイバーツ"
            case .sgd: return "シンガポールドル"
            case .aud: return "豪ドル"
            case .cad: return "カナダドル"
            case .brl: return "ブラジルレアル"
            case .mxn: return "メキシコペソ"
            }

        case .english:
            switch self {
            case .jpy: return "Japanese Yen"
            case .usd: return "US Dollar"
            case .eur: return "Euro"
            case .gbp: return "British Pound"
            case .krw: return "South Korean Won"
            case .cny: return "Chinese Yuan"
            case .twd: return "New Taiwan Dollar"
            case .hkd: return "Hong Kong Dollar"
            case .mop: return "Macanese Pataca"
            case .thb: return "Thai Baht"
            case .sgd: return "Singapore Dollar"
            case .aud: return "Australian Dollar"
            case .cad: return "Canadian Dollar"
            case .brl: return "Brazilian Real"
            case .mxn: return "Mexican Peso"
            }

        case .simplifiedChinese:
            switch self {
            case .jpy: return "日元"
            case .usd: return "美元"
            case .eur: return "欧元"
            case .gbp: return "英镑"
            case .krw: return "韩元"
            case .cny: return "人民币"
            case .twd: return "新台币"
            case .hkd: return "港币"
            case .mop: return "澳门元"
            case .thb: return "泰铢"
            case .sgd: return "新加坡元"
            case .aud: return "澳元"
            case .cad: return "加拿大元"
            case .brl: return "巴西雷亚尔"
            case .mxn: return "墨西哥比索"
            }

        case .traditionalChinese:
            switch self {
            case .jpy: return "日圓"
            case .usd: return "美元"
            case .eur: return "歐元"
            case .gbp: return "英鎊"
            case .krw: return "韓元"
            case .cny: return "人民幣"
            case .twd: return "新臺幣"
            case .hkd: return "港幣"
            case .mop: return "澳門元"
            case .thb: return "泰銖"
            case .sgd: return "新加坡元"
            case .aud: return "澳元"
            case .cad: return "加拿大元"
            case .brl: return "巴西雷亞爾"
            case .mxn: return "墨西哥披索"
            }

        case .korean:
            switch self {
            case .jpy: return "일본 엔"
            case .usd: return "미국 달러"
            case .eur: return "유로"
            case .gbp: return "영국 파운드"
            case .krw: return "대한민국 원"
            case .cny: return "중국 위안"
            case .twd: return "신 타이완 달러"
            case .hkd: return "홍콩 달러"
            case .mop: return "마카오 파타카"
            case .thb: return "태국 바트"
            case .sgd: return "싱가포르 달러"
            case .aud: return "호주 달러"
            case .cad: return "캐나다 달러"
            case .brl: return "브라질 헤알"
            case .mxn: return "멕시코 페소"
            }

        case .spanish:
            switch self {
            case .jpy: return "Yen japonés"
            case .usd: return "Dólar estadounidense"
            case .eur: return "Euro"
            case .gbp: return "Libra esterlina"
            case .krw: return "Won surcoreano"
            case .cny: return "Yuan chino"
            case .twd: return "Nuevo dólar taiwanés"
            case .hkd: return "Dólar de Hong Kong"
            case .mop: return "Pataca de Macao"
            case .thb: return "Baht tailandés"
            case .sgd: return "Dólar de Singapur"
            case .aud: return "Dólar australiano"
            case .cad: return "Dólar canadiense"
            case .brl: return "Real brasileño"
            case .mxn: return "Peso mexicano"
            }

        case .portuguese:
            switch self {
            case .jpy: return "Iene japonês"
            case .usd: return "Dólar americano"
            case .eur: return "Euro"
            case .gbp: return "Libra esterlina"
            case .krw: return "Won sul-coreano"
            case .cny: return "Yuan chinês"
            case .twd: return "Novo dólar taiwanês"
            case .hkd: return "Dólar de Hong Kong"
            case .mop: return "Pataca de Macau"
            case .thb: return "Baht tailandês"
            case .sgd: return "Dólar de Singapura"
            case .aud: return "Dólar australiano"
            case .cad: return "Dólar canadense"
            case .brl: return "Real brasileiro"
            case .mxn: return "Peso mexicano"
            }
        }
    }

    func pickerTitle(for language: AppLanguage) -> String {
        "\(code)  \(name(for: language))  \(symbol)"
    }

    func formatted(minorUnits: Int) -> String {
        let value = Decimal(minorUnits) / Decimal(minorUnitScale)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = .autoupdatingCurrent
        formatter.usesGroupingSeparator = true
        formatter.minimumFractionDigits = fractionDigits
        formatter.maximumFractionDigits = fractionDigits

        let text = formatter.string(from: NSDecimalNumber(decimal: value))
            ?? NSDecimalNumber(decimal: value).stringValue

        return "\(symbol)\(text)"
    }

    func inputText(minorUnits: Int) -> String {
        if fractionDigits == 0 { return String(minorUnits) }

        let value = Decimal(minorUnits) / Decimal(minorUnitScale)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = .autoupdatingCurrent
        formatter.usesGroupingSeparator = false
        formatter.minimumFractionDigits = fractionDigits
        formatter.maximumFractionDigits = fractionDigits

        return formatter.string(from: NSDecimalNumber(decimal: value))
            ?? NSDecimalNumber(decimal: value).stringValue
    }

    func minorUnits(from input: String) -> Int? {
        var text = input
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: symbol, with: "")
            .replacingOccurrences(of: code, with: "", options: .caseInsensitive)

        guard !text.isEmpty else { return nil }

        let dots = text.filter { $0 == "." }.count
        let commas = text.filter { $0 == "," }.count

        if dots > 0 && commas > 0 {
            let lastDot = text.lastIndex(of: ".")!
            let lastComma = text.lastIndex(of: ",")!

            if lastDot > lastComma {
                text = text.replacingOccurrences(of: ",", with: "")
            } else {
                text = text.replacingOccurrences(of: ".", with: "")
                text = text.replacingOccurrences(of: ",", with: ".")
            }
        } else if dots + commas > 0 {
            let separator: Character = dots > 0 ? "." : ","
            let count = dots > 0 ? dots : commas

            if count > 1 || fractionDigits == 0 {
                text.removeAll { $0 == separator }
            } else if let index = text.lastIndex(of: separator) {
                let digitsAfter = text.distance(
                    from: text.index(after: index),
                    to: text.endIndex
                )

                if digitsAfter > fractionDigits {
                    text.removeAll { $0 == separator }
                } else if separator == "," {
                    text = text.replacingOccurrences(of: ",", with: ".")
                }
            }
        }

        guard let value = Decimal(
            string: text,
            locale: Locale(identifier: "en_US_POSIX")
        ), value > 0 else {
            return nil
        }

        var scaled = value * Decimal(minorUnitScale)
        var rounded = Decimal()
        NSDecimalRound(&rounded, &scaled, 0, .plain)

        guard scaled == rounded else { return nil }

        let number = NSDecimalNumber(decimal: rounded)
        guard number != .notANumber else { return nil }

        let result = number.intValue
        return result > 0 ? result : nil
    }

    static func deviceDefault(
        for language: AppLanguage = .deviceDefault
    ) -> AppCurrency {
        if let code = Locale.current.currency?.identifier,
           let currency = AppCurrency(rawValue: code) {
            return currency
        }

        switch language {
        case .japanese: return .jpy
        case .korean: return .krw
        case .simplifiedChinese: return .cny
        case .traditionalChinese: return .twd
        case .spanish: return .mxn
        case .portuguese: return .brl
        case .english: return .usd
        }
    }
}
