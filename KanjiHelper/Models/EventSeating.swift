import Foundation

struct SeatingAssignment: Codable, Equatable {
    var seatNumber: Int
    var participantId: UUID
}

struct SeatingTable: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var seatCount: Int
    var assignments: [SeatingAssignment]

    init(
        id: UUID = UUID(),
        name: String,
        seatCount: Int = 4,
        assignments: [SeatingAssignment] = []
    ) {
        self.id = id
        self.name = name
        self.seatCount = max(1, seatCount)
        self.assignments = assignments
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, seatCount, assignments
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        seatCount = max(
            1,
            min(
                try container.decodeIfPresent(Int.self, forKey: .seatCount) ?? 4,
                100
            )
        )
        assignments = try container.decodeIfPresent(
            [SeatingAssignment].self,
            forKey: .assignments
        ) ?? []
    }
}

struct EventSeatingPlan: Codable, Equatable {
    var tables: [SeatingTable]

    init(tables: [SeatingTable] = []) {
        self.tables = tables
    }

    var totalSeatCount: Int {
        tables.reduce(0) { $0 + $1.seatCount }
    }

    var assignedParticipantIds: Set<UUID> {
        Set(tables.flatMap(\.assignments).map(\.participantId))
    }

    mutating func removeParticipant(_ participantId: UUID) {
        for index in tables.indices {
            tables[index].assignments.removeAll {
                $0.participantId == participantId
            }
        }
    }

    mutating func assignParticipants(_ participantIds: [UUID]) {
        for index in tables.indices {
            tables[index].assignments = []
        }

        var participantIndex = 0
        for tableIndex in tables.indices {
            for seatNumber in 1...tables[tableIndex].seatCount {
                guard participantIds.indices.contains(participantIndex) else {
                    return
                }
                tables[tableIndex].assignments.append(
                    SeatingAssignment(
                        seatNumber: seatNumber,
                        participantId: participantIds[participantIndex]
                    )
                )
                participantIndex += 1
            }
        }
    }

    func duplicated() -> Self {
        Self(
            tables: tables.map {
                SeatingTable(name: $0.name, seatCount: $0.seatCount)
            }
        )
    }
}
