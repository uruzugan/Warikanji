import SwiftUI

struct SeatingPlanView: View {
    @EnvironmentObject private var viewModel: EventViewModel
    @EnvironmentObject private var profileStore: ProfileStore

    let eventId: UUID

    @State private var showRandomizeConfirmation = false

    private var event: Event? { viewModel.event(for: eventId) }
    private var language: AppLanguage { profileStore.activeLanguage }
    private var isLocked: Bool { !viewModel.canEdit(eventId) }

    var body: some View {
        Group {
            if let event {
                List {
                    Section {
                        Label(
                            language.planningText(.seatingDescription),
                            systemImage: "chair.lounge.fill"
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }

                    Section {
                        Button {
                            showRandomizeConfirmation = true
                        } label: {
                            Label(
                                language.planningText(.randomizeSeating),
                                systemImage: "shuffle"
                            )
                        }
                        .disabled(
                            isLocked
                                || event.participants.isEmpty
                                || event.planning.seatingPlan.totalSeatCount
                                    < event.participants.count
                        )

                        if event.planning.seatingPlan.totalSeatCount
                            < event.participants.count {
                            Label(
                                language.planningText(.notEnoughSeats),
                                systemImage: "exclamationmark.triangle.fill"
                            )
                            .font(.caption)
                            .foregroundStyle(AppTheme.warning)
                        }
                    }

                    Section(language.planningText(.seatingTitle)) {
                        if event.planning.seatingPlan.tables.isEmpty {
                            ContentUnavailableView(
                                language.planningText(.noTables),
                                systemImage: "chair.lounge"
                            )
                        } else {
                            ForEach(event.planning.seatingPlan.tables) { table in
                                NavigationLink {
                                    SeatingTableView(
                                        eventId: eventId,
                                        tableId: table.id
                                    )
                                } label: {
                                    tableRow(table)
                                }
                                .deleteDisabled(isLocked)
                            }
                            .onDelete { offsets in
                                viewModel.deleteSeatingTables(
                                    at: offsets,
                                    from: eventId
                                )
                            }
                        }
                    }

                    let unassigned = unassignedParticipants(event)
                    if !unassigned.isEmpty {
                        Section(language.planningText(.unassignedParticipants)) {
                            ForEach(unassigned) { participant in
                                Text(
                                    event.displayName(
                                        for: participant.id,
                                        language: language
                                    )
                                )
                            }
                        }
                    }
                }
            } else {
                ContentUnavailableView(
                    language.planningText(.seatingTitle),
                    systemImage: "chair.lounge"
                )
            }
        }
        .navigationTitle(language.planningText(.seatingTitle))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !isLocked, event != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SeatingTableEditView(
                            eventId: eventId,
                            existingTable: nil
                        )
                    } label: {
                        Label(
                            language.planningText(.addTable),
                            systemImage: "plus"
                        )
                    }
                }
            }
        }
        .alert(
            language.planningText(.randomizeSeating),
            isPresented: $showRandomizeConfirmation
        ) {
            Button(language.planningText(.cancel), role: .cancel) {}
            Button(language.planningText(.randomizeSeating)) {
                viewModel.randomizeSeating(in: eventId)
            }
        } message: {
            Text(language.planningText(.randomizeMessage))
        }
    }

    private func tableRow(_ table: SeatingTable) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(table.name)
                .font(.body.bold())
            Text(
                "\(language.planningText(.assignedSeats)) "
                    + "\(table.assignments.count) / \(table.seatCount)"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 3)
    }

    private func unassignedParticipants(_ event: Event) -> [EventParticipant] {
        let assigned = event.planning.seatingPlan.assignedParticipantIds
        return event.participants.filter { !assigned.contains($0.id) }
    }
}

private struct SeatingTableView: View {
    @EnvironmentObject private var viewModel: EventViewModel
    @EnvironmentObject private var profileStore: ProfileStore
    @Environment(\.dismiss) private var dismiss

    let eventId: UUID
    let tableId: UUID

    @State private var assignments: [Int: UUID] = [:]
    @State private var hasLoaded = false

    private var event: Event? { viewModel.event(for: eventId) }
    private var table: SeatingTable? {
        event?.planning.seatingPlan.tables.first { $0.id == tableId }
    }
    private var language: AppLanguage { profileStore.activeLanguage }
    private var isLocked: Bool { !viewModel.canEdit(eventId) }

    var body: some View {
        Group {
            if let event, let table {
                Form {
                    Section(language.planningText(.manageSeats)) {
                        ForEach(1...table.seatCount, id: \.self) { seatNumber in
                            Picker(
                                "\(language.planningText(.seatNumber)) \(seatNumber)",
                                selection: assignmentBinding(seatNumber)
                            ) {
                                Text(language.planningText(.unanswered)).tag(UUID?.none)
                                ForEach(
                                    availableParticipants(
                                        for: seatNumber,
                                        event: event
                                    )
                                ) { participant in
                                    Text(
                                        event.displayName(
                                            for: participant.id,
                                            language: language
                                        )
                                    )
                                    .tag(Optional(participant.id))
                                }
                            }
                        }
                    }
                }
            } else {
                ContentUnavailableView(
                    language.planningText(.seatingTitle),
                    systemImage: "chair.lounge"
                )
            }
        }
        .navigationTitle(table?.name ?? language.planningText(.seatingTitle))
        .navigationBarTitleDisplayMode(.inline)
        .disabled(isLocked)
        .toolbar {
            if !isLocked, let table {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    NavigationLink {
                        SeatingTableEditView(
                            eventId: eventId,
                            existingTable: table
                        )
                    } label: {
                        Label(
                            language.planningText(.editTable),
                            systemImage: "pencil"
                        )
                    }

                    Button(language.planningText(.save), action: save)
                }
            }
        }
        .onAppear(perform: loadIfNeeded)
    }

    private func assignmentBinding(_ seatNumber: Int) -> Binding<UUID?> {
        Binding(
            get: { assignments[seatNumber] },
            set: { participantId in
                if let participantId {
                    let duplicateSeats = assignments.keys.filter {
                        assignments[$0] == participantId
                    }
                    for key in duplicateSeats {
                        assignments.removeValue(forKey: key)
                    }
                    assignments[seatNumber] = participantId
                } else {
                    assignments.removeValue(forKey: seatNumber)
                }
            }
        )
    }

    private func availableParticipants(
        for seatNumber: Int,
        event: Event
    ) -> [EventParticipant] {
        let current = assignments[seatNumber]
        let assignedElsewhere = Set(
            event.planning.seatingPlan.tables
                .filter { $0.id != tableId }
                .flatMap(\.assignments)
                .map(\.participantId)
        )
        let assignedAtThisTable = Set(
            assignments.compactMap { key, value in
                key == seatNumber ? nil : value
            }
        )
        return event.participants.filter {
            $0.id == current
                || (!assignedElsewhere.contains($0.id)
                    && !assignedAtThisTable.contains($0.id))
        }
    }

    private func loadIfNeeded() {
        guard !hasLoaded, let table else { return }
        for assignment in table.assignments
        where assignments[assignment.seatNumber] == nil {
            assignments[assignment.seatNumber] = assignment.participantId
        }
        hasLoaded = true
    }

    private func save() {
        let values = assignments.map {
            SeatingAssignment(seatNumber: $0.key, participantId: $0.value)
        }
        if viewModel.saveSeatingAssignments(
            values,
            for: tableId,
            in: eventId
        ) {
            dismiss()
        }
    }
}

private struct SeatingTableEditView: View {
    @EnvironmentObject private var viewModel: EventViewModel
    @EnvironmentObject private var profileStore: ProfileStore
    @Environment(\.dismiss) private var dismiss

    let eventId: UUID
    let existingTable: SeatingTable?

    @State private var table: SeatingTable

    init(eventId: UUID, existingTable: SeatingTable?) {
        self.eventId = eventId
        self.existingTable = existingTable
        _table = State(
            initialValue: existingTable ?? SeatingTable(name: "")
        )
    }

    private var language: AppLanguage { profileStore.activeLanguage }
    private var isLocked: Bool { !viewModel.canEdit(eventId) }
    private var isSaveDisabled: Bool {
        table.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Form {
            Section(language.planningText(.seatingTitle)) {
                TextField(
                    language.planningText(.tableName),
                    text: $table.name
                )
                Stepper(
                    "\(language.planningText(.seatCount)): \(table.seatCount)",
                    value: $table.seatCount,
                    in: 1...100
                )
            }
        }
        .navigationTitle(
            language.planningText(
                existingTable == nil ? .newTable : .editTable
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
        if viewModel.saveSeatingTable(table, in: eventId) {
            dismiss()
        }
    }
}
