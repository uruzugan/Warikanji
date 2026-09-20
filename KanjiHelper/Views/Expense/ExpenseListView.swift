import SwiftUI

struct ExpenseListView: View {
    @EnvironmentObject private var viewModel: EventViewModel
    @EnvironmentObject private var profileStore: ProfileStore
    @ObservedObject private var lifecycleStore = EventLifecycleStore.shared

    let eventId: UUID

    @State private var isShowingCreateSheet = false
    @State private var selectedExpense: Expense?

    private var event: Event? { viewModel.event(for: eventId) }
    private var language: AppLanguage { profileStore.activeLanguage }
    private var currency: AppCurrency { event?.currency ?? .jpy }
    private var expenses: [Expense] { event?.expenses ?? [] }
    private var totalAmount: Int { expenses.reduce(0) { $0 + $1.amount } }
    private var isLocked: Bool { lifecycleStore.isLocked(eventId) }
    private var usesDateGroups: Bool { event?.hasDatedExpenses ?? false }

    private var lockedText: String {
        language.text(
            ja: "精算確定済みのため、費用の追加・編集・削除はできません。",
            en: "Settlement is finalized. Expenses cannot be added, edited or deleted.",
            zhHans: "结算已确定，无法添加、编辑或删除费用。",
            zhHant: "結算已確定，無法新增、編輯或刪除費用。",
            ko: "정산이 확정되어 비용을 추가, 편집 또는 삭제할 수 없습니다.",
            es: "La liquidación está finalizada. No se pueden añadir, editar ni eliminar gastos.",
            pt: "O acerto está finalizado. Não é possível adicionar, editar ou excluir despesas."
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                summaryCard

                if isLocked {
                    Label(lockedText, systemImage: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(AppTheme.primary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                if expenses.isEmpty {
                    emptyStateCard
                } else if usesDateGroups {
                    groupedExpenseSection
                } else {
                    expenseSection
                }
            }
            .padding()
            .padding(.bottom, 30)
        }
        .background(AppTheme.background)
        .navigationTitle(language.expenseText(.title))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !isLocked {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { isShowingCreateSheet = true } label: {
                        Image(systemName: "plus")
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .frame(width: 34, height: 34)
                            .background(AppTheme.gradient)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .sheet(isPresented: $isShowingCreateSheet) {
            ExpenseCreateView(eventId: eventId)
                .environmentObject(viewModel)
                .environmentObject(profileStore)
        }
        .sheet(item: $selectedExpense) { expense in
            ExpenseEditView(eventId: eventId, expense: expense)
                .environmentObject(viewModel)
                .environmentObject(profileStore)
        }
        .tint(AppTheme.primary)
    }

    private var summaryCard: some View {
        HStack(spacing: 16) {
            Image(systemName: "banknote.fill")
                .font(.system(size: 25, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 58, height: 58)
                .background(.white.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(language.expenseText(.currentTotal))
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.75))

                Text(currency.formatted(minorUnits: totalAmount))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("\(language.expenseCount(expenses.count))・\(currency.code)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.75))
            }

            Spacer()
        }
        .padding(20)
        .background(AppTheme.gradient)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: AppTheme.primary.opacity(0.18), radius: 12, y: 6)
    }

    private var groupedExpenseSection: some View {
        VStack(spacing: 22) {
            if let event {
                ForEach(event.datedExpenseGroups) { group in
                    expenseGroup(
                        title: event.expenseGroupTitle(for: group.date, language: language),
                        symbol: "calendar",
                        expenses: group.expenses
                    )
                }

                if !event.undatedExpenses.isEmpty {
                    expenseGroup(
                        title: language.text(
                            ja: "日付なし", en: "No Date", zhHans: "无日期", zhHant: "無日期",
                            ko: "날짜 없음", es: "Sin fecha", pt: "Sem data"
                        ),
                        symbol: "calendar.badge.clock",
                        expenses: event.undatedExpenses
                    )
                }
            }
        }
    }

    private func expenseGroup(title: String, symbol: String, expenses: [Expense]) -> some View {
        let subtotal = expenses.reduce(0) { $0 + $1.amount }

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(title, systemImage: symbol)
                    .font(.headline)
                    .foregroundStyle(AppTheme.primary)

                Spacer()

                Text(currency.formatted(minorUnits: subtotal))
                    .font(.subheadline.bold())
                    .monospacedDigit()
            }

            ForEach(expenses) { expense in
                expenseButton(expense)
            }
        }
    }

    private var expenseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(language.expenseText(.registered)).font(.headline)
                Spacer()
                Text(language.expenseCount(expenses.count))
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }

            ForEach(expenses) { expense in
                expenseButton(expense)
            }
        }
    }

    private func expenseButton(_ expense: Expense) -> some View {
        Button {
            if !isLocked { selectedExpense = expense }
        } label: {
            ExpenseListCard(
                expense: expense,
                payerName: payerName(for: expense),
                currency: currency,
                language: language,
                isLocked: isLocked,
                showDate: !usesDateGroups
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            if !isLocked {
                Button(role: .destructive) {
                    delete(expense)
                } label: {
                    Label(language.expenseText(.delete), systemImage: "trash")
                }
            }
        }
    }

    private var emptyStateCard: some View {
        VStack(spacing: 18) {
            Image(systemName: "receipt")
                .font(.system(size: 37))
                .foregroundStyle(AppTheme.primary)
                .frame(width: 92, height: 92)
                .background(AppTheme.primary.opacity(0.1))
                .clipShape(Circle())

            VStack(spacing: 5) {
                Text(language.expenseText(.emptyTitle)).font(.headline)

                Text(language.expenseText(.emptyBody))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if !isLocked {
                Button { isShowingCreateSheet = true } label: {
                    Label(language.expenseText(.addFirst), systemImage: "plus")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppTheme.gradient)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
            }
        }
        .appCard()
    }

    private func payerName(for expense: Expense) -> String {
        guard let payerId = expense.payerId else { return language.expenseText(.notSet) }
        return event?.displayName(for: payerId, language: language) ?? language.expenseText(.unknownParticipant)
    }

    private func delete(_ expense: Expense) {
        guard !isLocked,
              let index = expenses.firstIndex(where: { $0.id == expense.id })
        else { return }

        ReceiptImageStorage.shared.delete(expense.receiptImages)
        viewModel.deleteExpenses(at: IndexSet(integer: index), from: eventId)
    }
}

private struct ExpenseListCard: View {
    let expense: Expense
    let payerName: String
    let currency: AppCurrency
    let language: AppLanguage
    let isLocked: Bool
    let showDate: Bool

    private var dateText: String? {
        guard showDate, let date = expense.date else { return nil }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language.localeIdentifier)

        if language == .japanese {
            formatter.dateFormat = "M月d日(E)"
        } else {
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
        }

        return formatter.string(from: date)
    }

    private var receiptText: String {
        let count = expense.receiptImages.count

        return language.text(
            ja: "レシート \(count)枚",
            en: "\(count) \(count == 1 ? "receipt" : "receipts")",
            zhHans: "\(count)张收据",
            zhHant: "\(count)張收據",
            ko: "영수증 \(count)장",
            es: "\(count) \(count == 1 ? "recibo" : "recibos")",
            pt: "\(count) \(count == 1 ? "recibo" : "recibos")"
        )
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: expense.category.symbolName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(AppTheme.success)
                .frame(width: 48, height: 48)
                .background(AppTheme.success.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(expense.title)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.primary)
                    }
                }

                Text("\(expense.category.displayName(for: language))・\(expense.splitMethod.displayName(for: language))")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 10) {
                    Label(language.payerText(payerName), systemImage: "person.fill")

                    if !expense.receiptImages.isEmpty {
                        Label(receiptText, systemImage: "paperclip")
                            .foregroundStyle(AppTheme.primary)
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)

                if let dateText {
                    Label(dateText, systemImage: "calendar")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.primary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text(currency.formatted(minorUnits: expense.amount))
                    .font(.headline)
                    .foregroundStyle(.primary)

                Image(systemName: isLocked ? "lock.fill" : "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(isLocked ? AppTheme.primary : Color.secondary.opacity(0.5))
            }
        }
        .appCard()
    }
}

private enum ExpenseListText: Int {
    case title, currentTotal, registered, delete, emptyTitle, emptyBody, addFirst, notSet, unknownParticipant
}

private let expenseListTexts: [[String]] = [
    ["費用管理", "Expenses", "费用管理", "費用管理", "비용 관리", "Gastos", "Despesas"],
    ["現在の費用合計", "Current Total", "当前费用总计", "目前費用總計", "현재 비용 합계", "Total actual", "Total atual"],
    ["登録済みの費用", "Added Expenses", "已添加的费用", "已新增的費用", "등록된 비용", "Gastos añadidos", "Despesas adicionadas"],
    ["削除", "Delete", "删除", "刪除", "삭제", "Eliminar", "Excluir"],
    ["費用がまだありません", "No expenses yet", "还没有费用", "尚無費用", "아직 비용이 없습니다", "Aún no hay gastos", "Ainda não há despesas"],
    ["食事代や交通費など、立て替えた費用を追加しましょう。", "Add expenses you paid for, such as meals or transport.", "添加餐饮费、交通费等已垫付的费用。", "新增餐飲費、交通費等已代墊的費用。", "식비나 교통비 등 대신 결제한 비용을 추가하세요.", "Añade gastos que hayas adelantado, como comida o transporte.", "Adicione despesas que você pagou, como alimentação ou transporte."],
    ["最初の費用を追加", "Add First Expense", "添加第一笔费用", "新增第一筆費用", "첫 비용 추가", "Añadir primer gasto", "Adicionar primeira despesa"],
    ["未設定", "Not Set", "未设置", "未設定", "미설정", "Sin definir", "Não definido"],
    ["不明な参加者", "Unknown Participant", "未知参与者", "未知參加者", "알 수 없는 참가자", "Participante desconocido", "Participante desconhecido"]
]

private extension AppLanguage {
    var expenseTextIndex: Int {
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

    func expenseText(_ key: ExpenseListText) -> String {
        expenseListTexts[key.rawValue][expenseTextIndex]
    }

    func expenseCount(_ count: Int) -> String {
        switch self {
        case .japanese: return "\(count)件"
        case .english: return "\(count) \(count == 1 ? "expense" : "expenses")"
        case .simplifiedChinese: return "\(count)笔"
        case .traditionalChinese: return "\(count)筆"
        case .korean: return "\(count)건"
        case .spanish: return "\(count) \(count == 1 ? "gasto" : "gastos")"
        case .portuguese: return "\(count) \(count == 1 ? "despesa" : "despesas")"
        }
    }

    func payerText(_ name: String) -> String {
        switch self {
        case .japanese: return "支払者：\(name)"
        case .english: return "Paid by \(name)"
        case .simplifiedChinese: return "付款人：\(name)"
        case .traditionalChinese: return "付款人：\(name)"
        case .korean: return "결제자: \(name)"
        case .spanish: return "Pagado por \(name)"
        case .portuguese: return "Pago por \(name)"
        }
    }
}
