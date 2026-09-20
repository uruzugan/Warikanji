import SwiftUI

struct EventCurrencyCard: View {
    @Binding var currency: AppCurrency

    let language: AppLanguage
    var isLocked = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                EventSectionTitle(
                    title: language.text(
                        ja: "イベント通貨",
                        en: "Event Currency",
                        zhHans: "活动货币",
                        zhHant: "活動貨幣",
                        ko: "이벤트 통화",
                        es: "Moneda del evento",
                        pt: "Moeda do evento"
                    ),
                    symbol: "banknote.fill"
                )

                Spacer()

                Text(currency.code)
                    .font(.caption.bold().monospaced())
                    .foregroundStyle(AppTheme.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(AppTheme.primary.opacity(0.1))
                    .clipShape(Capsule())
            }

            Picker("", selection: $currency) {
                ForEach(AppCurrency.allCases) { item in
                    Text(item.pickerTitle(for: language))
                        .tag(item)
                }
            }
            .labelsHidden()
            .frame(maxWidth: .infinity, alignment: .leading)
            .inputStyle()
            .disabled(isLocked)

            if isLocked {
                Label(
                    language.text(
                        ja: "費用が登録済みのため、通貨は変更できません。",
                        en: "Currency cannot be changed after expenses are added.",
                        zhHans: "已有费用记录，因此无法更改货币。",
                        zhHant: "已有費用紀錄，因此無法更改貨幣。",
                        ko: "비용이 등록되어 있어 통화를 변경할 수 없습니다.",
                        es: "No puedes cambiar la moneda después de añadir gastos.",
                        pt: "A moeda não pode ser alterada após adicionar despesas."
                    ),
                    systemImage: "lock.fill"
                )
                .font(.caption)
                .foregroundStyle(AppTheme.warning)
            } else {
                Text(
                    language.text(
                        ja: "このイベントの費用・精算・支払いで使う通貨です。",
                        en: "This currency will be used for expenses and settlements.",
                        zhHans: "此货币将用于本活动的费用、结算和付款。",
                        zhHant: "此貨幣將用於本活動的費用、結算和付款。",
                        ko: "이 통화는 이벤트의 비용, 정산 및 결제에 사용됩니다.",
                        es: "Esta moneda se usará para gastos y liquidaciones.",
                        pt: "Esta moeda será usada para despesas e acertos."
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .appCard()
    }
}
