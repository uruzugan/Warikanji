import SwiftUI

struct EventTaskListView: View {
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
                            language.planningText(.tasksDescription),
                            systemImage: "checklist"
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }

                    Section(language.planningText(.tasks)) {
                        if event.planning.tasks.isEmpty {
                            ContentUnavailableView(
                                language.planningText(.noTasks),
                                systemImage: "checklist"
                            )
                        } else {
                            ForEach(event.planning.tasks) { task in
                                NavigationLink {
                                    EventTaskEditView(
                                        eventId: eventId,
                                        existingTask: task
                                    )
                                } label: {
                                    taskRow(task, event: event)
                                }
                                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                    if !isLocked {
                                        Button {
                                            let nextStatus: EventTaskStatus = task.status == .completed
                                                ? .pending
                                                : .completed
                                            viewModel.setEventTaskStatus(
                                                nextStatus,
                                                taskId: task.id,
                                                in: eventId
                                            )
                                        } label: {
                                            Label(
                                                task.status == .completed
                                                    ? language.planningText(.pending)
                                                    : language.planningText(.completed),
                                                systemImage: task.status == .completed
                                                    ? "arrow.uturn.backward"
                                                    : "checkmark"
                                            )
                                        }
                                        .tint(task.status == .completed ? AppTheme.warning : AppTheme.success)
                                    }
                                }
                            }
                            .onDelete { offsets in
                                viewModel.deleteEventTasks(
                                    at: offsets,
                                    from: eventId
                                )
                            }
                        }
                    }
                }
            } else {
                ContentUnavailableView(
                    language.planningText(.tasks),
                    systemImage: "checklist"
                )
            }
        }
        .navigationTitle(language.planningText(.tasks))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !isLocked, event != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        EventTaskEditView(
                            eventId: eventId,
                            existingTask: nil
                        )
                    } label: {
                        Label(
                            language.planningText(.addTask),
                            systemImage: "plus"
                        )
                    }
                }
            }
        }
    }

    private func taskRow(_ task: EventTask, event: Event) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: statusSymbol(task.status))
                .foregroundStyle(statusColor(task.status))
                .font(.title3)

            VStack(alignment: .leading, spacing: 5) {
                Text(task.title)
                    .font(.body.bold())
                    .strikethrough(task.status == .completed)

                HStack(spacing: 8) {
                    Text(task.status.displayName(for: language))

                    if let dueAt = task.dueAt {
                        Label(
                            dueAt.formatted(date: .abbreviated, time: .shortened),
                            systemImage: "clock"
                        )
                        .foregroundStyle(
                            dueAt < Date() && task.status != .completed
                                ? AppTheme.danger
                                : .secondary
                        )
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                if !task.assigneeParticipantIds.isEmpty {
                    Text(assigneeText(task, event: event))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 3)
    }

    private func assigneeText(_ task: EventTask, event: Event) -> String {
        task.assigneeParticipantIds
            .map { event.displayName(for: $0, language: language) }
            .sorted()
            .joined(separator: ", ")
    }

    private func statusSymbol(_ status: EventTaskStatus) -> String {
        switch status {
        case .pending: return "circle"
        case .inProgress: return "circle.dotted"
        case .completed: return "checkmark.circle.fill"
        }
    }

    private func statusColor(_ status: EventTaskStatus) -> Color {
        switch status {
        case .pending: return .secondary
        case .inProgress: return AppTheme.warning
        case .completed: return AppTheme.success
        }
    }
}

private struct EventTaskEditView: View {
    @EnvironmentObject private var viewModel: EventViewModel
    @EnvironmentObject private var profileStore: ProfileStore
    @Environment(\.dismiss) private var dismiss

    let eventId: UUID
    let existingTask: EventTask?

    @State private var task: EventTask
    @State private var hasDueDate: Bool

    init(eventId: UUID, existingTask: EventTask?) {
        self.eventId = eventId
        self.existingTask = existingTask
        let initial = existingTask ?? EventTask(title: "")
        _task = State(initialValue: initial)
        _hasDueDate = State(initialValue: initial.dueAt != nil)
    }

    private var event: Event? { viewModel.event(for: eventId) }
    private var language: AppLanguage { profileStore.activeLanguage }
    private var isSaveDisabled: Bool {
        task.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Form {
            Section(language.planningText(.taskTitle)) {
                TextField(
                    language.planningText(.taskTitle),
                    text: $task.title
                )
                TextField(
                    language.planningText(.notes),
                    text: $task.notes,
                    axis: .vertical
                )
                .lineLimit(2...5)
            }

            Section(language.planningText(.status)) {
                Picker(
                    language.planningText(.status),
                    selection: $task.status
                ) {
                    ForEach(EventTaskStatus.allCases, id: \.self) { status in
                        Text(status.displayName(for: language)).tag(status)
                    }
                }

                Toggle(
                    language.planningText(.dueDate),
                    isOn: $hasDueDate
                )
                if hasDueDate {
                    DatePicker(
                        language.planningText(.dueDate),
                        selection: dueDateBinding,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }

                Toggle(
                    language.planningText(.privateTask),
                    isOn: $task.isPrivate
                )
            }

            if let event,
               event.planning.features.contains(.multipleParts),
               !event.planning.parts.isEmpty {
                Section(language.planningText(.eventParts)) {
                    Picker(
                        language.planningText(.eventParts),
                        selection: $task.partId
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
                        Button {
                            toggleAssignee(participant.id)
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
                                    systemName: task.assigneeParticipantIds.contains(participant.id)
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
                existingTask == nil ? .newTask : .editTask
            )
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(language.planningText(.save), action: save)
                    .disabled(isSaveDisabled)
            }
        }
        .onChange(of: hasDueDate) { _, enabled in
            if enabled, task.dueAt == nil {
                task.dueAt = event?.date ?? Date()
            } else if !enabled {
                task.dueAt = nil
            }
        }
    }

    private var dueDateBinding: Binding<Date> {
        Binding(
            get: { task.dueAt ?? event?.date ?? Date() },
            set: { task.dueAt = $0 }
        )
    }

    private func toggleAssignee(_ participantId: UUID) {
        if task.assigneeParticipantIds.contains(participantId) {
            task.assigneeParticipantIds.remove(participantId)
        } else {
            task.assigneeParticipantIds.insert(participantId)
        }
    }

    private func save() {
        task.title = task.title.trimmingCharacters(in: .whitespacesAndNewlines)
        task.notes = task.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let saved = existingTask == nil
            ? viewModel.addEventTask(task, to: eventId)
            : viewModel.updateEventTask(task, in: eventId)

        if saved { dismiss() }
    }
}
