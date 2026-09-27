import SwiftUI

struct EventBudgetView: View {
    @EnvironmentObject private var viewModel: EventViewModel
    @EnvironmentObject private var profileStore: ProfileStore
    @Environment(\.dismiss) private var dismiss

    let eventId: UUID

    @State private var plan = EventBudgetPlan()
    @State private var hasTotalBudget = false
    @State private var totalBudgetText = ""
    @State private var hasPerPersonBudget = false
    @State private var perPersonBudgetText = ""
    @State private var hasAdvanceLimit = false
    @State private var advanceLimitText = ""
    @State private var hasCompanySubsidy = false
    @State private var companySubsidyText = ""
    @State private var hasLoaded = false

    private var event: Event? { viewModel.event(for: eventId) }
    private var language: AppLanguage { profileStore.activeLanguage }
    private var currency: AppCurrency { event?.currency ?? .jpy }
    private var isLocked: Bool { !viewModel.canEdit(eventId) }

    private var hasInvalidAmount: Bool {
        (hasTotalBudget && currency.minorUnits(from: totalBudgetText) == nil)
            || (hasPerPersonBudget && currency.minorUnits(from: perPersonBudgetText) == nil)
            || (plan.organizerParticipantId != nil
                && hasAdvanceLimit
                && currency.minorUnits(from: advanceLimitText) == nil)
            || (hasCompanySubsidy && currency.minorUnits(from: companySubsidyText) == nil)
    }

    var body: some View {
        Form {
            Section {
                Label(
                    language.budgetText(.description),
                    systemImage: "chart.pie.fill"
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            if let event {
                budgetSummary(event)
                budgetLimits
                organizerAdvance(event)
                companySubsidy(event)
                approvalAndNotes
            }
        }
        .navigationTitle(language.budgetText(.budget))
        .navigationBarTitleDisplayMode(.inline)
        .disabled(isLocked)
        .toolbar {
            if !isLocked {
                ToolbarItem(placement: .confirmationAction) {
                    Button(language.planningText(.save), action: save)
                        .disabled(hasInvalidAmount)
                }
            }
        }
        .onAppear(perform: loadIfNeeded)
    }

    private func budgetSummary(_ event: Event) -> some View {
        let saved = event.planning.budgetPlan
        let spent = event.totalExpenseAmount
        let participantCount = max(event.participants.count, 1)
        let perPerson = spent / participantCount
        let subsidy = saved.estimatedCompanySubsidy(
            participantCount: event.participants.count
        )

        return Section(language.budgetText(.currentSpend)) {
            valueRow(
                language.budgetText(.currentSpend),
                currency.formatted(minorUnits: spent),
                color: .primary
            )
            valueRow(
                language.budgetText(.currentPerPerson),
                currency.formatted(minorUnits: perPerson),
                color: .secondary
            )

            if let limit = saved.totalLimitMinorUnits {
                valueRow(
                    spent > limit
                        ? language.budgetText(.overBudget)
                        : language.budgetText(.remaining),
                    currency.formatted(minorUnits: abs(limit - spent)),
                    color: spent > limit ? AppTheme.danger : AppTheme.success
                )
            }

            if subsidy > 0 {
                valueRow(
                    language.budgetText(.estimatedSubsidy),
                    currency.formatted(minorUnits: subsidy),
                    color: AppTheme.success
                )
                valueRow(
                    language.budgetText(.afterSubsidy),
                    currency.formatted(minorUnits: max(spent - subsidy, 0)),
                    color: AppTheme.primary
                )
            }
        }
    }

    private var budgetLimits: some View {
        Section(language.budgetText(.budget)) {
            Toggle(language.budgetText(.totalBudget), isOn: $hasTotalBudget)
            if hasTotalBudget {
                amountField(
                    language.budgetText(.totalBudget),
                    text: $totalBudgetText
                )
            }

            Toggle(
                language.budgetText(.perPersonBudget),
                isOn: $hasPerPersonBudget
            )
            if hasPerPersonBudget {
                amountField(
                    language.budgetText(.perPersonBudget),
                    text: $perPersonBudgetText
                )
            }
        }
    }

    private func organizerAdvance(_ event: Event) -> some View {
        Section(language.budgetText(.organizerAdvance)) {
            Picker(
                language.budgetText(.organizer),
                selection: $plan.organizerParticipantId
            ) {
                Text(language.budgetText(.selectOrganizer)).tag(UUID?.none)
                ForEach(event.participants) { participant in
                    Text(event.displayName(for: participant.id, language: language))
                        .tag(Optional(participant.id))
                }
            }

            if let organizerId = plan.organizerParticipantId {
                let paid = event.expenses
                    .filter { $0.payerId == organizerId }
                    .reduce(0) { $0 + $1.amount }
                valueRow(
                    language.budgetText(.organizerAdvance),
                    currency.formatted(minorUnits: paid),
                    color: advanceColor(paid: paid)
                )

                Toggle(
                    language.budgetText(.advanceLimit),
                    isOn: $hasAdvanceLimit
                )
                if hasAdvanceLimit {
                    amountField(
                        language.budgetText(.advanceLimit),
                        text: $advanceLimitText
                    )
                }
            }
        }
    }

    private func companySubsidy(_ event: Event) -> some View {
        Section(language.budgetText(.companySubsidy)) {
            Toggle(
                language.budgetText(.companySubsidy),
                isOn: $hasCompanySubsidy
            )

            if hasCompanySubsidy {
                Picker(
                    language.budgetText(.subsidyMode),
                    selection: $plan.companySubsidyMode
                ) {
                    ForEach(CompanySubsidyMode.allCases, id: \.self) { mode in
                        Text(mode.displayName(for: language)).tag(mode)
                    }
                }

                amountField(
                    plan.companySubsidyMode == .total
                        ? language.budgetText(.totalAmount)
                        : language.budgetText(.perParticipant),
                    text: $companySubsidyText
                )

                if plan.companySubsidyMode == .perParticipant {
                    Toggle(
                        language.budgetText(.allParticipants),
                        isOn: $plan.companySubsidyAppliesToAll
                    )

                    if !plan.companySubsidyAppliesToAll {
                        ForEach(event.participants) { participant in
                            Toggle(
                                event.displayName(
                                    for: participant.id,
                                    language: language
                                ),
                                isOn: subsidyBinding(participant.id)
                            )
                        }
                    }
                }
            }
        }
    }

    private var approvalAndNotes: some View {
        Group {
            Section(language.budgetText(.budgetApproval)) {
                Picker(
                    language.budgetText(.budgetApproval),
                    selection: $plan.approvalStatus
                ) {
                    ForEach(BudgetApprovalStatus.allCases, id: \.self) { status in
                        Text(status.displayName(for: language)).tag(status)
                    }
                }
            }

            Section(language.budgetText(.notes)) {
                TextField(
                    language.budgetText(.notes),
                    text: $plan.notes,
                    axis: .vertical
                )
                .lineLimit(2...5)
            }
        }
    }

    private func amountField(
        _ label: String,
        text: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                Spacer()
                Text(currency.symbol)
                    .foregroundStyle(.secondary)
                TextField(
                    currency.fractionDigits == 0 ? "0" : "0.00",
                    text: text
                )
                .keyboardType(currency.fractionDigits == 0 ? .numberPad : .decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 160)
            }

            if !text.wrappedValue.isEmpty,
               currency.minorUnits(from: text.wrappedValue) == nil {
                Label(
                    language.budgetText(.invalidAmount),
                    systemImage: "exclamationmark.circle"
                )
                .font(.caption)
                .foregroundStyle(AppTheme.warning)
            }
        }
    }

    private func valueRow(
        _ label: String,
        _ value: String,
        color: Color
    ) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .font(.body.bold().monospacedDigit())
                .foregroundStyle(color)
        }
    }

    private func subsidyBinding(_ participantId: UUID) -> Binding<Bool> {
        Binding(
            get: { plan.subsidizedParticipantIds.contains(participantId) },
            set: { isIncluded in
                if isIncluded {
                    plan.subsidizedParticipantIds.insert(participantId)
                } else {
                    plan.subsidizedParticipantIds.remove(participantId)
                }
            }
        )
    }

    private func advanceColor(paid: Int) -> Color {
        guard let limit = event?.planning.budgetPlan.organizerAdvanceLimitMinorUnits
        else { return .primary }
        return paid > limit ? AppTheme.danger : AppTheme.success
    }

    private func loadIfNeeded() {
        guard !hasLoaded, let event else { return }
        plan = event.planning.budgetPlan

        if let amount = plan.totalLimitMinorUnits {
            hasTotalBudget = true
            totalBudgetText = currency.inputText(minorUnits: amount)
        }
        if let amount = plan.perParticipantLimitMinorUnits {
            hasPerPersonBudget = true
            perPersonBudgetText = currency.inputText(minorUnits: amount)
        }
        if let amount = plan.organizerAdvanceLimitMinorUnits {
            hasAdvanceLimit = true
            advanceLimitText = currency.inputText(minorUnits: amount)
        }
        if let amount = plan.companySubsidyMinorUnits {
            hasCompanySubsidy = true
            companySubsidyText = currency.inputText(minorUnits: amount)
        }
        hasLoaded = true
    }

    private func save() {
        plan.totalLimitMinorUnits = hasTotalBudget
            ? currency.minorUnits(from: totalBudgetText)
            : nil
        plan.perParticipantLimitMinorUnits = hasPerPersonBudget
            ? currency.minorUnits(from: perPersonBudgetText)
            : nil
        plan.organizerAdvanceLimitMinorUnits = hasAdvanceLimit
            && plan.organizerParticipantId != nil
            ? currency.minorUnits(from: advanceLimitText)
            : nil
        plan.companySubsidyMinorUnits = hasCompanySubsidy
            ? currency.minorUnits(from: companySubsidyText)
            : nil

        if !hasCompanySubsidy {
            plan.subsidizedParticipantIds = []
        }

        if viewModel.saveBudgetPlan(plan, in: eventId) {
            dismiss()
        }
    }
}
