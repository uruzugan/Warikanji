import Foundation

enum PreparationItemStatus: String, Codable, CaseIterable {
    case needed
    case assigned
    case ready
}

struct EventPreparationItem: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var quantity: Int
    var notes: String
    var assigneeParticipantIds: Set<UUID>
    var partId: UUID?
    var status: PreparationItemStatus
    var isPrivate: Bool

    init(
        id: UUID = UUID(),
        title: String,
        quantity: Int = 1,
        notes: String = "",
        assigneeParticipantIds: Set<UUID> = [],
        partId: UUID? = nil,
        status: PreparationItemStatus = .needed,
        isPrivate: Bool = false
    ) {
        self.id = id
        self.title = title
        self.quantity = max(quantity, 1)
        self.notes = notes
        self.assigneeParticipantIds = assigneeParticipantIds
        self.partId = partId
        self.status = status
        self.isPrivate = isPrivate
    }
}

struct EventTimelineEntry: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var startAt: Date
    var endAt: Date?
    var location: String
    var notes: String
    var assigneeParticipantIds: Set<UUID>
    var partId: UUID?
    var isPrivate: Bool
    var isCompleted: Bool

    init(
        id: UUID = UUID(),
        title: String,
        startAt: Date,
        endAt: Date? = nil,
        location: String = "",
        notes: String = "",
        assigneeParticipantIds: Set<UUID> = [],
        partId: UUID? = nil,
        isPrivate: Bool = false,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.title = title
        self.startAt = startAt
        self.endAt = endAt
        self.location = location
        self.notes = notes
        self.assigneeParticipantIds = assigneeParticipantIds
        self.partId = partId
        self.isPrivate = isPrivate
        self.isCompleted = isCompleted
    }
}
