import SwiftUI

struct AttendanceManagementView: View {
    @EnvironmentObject private var viewModel: EventViewModel
    @EnvironmentObject private var profileStore: ProfileStore

    let eventId: UUID

    private var event: Event? { viewModel.event(for: eventId) }
    private var language: AppLanguage { profileStore.activeLanguage }

    var body: some View {
        Group {
            if let event {
                List {
                    Section {
                        attendanceSummary(event)
                    }

                    Section(language.planningText(.participants)) {
                        ForEach(event.participants) { participant in
                            NavigationLink {
                                AttendanceResponseEditView(
                                    eventId: eventId,
                                    participantId: participant.id
                                )
                            } label: {
                                participantRow(participant, event: event)
                            }
                        }
                    }
                }
            } else {
                ContentUnavailableView(
                    language.planningText(.attendance),
                    systemImage: "person.2.slash"
                )
            }
        }
        .navigationTitle(language.planningText(.attendance))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func attendanceSummary(_ event: Event) -> some View {
        let counts = Dictionary(
            grouping: event.participants,
            by: { status(for: $0.id, event: event) }
        ).mapValues(\.count)

        return VStack(alignment: .leading, spacing: 10) {
            Text(language.planningText(.attendanceSummary))
                .font(.subheadline.bold())

            HStack(spacing: 8) {
                statusCount(.attending, count: counts[.attending, default: 0])
                statusCount(.maybe, count: counts[.maybe, default: 0])
                statusCount(.notAttending, count: counts[.notAttending, default: 0])
                statusCount(.unanswered, count: counts[.unanswered, default: 0])
            }
        }
        .padding(.vertical, 4)
    }

    private func statusCount(_ status: AttendanceStatus, count: Int) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.headline.monospacedDigit())
                .foregroundStyle(statusColor(status))

            Text(status.displayName(for: language))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    private func participantRow(
        _ participant: EventParticipant,
        event: Event
    ) -> some View {
        let response = event.planning.participantResponses.first {
            $0.participantId == participant.id
        }
        let status = response?.attendance ?? .unanswered

        return HStack(spacing: 12) {
            Image(systemName: statusSymbol(status))
                .foregroundStyle(statusColor(status))
                .frame(width: 34, height: 34)
                .background(statusColor(status).opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(event.displayName(for: participant.id, language: language))
                    .font(.body)

                HStack(spacing: 8) {
                    Text(status.displayName(for: language))

                    if let companionCount = response?.companions.count,
                       companionCount > 0 {
                        Text("+\(companionCount)")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }

    private func status(for participantId: UUID, event: Event) -> AttendanceStatus {
        event.planning.participantResponses.first {
            $0.participantId == participantId
        }?.attendance ?? .unanswered
    }

    private func statusColor(_ status: AttendanceStatus) -> Color {
        switch status {
        case .attending: return AppTheme.success
        case .notAttending: return AppTheme.danger
        case .maybe: return AppTheme.warning
        case .unanswered: return .secondary
        }
    }

    private func statusSymbol(_ status: AttendanceStatus) -> String {
        switch status {
        case .attending: return "checkmark.circle.fill"
        case .notAttending: return "xmark.circle.fill"
        case .maybe: return "questionmark.circle.fill"
        case .unanswered: return "ellipsis.circle.fill"
        }
    }
}

private struct AttendanceResponseEditView: View {
    @EnvironmentObject private var viewModel: EventViewModel
    @EnvironmentObject private var profileStore: ProfileStore
    @Environment(\.dismiss) private var dismiss

    let eventId: UUID
    let participantId: UUID

    @State private var response: ParticipantResponse
    @State private var hasLoaded = false
    @State private var includesAttendingFrom = false
    @State private var includesLeavingAt = false

    init(eventId: UUID, participantId: UUID) {
        self.eventId = eventId
        self.participantId = participantId
        _response = State(
            initialValue: ParticipantResponse(participantId: participantId)
        )
    }

    private var event: Event? { viewModel.event(for: eventId) }
    private var language: AppLanguage { profileStore.activeLanguage }
    private var isLocked: Bool { !viewModel.canEdit(eventId) }

    var body: some View {
        Form {
            if let event {
                Section(language.planningText(.attendance)) {
                    Picker(
                        language.planningText(.status),
                        selection: $response.attendance
                    ) {
                        ForEach(AttendanceStatus.allCases, id: \.self) { status in
                            Text(status.displayName(for: language)).tag(status)
                        }
                    }
                }

                if event.planning.features.contains(.multipleParts),
                   !event.planning.parts.isEmpty {
                    Section(language.planningText(.partAttendance)) {
                        ForEach(event.planning.parts.sorted(by: partOrder)) { part in
                            Picker(
                                part.title,
                                selection: partAttendanceBinding(part.id)
                            ) {
                                ForEach(AttendanceStatus.allCases, id: \.self) { status in
                                    Text(status.displayName(for: language)).tag(status)
                                }
                            }
                        }
                    }
                }

                Section(language.planningText(.responseDetails)) {
                    Toggle(
                        language.planningText(.attendingFrom),
                        isOn: $includesAttendingFrom
                    )
                    if includesAttendingFrom {
                        DatePicker(
                            language.planningText(.attendingFrom),
                            selection: attendingFromBinding,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }

                    Toggle(
                        language.planningText(.leavingAt),
                        isOn: $includesLeavingAt
                    )
                    if includesLeavingAt {
                        DatePicker(
                            language.planningText(.leavingAt),
                            selection: leavingAtBinding,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }
                }

                if event.planning.features.contains(.meetingAndArrival) {
                    Section(language.planningText(.arrivalStatus)) {
                        Picker(
                            language.planningText(.arrivalStatus),
                            selection: $response.arrivalStatus
                        ) {
                            ForEach(ArrivalStatus.allCases, id: \.self) { status in
                                Text(status.displayName(for: language)).tag(status)
                            }
                        }
                    }
                }

                Section(language.planningText(.companions)) {
                    ForEach($response.companions) { $companion in
                        VStack(alignment: .leading, spacing: 8) {
                            TextField(
                                language.planningText(.companionName),
                                text: $companion.name
                            )

                            Picker(
                                language.planningText(.status),
                                selection: $companion.category
                            ) {
                                ForEach(ParticipantCategory.allCases, id: \.self) { category in
                                    Text(category.displayName(for: language)).tag(category)
                                }
                            }

                            Button(
                                language.planningText(.delete),
                                role: .destructive
                            ) {
                                response.companions.removeAll { $0.id == companion.id }
                            }
                        }
                    }

                    Button {
                        response.companions.append(EventCompanion())
                    } label: {
                        Label(
                            language.planningText(.addCompanion),
                            systemImage: "person.badge.plus"
                        )
                    }
                }

                if event.planning.features.contains(.dietaryNeeds) {
                    Section(language.planningText(.dietaryNotes)) {
                        TextField(
                            language.planningText(.dietaryPlaceholder),
                            text: $response.dietaryNotes,
                            axis: .vertical
                        )
                        .lineLimit(3...6)
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
                }
            }
        }
        .onAppear(perform: loadIfNeeded)
        .onChange(of: includesAttendingFrom) { _, enabled in
            if enabled, response.attendingFrom == nil {
                response.attendingFrom = event?.date ?? Date()
            } else if !enabled {
                response.attendingFrom = nil
            }
        }
        .onChange(of: includesLeavingAt) { _, enabled in
            if enabled, response.leavingAt == nil {
                response.leavingAt = event?.endDate ?? Date()
            } else if !enabled {
                response.leavingAt = nil
            }
        }
    }

    private var participantName: String {
        event?.displayName(for: participantId, language: language)
            ?? language.planningText(.attendance)
    }

    private var attendingFromBinding: Binding<Date> {
        Binding(
            get: { response.attendingFrom ?? event?.date ?? Date() },
            set: { response.attendingFrom = $0 }
        )
    }

    private var leavingAtBinding: Binding<Date> {
        Binding(
            get: { response.leavingAt ?? event?.endDate ?? Date() },
            set: { response.leavingAt = $0 }
        )
    }

    private func partAttendanceBinding(_ partId: UUID) -> Binding<AttendanceStatus> {
        Binding(
            get: {
                response.partAttendance.first { $0.partId == partId }?.status
                    ?? .unanswered
            },
            set: { status in
                if let index = response.partAttendance.firstIndex(where: {
                    $0.partId == partId
                }) {
                    response.partAttendance[index].status = status
                } else {
                    response.partAttendance.append(
                        PartAttendanceResponse(partId: partId, status: status)
                    )
                }
            }
        )
    }

    private func partOrder(_ lhs: EventPart, _ rhs: EventPart) -> Bool {
        if lhs.order == rhs.order { return lhs.id.uuidString < rhs.id.uuidString }
        return lhs.order < rhs.order
    }

    private func loadIfNeeded() {
        guard !hasLoaded else { return }
        if let saved = event?.planning.participantResponses.first(where: {
            $0.participantId == participantId
        }) {
            response = saved
        }
        includesAttendingFrom = response.attendingFrom != nil
        includesLeavingAt = response.leavingAt != nil
        hasLoaded = true
    }

    private func save() {
        response.companions = response.companions.map {
            var companion = $0
            companion.name = companion.name.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            return companion
        }
        response.dietaryNotes = response.dietaryNotes.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        if viewModel.saveParticipantResponse(response, in: eventId) {
            dismiss()
        }
    }
}
