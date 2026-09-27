import SwiftUI

struct SchedulePollView: View {
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
                            language.planningText(.datePollDescription),
                            systemImage: "calendar.badge.questionmark"
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }

                    Section {
                        NavigationLink {
                            SchedulePollSettingsView(eventId: eventId)
                        } label: {
                            settingsSummary(event)
                        }
                    }

                    Section(language.planningText(.datePoll)) {
                        if event.planning.schedulePoll.options.isEmpty {
                            ContentUnavailableView(
                                language.planningText(.noDateOptions),
                                systemImage: "calendar.badge.plus"
                            )
                        } else {
                            ForEach(event.planning.schedulePoll.options) { option in
                                NavigationLink {
                                    ScheduleOptionEditView(
                                        eventId: eventId,
                                        existingOption: option
                                    )
                                } label: {
                                    optionRow(option, event: event)
                                }
                            }
                            .onDelete { offsets in
                                viewModel.deleteScheduleOptions(
                                    at: offsets,
                                    from: eventId
                                )
                            }
                        }
                    }
                }
            } else {
                ContentUnavailableView(
                    language.planningText(.datePoll),
                    systemImage: "calendar.badge.exclamationmark"
                )
            }
        }
        .navigationTitle(language.planningText(.datePoll))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !isLocked, event != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        ScheduleOptionEditView(
                            eventId: eventId,
                            existingOption: nil
                        )
                    } label: {
                        Label(
                            language.planningText(.addDateOption),
                            systemImage: "plus"
                        )
                    }
                }
            }
        }
    }

    private func settingsSummary(_ event: Event) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Label(
                language.planningText(.finalChoice),
                systemImage: "checkmark.seal.fill"
            )
            .font(.subheadline.bold())

            if let finalizedId = event.planning.schedulePoll.finalizedOptionId,
               let option = event.planning.schedulePoll.options.first(where: {
                   $0.id == finalizedId
               }) {
                Text(option.startAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(AppTheme.success)
            } else {
                Text(language.planningText(.notFinalized))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let deadline = event.planning.schedulePoll.responseDeadline {
                Label(
                    deadline.formatted(date: .abbreviated, time: .shortened),
                    systemImage: "hourglass"
                )
                .font(.caption)
                .foregroundStyle(deadline < Date() ? AppTheme.danger : .secondary)
            }
        }
        .padding(.vertical, 3)
    }

    private func optionRow(_ option: ScheduleOption, event: Event) -> some View {
        let counts = choiceCounts(optionId: option.id, event: event)
        let isFinal = event.planning.schedulePoll.finalizedOptionId == option.id

        return VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(option.startAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.body.bold())

                if isFinal {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(AppTheme.success)
                }
            }

            if let endAt = option.endAt {
                Text("→ \(endAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !option.note.isEmpty {
                Text(option.note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            HStack(spacing: 10) {
                choiceBadge(.yes, count: counts[.yes, default: 0])
                choiceBadge(.maybe, count: counts[.maybe, default: 0])
                choiceBadge(.no, count: counts[.no, default: 0])
                choiceBadge(.unanswered, count: counts[.unanswered, default: 0])
            }
        }
        .padding(.vertical, 3)
    }

    private func choiceCounts(
        optionId: UUID,
        event: Event
    ) -> [CoordinationChoice: Int] {
        var result: [CoordinationChoice: Int] = [:]
        for participant in event.participants {
            let choice = event.planning.schedulePoll.responses.first {
                $0.participantId == participant.id
            }?.optionResponses.first {
                $0.optionId == optionId
            }?.choice ?? .unanswered
            result[choice, default: 0] += 1
        }
        return result
    }

    private func choiceBadge(_ choice: CoordinationChoice, count: Int) -> some View {
        Text("\(choice.displayName(for: language)) \(count)")
            .font(.caption2.bold())
            .foregroundStyle(choiceColor(choice))
    }

    private func choiceColor(_ choice: CoordinationChoice) -> Color {
        switch choice {
        case .yes: return AppTheme.success
        case .maybe: return AppTheme.warning
        case .no: return AppTheme.danger
        case .unanswered: return .secondary
        }
    }
}

private struct ScheduleOptionEditView: View {
    @EnvironmentObject private var viewModel: EventViewModel
    @EnvironmentObject private var profileStore: ProfileStore
    @Environment(\.dismiss) private var dismiss

    let eventId: UUID
    let existingOption: ScheduleOption?

    @State private var option: ScheduleOption
    @State private var hasEndAt: Bool
    @State private var choices: [UUID: CoordinationChoice] = [:]
    @State private var hasLoaded = false

    init(eventId: UUID, existingOption: ScheduleOption?) {
        self.eventId = eventId
        self.existingOption = existingOption
        let initial = existingOption ?? ScheduleOption(startAt: Date())
        _option = State(initialValue: initial)
        _hasEndAt = State(initialValue: initial.endAt != nil)
    }

    private var event: Event? { viewModel.event(for: eventId) }
    private var language: AppLanguage { profileStore.activeLanguage }
    private var isLocked: Bool { !viewModel.canEdit(eventId) }

    var body: some View {
        Form {
            Section(language.planningText(.dateOption)) {
                DatePicker(
                    language.planningText(.startTime),
                    selection: $option.startAt,
                    displayedComponents: [.date, .hourAndMinute]
                )

                Toggle(
                    language.planningText(.endTime),
                    isOn: $hasEndAt
                )
                if hasEndAt {
                    DatePicker(
                        language.planningText(.endTime),
                        selection: endBinding,
                        in: option.startAt...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }

                TextField(
                    language.planningText(.notes),
                    text: $option.note,
                    axis: .vertical
                )
                .lineLimit(2...5)
            }

            if let event {
                Section(language.planningText(.participants)) {
                    ForEach(event.participants) { participant in
                        Picker(
                            event.displayName(
                                for: participant.id,
                                language: language
                            ),
                            selection: choiceBinding(participant.id)
                        ) {
                            ForEach(CoordinationChoice.allCases, id: \.self) { choice in
                                Text(choice.displayName(for: language)).tag(choice)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(
            language.planningText(
                existingOption == nil ? .newDateOption : .editDateOption
            )
        )
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
        .onChange(of: hasEndAt) { _, enabled in
            if enabled, option.endAt == nil {
                option.endAt = event?.endDate ?? option.startAt
            } else if !enabled {
                option.endAt = nil
            }
        }
        .onChange(of: option.startAt) { _, startAt in
            if let endAt = option.endAt, endAt < startAt {
                option.endAt = startAt
            }
        }
    }

    private var endBinding: Binding<Date> {
        Binding(
            get: { option.endAt ?? event?.endDate ?? option.startAt },
            set: { option.endAt = $0 }
        )
    }

    private func choiceBinding(_ participantId: UUID) -> Binding<CoordinationChoice> {
        Binding(
            get: { choices[participantId, default: .unanswered] },
            set: { choices[participantId] = $0 }
        )
    }

    private func loadIfNeeded() {
        guard !hasLoaded, let event else { return }
        if existingOption == nil {
            option.startAt = event.date
            option.endAt = event.endDate
            hasEndAt = true
        }
        for participant in event.participants {
            choices[participant.id] = event.planning.schedulePoll.responses.first {
                $0.participantId == participant.id
            }?.optionResponses.first {
                $0.optionId == option.id
            }?.choice ?? .unanswered
        }
        hasLoaded = true
    }

    private func save() {
        option.note = option.note.trimmingCharacters(in: .whitespacesAndNewlines)
        if viewModel.saveScheduleOptionDetails(
            option,
            choices: choices,
            in: eventId
        ) {
            dismiss()
        }
    }
}

private struct SchedulePollSettingsView: View {
    @EnvironmentObject private var viewModel: EventViewModel
    @EnvironmentObject private var profileStore: ProfileStore
    @Environment(\.dismiss) private var dismiss

    let eventId: UUID

    @State private var hasDeadline = false
    @State private var deadline = Date()
    @State private var finalizedOptionId: UUID?
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

            if let event {
                Section(language.planningText(.finalChoice)) {
                    Picker(
                        language.planningText(.finalChoice),
                        selection: $finalizedOptionId
                    ) {
                        Text(language.planningText(.notFinalized)).tag(UUID?.none)
                        ForEach(event.planning.schedulePoll.options) { option in
                            Text(
                                option.startAt.formatted(
                                    date: .abbreviated,
                                    time: .shortened
                                )
                            )
                            .tag(Optional(option.id))
                        }
                    }
                }
            }
        }
        .navigationTitle(language.planningText(.datePoll))
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
        guard !hasLoaded, let poll = event?.planning.schedulePoll else { return }
        if let savedDeadline = poll.responseDeadline {
            deadline = savedDeadline
            hasDeadline = true
        } else {
            deadline = min(event?.date ?? Date(), Date().addingTimeInterval(86_400))
        }
        finalizedOptionId = poll.finalizedOptionId
        hasLoaded = true
    }

    private func save() {
        if viewModel.updateSchedulePollSettings(
            deadline: hasDeadline ? deadline : nil,
            finalizedOptionId: finalizedOptionId,
            in: eventId
        ) {
            dismiss()
        }
    }
}
