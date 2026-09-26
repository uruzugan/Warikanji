import SwiftUI
import Translation
import NaturalLanguage

struct ReceiptOCRReviewView: View {
    @EnvironmentObject private var profileStore: ProfileStore
    @Environment(\.dismiss) private var dismiss

    let result: ReceiptOCRResult
    let currency: AppCurrency
    let onApply: (ReceiptOCRResult) -> Void

    @State private var merchant: String
    @State private var amountText: String
    @State private var hasDate: Bool
    @State private var date: Date
    @State private var showsRecognizedText = false
    @State private var translatedText: String?
    @State private var isTranslating = true
    @State private var translationFailed = false

    init(
        result: ReceiptOCRResult,
        currency: AppCurrency,
        onApply: @escaping (ReceiptOCRResult) -> Void
    ) {
        self.result = result
        self.currency = currency
        self.onApply = onApply
        let hasCurrencyMismatch = result.detectedCurrency.map { $0 != currency } ?? false
        _merchant = State(initialValue: result.merchant ?? "")
        _amountText = State(
            initialValue: hasCurrencyMismatch
                ? ""
                : result.amountMinorUnits.map(currency.inputText) ?? ""
        )
        _hasDate = State(initialValue: result.date != nil)
        _date = State(initialValue: result.date ?? Date())
    }

    private var language: AppLanguage { profileStore.activeLanguage }
    private var amount: Int? { currency.minorUnits(from: amountText) }
    private var targetLanguage: Locale.Language {
        Locale.Language(identifier: language.localeIdentifier)
    }
    private var canApply: Bool {
        !merchant.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            amount != nil || hasDate
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    warningCard
                    currencyCard
                    resultCard
                    recognizedTextCard
                    applyButton
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .background(AppTheme.background)
            .navigationTitle(text(
                ja: "読み取り結果を確認", en: "Review Scan",
                zhHans: "确认识别结果", zhHant: "確認辨識結果",
                ko: "인식 결과 확인", es: "Revisar lectura", pt: "Revisar leitura"
            ))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(language.t(.cancel)) { dismiss() }
                }
            }
        }
        .tint(AppTheme.primary)
        .translationTask(source: nil, target: targetLanguage) { session in
            await translateRecognizedText(using: session)
        }
    }

    private var warningCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(AppTheme.warning)

            Text(text(
                ja: "写真から読み取った内容には誤りが含まれる場合があります。費用へ反映する前に必ず確認してください。",
                en: "Scanned information may contain errors. Always check it before applying it to the expense.",
                zhHans: "从照片识别的内容可能有误。应用到费用前请务必确认。",
                zhHant: "從照片辨識的內容可能有誤。套用到費用前請務必確認。",
                ko: "사진에서 인식한 내용에는 오류가 있을 수 있습니다. 비용에 적용하기 전에 반드시 확인하세요.",
                es: "La información leída puede contener errores. Revísala antes de aplicarla al gasto.",
                pt: "As informações lidas podem conter erros. Confira antes de aplicá-las à despesa."
            ))
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard()
    }

    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(text(
                ja: "読み取り内容", en: "Scanned Details",
                zhHans: "识别内容", zhHant: "辨識內容",
                ko: "인식 내용", es: "Datos leídos", pt: "Dados lidos"
            ), systemImage: "doc.text.viewfinder")
            .font(.headline)

            TextField(text(
                ja: "店名・費用名", en: "Merchant or Expense Name",
                zhHans: "店名或费用名称", zhHant: "店名或費用名稱",
                ko: "가게명 또는 비용명", es: "Comercio o gasto", pt: "Estabelecimento ou despesa"
            ), text: $merchant)
            .inputStyle()

            HStack(spacing: 10) {
                Text(currency.symbol)
                    .font(.title2.bold())
                    .foregroundStyle(.secondary)

                TextField(
                    currency.fractionDigits == 0 ? "0" : "0.00",
                    text: $amountText
                )
                .keyboardType(currency.fractionDigits == 0 ? .numberPad : .decimalPad)
                .font(.title2.bold())
                .multilineTextAlignment(.trailing)
            }
            .inputStyle()

            Toggle(text(
                ja: "日付を反映", en: "Apply Date",
                zhHans: "应用日期", zhHant: "套用日期",
                ko: "날짜 적용", es: "Aplicar fecha", pt: "Aplicar data"
            ), isOn: $hasDate)

            if hasDate {
                DatePicker("", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
            }
        }
        .appCard()
    }

    @ViewBuilder
    private var currencyCard: some View {
        if let detected = result.detectedCurrency {
            VStack(alignment: .leading, spacing: 8) {
                Label(
                    text(
                        ja: "検出した通貨：", en: "Detected currency: ",
                        zhHans: "检测到的货币：", zhHant: "偵測到的貨幣：",
                        ko: "감지된 통화: ", es: "Moneda detectada: ", pt: "Moeda detectada: "
                    ) + detected.code,
                    systemImage: "banknote"
                )
                .font(.subheadline.bold())

                if detected != currency {
                    if let scannedAmount = result.amountMinorUnits {
                        Text(text(
                            ja: "読み取った金額：\(detected.formatted(minorUnits: scannedAmount))",
                            en: "Scanned amount: \(detected.formatted(minorUnits: scannedAmount))",
                            zhHans: "识别金额：\(detected.formatted(minorUnits: scannedAmount))",
                            zhHant: "辨識金額：\(detected.formatted(minorUnits: scannedAmount))",
                            ko: "인식한 금액: \(detected.formatted(minorUnits: scannedAmount))",
                            es: "Importe leído: \(detected.formatted(minorUnits: scannedAmount))",
                            pt: "Valor lido: \(detected.formatted(minorUnits: scannedAmount))"
                        ))
                        .font(.subheadline.bold())
                    }

                    Text(text(
                        ja: "イベント通貨は\(currency.code)です。誤った通貨で保存しないよう、金額は自動入力していません。\(currency.code)への換算額を入力するか、イベント通貨を確認してください。",
                        en: "The event uses \(currency.code). To prevent saving the wrong currency, the amount was not filled in. Enter the converted \(currency.code) amount or check the event currency.",
                        zhHans: "活动货币为\(currency.code)。为避免以错误货币保存，金额未自动填写。请输入换算后的\(currency.code)金额，或检查活动货币。",
                        zhHant: "活動貨幣為\(currency.code)。為避免以錯誤貨幣儲存，金額未自動填入。請輸入換算後的\(currency.code)金額，或確認活動貨幣。",
                        ko: "이벤트 통화는 \(currency.code)입니다. 잘못된 통화로 저장하지 않도록 금액을 자동 입력하지 않았습니다. \(currency.code) 환산 금액을 입력하거나 이벤트 통화를 확인하세요.",
                        es: "El evento usa \(currency.code). Para evitar guardar una moneda incorrecta, el importe no se rellenó. Introduce el valor convertido a \(currency.code) o revisa la moneda del evento.",
                        pt: "O evento usa \(currency.code). Para evitar salvar na moeda errada, o valor não foi preenchido. Digite o valor convertido para \(currency.code) ou confira a moeda do evento."
                    ))
                    .font(.caption)
                    .foregroundStyle(AppTheme.warning)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .appCard()
        }
    }

    private var recognizedTextCard: some View {
        DisclosureGroup(isExpanded: $showsRecognizedText) {
            VStack(alignment: .leading, spacing: 10) {
                if isTranslating {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text(text(
                            ja: "翻訳中…", en: "Translating…",
                            zhHans: "正在翻译…", zhHant: "正在翻譯…",
                            ko: "번역 중…", es: "Traduciendo…", pt: "Traduzindo…"
                        ))
                    }
                } else if let translatedText {
                    Text(translatedText)
                        .textSelection(.enabled)

                    if translatedText != result.recognizedText {
                        Divider()
                        DisclosureGroup(text(
                            ja: "原文を表示", en: "Show Original",
                            zhHans: "显示原文", zhHant: "顯示原文",
                            ko: "원문 보기", es: "Mostrar original", pt: "Mostrar original"
                        )) {
                            Text(result.recognizedText)
                                .font(.caption.monospaced())
                                .textSelection(.enabled)
                                .padding(.top, 6)
                        }
                    }
                }

                if translationFailed {
                    Text(text(
                        ja: "翻訳できなかったため原文を表示しています。",
                        en: "The original text is shown because translation was unavailable.",
                        zhHans: "无法翻译，因此显示原文。", zhHant: "無法翻譯，因此顯示原文。",
                        ko: "번역할 수 없어 원문을 표시합니다.",
                        es: "Se muestra el original porque la traducción no está disponible.",
                        pt: "O original é exibido porque a tradução não está disponível."
                    ))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .font(.caption)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
        } label: {
            Label(text(
                ja: "認識した全文（翻訳）", en: "Recognized Text (Translated)",
                zhHans: "识别的全文（翻译）", zhHant: "辨識的全文（翻譯）",
                ko: "인식된 전체 텍스트 (번역)", es: "Texto reconocido (traducido)",
                pt: "Texto reconhecido (traduzido)"
            ), systemImage: "text.alignleft")
            .font(.headline)
        }
        .appCard()
    }

    private var applyButton: some View {
        Button(action: apply) {
            Label(text(
                ja: "費用へ反映", en: "Apply to Expense",
                zhHans: "应用到费用", zhHant: "套用到費用",
                ko: "비용에 적용", es: "Aplicar al gasto", pt: "Aplicar à despesa"
            ), systemImage: "checkmark")
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(AppTheme.gradient)
            .clipShape(RoundedRectangle(cornerRadius: 17))
        }
        .buttonStyle(.plain)
        .disabled(!canApply)
        .opacity(canApply ? 1 : 0.4)
        .padding(.bottom, 10)
    }

    private func apply() {
        let name = merchant.trimmingCharacters(in: .whitespacesAndNewlines)
        onApply(ReceiptOCRResult(
            id: result.id,
            merchant: name.isEmpty ? nil : name,
            amountMinorUnits: amount,
            date: hasDate ? date : nil,
            detectedCurrency: result.detectedCurrency,
            recognizedText: result.recognizedText
        ))
        dismiss()
    }

    private func translateRecognizedText(using session: TranslationSession) async {
        isTranslating = true
        translationFailed = false

        if recognizedLanguageMatchesAppLanguage {
            translatedText = result.recognizedText
            isTranslating = false
            return
        }

        do {
            translatedText = try await session.translate(result.recognizedText).targetText
        } catch {
            translatedText = result.recognizedText
            translationFailed = true
        }

        isTranslating = false
    }

    private var recognizedLanguageMatchesAppLanguage: Bool {
        guard let recognized = NLLanguageRecognizer.dominantLanguage(
            for: result.recognizedText
        )?.rawValue else { return false }

        switch language {
        case .simplifiedChinese:
            return recognized == "zh-Hans"
        case .traditionalChinese:
            return recognized == "zh-Hant"
        default:
            return recognized.split(separator: "-").first.map(String.init) == language.rawValue
        }
    }

    private func text(
        ja: String,
        en: String,
        zhHans: String,
        zhHant: String,
        ko: String,
        es: String,
        pt: String
    ) -> String {
        language.text(
            ja: ja, en: en, zhHans: zhHans, zhHant: zhHant,
            ko: ko, es: es, pt: pt
        )
    }
}
