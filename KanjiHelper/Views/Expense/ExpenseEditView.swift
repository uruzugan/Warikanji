import SwiftUI

struct ExpenseEditView: View {
    @EnvironmentObject private var viewModel: EventViewModel
    @EnvironmentObject private var profileStore: ProfileStore
    @Environment(\.dismiss) private var dismiss

    let eventId: UUID
    let expense: Expense

    @State private var title: String
    @State private var amountText = ""
    @State private var category: ExpenseCategory
    @State private var payerId: UUID?
    @State private var rounding: SettlementRounding
    @State private var receiptImageData: [Data] = []
    @State private var hasExpenseDate: Bool
    @State private var expenseDate: Date
    @State private var showRoulette = false
    @State private var showDeleteConfirmation = false
    @State private var hasLoaded = false

    init(eventId: UUID, expense: Expense) {
        self.eventId = eventId
        self.expense = expense
        _title = State(initialValue: expense.title)
        _category = State(initialValue: expense.category)
        _payerId = State(initialValue: expense.payerId)
        _rounding = State(initialValue: expense.rounding)
        _hasExpenseDate = State(initialValue: expense.date != nil)
        _expenseDate = State(initialValue: expense.date ?? Date())
    }

    private var event: Event? { viewModel.event(for: eventId) }
    private var latestExpense: Expense? { viewModel.expense(for: expense.id, in: eventId) }
    private var language: AppLanguage { profileStore.activeLanguage }
    private var currency: AppCurrency { event?.currency ?? .jpy }
    private var participants: [EventParticipant] { event?.participants ?? [] }
    private var amount: Int { currency.minorUnits(from: amountText) ?? 0 }

    private var saveDisabled: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || amount <= 0 || payerId == nil
    }

    private var currentSplitMethod: SplitMethod {
        latestExpense?.splitMethod ?? expense.splitMethod
    }

    private var copy: (
        title: String,
        condition: String,
        current: String,
        deleteExpense: String,
        save: String,
        deletePrompt: String,
        delete: String,
        warning: String
    ) {
        switch language {
        case .japanese:
            return (
                "費用を編集", "負担条件", "現在", "この費用を削除",
                "変更を保存", "「\(expense.title)」を削除しますか？",
                "削除する", "この操作は取り消せません。"
            )
        case .english:
            return (
                "Edit Expense", "Split Conditions", "Current", "Delete This Expense",
                "Save Changes", "Delete “\(expense.title)”?",
                "Delete", "This action cannot be undone."
            )
        case .simplifiedChinese:
            return (
                "编辑费用", "分摊条件", "当前", "删除此费用",
                "保存更改", "要删除“\(expense.title)”吗？",
                "删除", "此操作无法撤销。"
            )
        case .traditionalChinese:
            return (
                "編輯費用", "分攤條件", "目前", "刪除此費用",
                "儲存變更", "要刪除「\(expense.title)」嗎？",
                "刪除", "此操作無法復原。"
            )
        case .korean:
            return (
                "비용 편집", "부담 조건", "현재", "이 비용 삭제",
                "변경 사항 저장", "“\(expense.title)”을 삭제하시겠습니까?",
                "삭제", "이 작업은 되돌릴 수 없습니다."
            )
        case .spanish:
            return (
                "Editar gasto", "Condiciones de reparto", "Actual", "Eliminar este gasto",
                "Guardar cambios", "¿Eliminar «\(expense.title)»?",
                "Eliminar", "Esta acción no se puede deshacer."
            )
        case .portuguese:
            return (
                "Editar despesa", "Condições de divisão", "Atual", "Excluir esta despesa",
                "Salvar alterações", "Excluir “\(expense.title)”?",
                "Excluir", "Esta ação não pode ser desfeita."
            )
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ExpenseFormHero(
                        title: title,
                        amount: amount,
                        category: category,
                        currency: currency,
                        isEditing: true
                    )

                    ExpenseInfoCard(
                        title: $title,
                        amountText: $amountText,
                        category: $category,
                        currency: currency
                    )

                    ExpenseDateCard(
                        hasDate: $hasExpenseDate,
                        date: $expenseDate,
                        event: event,
                        language: language
                    )

                    ExpensePayerCard(
                        participants: participants,
                        payerId: $payerId
                    ) {
                        showRoulette = true
                    }

                    SettlementRoundingPicker(rounding: $rounding, currency: currency)

                    ReceiptPhotoPickerCard(imageData: $receiptImageData)
                        .environmentObject(profileStore)

                    conditionCard
                    deleteButton
                    saveButton
                }
                .padding()
            }
            .background(AppTheme.background)
            .navigationTitle(copy.title)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { loadIfNeeded() }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(language.t(.cancel)) { dismiss() }
                }
            }
            .sheet(isPresented: $showRoulette) {
                NavigationStack {
                    PayerRouletteView(participants: participants) {
                        payerId = $0
                        showRoulette = false
                    }
                }
            }
            .confirmationDialog(
                copy.deletePrompt,
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button(copy.delete, role: .destructive) {
                    let files = latestExpense?.receiptImages ?? expense.receiptImages
                    ReceiptImageStorage.shared.delete(files)
                    viewModel.deleteExpense(expenseId: expense.id, from: eventId)
                    dismiss()
                }

                Button(language.t(.cancel), role: .cancel) {}
            } message: {
                Text(copy.warning)
            }
        }
        .tint(AppTheme.primary)
    }

    private var conditionCard: some View {
        NavigationLink {
            ExpenseConditionView(eventId: eventId, expenseId: expense.id)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "person.3.sequence.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(AppTheme.secondary.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 15))

                VStack(alignment: .leading, spacing: 3) {
                    Text(copy.condition)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text("\(copy.current)：\(currentSplitMethod.displayName(for: language))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.tertiary)
            }
            .appCard()
        }
        .buttonStyle(.plain)
    }

    private var deleteButton: some View {
        Button {
            showDeleteConfirmation = true
        } label: {
            Label(copy.deleteExpense, systemImage: "trash")
                .font(.subheadline.bold())
                .foregroundStyle(AppTheme.danger)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(AppTheme.danger.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 15))
        }
        .buttonStyle(.plain)
    }

    private var saveButton: some View {
        Button(action: save) {
            Label(copy.save, systemImage: "checkmark")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(AppTheme.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 17))
        }
        .buttonStyle(.plain)
        .disabled(saveDisabled)
        .opacity(saveDisabled ? 0.4 : 1)
        .padding(.bottom, 10)
    }

    private func loadIfNeeded() {
        guard !hasLoaded else { return }

        amountText = currency.inputText(minorUnits: expense.amount)

        if expense.date == nil, let event {
            expenseDate = event.date
        }

        receiptImageData = expense.receiptImages.compactMap {
            ReceiptImageStorage.shared.load($0)?.jpegData(compressionQuality: 0.9)
        }

        hasLoaded = true
    }

    private func save() {
        guard let payerId,
              var updated = viewModel.expense(for: expense.id, in: eventId) else { return }

        let oldFiles = updated.receiptImages
        var newFiles: [String] = []

        for data in receiptImageData {
            guard let fileName = try? ReceiptImageStorage.shared.save(data) else {
                ReceiptImageStorage.shared.delete(newFiles)
                return
            }
            newFiles.append(fileName)
        }

        updated.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.amount = amount
        updated.category = category
        updated.payerId = payerId
        updated.rounding = rounding
        updated.date = hasExpenseDate ? expenseDate : nil
        updated.receiptImageFileNames = newFiles.isEmpty ? nil : newFiles

        viewModel.updateExpense(updated, in: eventId)
        ReceiptImageStorage.shared.delete(oldFiles)
        dismiss()
    }
}
