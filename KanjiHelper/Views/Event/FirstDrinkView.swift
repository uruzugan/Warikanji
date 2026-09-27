import SwiftUI

struct FirstDrinkView: View {
    @EnvironmentObject private var viewModel: EventViewModel
    @EnvironmentObject private var profileStore: ProfileStore

    let eventId: UUID

    private var event: Event? { viewModel.event(for: eventId) }
    private var language: AppLanguage { profileStore.activeLanguage }
    private var isLocked: Bool { !viewModel.canEdit(eventId) }

    var body: some View {
        Group {
            if let event {
                List {
                    Section {
                        Label(
                            language.planningText(.firstDrinkDescription),
                            systemImage: "wineglass.fill"
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }

                    Section {
                        NavigationLink {
                            FirstDrinkSettingsView(eventId: eventId)
                        } label: {
                            deadlineRow(event)
                        }
                    }

                    if !event.planning.firstDrinkPlan.options.isEmpty {
                        Section(language.planningText(.aggregate)) {
                            ForEach(event.planning.firstDrinkPlan.options) { option in
                                aggregateRow(option, event: event)
                            }
                        }
                    }

                    Section(language.planningText(.participants)) {
                        if event.participants.isEmpty {
                            ContentUnavailableView(
                                language.planningText(.participants),
                                systemImage: "person.2.slash"
                            )
                        } else {
                            ForEach(event.participants) { participant in
                                NavigationLink {
                                    FirstDrinkSelectionEditView(
                                        eventId: eventId,
                                        participantId: participant.id
                                    )
                                } label: {
                                    participantRow(participant, event: event)
                                }
                            }
                        }
                    }

                    Section(language.planningText(.drinkMenu)) {
                        if event.planning.firstDrinkPlan.options.isEmpty {
                            ContentUnavailableView(
                                language.planningText(.noDrinks),
                                systemImage: "wineglass"
                            )
                        } else {
                            ForEach(event.planning.firstDrinkPlan.options) { option in
                                NavigationLink {
                                    DrinkOptionEditView(
                                        eventId: eventId,
                                        existingOption: option
                                    )
                                } label: {
                                    optionRow(option)
                                }
                                .deleteDisabled(isLocked)
                            }
                            .onDelete { offsets in
                                viewModel.deleteDrinkOptions(
                                    at: offsets,
                                    from: eventId
                                )
                            }
                        }
                    }
                }
            } else {
                ContentUnavailableView(
                    language.planningText(.firstDrinkTitle),
                    systemImage: "wineglass"
                )
            }
        }
        .navigationTitle(language.planningText(.firstDrinkTitle))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !isLocked, event != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        DrinkOptionEditView(
                            eventId: eventId,
                            existingOption: nil
                        )
                    } label: {
                        Label(
                            language.planningText(.addDrink),
                            systemImage: "plus"
                        )
                    }
                }
            }
        }
    }

    private func deadlineRow(_ event: Event) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Label(
                language.planningText(.responseDeadline),
                systemImage: "hourglass"
            )
            .font(.subheadline.bold())

            if let deadline = event.planning.firstDrinkPlan.responseDeadline {
                Text(deadline.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(deadline < Date() ? AppTheme.danger : .secondary)
            } else {
                Text(language.planningText(.optional))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 3)
    }

    private func aggregateRow(_ option: DrinkOption, event: Event) -> some View {
        let count = event.planning.firstDrinkPlan.selections.filter {
            $0.firstChoiceId == option.id
        }.count

        return HStack {
            optionLabel(option)
            Spacer()
            Text("\(count)")
                .font(.headline.monospacedDigit())
                .foregroundStyle(AppTheme.primary)
        }
    }

    private func participantRow(
        _ participant: EventParticipant,
        event: Event
    ) -> some View {
        let selection = event.planning.firstDrinkPlan.selections.first {
            $0.participantId == participant.id
        }
        let isAnswered = selection?.isAnswered == true

        return HStack(spacing: 12) {
            Image(systemName: isAnswered ? "checkmark.circle.fill" : "ellipsis.circle.fill")
                .foregroundStyle(isAnswered ? AppTheme.success : .secondary)
                .font(.title3)

            VStack(alignment: .leading, spacing: 3) {
                Text(event.displayName(for: participant.id, language: language))

                Text(
                    isAnswered
                        ? language.planningText(.answered)
                        : language.planningText(.unanswered)
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }

    private func optionRow(_ option: DrinkOption) -> some View {
        HStack {
            optionLabel(option)
            Spacer()
            if option.isToastOption {
                Image(systemName: "party.popper.fill")
                    .foregroundStyle(AppTheme.warning)
                    .accessibilityLabel(language.planningText(.toastOption))
            }
        }
    }

    private func optionLabel(_ option: DrinkOption) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(option.name)
                .font(.body.bold())
            Text(
                language.planningText(
                    option.isAlcoholic ? .alcoholic : .nonAlcoholic
                )
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}

private struct DrinkOptionEditView: View {
    @EnvironmentObject private var viewModel: EventViewModel
    @EnvironmentObject private var profileStore: ProfileStore
    @Environment(\.dismiss) private var dismiss

    let eventId: UUID
    let existingOption: DrinkOption?

    @State private var option: DrinkOption

    init(eventId: UUID, existingOption: DrinkOption?) {
        self.eventId = eventId
        self.existingOption = existingOption
        _option = State(
            initialValue: existingOption ?? DrinkOption(name: "")
        )
    }

    private var language: AppLanguage { profileStore.activeLanguage }
    private var isLocked: Bool { !viewModel.canEdit(eventId) }
    private var isSaveDisabled: Bool {
        option.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Form {
            Section(language.planningText(.drinkMenu)) {
                TextField(
                    language.planningText(.drinkName),
                    text: $option.name
                )
                Toggle(
                    language.planningText(.alcoholic),
                    isOn: $option.isAlcoholic
                )
                Toggle(
                    language.planningText(.toastOption),
                    isOn: $option.isToastOption
                )
            }
        }
        .navigationTitle(
            language.planningText(
                existingOption == nil ? .newDrink : .editDrink
            )
        )
        .navigationBarTitleDisplayMode(.inline)
        .disabled(isLocked)
        .toolbar {
            if !isLocked {
                ToolbarItem(placement: .confirmationAction) {
                    Button(language.planningText(.save), action: save)
                        .disabled(isSaveDisabled)
                }
            }
        }
    }

    private func save() {
        option.name = option.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if viewModel.saveDrinkOption(option, in: eventId) {
            dismiss()
        }
    }
}

private struct FirstDrinkSelectionEditView: View {
    @EnvironmentObject private var viewModel: EventViewModel
    @EnvironmentObject private var profileStore: ProfileStore
    @Environment(\.dismiss) private var dismiss

    let eventId: UUID
    let participantId: UUID

    @State private var selection: FirstDrinkSelection
    @State private var hasLoaded = false

    init(eventId: UUID, participantId: UUID) {
        self.eventId = eventId
        self.participantId = participantId
        _selection = State(
            initialValue: FirstDrinkSelection(participantId: participantId)
        )
    }

    private var event: Event? { viewModel.event(for: eventId) }
    private var language: AppLanguage { profileStore.activeLanguage }
    private var isLocked: Bool { !viewModel.canEdit(eventId) }
    private var isSaveDisabled: Bool {
        selection.firstChoiceId == nil
            || selection.secondChoiceId == nil
            || selection.firstChoiceId == selection.secondChoiceId
    }

    var body: some View {
        Form {
            if let event {
                Section(language.planningText(.firstDrinkTitle)) {
                    drinkPicker(
                        language.planningText(.firstChoice),
                        selection: $selection.firstChoiceId,
                        excluding: [selection.secondChoiceId, selection.thirdChoiceId]
                    )
                    drinkPicker(
                        language.planningText(.secondChoice),
                        selection: $selection.secondChoiceId,
                        excluding: [selection.firstChoiceId, selection.thirdChoiceId]
                    )
                    drinkPicker(
                        language.planningText(.thirdChoice),
                        selection: $selection.thirdChoiceId,
                        excluding: [selection.firstChoiceId, selection.secondChoiceId]
                    )
                }

                if event.planning.firstDrinkPlan.options.count < 2 {
                    Section {
                        Label(
                            language.planningText(.selectionIncomplete),
                            systemImage: "exclamationmark.triangle.fill"
                        )
                        .foregroundStyle(AppTheme.warning)
                    }
                }
            }
        }
        .navigationTitle(participantName)
        .navigationBarTitleDisplayMode(.inline)
        .disabled(isLocked)
        .toolbar {
            if !isLocked {
                ToolbarItem(placement: .confirmationAction) {
                    Button(language.planningText(.save), action: save)
                        .disabled(isSaveDisabled)
                }
            }
        }
        .onAppear(perform: loadIfNeeded)
    }

    private var participantName: String {
        event?.displayName(for: participantId, language: language)
            ?? language.planningText(.firstDrinkTitle)
    }

    private func drinkPicker(
        _ title: String,
        selection: Binding<UUID?>,
        excluding excludedIds: [UUID?]
    ) -> some View {
        Picker(title, selection: selection) {
            Text(language.planningText(.unanswered)).tag(UUID?.none)
            ForEach(availableOptions(current: selection.wrappedValue, excluding: excludedIds)) {
                Text($0.name).tag(Optional($0.id))
            }
        }
    }

    private func availableOptions(
        current: UUID?,
        excluding excludedIds: [UUID?]
    ) -> [DrinkOption] {
        let excluded = Set(excludedIds.compactMap { $0 })
        return event?.planning.firstDrinkPlan.options.filter {
            $0.id == current || !excluded.contains($0.id)
        } ?? []
    }

    private func loadIfNeeded() {
        guard !hasLoaded else { return }
        if let saved = event?.planning.firstDrinkPlan.selections.first(where: {
            $0.participantId == participantId
        }) {
            selection = saved
        }
        hasLoaded = true
    }

    private func save() {
        if viewModel.saveFirstDrinkSelection(selection, in: eventId) {
            dismiss()
        }
    }
}

private struct FirstDrinkSettingsView: View {
    @EnvironmentObject private var viewModel: EventViewModel
    @EnvironmentObject private var profileStore: ProfileStore
    @Environment(\.dismiss) private var dismiss

    let eventId: UUID

    @State private var hasDeadline = false
    @State private var deadline = Date()
    @State private var hasLoaded = false

    private var event: Event? { viewModel.event(for: eventId) }
    private var language: AppLanguage { profileStore.activeLanguage }
    private var isLocked: Bool { !viewModel.canEdit(eventId) }

    var body: some View {
        Form {
            Section {
                Toggle(
                    language.planningText(.responseDeadline),
                    isOn: $hasDeadline
                )
                if hasDeadline {
                    DatePicker(
                        language.planningText(.responseDeadline),
                        selection: $deadline,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }
            }
        }
        .navigationTitle(language.planningText(.responseDeadline))
        .navigationBarTitleDisplayMode(.inline)
        .disabled(isLocked)
        .toolbar {
            if !isLocked {
                ToolbarItem(placement: .confirmationAction) {
                    Button(language.planningText(.save), action: save)
                }
            }
        }
        .onAppear(perform: loadIfNeeded)
    }

    private func loadIfNeeded() {
        guard !hasLoaded else { return }
        if let saved = event?.planning.firstDrinkPlan.responseDeadline {
            hasDeadline = true
            deadline = saved
        } else {
            deadline = event?.date ?? Date()
        }
        hasLoaded = true
    }

    private func save() {
        if viewModel.updateFirstDrinkDeadline(
            hasDeadline ? deadline : nil,
            in: eventId
        ) {
            dismiss()
        }
    }
}
