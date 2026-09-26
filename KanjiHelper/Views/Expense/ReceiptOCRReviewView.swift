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
    @State private var eventConvertedAmount: Int?
    @State private var referenceAmount: Int?
    @State private var isConvertingEvent = false
    @State private var isConvertingReference = false
    @State private var eventConversionFailed = false
    @State private var referenceConversionFailed = false

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
    private var referenceCurrency: AppCurrency { profileStore.activeReferenceCurrency }
    private var sourceCurrency: AppCurrency { result.detectedCurrency ?? currency }
    private var amount: Int? { currency.minorUnits(from: amountText) }
    private var targetLanguage: Locale.Language {
        Locale.Language(identifier: language.localeIdentifier)
    }
    private var canApply: Bool {
        !isConvertingEvent && (
            !merchant.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                amount != nil || hasDate
        )
    }
    private var conversionKey: String {
        "\(sourceCurrency.code)-\(currency.code)-\(referenceCurrency.code)-\(result.amountMinorUnits ?? 0)"
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
        .task(id: conversionKey) {
            await loadConvertedAmounts()
        }
    }

    private var warningCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(AppTheme.warning)

            Text(text(
                ja: "読み取り結果と参考換算額は誤る場合があります。費用へ反映する前に金額と通貨を確認してください。",
                en: "Scan results and estimated conversions may be inaccurate. Check the amount and currency before applying them.",
                zhHans: "识别结果和参考换算金额可能有误。应用前请确认金额和货币。",
                zhHant: "辨識結果和參考換算金額可能有誤。套用前請確認金額和貨幣。",
                ko: "인식 결과와 참고 환산액은 틀릴 수 있습니다. 적용하기 전에 금액과 통화를 확인하세요.",
                es: "La lectura y la conversión estimada pueden contener errores. Comprueba el importe y la moneda.",
                pt: "A leitura e a conversão estimada podem conter erros. Confira o valor e a moeda."
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
        if let scannedAmount = result.amountMinorUnits {
            VStack(alignment: .leading, spacing: 12) {
                Label(text(
                    ja: "金額と参考換算", en: "Amount & Estimate",
                    zhHans: "金额与参考换算", zhHant: "金額與參考換算",
                    ko: "금액 및 참고 환산", es: "Importe y conversión", pt: "Valor e conversão"
                ), systemImage: "arrow.left.arrow.right")
                .font(.headline)

                amountRow(
                    label: text(
                        ja: "現地金額", en: "Local amount",
                        zhHans: "当地金额", zhHant: "當地金額",
                        ko: "현지 금액", es: "Importe local", pt: "Valor local"
                    ),
                    value: "\(sourceCurrency.code)  \(sourceCurrency.formatted(minorUnits: scannedAmount))"
                )

                referenceAmountRow

                if sourceCurrency != currency && currency != referenceCurrency {
                    eventAmountRow
                }

                Text(text(
                    ja: "換算額は最新の取得レートによる目安です。イベント通貨（\(currency.code)）の金額欄へ自動入力します。",
                    en: "The conversion is an estimate based on the latest available rate. It is filled into the event currency (\(currency.code)) automatically.",
                    zhHans: "换算金额仅供参考，并会自动填写为活动货币（\(currency.code)）。",
                    zhHant: "換算金額僅供參考，並會自動填入活動貨幣（\(currency.code)）。",
                    ko: "환산액은 참고값이며 이벤트 통화(\(currency.code)) 금액란에 자동 입력됩니다.",
                    es: "La conversión es orientativa y se introduce automáticamente en la moneda del evento (\(currency.code)).",
                    pt: "A conversão é uma estimativa e é preenchida automaticamente na moeda do evento (\(currency.code))."
                ))
                .font(.caption)
                .foregroundStyle(.secondary)

                if sourceCurrency != currency || sourceCurrency != referenceCurrency {
                    Link(
                        "Rates By Exchange Rate API",
                        destination: URL(string: "https://www.exchangerate-api.com")!
                    )
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .appCard()
        }
    }

    private func amountRow(label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .monospacedDigit()
        }
        .font(.subheadline)
    }

    @ViewBuilder
    private var referenceAmountRow: some View {
        if isConvertingReference {
            conversionProgressRow(label: text(
                ja: "参考換算額", en: "Reference estimate",
                zhHans: "参考换算金额", zhHant: "參考換算金額",
                ko: "참고 환산액", es: "Conversión de referencia", pt: "Conversão de referência"
            ))
        } else if let referenceAmount {
            amountRow(
                label: text(
                    ja: "参考換算額", en: "Reference estimate",
                    zhHans: "参考换算金额", zhHant: "參考換算金額",
                    ko: "참고 환산액", es: "Conversión de referencia", pt: "Conversão de referência"
                ),
                value: "≈ \(referenceCurrency.code)  \(referenceCurrency.formatted(minorUnits: referenceAmount))"
            )
        } else if referenceConversionFailed {
            conversionFailureRow { Task { await loadConvertedAmounts() } }
        }
    }

    @ViewBuilder
    private var eventAmountRow: some View {
        if isConvertingEvent {
            conversionProgressRow(label: text(
                ja: "イベント通貨", en: "Event currency",
                zhHans: "活动货币", zhHant: "活動貨幣",
                ko: "이벤트 통화", es: "Moneda del evento", pt: "Moeda do evento"
            ))
        } else if let eventConvertedAmount {
            amountRow(
                label: text(
                    ja: "イベント通貨", en: "Event currency",
                    zhHans: "活动货币", zhHant: "活動貨幣",
                    ko: "이벤트 통화", es: "Moneda del evento", pt: "Moeda do evento"
                ),
                value: "≈ \(currency.code)  \(currency.formatted(minorUnits: eventConvertedAmount))"
            )
        } else if eventConversionFailed {
            conversionFailureRow { Task { await loadConvertedAmounts() } }
        }
    }

    private func conversionProgressRow(label: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            ProgressView()
                .controlSize(.small)
            Text(text(
                ja: "換算中…", en: "Converting…",
                zhHans: "换算中…", zhHant: "換算中…",
                ko: "환산 중…", es: "Convirtiendo…", pt: "Convertendo…"
            ))
            .foregroundStyle(.secondary)
        }
        .font(.subheadline)
    }

    private func conversionFailureRow(retry: @escaping () -> Void) -> some View {
        HStack {
            Text(text(
                ja: "換算できませんでした", en: "Conversion unavailable",
                zhHans: "无法换算", zhHant: "無法換算",
                ko: "환산할 수 없음", es: "Conversión no disponible", pt: "Conversão indisponível"
            ))
            .font(.caption)
            .foregroundStyle(.secondary)

            Spacer()

            Button(action: retry) {
                Label(text(
                    ja: "再試行", en: "Retry",
                    zhHans: "重试", zhHant: "重試",
                    ko: "다시 시도", es: "Reintentar", pt: "Tentar novamente"
                ), systemImage: "arrow.clockwise")
                .font(.caption.bold())
            }
            .buttonStyle(.borderless)
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

    @MainActor
    private func loadConvertedAmounts() async {
        guard let scannedAmount = result.amountMinorUnits else { return }

        eventConvertedAmount = nil
        referenceAmount = nil
        eventConversionFailed = false
        referenceConversionFailed = false
        isConvertingEvent = sourceCurrency != currency
        isConvertingReference = sourceCurrency != referenceCurrency

        if sourceCurrency == currency {
            eventConvertedAmount = scannedAmount
            if amountText.isEmpty {
                amountText = currency.inputText(minorUnits: scannedAmount)
            }
        } else {
            do {
                let converted = try await ExchangeRateService.shared.convert(
                    minorUnits: scannedAmount,
                    from: sourceCurrency,
                    to: currency
                )
                eventConvertedAmount = converted
                if amountText.isEmpty {
                    amountText = currency.inputText(minorUnits: converted)
                }
            } catch {
                eventConversionFailed = true
            }
            isConvertingEvent = false
        }

        if sourceCurrency == referenceCurrency {
            referenceAmount = scannedAmount
        } else if referenceCurrency == currency {
            referenceAmount = eventConvertedAmount
            referenceConversionFailed = eventConversionFailed
        } else {
            do {
                referenceAmount = try await ExchangeRateService.shared.convert(
                    minorUnits: scannedAmount,
                    from: sourceCurrency,
                    to: referenceCurrency
                )
            } catch {
                referenceConversionFailed = true
            }
        }
        isConvertingReference = false
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
