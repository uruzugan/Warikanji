import SwiftUI

struct EventTimelineView: View {
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
                            language.planningText(.timelineDescription),
                            systemImage: "clock.fill"
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }

                    Section(language.planningText(.timeline)) {
                        if event.planning.timelineEntries.isEmpty {
                            ContentUnavailableView(
                                language.planningText(.noTimelineEntries),
                                systemImage: "clock"
                            )
                        } else {
                            ForEach(event.planning.timelineEntries) { entry in
                                NavigationLink {
                                    EventTimelineEntryEditView(
                                        eventId: eventId,
                                        existingEntry: entry
                                    )
                                } label: {
                                    timelineRow(entry, event: event)
                                }
                            }
                            .onDelete { offsets in
                                viewModel.deleteTimelineEntries(
                                    at: offsets,
                                    from: eventId
                                )
                            }
                        }
                    }
                }
            } else {
                ContentUnavailableView(
                    language.planningText(.noTimelineEntries),
                    systemImage: "clock"
                )
            }
        }
        .navigationTitle(language.planningText(.timeline))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !isLocked {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        EventTimelineEntryEditView(
                            eventId: eventId,
                            existingEntry: nil
                        )
                    } label: {
                        Label(
                            language.planningText(.addTimelineEntry),
                            systemImage: "plus"
                        )
                    }
                }
            }
        }
    }

    private func timelineRow(
        _ entry: EventTimelineEntry,
        event: Event
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 2) {
                Text(entry.startAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption.bold().monospacedDigit())
                if entry.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.success)
                }
            }
            .frame(width: 56)

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.title)
                    .font(.body.bold())
                    .strikethrough(entry.isCompleted)

                if !entry.location.isEmpty {
                    Label(entry.location, systemImage: "mappin")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                let names = entry.assigneeParticipantIds.map {
                    event.displayName(for: $0, language: language)
                }.sorted()
                if !names.isEmpty {
                    Text(names.joined(separator: ", "))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 3)
    }
}

private struct EventTimelineEntryEditView: View {
    @EnvironmentObject private var viewModel: EventViewModel
    @EnvironmentObject private var profileStore: ProfileStore
    @Environment(\.dismiss) private var dismiss

    let eventId: UUID
    let existingEntry: EventTimelineEntry?

    @State private var entry: EventTimelineEntry
    @State private var hasEndTime: Bool
    @State private var hasLoaded = false

    init(eventId: UUID, existingEntry: EventTimelineEntry?) {
        self.eventId = eventId
        self.existingEntry = existingEntry
        let initial = existingEntry ?? EventTimelineEntry(
            title: "",
            startAt: Date()
        )
        _entry = State(initialValue: initial)
        _hasEndTime = State(initialValue: initial.endAt != nil)
    }

    private var event: Event? { viewModel.event(for: eventId) }
    private var language: AppLanguage { profileStore.activeLanguage }
    private var isLocked: Bool { !viewModel.canEdit(eventId) }
    private var isSaveDisabled: Bool {
        entry.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Form {
            Section(language.planningText(.timeline)) {
                TextField(
                    language.planningText(.timelineTitle),
                    text: $entry.title
                )
                DatePicker(
                    language.planningText(.startTime),
                    selection: $entry.startAt,
                    displayedComponents: [.date, .hourAndMinute]
                )
                Toggle(language.planningText(.endTime), isOn: $hasEndTime)
                if hasEndTime {
                    DatePicker(
                        language.planningText(.endTime),
                        selection: endTimeBinding,
                        in: entry.startAt...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }
                TextField(
                    language.planningText(.location),
                    text: $entry.location
                )
                Toggle(
                    language.planningText(.completedTimeline),
                    isOn: $entry.isCompleted
                )
            }

            if let event, !event.planning.parts.isEmpty {
                Section(language.planningText(.eventParts)) {
                    Picker(
                        language.planningText(.eventParts),
                        selection: $entry.partId
                    ) {
                        Text(language.planningText(.optional)).tag(UUID?.none)
                        ForEach(event.planning.parts) { part in
                            Text(part.title).tag(Optional(part.id))
                        }
                    }
                }
            }

            if let event {
                Section(language.planningText(.assignees)) {
                    ForEach(event.participants) { participant in
                        Toggle(
                            event.displayName(
                                for: participant.id,
                                language: language
                            ),
                            isOn: assigneeBinding(participant.id)
                        )
                    }
                }
            }

            Section(language.planningText(.notes)) {
                TextField(
                    language.planningText(.notes),
                    text: $entry.notes,
                    axis: .vertical
                )
                .lineLimit(2...5)
                Toggle(
                    language.planningText(.privateTask),
                    isOn: $entry.isPrivate
                )
            }
        }
        .navigationTitle(
            existingEntry == nil
                ? language.planningText(.newTimelineEntry)
                : language.planningText(.editTimelineEntry)
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
        .onAppear(perform: loadIfNeeded)
        .onChange(of: hasEndTime) { _, enabled in
            if enabled, entry.endAt == nil {
                entry.endAt = max(entry.startAt, entry.startAt.addingTimeInterval(3_600))
            } else if !enabled {
                entry.endAt = nil
            }
        }
        .onChange(of: entry.startAt) { _, startAt in
            if let endAt = entry.endAt, endAt < startAt {
                entry.endAt = startAt
            }
        }
    }

    private var endTimeBinding: Binding<Date> {
        Binding(
            get: { entry.endAt ?? entry.startAt },
            set: { entry.endAt = $0 }
        )
    }

    private func assigneeBinding(_ participantId: UUID) -> Binding<Bool> {
        Binding(
            get: { entry.assigneeParticipantIds.contains(participantId) },
            set: { isAssigned in
                if isAssigned {
                    entry.assigneeParticipantIds.insert(participantId)
                } else {
                    entry.assigneeParticipantIds.remove(participantId)
                }
            }
        )
    }

    private func loadIfNeeded() {
        guard !hasLoaded else { return }
        if existingEntry == nil {
            entry.startAt = event?.date ?? Date()
        }
        hasLoaded = true
    }

    private func save() {
        if viewModel.saveTimelineEntry(entry, in: eventId) {
            dismiss()
        }
    }
}
