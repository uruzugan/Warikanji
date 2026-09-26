import SwiftUI

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

    init(
        result: ReceiptOCRResult,
        currency: AppCurrency,
        onApply: @escaping (ReceiptOCRResult) -> Void
    ) {
        self.result = result
        self.currency = currency
        self.onApply = onApply
        _merchant = State(initialValue: result.merchant ?? "")
        _amountText = State(initialValue: result.amountMinorUnits.map(currency.inputText) ?? "")
        _hasDate = State(initialValue: result.date != nil)
        _date = State(initialValue: result.date ?? Date())
    }

    private var language: AppLanguage { profileStore.activeLanguage }
    private var amount: Int? { currency.minorUnits(from: amountText) }
    private var canApply: Bool {
        !merchant.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            amount != nil || hasDate
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    warningCard
                    resultCard
                    currencyCard
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
                    Text(text(
                        ja: "イベント通貨は\(currency.code)です。現在は費用ごとの通貨に未対応のため、金額は\(currency.code)として反映されます。必要なら修正してください。",
                        en: "The event uses \(currency.code). Per-expense currencies are not available yet, so the amount will be applied as \(currency.code). Edit it if needed.",
                        zhHans: "活动货币为\(currency.code)。目前尚不支持每笔费用使用不同货币，因此金额将按\(currency.code)应用，请按需修改。",
                        zhHant: "活動貨幣為\(currency.code)。目前尚不支援每筆費用使用不同貨幣，因此金額將以\(currency.code)套用，請視需要修改。",
                        ko: "이벤트 통화는 \(currency.code)입니다. 비용별 통화는 아직 지원되지 않아 금액이 \(currency.code)로 적용됩니다. 필요하면 수정하세요.",
                        es: "El evento usa \(currency.code). Aún no se admiten monedas por gasto, así que el importe se aplicará como \(currency.code). Edítalo si es necesario.",
                        pt: "O evento usa \(currency.code). Moedas por despesa ainda não são aceitas, então o valor será aplicado como \(currency.code). Edite se necessário."
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
            Text(result.recognizedText)
                .font(.caption.monospaced())
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
        } label: {
            Label(text(
                ja: "認識した全文", en: "Recognized Text",
                zhHans: "识别的全文", zhHant: "辨識的全文",
                ko: "인식된 전체 텍스트", es: "Texto reconocido", pt: "Texto reconhecido"
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
