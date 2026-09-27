import Foundation

enum CoordinationChoice: String, Codable, CaseIterable {
    case unanswered
    case yes
    case maybe
    case no
}

struct ScheduleOption: Identifiable, Codable, Equatable {
    var id: UUID
    var startAt: Date
    var endAt: Date?
    var note: String

    init(
        id: UUID = UUID(),
        startAt: Date,
        endAt: Date? = nil,
        note: String = ""
    ) {
        self.id = id
        self.startAt = startAt
        self.endAt = endAt
        self.note = note
    }
}

struct ScheduleOptionResponse: Codable, Equatable {
    var optionId: UUID
    var choice: CoordinationChoice
}

struct SchedulePollResponse: Identifiable, Codable, Equatable {
    var id: UUID
    var participantId: UUID
    var optionResponses: [ScheduleOptionResponse]
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        participantId: UUID,
        optionResponses: [ScheduleOptionResponse] = [],
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.participantId = participantId
        self.optionResponses = optionResponses
        self.updatedAt = updatedAt
    }
}

struct EventSchedulePoll: Codable, Equatable {
    var options: [ScheduleOption]
    var responses: [SchedulePollResponse]
    var responseDeadline: Date?
    var finalizedOptionId: UUID?

    init(
        options: [ScheduleOption] = [],
        responses: [SchedulePollResponse] = [],
        responseDeadline: Date? = nil,
        finalizedOptionId: UUID? = nil
    ) {
        self.options = options
        self.responses = responses
        self.responseDeadline = responseDeadline
        self.finalizedOptionId = finalizedOptionId
    }

    mutating func removeOption(_ optionId: UUID) {
        options.removeAll { $0.id == optionId }
        for index in responses.indices {
            responses[index].optionResponses.removeAll {
                $0.optionId == optionId
            }
        }
        if finalizedOptionId == optionId {
            finalizedOptionId = nil
        }
    }

    mutating func removeParticipant(_ participantId: UUID) {
        responses.removeAll { $0.participantId == participantId }
    }

    func duplicated() -> Self {
        return Self(
            options: options.map {
                ScheduleOption(
                    startAt: $0.startAt,
                    endAt: $0.endAt,
                    note: $0.note
                )
            },
            responseDeadline: responseDeadline
        )
    }
}

struct VenueVote: Codable, Equatable {
    var participantId: UUID
    var choice: CoordinationChoice
}

struct VenueCandidate: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var location: String
    var webURL: String
    var priceNote: String
    var notes: String
    var votes: [VenueVote]

    init(
        id: UUID = UUID(),
        name: String,
        location: String = "",
        webURL: String = "",
        priceNote: String = "",
        notes: String = "",
        votes: [VenueVote] = []
    ) {
        self.id = id
        self.name = name
        self.location = location
        self.webURL = webURL
        self.priceNote = priceNote
        self.notes = notes
        self.votes = votes
    }
}

enum ReservationStatus: String, Codable, CaseIterable {
    case planned
    case requested
    case confirmed
    case cancelled
}

struct EventReservation: Codable, Equatable {
    var candidateId: UUID?
    var venueName: String
    var confirmationNumber: String
    var reservedAt: Date?
    var partySize: Int?
    var contactName: String
    var cancellationDeadline: Date?
    var status: ReservationStatus
    var notes: String

    init(
        candidateId: UUID? = nil,
        venueName: String = "",
        confirmationNumber: String = "",
        reservedAt: Date? = nil,
        partySize: Int? = nil,
        contactName: String = "",
        cancellationDeadline: Date? = nil,
        status: ReservationStatus = .planned,
        notes: String = ""
    ) {
        self.candidateId = candidateId
        self.venueName = venueName
        self.confirmationNumber = confirmationNumber
        self.reservedAt = reservedAt
        self.partySize = partySize
        self.contactName = contactName
        self.cancellationDeadline = cancellationDeadline
        self.status = status
        self.notes = notes
    }
}

struct EventVenuePlanning: Codable, Equatable {
    var candidates: [VenueCandidate]
    var selectedCandidateId: UUID?
    var reservation: EventReservation?

    init(
        candidates: [VenueCandidate] = [],
        selectedCandidateId: UUID? = nil,
        reservation: EventReservation? = nil
    ) {
        self.candidates = candidates
        self.selectedCandidateId = selectedCandidateId
        self.reservation = reservation
    }

    mutating func removeCandidate(_ candidateId: UUID) {
        candidates.removeAll { $0.id == candidateId }
        if selectedCandidateId == candidateId {
            selectedCandidateId = nil
        }
        if reservation?.candidateId == candidateId {
            reservation?.candidateId = nil
        }
    }

    mutating func removeParticipant(_ participantId: UUID) {
        for index in candidates.indices {
            candidates[index].votes.removeAll {
                $0.participantId == participantId
            }
        }
    }

    func duplicated() -> Self {
        Self(
            candidates: candidates.map {
                VenueCandidate(
                    name: $0.name,
                    location: $0.location,
                    webURL: $0.webURL,
                    priceNote: $0.priceNote,
                    notes: $0.notes
                )
            }
        )
    }
}
