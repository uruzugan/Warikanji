import SwiftUI

struct VenuePlanningView: View {
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
                            language.planningText(.venueDescription),
                            systemImage: "mappin.and.ellipse"
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }

                    if event.planning.features.contains(.reservations) {
                        Section(language.planningText(.reservation)) {
                            NavigationLink {
                                ReservationEditView(eventId: eventId)
                            } label: {
                                reservationRow(event)
                            }
                        }
                    }

                    if event.planning.features.contains(.venueCandidates) {
                        Section(language.planningText(.venuePlanning)) {
                            if event.planning.venuePlanning.candidates.isEmpty {
                                ContentUnavailableView(
                                    language.planningText(.noVenues),
                                    systemImage: "mappin.slash"
                                )
                            } else {
                                ForEach(event.planning.venuePlanning.candidates) { candidate in
                                    NavigationLink {
                                        VenueCandidateEditView(
                                            eventId: eventId,
                                            existingCandidate: candidate
                                        )
                                    } label: {
                                        candidateRow(candidate, event: event)
                                    }
                                }
                                .onDelete { offsets in
                                    viewModel.deleteVenueCandidates(
                                        at: offsets,
                                        from: eventId
                                    )
                                }
                            }
                        }
                    }
                }
            } else {
                ContentUnavailableView(
                    language.planningText(.venuePlanning),
                    systemImage: "mappin.slash"
                )
            }
        }
        .navigationTitle(language.planningText(.venuePlanning))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !isLocked,
               event?.planning.features.contains(.venueCandidates) == true {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        VenueCandidateEditView(
                            eventId: eventId,
                            existingCandidate: nil
                        )
                    } label: {
                        Label(
                            language.planningText(.addVenue),
                            systemImage: "plus"
                        )
                    }
                }
            }
        }
    }

    private func reservationRow(_ event: Event) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(reservationColor(event.planning.venuePlanning.reservation?.status))
                .font(.title3)

            VStack(alignment: .leading, spacing: 3) {
                if let reservation = event.planning.venuePlanning.reservation {
                    Text(
                        reservation.venueName.isEmpty
                            ? language.planningText(.reservation)
                            : reservation.venueName
                    )
                    .font(.body.bold())

                    Text(reservation.status.displayName(for: language))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let deadline = reservation.cancellationDeadline {
                        Label(
                            deadline.formatted(date: .abbreviated, time: .shortened),
                            systemImage: "hourglass"
                        )
                        .font(.caption2)
                        .foregroundStyle(deadline < Date() ? AppTheme.danger : .secondary)
                    }
                } else {
                    Text(language.planningText(.reservation))
                        .font(.body.bold())
                    Text(language.planningText(.notFinalized))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func candidateRow(
        _ candidate: VenueCandidate,
        event: Event
    ) -> some View {
        let isSelected = event.planning.venuePlanning.selectedCandidateId == candidate.id
        let counts = Dictionary(grouping: candidate.votes, by: \.choice).mapValues(\.count)
        let unanswered = counts[.unanswered, default: 0]
            + max(event.participants.count - candidate.votes.count, 0)

        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(candidate.name)
                    .font(.body.bold())

                if isSelected {
                    Label(
                        language.planningText(.selected),
                        systemImage: "checkmark.seal.fill"
                    )
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.success)
                }
            }

            if !candidate.location.isEmpty {
                Label(candidate.location, systemImage: "mappin")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !candidate.priceNote.isEmpty {
                Label(candidate.priceNote, systemImage: "banknote")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                choiceCount(.yes, count: counts[.yes, default: 0])
                choiceCount(.maybe, count: counts[.maybe, default: 0])
                choiceCount(.no, count: counts[.no, default: 0])
                choiceCount(.unanswered, count: unanswered)
            }
        }
        .padding(.vertical, 3)
    }

    private func choiceCount(_ choice: CoordinationChoice, count: Int) -> some View {
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

    private func reservationColor(_ status: ReservationStatus?) -> Color {
        switch status {
        case .confirmed: return AppTheme.success
        case .cancelled: return AppTheme.danger
        case .requested: return AppTheme.warning
        case .planned, .none: return AppTheme.primary
        }
    }
}

private struct VenueCandidateEditView: View {
    @EnvironmentObject private var viewModel: EventViewModel
    @EnvironmentObject private var profileStore: ProfileStore
    @Environment(\.dismiss) private var dismiss

    let eventId: UUID
    let existingCandidate: VenueCandidate?

    @State private var candidate: VenueCandidate
    @State private var isSelected = false
    @State private var hasLoaded = false

    init(eventId: UUID, existingCandidate: VenueCandidate?) {
        self.eventId = eventId
        self.existingCandidate = existingCandidate
        _candidate = State(
            initialValue: existingCandidate ?? VenueCandidate(name: "")
        )
    }

    private var event: Event? { viewModel.event(for: eventId) }
    private var language: AppLanguage { profileStore.activeLanguage }
    private var isLocked: Bool { !viewModel.canEdit(eventId) }
    private var isSaveDisabled: Bool {
        candidate.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Form {
            Section(language.planningText(.venueName)) {
                TextField(
                    language.planningText(.venueName),
                    text: $candidate.name
                )
                TextField(
                    language.planningText(.location),
                    text: $candidate.location
                )
                TextField(
                    language.planningText(.webURL),
                    text: $candidate.webURL
                )
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                TextField(
                    language.planningText(.priceNote),
                    text: $candidate.priceNote
                )
                TextField(
                    language.planningText(.notes),
                    text: $candidate.notes,
                    axis: .vertical
                )
                .lineLimit(2...5)
            }

            Section {
                Toggle(
                    language.planningText(.selectVenue),
                    isOn: $isSelected
                )
            }

            if let event {
                Section(language.planningText(.participants)) {
                    ForEach(event.participants) { participant in
                        Picker(
                            event.displayName(
                                for: participant.id,
                                language: language
                            ),
                            selection: voteBinding(participant.id)
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
            existingCandidate == nil
                ? language.planningText(.addVenue)
                : language.planningText(.venueName)
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
    }

    private func voteBinding(_ participantId: UUID) -> Binding<CoordinationChoice> {
        Binding(
            get: {
                candidate.votes.first {
                    $0.participantId == participantId
                }?.choice ?? .unanswered
            },
            set: { choice in
                if let index = candidate.votes.firstIndex(where: {
                    $0.participantId == participantId
                }) {
                    candidate.votes[index].choice = choice
                } else {
                    candidate.votes.append(
                        VenueVote(participantId: participantId, choice: choice)
                    )
                }
            }
        )
    }

    private func loadIfNeeded() {
        guard !hasLoaded else { return }
        isSelected = event?.planning.venuePlanning.selectedCandidateId == candidate.id
        hasLoaded = true
    }

    private func save() {
        candidate.name = candidate.name.trimmingCharacters(in: .whitespacesAndNewlines)
        candidate.location = candidate.location.trimmingCharacters(in: .whitespacesAndNewlines)
        candidate.webURL = candidate.webURL.trimmingCharacters(in: .whitespacesAndNewlines)
        candidate.priceNote = candidate.priceNote.trimmingCharacters(in: .whitespacesAndNewlines)
        candidate.notes = candidate.notes.trimmingCharacters(in: .whitespacesAndNewlines)

        if viewModel.saveVenueCandidateDetails(
            candidate,
            isSelected: isSelected,
            in: eventId
        ) {
            dismiss()
        }
    }
}

private struct ReservationEditView: View {
    @EnvironmentObject private var viewModel: EventViewModel
    @EnvironmentObject private var profileStore: ProfileStore
    @Environment(\.dismiss) private var dismiss

    let eventId: UUID

    @State private var reservation = EventReservation()
    @State private var hasReservationDate = false
    @State private var hasPartySize = false
    @State private var partySize = 1
    @State private var hasCancellationDeadline = false
    @State private var hasLoaded = false

    private var event: Event? { viewModel.event(for: eventId) }
    private var language: AppLanguage { profileStore.activeLanguage }
    private var isLocked: Bool { !viewModel.canEdit(eventId) }

    var body: some View {
        Form {
            if let event, !event.planning.venuePlanning.candidates.isEmpty {
                Section(language.planningText(.venuePlanning)) {
                    Picker(
                        language.planningText(.venueName),
                        selection: $reservation.candidateId
                    ) {
                        Text(language.planningText(.optional)).tag(UUID?.none)
                        ForEach(event.planning.venuePlanning.candidates) { candidate in
                            Text(candidate.name).tag(Optional(candidate.id))
                        }
                    }
                }
            }

            Section(language.planningText(.reservation)) {
                TextField(
                    language.planningText(.venueName),
                    text: $reservation.venueName
                )
                Picker(
                    language.planningText(.reservationStatus),
                    selection: $reservation.status
                ) {
                    ForEach(ReservationStatus.allCases, id: \.self) { status in
                        Text(status.displayName(for: language)).tag(status)
                    }
                }
                TextField(
                    language.planningText(.confirmationNumber),
                    text: $reservation.confirmationNumber
                )
                TextField(
                    language.planningText(.contactName),
                    text: $reservation.contactName
                )
            }

            Section {
                Toggle(
                    language.planningText(.reservationDate),
                    isOn: $hasReservationDate
                )
                if hasReservationDate {
                    DatePicker(
                        language.planningText(.reservationDate),
                        selection: reservationDateBinding,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }

                Toggle(
                    language.planningText(.partySize),
                    isOn: $hasPartySize
                )
                if hasPartySize {
                    Stepper(
                        "\(language.planningText(.partySize)): \(partySize)",
                        value: $partySize,
                        in: 1...10_000
                    )
                }

                Toggle(
                    language.planningText(.cancellationDeadline),
                    isOn: $hasCancellationDeadline
                )
                if hasCancellationDeadline {
                    DatePicker(
                        language.planningText(.cancellationDeadline),
                        selection: cancellationDeadlineBinding,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }
            }

            Section(language.planningText(.notes)) {
                TextField(
                    language.planningText(.notes),
                    text: $reservation.notes,
                    axis: .vertical
                )
                .lineLimit(2...5)
            }

            if event?.planning.venuePlanning.reservation != nil, !isLocked {
                Section {
                    Button(
                        language.planningText(.clearReservation),
                        role: .destructive,
                        action: clearReservation
                    )
                }
            }
        }
        .navigationTitle(language.planningText(.reservation))
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
        .onChange(of: reservation.candidateId) { _, candidateId in
            guard reservation.venueName.isEmpty,
                  let candidateId,
                  let candidate = event?.planning.venuePlanning.candidates.first(where: {
                      $0.id == candidateId
                  }) else { return }
            reservation.venueName = candidate.name
        }
        .onChange(of: hasReservationDate) { _, enabled in
            if enabled, reservation.reservedAt == nil {
                reservation.reservedAt = event?.date ?? Date()
            } else if !enabled {
                reservation.reservedAt = nil
            }
        }
        .onChange(of: hasPartySize) { _, enabled in
            reservation.partySize = enabled ? partySize : nil
        }
        .onChange(of: partySize) { _, value in
            if hasPartySize { reservation.partySize = value }
        }
        .onChange(of: hasCancellationDeadline) { _, enabled in
            if enabled, reservation.cancellationDeadline == nil {
                reservation.cancellationDeadline = event?.date ?? Date()
            } else if !enabled {
                reservation.cancellationDeadline = nil
            }
        }
    }

    private var reservationDateBinding: Binding<Date> {
        Binding(
            get: { reservation.reservedAt ?? event?.date ?? Date() },
            set: { reservation.reservedAt = $0 }
        )
    }

    private var cancellationDeadlineBinding: Binding<Date> {
        Binding(
            get: { reservation.cancellationDeadline ?? event?.date ?? Date() },
            set: { reservation.cancellationDeadline = $0 }
        )
    }

    private func loadIfNeeded() {
        guard !hasLoaded else { return }
        if let saved = event?.planning.venuePlanning.reservation {
            reservation = saved
        } else if let selectedId = event?.planning.venuePlanning.selectedCandidateId,
                  let candidate = event?.planning.venuePlanning.candidates.first(where: {
                      $0.id == selectedId
                  }) {
            reservation.candidateId = candidate.id
            reservation.venueName = candidate.name
        }
        hasReservationDate = reservation.reservedAt != nil
        hasCancellationDeadline = reservation.cancellationDeadline != nil
        if let savedPartySize = reservation.partySize {
            partySize = savedPartySize
            hasPartySize = true
        } else {
            partySize = max(event?.participants.count ?? 1, 1)
        }
        hasLoaded = true
    }

    private func save() {
        reservation.venueName = reservation.venueName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        reservation.confirmationNumber = reservation.confirmationNumber
            .trimmingCharacters(in: .whitespacesAndNewlines)
        reservation.contactName = reservation.contactName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        reservation.notes = reservation.notes.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        if viewModel.saveReservation(reservation, in: eventId) {
            dismiss()
        }
    }

    private func clearReservation() {
        if viewModel.saveReservation(nil, in: eventId) {
            dismiss()
        }
    }
}
