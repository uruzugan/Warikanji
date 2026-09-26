import SwiftUI

struct ExpenseConditionView: View {
    @EnvironmentObject private var viewModel: EventViewModel
    @EnvironmentObject private var profileStore: ProfileStore
    @Environment(\.dismiss) private var dismiss

    let eventId: UUID
    let expenseId: UUID

    @State private var splitMethod: SplitMethod = .equal
    @State private var conditions: [ExpenseCondition] = []
    @State private var names: [UUID: String] = [:]
    @State private var fixedIds: Set<UUID> = []
    @State private var hasLoaded = false

    private var event: Event? { viewModel.event(for: eventId) }
    private var expense: Expense? { viewModel.expense(for: expenseId, in: eventId) }
    private var language: AppLanguage { profileStore.activeLanguage }
    private var currency: AppCurrency { event?.currency ?? .jpy }
    private var participants: [EventParticipant] { event?.participants ?? [] }
    private var includedCount: Int { conditions.filter(\.isIncluded).count }
    private var totalWeight: Double {
        conditions.filter(\.isIncluded).reduce(0) { $0 + max($1.customWeight, 0) }
    }

    private var saveDisabled: Bool {
        splitMethod == .custom && (includedCount == 0 || totalWeight <= 0)
    }

    private var copy: (title: String, notFound: String, target: String, equal: String, note: String, save: String) {
        switch language {
        case .japanese:
            return ("負担条件", "費用が見つかりません", "負担対象",
                    "\(participants.count)人で均等に負担します",
                    "均等割りでは全員が負担対象です。割り切れない最小通貨単位の端数はランダムに振り分けられます。",
                    "負担条件を保存")
        case .english:
            return ("Split Conditions", "Expense not found", "Participants",
                    "Split equally among \(participants.count) participants",
                    "Everyone is included in an equal split. Any indivisible smallest currency units are distributed randomly.",
                    "Save Conditions")
        case .simplifiedChinese:
            return ("分摊条件", "未找到费用", "分摊对象",
                    "由\(participants.count)人平均分摊",
                    "平均分摊时所有人都会参与。无法整除的最小货币单位将随机分配。",
                    "保存分摊条件")
        case .traditionalChinese:
            return ("分攤條件", "找不到費用", "分攤對象",
                    "由\(participants.count)人平均分攤",
                    "平均分攤時所有人都會參與。無法整除的最小貨幣單位將隨機分配。",
                    "儲存分攤條件")
        case .korean:
            return ("부담 조건", "비용을 찾을 수 없습니다", "부담 대상",
                    "\(participants.count)명이 균등하게 부담합니다",
                    "균등 분할에서는 모두가 부담 대상입니다. 나누어지지 않는 최소 통화 단위는 무작위로 배분됩니다.",
                    "부담 조건 저장")
        case .spanish:
            return ("Condiciones de reparto", "Gasto no encontrado", "Participantes",
                    "Se divide por igual entre \(participants.count) personas",
                    "En un reparto equitativo participan todos. Las unidades mínimas que no puedan dividirse se asignan al azar.",
                    "Guardar condiciones")
        case .portuguese:
            return ("Condições de divisão", "Despesa não encontrada", "Participantes",
                    "Divisão igual entre \(participants.count) pessoas",
                    "Na divisão igual todos participam. As menores unidades monetárias que não puderem ser divididas serão distribuídas aleatoriamente.",
                    "Salvar condições")
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let expense {
                    hero(expense)

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
                    } else {
                        equalCard
                    }

                    saveButton
                } else {
                    ContentUnavailableView(copy.notFound, systemImage: "banknote")
                }
            }
            .padding()
        }
        .background(AppTheme.background)
        .navigationTitle(copy.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
        .tint(AppTheme.primary)
    }

    private func hero(_ expense: Expense) -> some View {
        HStack(spacing: 14) {
            Image(systemName: expense.category.symbolName)
                .font(.title2.bold())
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(.white.opacity(0.18))
                .clipShape(RoundedRectangle(cornerRadius: 16))

            VStack(alignment: .leading, spacing: 4) {
                Text(expense.displayTitle(for: language)).font(.headline).lineLimit(1)

                Text(expense.category.displayName(for: language))
                    .font(.caption)
                    .opacity(0.8)
            }

            Spacer()

            Text(currency.formatted(minorUnits: expense.amount))
                .font(.title3.bold())
                .monospacedDigit()
        }
        .foregroundStyle(.white)
        .padding(18)
        .background(AppTheme.gradient)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private var equalCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(copy.target, systemImage: "person.2.fill")
                .font(.headline)

            Text(copy.equal)
                .font(.subheadline.bold())

            Text(copy.note)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard()
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

    private func load() {
        guard !hasLoaded, let expense else { return }

        splitMethod = expense.splitMethod

        conditions = participants.map { participant in
            expense.conditions.first { $0.participantId == participant.id }
            ?? ExpenseCondition(expenseId: expenseId, participantId: participant.id)
        }

        names = Dictionary(uniqueKeysWithValues: participants.map { ($0.id, $0.name) })
        hasLoaded = true
    }

    private func save() {
        guard !saveDisabled else { return }

        for participant in participants {
            var updated = participant
            updated.name = names[participant.id, default: ""]
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard updated.name != participant.name else { continue }
            viewModel.updateParticipant(updated, in: eventId)
        }

        viewModel.updateExpenseConditions(
            eventId: eventId,
            expenseId: expenseId,
            splitMethod: splitMethod,
            conditions: splitMethod == .custom ? conditions : []
        )

        dismiss()
    }
}
