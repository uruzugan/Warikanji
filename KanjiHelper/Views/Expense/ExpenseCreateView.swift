import SwiftUI

struct ExpenseCreateView: View {
    @EnvironmentObject private var viewModel: EventViewModel
    @EnvironmentObject private var profileStore: ProfileStore
    @Environment(\.dismiss) private var dismiss

    let eventId: UUID

    @State private var expenseId = UUID()
    @State private var title = ""
    @State private var amountText = ""
    @State private var category: ExpenseCategory = .food
    @State private var payerId: UUID?
    @State private var splitMethod: SplitMethod = .equal
    @State private var rounding: SettlementRounding = .exact
    @State private var conditions: [ExpenseCondition] = []
    @State private var fixedIds: Set<UUID> = []
    @State private var names: [UUID: String] = [:]
    @State private var receiptImageData: [Data] = []
    @State private var hasExpenseDate = false
    @State private var expenseDate = Date()
    @State private var showRoulette = false
    @State private var hasPrepared = false

    private var event: Event? { viewModel.event(for: eventId) }
    private var language: AppLanguage { profileStore.activeLanguage }
    private var currency: AppCurrency { event?.currency ?? .jpy }
    private var participants: [EventParticipant] { event?.participants ?? [] }
    private var amount: Int { currency.minorUnits(from: amountText) ?? 0 }

    private var customTotalWeight: Double {
        conditions.filter(\.isIncluded).reduce(0) { $0 + max($1.customWeight, 0) }
    }

    private var isSaveDisabled: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        amount <= 0 ||
        payerId == nil ||
        (splitMethod == .custom && customTotalWeight <= 0)
    }

    private var rouletteParticipants: [EventParticipant] {
        participants.map { participant in
            var updated = participant
            updated.name = names[participant.id, default: participant.name]
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return updated
        }
    }

    private var screenTitle: String {
        language.text(
            ja: "費用を追加", en: "Add Expense",
            zhHans: "添加费用", zhHant: "新增費用",
            ko: "비용 추가", es: "Añadir gasto", pt: "Adicionar despesa"
        )
    }

    private var saveText: String {
        language.text(
            ja: "費用を保存", en: "Save Expense",
            zhHans: "保存费用", zhHant: "儲存費用",
            ko: "비용 저장", es: "Guardar gasto", pt: "Salvar despesa"
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    ExpenseFormHero(
                        title: title,
                        amount: amount,
                        category: category,
                        currency: currency,
                        isEditing: false
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
                        payerId: $payerId,
                        names: names
                    ) {
                        showRoulette = true
                    }

                    ExpenseSplitMethodCard(
                        eventType: event?.eventType,
                        splitMethod: $splitMethod
                    )

                    if splitMethod == .custom {
                        ExpenseRatioEditor(
                            participants: participants,
                            expenseId: expenseId,
                            conditions: $conditions,
                            names: $names,
                            fixedIds: $fixedIds
                        )
                    }

                    SettlementRoundingPicker(rounding: $rounding, currency: currency)

                    ReceiptPhotoPickerCard(imageData: $receiptImageData)
                        .environmentObject(profileStore)

                    saveButton
                }
                .padding()
            }
            .background(AppTheme.background)
            .navigationTitle(screenTitle)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { prepareIfNeeded() }
            .sheet(isPresented: $showRoulette) {
                NavigationStack {
                    PayerRouletteView(participants: rouletteParticipants) {
                        payerId = $0
                        showRoulette = false
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(language.t(.cancel)) { dismiss() }
                }
            }
        }
        .tint(AppTheme.primary)
    }

    private var saveButton: some View {
        Button(action: save) {
            Label(saveText, systemImage: "checkmark")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(AppTheme.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 17))
        }
        .buttonStyle(.plain)
        .disabled(isSaveDisabled)
        .opacity(isSaveDisabled ? 0.4 : 1)
        .padding(.bottom, 10)
    }

    private func prepareIfNeeded() {
        guard !hasPrepared else { return }

        conditions = participants.map {
            ExpenseCondition(expenseId: expenseId, participantId: $0.id)
        }

        names = Dictionary(uniqueKeysWithValues: participants.map {
            ($0.id, $0.name)
        })

        if let event {
            expenseDate = event.date
        }

        hasPrepared = true
    }

    private func save() {
        guard let payerId else { return }

        saveNames()

        let receiptFileNames = receiptImageData.compactMap {
            try? ReceiptImageStorage.shared.save($0)
        }

        let expense = Expense(
            id: expenseId,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category,
            amount: amount,
            payerId: payerId,
            splitMethod: splitMethod,
            conditions: splitMethod == .custom ? conditions : [],
            rounding: rounding,
            receiptImageFileNames: receiptFileNames,
            date: hasExpenseDate ? expenseDate : nil
        )

        viewModel.addExpense(expense, to: eventId)
        dismiss()
    }

    private func saveNames() {
        for participant in participants {
            var updated = participant
            let name = names[participant.id, default: ""]
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard updated.name != name else { continue }

            updated.name = name
            viewModel.updateParticipant(updated, in: eventId)
        }
    }
}

#Preview {
    ExpenseCreateView(eventId: UUID())
        .environmentObject(EventViewModel())
        .environmentObject(ProfileStore())
}
