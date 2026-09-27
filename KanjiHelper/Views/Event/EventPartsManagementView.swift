import SwiftUI

struct EventPartsManagementView: View {
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
                            language.planningText(.partsDescription),
                            systemImage: "square.stack.3d.up.fill"
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }

                    Section(language.planningText(.eventParts)) {
                        if event.planning.parts.isEmpty {
                            ContentUnavailableView(
                                language.planningText(.noParts),
                                systemImage: "square.stack.3d.up"
                            )
                        } else {
                            ForEach(event.planning.parts) { part in
                                NavigationLink {
                                    EventPartEditView(
                                        eventId: eventId,
                                        existingPart: part
                                    )
                                } label: {
                                    partRow(part, event: event)
                                }
                            }
                            .onDelete { offsets in
                                viewModel.deleteEventParts(
                                    at: offsets,
                                    from: eventId
                                )
                            }
                            .onMove { source, destination in
                                viewModel.moveEventParts(
                                    from: source,
                                    to: destination,
                                    in: eventId
                                )
                            }
                        }
                    }
                }
            } else {
                ContentUnavailableView(
                    language.planningText(.eventParts),
                    systemImage: "square.stack.3d.up"
                )
            }
        }
        .navigationTitle(language.planningText(.eventParts))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !isLocked, let event, !event.planning.parts.isEmpty {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
            }

            if !isLocked, event != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        EventPartEditView(
                            eventId: eventId,
                            existingPart: nil
                        )
                    } label: {
                        Label(
                            language.planningText(.addPart),
                            systemImage: "plus"
                        )
                    }
                }
            }
        }
    }

    private func partRow(_ part: EventPart, event: Event) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(part.title)
                .font(.body.bold())

            HStack(spacing: 10) {
                if let startAt = part.startAt {
                    Label(
                        startAt.formatted(date: .abbreviated, time: .shortened),
                        systemImage: "clock"
                    )
                }

                if !part.location.isEmpty {
                    Label(part.location, systemImage: "mappin")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Text(participantCountText(part, event: event))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 3)
    }

    private func participantCountText(_ part: EventPart, event: Event) -> String {
        let count = part.participantIds.count
        if count == event.participants.count {
            return language.planningText(.allParticipants)
        }

        switch language {
        case .japanese: return "\(count)人"
        case .english: return "\(count) participants"
        case .simplifiedChinese: return "\(count)人"
        case .traditionalChinese: return "\(count)人"
        case .korean: return "\(count)명"
        case .spanish: return "\(count) participantes"
        case .portuguese: return "\(count) participantes"
        }
    }
}

private struct EventPartEditView: View {
    @EnvironmentObject private var viewModel: EventViewModel
    @EnvironmentObject private var profileStore: ProfileStore
    @Environment(\.dismiss) private var dismiss

    let eventId: UUID
    let existingPart: EventPart?

    @State private var part: EventPart
    @State private var hasStartAt: Bool
    @State private var hasEndAt: Bool

    init(eventId: UUID, existingPart: EventPart?) {
        self.eventId = eventId
        self.existingPart = existingPart
        let initial = existingPart ?? EventPart(title: "")
        _part = State(initialValue: initial)
        _hasStartAt = State(initialValue: initial.startAt != nil)
        _hasEndAt = State(initialValue: initial.endAt != nil)
    }

    private var event: Event? { viewModel.event(for: eventId) }
    private var language: AppLanguage { profileStore.activeLanguage }
    private var isLocked: Bool { !viewModel.canEdit(eventId) }
    private var isSaveDisabled: Bool {
        part.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Form {
            Section(language.planningText(.partTitle)) {
                TextField(
                    language.planningText(.partTitle),
                    text: $part.title
                )

                TextField(
                    language.planningText(.location),
                    text: $part.location
                )
            }

            Section {
                Toggle(
                    language.planningText(.startTime),
                    isOn: $hasStartAt
                )
                if hasStartAt {
                    DatePicker(
                        language.planningText(.startTime),
                        selection: startBinding,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }

                Toggle(
                    language.planningText(.endTime),
                    isOn: $hasEndAt
                )
                if hasEndAt {
                    DatePicker(
                        language.planningText(.endTime),
                        selection: endBinding,
                        in: (part.startAt ?? .distantPast)...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }
            }

            if let event {
                Section(language.planningText(.participants)) {
                    ForEach(event.participants) { participant in
                        Button {
                            toggleParticipant(participant.id)
                        } label: {
                            HStack {
                                Text(
                                    event.displayName(
                                        for: participant.id,
                                        language: language
                                    )
                                )
                                .foregroundStyle(.primary)

                                Spacer()

                                Image(
                                    systemName: part.participantIds.contains(participant.id)
                                        ? "checkmark.circle.fill"
                                        : "circle"
                                )
                                .foregroundStyle(AppTheme.primary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(
            language.planningText(
                existingPart == nil ? .newPart : .editPart
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
        .onAppear {
            if existingPart == nil, let event, part.participantIds.isEmpty {
                part.participantIds = Set(event.participants.map(\.id))
                part.startAt = event.date
                part.endAt = event.endDate
                hasStartAt = true
                hasEndAt = true
            }
        }
        .onChange(of: hasStartAt) { _, enabled in
            if enabled, part.startAt == nil {
                part.startAt = event?.date ?? Date()
            } else if !enabled {
                part.startAt = nil
            }
        }
        .onChange(of: hasEndAt) { _, enabled in
            if enabled, part.endAt == nil {
                part.endAt = event?.endDate ?? part.startAt ?? Date()
            } else if !enabled {
                part.endAt = nil
            }
        }
    }

    private var startBinding: Binding<Date> {
        Binding(
            get: { part.startAt ?? event?.date ?? Date() },
            set: {
                part.startAt = $0
                if let endAt = part.endAt, endAt < $0 {
                    part.endAt = $0
                }
            }
        )
    }

    private var endBinding: Binding<Date> {
        Binding(
            get: { part.endAt ?? event?.endDate ?? part.startAt ?? Date() },
            set: { part.endAt = $0 }
        )
    }

    private func toggleParticipant(_ participantId: UUID) {
        if part.participantIds.contains(participantId) {
            part.participantIds.remove(participantId)
        } else {
            part.participantIds.insert(participantId)
        }
    }

    private func save() {
        part.title = part.title.trimmingCharacters(in: .whitespacesAndNewlines)
        part.location = part.location.trimmingCharacters(in: .whitespacesAndNewlines)
        let saved = existingPart == nil
            ? viewModel.addEventPart(part, to: eventId)
            : viewModel.updateEventPart(part, in: eventId)

        if saved { dismiss() }
    }
}
