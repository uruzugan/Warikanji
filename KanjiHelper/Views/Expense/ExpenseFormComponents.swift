import SwiftUI

struct ExpenseFormHero: View {
    @EnvironmentObject private var profileStore: ProfileStore

    let title: String
    let amount: Int
    let category: ExpenseCategory
    let currency: AppCurrency

    private var language: AppLanguage { profileStore.activeLanguage }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: category.symbolName)
                .font(.title2.bold())
                .frame(width: 54, height: 54)
                .background(.white.opacity(0.18))
                .clipShape(RoundedRectangle(cornerRadius: 17))

            VStack(alignment: .leading, spacing: 4) {
                Text(displayTitle)
                    .font(.headline)
                    .lineLimit(1)

                Text(amount > 0 ? currency.formatted(minorUnits: amount) : language.expenseFormText(.enterAmount))
                    .font(.subheadline)
                    .opacity(0.82)
            }

            Spacer()
        }
        .foregroundStyle(.white)
        .padding(18)
        .background(AppTheme.gradient)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private var displayTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? Expense.untitledName(for: language) : trimmed
    }
}

struct ExpenseInfoCard: View {
    @EnvironmentObject private var profileStore: ProfileStore

    @Binding var title: String
    @Binding var amountText: String
    @Binding var category: ExpenseCategory

    let currency: AppCurrency

    private var language: AppLanguage { profileStore.activeLanguage }
    private var amount: Int? { currency.minorUnits(from: amountText) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(language.expenseFormText(.expenseInfo), systemImage: "banknote.fill")
                .font(.headline)

            TextField(language.expenseFormText(.expenseNameOptional), text: $title)
                .inputStyle()

            HStack(spacing: 10) {
                Text(currency.symbol)
                    .font(.title2.bold())
                    .foregroundStyle(.secondary)

                TextField(currency.fractionDigits == 0 ? "0" : "0.00", text: $amountText)
                    .keyboardType(currency.fractionDigits == 0 ? .numberPad : .decimalPad)
                    .font(.title2.bold())
                    .multilineTextAlignment(.trailing)
            }
            .inputStyle()

            if let amount {
                HStack {
                    Text(language.expenseFormText(.enteredAmount))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text(currency.formatted(minorUnits: amount))
                        .font(.subheadline.bold().monospacedDigit())
                        .foregroundStyle(AppTheme.success)
                }
            } else if !amountText.isEmpty {
                Label(
                    language.expenseFormText(currency.fractionDigits == 0 ? .integerWarning : .decimalWarning),
                    systemImage: "exclamationmark.circle"
                )
                .font(.caption)
                .foregroundStyle(AppTheme.warning)
            }

            Picker(language.expenseFormText(.category), selection: $category) {
                ForEach(ExpenseCategory.allCases) { category in
                    Label(category.displayName(for: language), systemImage: category.symbolName)
                        .tag(category)
                }
            }
        }
        .appCard()
    }
}

struct ExpensePayerCard: View {
    @EnvironmentObject private var profileStore: ProfileStore

    let participants: [EventParticipant]
    @Binding var payerId: UUID?
    let names: [UUID: String]
    let onRoulette: () -> Void

    private var language: AppLanguage { profileStore.activeLanguage }

    init(
        participants: [EventParticipant],
        payerId: Binding<UUID?>,
        names: [UUID: String] = [:],
        onRoulette: @escaping () -> Void
    ) {
        self.participants = participants
        _payerId = payerId
        self.names = names
        self.onRoulette = onRoulette
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(language.expenseFormText(.payer), systemImage: "person.fill")
                .font(.headline)

            Picker(language.expenseFormText(.payer), selection: $payerId) {
                Text(language.expenseFormText(.choose))
                    .tag(UUID?.none)

                ForEach(Array(participants.enumerated()), id: \.element.id) { index, participant in
                    Text(displayName(participant, index: index))
                        .tag(UUID?.some(participant.id))
                }
            }
            .pickerStyle(.menu)
            .tint(AppTheme.primary)

            Button(action: onRoulette) {
                Label(language.expenseFormText(.roulette), systemImage: "die.face.5.fill")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(AppTheme.primary)
            .disabled(participants.isEmpty)
        }
        .appCard()
    }

    private func displayName(_ participant: EventParticipant, index: Int) -> String {
        let name = names[participant.id, default: participant.name]
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return name.isEmpty ? language.participantFallback(index + 1) : name
    }
}

struct ExpenseSplitMethodCard: View {
    @EnvironmentObject private var profileStore: ProfileStore

    let eventType: EventType?
    @Binding var splitMethod: SplitMethod

    private var language: AppLanguage { profileStore.activeLanguage }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(language.expenseFormText(.splitMethod), systemImage: "person.2.fill")
                .font(.headline)

            Picker(language.expenseFormText(.splitMethod), selection: $splitMethod) {
                ForEach(SplitMethod.allCases) { method in
                    Text(method.displayName(for: language))
                        .tag(method)
                }
            }
            .pickerStyle(.segmented)

            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .appCard()
    }

    private var description: String {
        splitMethod == .equal
            ? language.expenseFormText(.equalDescription)
            : eventType?.customSplitDescription(for: language) ?? language.expenseFormText(.customDescription)
    }
}

struct SettlementRoundingPicker: View {
    @EnvironmentObject private var profileStore: ProfileStore

    @Binding var rounding: SettlementRounding
    let currency: AppCurrency

    private var language: AppLanguage { profileStore.activeLanguage }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(language.expenseFormText(.collectionUnit), systemImage: "banknote.fill")
                .font(.headline)

            Picker(language.expenseFormText(.collectionUnit), selection: $rounding) {
                ForEach(SettlementRounding.allCases) { rounding in
                    Text(language.roundingTitle(rounding, currency: currency))
                        .tag(rounding)
                }
            }
            .pickerStyle(.menu)
            .tint(AppTheme.primary)

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(AppTheme.primary)

                Text(language.roundingDescription(rounding, currency: currency))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if rounding != .exact {
                Text(language.roundingAdjustment(currency: currency))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .appCard()
    }
}

fileprivate enum ExpenseFormText: Int {
    case enterAmount, expenseInfo, expenseNameOptional, enteredAmount
    case integerWarning, decimalWarning, category, payer, choose, roulette
    case splitMethod, equalDescription, customDescription, collectionUnit
}

private let expenseFormTexts: [[String]] = [
    ["金額を入力", "Enter amount", "输入金额", "輸入金額", "금액 입력", "Introduce el importe", "Digite o valor"],
    ["費用情報", "Expense Information", "费用信息", "費用資訊", "비용 정보", "Información del gasto", "Informações da despesa"],
    ["費用名（任意）", "Expense Name (Optional)", "费用名称（可选）", "費用名稱（選填）", "비용 이름 (선택)", "Nombre del gasto (opcional)", "Nome da despesa (opcional)"],
    ["入力金額", "Entered Amount", "输入金额", "輸入金額", "입력 금액", "Importe introducido", "Valor informado"],
    ["1以上の整数で入力してください", "Enter a whole number of 1 or more.", "请输入1以上的整数。", "請輸入1以上的整數。", "1 이상의 정수를 입력하세요.", "Introduce un número entero de 1 o más.", "Digite um número inteiro igual ou maior que 1."],
    ["0より大きい金額を小数第2位まで入力してください", "Enter an amount greater than 0 with up to 2 decimal places.", "请输入大于0且最多两位小数的金额。", "請輸入大於0且最多兩位小數的金額。", "0보다 큰 금액을 소수 둘째 자리까지 입력하세요.", "Introduce un importe mayor que 0 con hasta 2 decimales.", "Digite um valor maior que 0 com até 2 casas decimais."],
    ["カテゴリ", "Category", "类别", "類別", "카테고리", "Categoría", "Categoria"],
    ["支払者", "Payer", "付款人", "付款人", "결제자", "Pagador", "Pagador"],
    ["選択してください", "Select", "请选择", "請選擇", "선택하세요", "Seleccionar", "Selecionar"],
    ["会計ルーレットで決める", "Choose with Payer Roulette", "用付款轮盘决定", "用付款輪盤決定", "결제 룰렛으로 정하기", "Elegir con la ruleta", "Escolher com a roleta"],
    ["負担方法", "Split Method", "分摊方式", "分攤方式", "분담 방식", "Método de reparto", "Método de divisão"],
    ["参加者全員で均等に負担します。", "Split equally among all participants.", "由所有参与者平均分摊。", "由所有參加者平均分攤。", "모든 참가자가 균등하게 부담합니다.", "Se divide por igual entre todos.", "Divide igualmente entre todos."],
    ["参加者ごとに負担比率を調整できます。", "Adjust each participant's share.", "可以调整每位参与者的分摊比例。", "可以調整每位參加者的分攤比例。", "참가자별 부담 비율을 조정할 수 있습니다.", "Puedes ajustar la parte de cada persona.", "Você pode ajustar a parte de cada pessoa."],
    ["集金単位", "Collection Unit", "收款单位", "收款單位", "정산 단위", "Unidad de cobro", "Unidade de cobrança"]
]

extension AppLanguage {
    private var expenseFormIndex: Int {
        switch self {
        case .japanese: return 0
        case .english: return 1
        case .simplifiedChinese: return 2
        case .traditionalChinese: return 3
        case .korean: return 4
        case .spanish: return 5
        case .portuguese: return 6
        }
    }

    fileprivate func expenseFormText(_ key: ExpenseFormText) -> String {
        expenseFormTexts[key.rawValue][expenseFormIndex]
    }

    func participantFallback(_ number: Int) -> String {
        switch self {
        case .japanese: return "参加者\(number)"
        case .english: return "Participant \(number)"
        case .simplifiedChinese: return "参与者\(number)"
        case .traditionalChinese: return "參加者\(number)"
        case .korean: return "참가자 \(number)"
        case .spanish, .portuguese: return "Participante \(number)"
        }
    }

    func roundingTitle(_ rounding: SettlementRounding, currency: AppCurrency) -> String {
        let unit = currency.formatted(minorUnits: rounding == .exact ? 1 : rounding.rawValue)

        switch self {
        case .japanese: return rounding == .exact ? "\(unit)まで正確" : "\(unit)単位"
        case .english: return rounding == .exact ? "Exact to \(unit)" : "\(unit) increments"
        case .simplifiedChinese: return rounding == .exact ? "精确到 \(unit)" : "以 \(unit) 为单位"
        case .traditionalChinese: return rounding == .exact ? "精確到 \(unit)" : "以 \(unit) 為單位"
        case .korean: return rounding == .exact ? "\(unit) 단위까지 정확히" : "\(unit) 단위"
        case .spanish: return rounding == .exact ? "Exacto hasta \(unit)" : "Incrementos de \(unit)"
        case .portuguese: return rounding == .exact ? "Exato até \(unit)" : "Incrementos de \(unit)"
        }
    }

    func roundingDescription(_ rounding: SettlementRounding, currency: AppCurrency) -> String {
        let title = roundingTitle(rounding, currency: currency)

        if rounding == .exact {
            switch self {
            case .japanese: return "合計が一致するよう\(title)に計算します。"
            case .english: return "Calculates exactly so the total matches."
            case .simplifiedChinese: return "精确计算，使分摊总额与费用总额一致。"
            case .traditionalChinese: return "精確計算，使分攤總額與費用總額一致。"
            case .korean: return "합계가 일치하도록 정확하게 계산합니다."
            case .spanish: return "Calcula con precisión para que coincida el total."
            case .portuguese: return "Calcula com precisão para que o total corresponda."
            }
        }

        switch self {
        case .japanese: return "できるだけ\(title)のキリのよい金額に調整します。"
        case .english: return "Adjusts shares to convenient \(title.lowercased()) where possible."
        case .simplifiedChinese: return "尽量调整为\(title)的整齐金额。"
        case .traditionalChinese: return "盡量調整為\(title)的整齊金額。"
        case .korean: return "가능한 한 \(title)의 깔끔한 금액으로 조정합니다."
        case .spanish: return "Ajusta las partes a importes cómodos en \(title.lowercased()) cuando sea posible."
        case .portuguese: return "Ajusta as partes para valores convenientes em \(title.lowercased()) quando possível."
        }
    }

    func roundingAdjustment(currency: AppCurrency) -> String {
        let unit = currency.formatted(minorUnits: 1)

        switch self {
        case .japanese: return "合計額が選んだ単位で割り切れない場合、差額だけ\(unit)単位で調整されます。"
        case .english: return "If the total cannot be divided by the selected unit, the difference is adjusted in \(unit) increments."
        case .simplifiedChinese: return "如果总额无法按所选单位整除，差额将以\(unit)为最小单位进行调整。"
        case .traditionalChinese: return "如果總額無法按所選單位整除，差額將以\(unit)為最小單位進行調整。"
        case .korean: return "합계가 선택한 단위로 나누어지지 않으면 차액을 \(unit) 단위로 조정합니다."
        case .spanish: return "Si el total no puede dividirse por la unidad elegida, la diferencia se ajusta en incrementos de \(unit)."
        case .portuguese: return "Se o total não puder ser dividido pela unidade escolhida, a diferença será ajustada em incrementos de \(unit)."
        }
    }
}
