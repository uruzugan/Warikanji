import Foundation

struct ReceptionEntry: Identifiable, Codable, Equatable {
    var participantId: UUID
    var token: UUID
    var checkedInAt: Date?

    init(
        participantId: UUID,
        token: UUID = UUID(),
        checkedInAt: Date? = nil
    ) {
        self.participantId = participantId
        self.token = token
        self.checkedInAt = checkedInAt
    }

    var id: UUID { participantId }
    var isCheckedIn: Bool { checkedInAt != nil }

    func qrPayload(eventId: UUID) -> String {
        "warikanji-checkin://\(eventId.uuidString)/\(token.uuidString)"
    }

    static func token(from payload: String, eventId: UUID) -> UUID? {
        guard let url = URL(string: payload),
              url.scheme == "warikanji-checkin",
              let host = url.host,
              UUID(uuidString: host) == eventId else { return nil }
        return UUID(uuidString: url.pathComponents.dropFirst().first ?? "")
    }
}

struct EventReceptionPlan: Codable, Equatable {
    var entries: [ReceptionEntry]

    init(entries: [ReceptionEntry] = []) {
        self.entries = entries
    }

    var checkedInParticipantIds: Set<UUID> {
        Set(entries.filter(\.isCheckedIn).map(\.participantId))
    }

    mutating func synchronize(with participantIds: [UUID]) {
        let existing = Dictionary(
            entries.map { ($0.participantId, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        entries = participantIds.map {
            existing[$0] ?? ReceptionEntry(participantId: $0)
        }
    }

    mutating func removeParticipant(_ participantId: UUID) {
        entries.removeAll { $0.participantId == participantId }
    }

    func duplicated(using participantMap: [UUID: UUID]) -> Self {
        Self(
            entries: entries.compactMap { entry in
                guard let participantId = participantMap[entry.participantId] else {
                    return nil
                }
                return ReceptionEntry(participantId: participantId)
            }
        )
    }
}
