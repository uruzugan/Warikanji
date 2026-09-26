import SwiftUI
import UIKit

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
                    ReceiptScannerCard(
                        imageData: $receiptImageData,
                        currency: currency,
                        onApply: applyOCR
                    )
                    .environmentObject(profileStore)

                    ExpenseFormHero(
                        title: title,
                        amount: amount,
                        category: category,
                        currency: currency
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
                        dismissKeyboard()
                        DispatchQueue.main.async { showRoulette = true }
                    }

                    ExpenseSplitMethodCard(
                        eventType: event?.eventType,
                        splitMethod: $splitMethod
                    )

                    if event?.expenses.last != nil {
                        previousSettingsCard
                    }

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
            .scrollDismissesKeyboard(.interactively)
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
                    Button(language.t(.cancel)) {
                        dismissKeyboard()
                        dismiss()
                    }
                }

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(language.t(.done)) { dismissKeyboard() }
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

    private var previousSettingsCard: some View {
        Button(action: applyPreviousSplitSettings) {
            HStack(spacing: 12) {
                Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                    .font(.title3.bold())
                    .foregroundStyle(AppTheme.primary)
                    .frame(width: 42, height: 42)
                    .background(AppTheme.primary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 13))

                VStack(alignment: .leading, spacing: 3) {
                    Text(previousSettingsTitle)
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)

                    Text(previousSettingsDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()
            }
            .appCard()
        }
        .buttonStyle(.plain)
    }

    private var previousSettingsTitle: String {
        language.text(
            ja: "前回の負担設定を引き継ぐ", en: "Use Previous Split Settings",
            zhHans: "沿用上次的分摊设置", zhHant: "沿用上次的分攤設定",
            ko: "이전 부담 설정 사용", es: "Usar el reparto anterior",
            pt: "Usar a divisão anterior"
        )
    }

    private var previousSettingsDescription: String {
        language.text(
            ja: "負担方法・対象者・比率・集金単位を引き継ぎます。新しい費用には自動で適用されます。",
            en: "Copies the split method, participants, ratios, and collection unit. New expenses inherit them automatically.",
            zhHans: "沿用分摊方式、参与者、比例和收款单位。新费用会自动应用。",
            zhHant: "沿用分攤方式、參與者、比例和收款單位。新費用會自動套用。",
            ko: "부담 방식, 대상자, 비율 및 정산 단위를 이어받습니다. 새 비용에는 자동 적용됩니다.",
            es: "Copia el método, participantes, proporciones y unidad de cobro. Se aplica automáticamente a los gastos nuevos.",
            pt: "Copia o método, participantes, proporções e unidade de cobrança. É aplicado automaticamente às novas despesas."
        )
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

        applyPreviousSplitSettings()

        hasPrepared = true
    }

    private func applyPreviousSplitSettings() {
        guard let previous = event?.expenses.last else { return }

        splitMethod = previous.splitMethod
        rounding = previous.rounding
        conditions = participants.map { participant in
            guard let saved = previous.conditions.first(where: {
                $0.participantId == participant.id
            }) else {
                return ExpenseCondition(expenseId: expenseId, participantId: participant.id)
            }

            return ExpenseCondition(
                expenseId: expenseId,
                participantId: participant.id,
                isIncluded: saved.isIncluded,
                customWeight: saved.customWeight
            )
        }
        fixedIds = []
    }

    private func applyOCR(_ result: ReceiptOCRResult) {
        if let merchant = result.merchant {
            title = merchant
        }
        if let amount = result.amountMinorUnits {
            amountText = currency.inputText(minorUnits: amount)
        }
        if let date = result.date {
            hasExpenseDate = true
            expenseDate = date
        }
    }

    private func save() {
        guard let payerId else { return }
        dismissKeyboard()

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

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

#Preview {
    ExpenseCreateView(eventId: UUID())
        .environmentObject(EventViewModel())
        .environmentObject(ProfileStore())
}
