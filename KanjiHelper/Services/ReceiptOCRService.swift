import Foundation
import Vision

struct ReceiptOCRResult: Identifiable, Sendable {
    let id: UUID
    var merchant: String?
    var amountMinorUnits: Int?
    var date: Date?
    var detectedCurrency: AppCurrency?
    let recognizedText: String

    nonisolated init(
        id: UUID = UUID(),
        merchant: String?,
        amountMinorUnits: Int?,
        date: Date?,
        detectedCurrency: AppCurrency?,
        recognizedText: String
    ) {
        self.id = id
        self.merchant = merchant
        self.amountMinorUnits = amountMinorUnits
        self.date = date
        self.detectedCurrency = detectedCurrency
        self.recognizedText = recognizedText
    }
}

enum ReceiptOCRError: Error {
    case noText
}

enum ReceiptOCRService {
    nonisolated static func recognize(
        imageData: Data,
        inputCurrency: AppCurrency
    ) throws -> ReceiptOCRResult {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.automaticallyDetectsLanguage = true
        request.recognitionLanguages = [
            "ja-JP", "en-US", "zh-Hans", "zh-Hant", "ko-KR", "es-ES", "pt-BR"
        ]

        try VNImageRequestHandler(data: imageData).perform([request])

        let observations = (request.results ?? []).sorted { left, right in
            let verticalGap = abs(left.boundingBox.maxY - right.boundingBox.maxY)
            return verticalGap > 0.02
                ? left.boundingBox.maxY > right.boundingBox.maxY
                : left.boundingBox.minX < right.boundingBox.minX
        }
        let lines = observations.compactMap { $0.topCandidates(1).first?.string }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !lines.isEmpty else { throw ReceiptOCRError.noText }

        let text = lines.joined(separator: "\n")
        let detectedCurrency = detectCurrency(in: text, fallback: inputCurrency)
        let amountCurrency = detectedCurrency ?? inputCurrency

        return ReceiptOCRResult(
            merchant: detectMerchant(in: lines),
            amountMinorUnits: detectAmount(in: lines, currency: amountCurrency),
            date: detectDate(in: text),
            detectedCurrency: detectedCurrency,
            recognizedText: text
        )
    }

    nonisolated private static func detectMerchant(in lines: [String]) -> String? {
        let ignored = [
            "RECEIPT", "領収", "レシート", "TOTAL", "合計", "합계", "총액",
            "TEL", "PHONE", "電話", "THANK", "ありがとう", "GRACIAS", "OBRIGADO"
        ]

        return lines.prefix(8).first { line in
            let upper = line.uppercased()
            let digitCount = line.filter(\.isNumber).count
            let hasLetter = line.unicodeScalars.contains {
                CharacterSet.letters.contains($0)
            }
            return hasLetter && digitCount * 2 < line.count &&
                !ignored.contains(where: upper.contains)
        }
    }

    nonisolated private static func detectAmount(
        in lines: [String],
        currency: AppCurrency
    ) -> Int? {
        let totalWords = [
            "TOTAL", "GRAND TOTAL", "AMOUNT DUE", "BALANCE DUE", "合計", "総額", "お会計",
            "支払額", "合计", "总计", "金额合计", "總計", "金額合計", "합계", "총액", "A PAGAR"
        ]
        let subtotalWords = ["SUBTOTAL", "小計", "商品小计", "商品小計"]
        let excludedWords = [
            "TAX", "税", "CHANGE", "お釣り", "釣銭", "找零",
            "TEL", "PHONE", "電話", "电话", "FAX", "热线", "熱線",
            "CASHIER", "收银员", "收銀員", "店員", "收据员", "收據員"
        ]
        let currencyMarks = ["¥", "￥", "$", "€", "£", "₩", "฿", currency.code]
        let datePattern = #"\d{1,4}[./\-年]\d{1,2}[./\-月]\d{1,4}"#
        var candidates: [(score: Int, amount: Int)] = []

        for (index, line) in lines.enumerated() {
            let upper = line.uppercased()
            let isTotal = totalWords.contains(where: upper.contains)
            let isSubtotal = subtotalWords.contains(where: upper.contains)
            let previous = index > 0 ? lines[index - 1].uppercased() : ""
            let followsTotal = totalWords.contains(where: previous.contains)
            let followsSubtotal = subtotalWords.contains(where: previous.contains)
            let looksLikeDate = line.range(of: datePattern, options: .regularExpression) != nil
            let isExcluded = excludedWords.contains(where: upper.contains)
            if !isTotal && !isSubtotal && (looksLikeDate || isExcluded) { continue }

            var score = isTotal || followsTotal ? 120 : 0
            if isSubtotal || followsSubtotal { score = max(score, 80) }
            if currencyMarks.contains(where: upper.contains) { score += 25 }
            score += min(index, 10)

            for candidate in numbers(in: line, currency: currency) {
                let digitCount = candidate.token.filter(\.isNumber).count
                let adjustedScore = digitCount >= 7 ? score - 100 : score
                candidates.append((adjustedScore, candidate.amount))
            }
        }

        return candidates.max {
            $0.score == $1.score ? $0.amount < $1.amount : $0.score < $1.score
        }?.amount
    }

    nonisolated private static func numbers(
        in line: String,
        currency: AppCurrency
    ) -> [(token: String, amount: Int)] {
        let pattern = #"\d+(?:[.,]\d+)*"#
        guard let expression = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(line.startIndex..., in: line)

        return expression.matches(in: line, range: range).compactMap { match in
            guard let range = Range(match.range, in: line) else { return nil }
            let token = String(line[range]).trimmingCharacters(in: .whitespaces)
            guard let amount = currency.minorUnits(from: token) else { return nil }
            return (token, amount)
        }
    }

    nonisolated private static func detectDate(in text: String) -> Date? {
        if let detector = try? NSDataDetector(
            types: NSTextCheckingResult.CheckingType.date.rawValue
        ) {
            let range = NSRange(text.startIndex..., in: text)
            if let date = detector.firstMatch(in: text, range: range)?.date,
               isReasonable(date) {
                return date
            }
        }

        let patterns = [
            "yyyy/MM/dd", "yyyy-MM-dd", "yyyy.MM.dd", "yyyy年M月d日",
            "dd/MM/yyyy", "dd-MM-yyyy", "dd.MM.yyyy",
            "MM/dd/yyyy", "MM-dd-yyyy", "MM.dd.yyyy"
        ]

        for pattern in patterns {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = pattern
            formatter.isLenient = false

            let regex = dateRegex(for: pattern)
            guard let range = text.range(of: regex, options: .regularExpression),
                  let date = formatter.date(from: String(text[range])),
                  isReasonable(date) else { continue }
            return date
        }

        return nil
    }

    nonisolated private static func dateRegex(for pattern: String) -> String {
        switch pattern {
        case "yyyy年M月d日": return #"\d{4}年\d{1,2}月\d{1,2}日"#
        case _ where pattern.hasPrefix("yyyy"):
            let separator = String(pattern.dropFirst(4).first ?? "/")
            return #"\d{4}"# + NSRegularExpression.escapedPattern(for: separator) +
                #"\d{1,2}"# + NSRegularExpression.escapedPattern(for: separator) + #"\d{1,2}"#
        default:
            let separator = String(pattern.dropFirst(2).first ?? "/")
            return #"\d{1,2}"# + NSRegularExpression.escapedPattern(for: separator) +
                #"\d{1,2}"# + NSRegularExpression.escapedPattern(for: separator) + #"\d{4}"#
        }
    }

    nonisolated private static func isReasonable(_ date: Date) -> Bool {
        let year = Calendar(identifier: .gregorian).component(.year, from: date)
        let nextYear = Calendar(identifier: .gregorian).component(.year, from: Date()) + 1
        return (2000...nextYear).contains(year)
    }

    nonisolated private static func detectCurrency(
        in text: String,
        fallback: AppCurrency
    ) -> AppCurrency? {
        let upper = text.uppercased()
        let markers: [(AppCurrency, [String])] = [
            (.brl, ["BRL", "R$"]), (.mxn, ["MXN", "MX$"]),
            (.cad, ["CAD", "CA$"]), (.aud, ["AUD", "A$"]),
            (.usd, ["USD", "US$"]), (.sgd, ["SGD", "S$"]),
            (.hkd, ["HKD", "HK$"]),
            (.mop, ["MOP", "MOP$"]), (.twd, ["TWD", "NT$"]),
            (.cny, ["CNY", "RMB", "人民币", "人民幣"]),
            (.jpy, ["JPY", "日本円", "円", "日元", "日圓"]),
            (.krw, ["KRW", "₩", "원"]), (.eur, ["EUR", "€"]),
            (.gbp, ["GBP", "£"]), (.thb, ["THB", "฿"])
        ]

        if let currency = markers.first(where: { entry in
            entry.1.contains(where: upper.contains)
        })?.0 {
            return currency
        }

        let mainlandChinaMarkers = [
            ".COM.CN", "商品小计", "金额合计", "收银员", "找零", "服务热线"
        ]
        if mainlandChinaMarkers.filter({ upper.contains($0) }).count >= 2 {
            return .cny
        }

        if upper.contains("¥") || upper.contains("￥") {
            return [.jpy, .cny].contains(fallback) ? fallback : .jpy
        }

        if upper.contains("$") {
            let dollars: [AppCurrency] = [.usd, .hkd, .sgd, .aud, .cad, .brl, .mxn]
            return dollars.contains(fallback) ? fallback : .usd
        }

        return nil
    }
}
