import SwiftUI

struct EventChecklistView: View {
    @EnvironmentObject private var viewModel: EventViewModel
    @EnvironmentObject private var profileStore: ProfileStore

    let eventId: UUID

    private var event: Event? { viewModel.event(for: eventId) }
    private var language: AppLanguage { profileStore.activeLanguage }

    var body: some View {
        List {
            if let event {
                Section {
                    NavigationLink {
                        EventTaskListView(eventId: eventId)
                    } label: {
                        row(
                            title: language.planningText(.tasks),
                            detail: taskSummary(event),
                            symbol: "checklist",
                            color: AppTheme.primary
                        )
                    }

                    NavigationLink {
                        EventPreparationItemListView(eventId: eventId)
                    } label: {
                        row(
                            title: language.planningText(.preparationItems),
                            detail: itemSummary(event),
                            symbol: "shippingbox.fill",
                            color: AppTheme.warning
                        )
                    }
                }
            }
        }
        .navigationTitle(language.planningText(.tasks))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(
        title: String,
        detail: String,
        symbol: String,
        color: Color
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(color)
                .frame(width: 38, height: 38)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 11))
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.body.bold())
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func taskSummary(_ event: Event) -> String {
        let incomplete = event.planning.tasks.filter { $0.status != .completed }.count
        return summary(incomplete: incomplete, total: event.planning.tasks.count)
    }

    private func itemSummary(_ event: Event) -> String {
        let incomplete = event.planning.preparationItems.filter {
            $0.status != .ready
        }.count
        return summary(
            incomplete: incomplete,
            total: event.planning.preparationItems.count
        )
    }

    private func summary(incomplete: Int, total: Int) -> String {
        switch language {
        case .japanese: return "未完了 \(incomplete) / 全\(total)件"
        case .english: return "\(incomplete) incomplete · \(total) total"
        case .simplifiedChinese: return "未完成 \(incomplete) / 共\(total)项"
        case .traditionalChinese: return "未完成 \(incomplete) / 共\(total)項"
        case .korean: return "미완료 \(incomplete) / 총 \(total)개"
        case .spanish: return "\(incomplete) pendientes · \(total) en total"
        case .portuguese: return "\(incomplete) pendentes · \(total) no total"
        }
    }
}

struct EventPreparationItemListView: View {
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
                            language.planningText(.itemsDescription),
                            systemImage: "shippingbox.fill"
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }

                    Section(language.planningText(.preparationItems)) {
                        if event.planning.preparationItems.isEmpty {
                            ContentUnavailableView(
                                language.planningText(.noItems),
                                systemImage: "shippingbox"
                            )
                        } else {
                            ForEach(event.planning.preparationItems) { item in
                                NavigationLink {
                                    EventPreparationItemEditView(
                                        eventId: eventId,
                                        existingItem: item
                                    )
                                } label: {
                                    itemRow(item, event: event)
                                }
                            }
                            .onDelete { offsets in
                                viewModel.deletePreparationItems(
                                    at: offsets,
                                    from: eventId
                                )
                            }
                        }
                    }
                }
            } else {
                ContentUnavailableView(
                    language.planningText(.noItems),
                    systemImage: "shippingbox"
                )
            }
        }
        .navigationTitle(language.planningText(.preparationItems))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !isLocked {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        EventPreparationItemEditView(
                            eventId: eventId,
                            existingItem: nil
                        )
                    } label: {
                        Label(
                            language.planningText(.addItem),
                            systemImage: "plus"
                        )
                    }
                }
            }
        }
    }

    private func itemRow(
        _ item: EventPreparationItem,
        event: Event
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: statusSymbol(item.status))
                .foregroundStyle(statusColor(item.status))
                .font(.title3)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.body.bold())
                Text("\(language.planningText(.quantity)): \(item.quantity)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                let names = item.assigneeParticipantIds.map {
                    event.displayName(for: $0, language: language)
                }.sorted()
                if !names.isEmpty {
                    Text(names.joined(separator: ", "))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
            Text(item.status.displayName(for: language))
                .font(.caption.bold())
                .foregroundStyle(statusColor(item.status))
        }
        .padding(.vertical, 3)
    }

    private func statusSymbol(_ status: PreparationItemStatus) -> String {
        switch status {
        case .needed: return "circle"
        case .assigned: return "person.crop.circle.badge.checkmark"
        case .ready: return "checkmark.circle.fill"
        }
    }

    private func statusColor(_ status: PreparationItemStatus) -> Color {
        switch status {
        case .needed: return AppTheme.danger
        case .assigned: return AppTheme.warning
        case .ready: return AppTheme.success
        }
    }
}

private struct EventPreparationItemEditView: View {
    @EnvironmentObject private var viewModel: EventViewModel
    @EnvironmentObject private var profileStore: ProfileStore
    @Environment(\.dismiss) private var dismiss

    let eventId: UUID
    let existingItem: EventPreparationItem?

    @State private var item: EventPreparationItem

    init(eventId: UUID, existingItem: EventPreparationItem?) {
        self.eventId = eventId
        self.existingItem = existingItem
        _item = State(initialValue: existingItem ?? EventPreparationItem(title: ""))
    }

    private var event: Event? { viewModel.event(for: eventId) }
    private var language: AppLanguage { profileStore.activeLanguage }
    private var isLocked: Bool { !viewModel.canEdit(eventId) }
    private var isSaveDisabled: Bool {
        item.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Form {
            Section(language.planningText(.preparationItems)) {
                TextField(
                    language.planningText(.itemTitle),
                    text: $item.title
                )
                Stepper(
                    "\(language.planningText(.quantity)): \(item.quantity)",
                    value: $item.quantity,
                    in: 1...10_000
                )
                Picker(
                    language.planningText(.status),
                    selection: $item.status
                ) {
                    ForEach(PreparationItemStatus.allCases, id: \.self) { status in
                        Text(status.displayName(for: language)).tag(status)
                    }
                }
            }

            if let event, !event.planning.parts.isEmpty {
                Section(language.planningText(.eventParts)) {
                    Picker(
                        language.planningText(.eventParts),
                        selection: $item.partId
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
                    text: $item.notes,
                    axis: .vertical
                )
                .lineLimit(2...5)
                Toggle(
                    language.planningText(.privateTask),
                    isOn: $item.isPrivate
                )
            }
        }
        .navigationTitle(
            existingItem == nil
                ? language.planningText(.newItem)
                : language.planningText(.editItem)
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

    private func assigneeBinding(_ participantId: UUID) -> Binding<Bool> {
        Binding(
            get: { item.assigneeParticipantIds.contains(participantId) },
            set: { isAssigned in
                if isAssigned {
                    item.assigneeParticipantIds.insert(participantId)
                    if item.status == .needed { item.status = .assigned }
                } else {
                    item.assigneeParticipantIds.remove(participantId)
                    if item.assigneeParticipantIds.isEmpty && item.status == .assigned {
                        item.status = .needed
                    }
                }
            }
        )
    }

    private func save() {
        if viewModel.savePreparationItem(item, in: eventId) {
            dismiss()
        }
    }
}
