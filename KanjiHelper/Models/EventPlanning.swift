import Foundation

struct EventPart: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var startAt: Date?
    var endAt: Date?
    var location: String
    var participantIds: Set<UUID>
    var order: Int

    init(
        id: UUID = UUID(),
        title: String,
        startAt: Date? = nil,
        endAt: Date? = nil,
        location: String = "",
        participantIds: Set<UUID> = [],
        order: Int = 0
    ) {
        self.id = id
        self.title = title
        self.startAt = startAt
        self.endAt = endAt
        self.location = location
        self.participantIds = participantIds
        self.order = order
    }
}

enum AttendanceStatus: String, Codable, CaseIterable {
    case unanswered
    case attending
    case notAttending
    case maybe
}

enum ArrivalStatus: String, Codable, CaseIterable {
    case notShared
    case onTheWay
    case arrived
    case delayed
}

enum ParticipantCategory: String, Codable, CaseIterable {
    case adult
    case child
    case preschooler
    case other
}

struct EventCompanion: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var category: ParticipantCategory

    init(
        id: UUID = UUID(),
        name: String = "",
        category: ParticipantCategory = .adult
    ) {
        self.id = id
        self.name = name
        self.category = category
    }
}

struct PartAttendanceResponse: Codable, Equatable {
    var partId: UUID
    var status: AttendanceStatus
}

struct ParticipantResponse: Identifiable, Codable, Equatable {
    var id: UUID
    var participantId: UUID
    var attendance: AttendanceStatus
    var partAttendance: [PartAttendanceResponse]
    var companions: [EventCompanion]
    var attendingFrom: Date?
    var leavingAt: Date?
    var dietaryNotes: String
    var arrivalStatus: ArrivalStatus
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        participantId: UUID,
        attendance: AttendanceStatus = .unanswered,
        partAttendance: [PartAttendanceResponse] = [],
        companions: [EventCompanion] = [],
        attendingFrom: Date? = nil,
        leavingAt: Date? = nil,
        dietaryNotes: String = "",
        arrivalStatus: ArrivalStatus = .notShared,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.participantId = participantId
        self.attendance = attendance
        self.partAttendance = partAttendance
        self.companions = companions
        self.attendingFrom = attendingFrom
        self.leavingAt = leavingAt
        self.dietaryNotes = dietaryNotes
        self.arrivalStatus = arrivalStatus
        self.updatedAt = updatedAt
    }
}

enum EventTaskStatus: String, Codable, CaseIterable {
    case pending
    case inProgress
    case completed
}

struct EventTask: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var notes: String
    var dueAt: Date?
    var assigneeParticipantIds: Set<UUID>
    var partId: UUID?
    var status: EventTaskStatus
    var isPrivate: Bool
    var createdAt: Date
    var completedAt: Date?

    init(
        id: UUID = UUID(),
        title: String,
        notes: String = "",
        dueAt: Date? = nil,
        assigneeParticipantIds: Set<UUID> = [],
        partId: UUID? = nil,
        status: EventTaskStatus = .pending,
        isPrivate: Bool = false,
        createdAt: Date = Date(),
        completedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.dueAt = dueAt
        self.assigneeParticipantIds = assigneeParticipantIds
        self.partId = partId
        self.status = status
        self.isPrivate = isPrivate
        self.createdAt = createdAt
        self.completedAt = completedAt
    }
}

struct EventActivitySource: RawRepresentable, Codable, Hashable {
    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }

    init(from decoder: Decoder) throws {
        rawValue = try decoder.singleValueContainer().decode(String.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    static let local = Self(rawValue: "local")
    static let shared = Self(rawValue: "shared")
    static let system = Self(rawValue: "system")
    static let paymentProvider = Self(rawValue: "paymentProvider")
}

struct EventActivityRecord: Identifiable, Codable, Equatable {
    var id: UUID
    var timestamp: Date
    var actorMemberId: UUID?
    var targetType: String
    var targetId: UUID?
    var actionKey: String
    var details: [String: String]
    var source: EventActivitySource

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        actorMemberId: UUID? = nil,
        targetType: String,
        targetId: UUID? = nil,
        actionKey: String,
        details: [String: String] = [:],
        source: EventActivitySource = .local
    ) {
        self.id = id
        self.timestamp = timestamp
        self.actorMemberId = actorMemberId
        self.targetType = targetType
        self.targetId = targetId
        self.actionKey = actionKey
        self.details = details
        self.source = source
    }
}

struct EventPlanningState: Codable, Equatable {
    var formatVersion: Int
    var features: EventFeatureConfiguration
    var access: EventAccessPolicy
    var parts: [EventPart]
    var participantResponses: [ParticipantResponse]
    var tasks: [EventTask]
    var activity: [EventActivityRecord]
    var dismissedAssistantActionKeys: Set<String>

    init(
        formatVersion: Int = 1,
        features: EventFeatureConfiguration,
        access: EventAccessPolicy = EventAccessPolicy(),
        parts: [EventPart] = [],
        participantResponses: [ParticipantResponse] = [],
        tasks: [EventTask] = [],
        activity: [EventActivityRecord] = [],
        dismissedAssistantActionKeys: Set<String> = []
    ) {
        self.formatVersion = formatVersion
        self.features = features
        self.access = access
        self.parts = parts
        self.participantResponses = participantResponses
        self.tasks = tasks
        self.activity = activity
        self.dismissedAssistantActionKeys = dismissedAssistantActionKeys
    }

    private enum CodingKeys: String, CodingKey {
        case formatVersion, features, access, parts, participantResponses
        case tasks, activity, dismissedAssistantActionKeys
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        formatVersion = try container.decodeIfPresent(Int.self, forKey: .formatVersion) ?? 1
        features = try container.decodeIfPresent(
            EventFeatureConfiguration.self,
            forKey: .features
        ) ?? EventFeatureConfiguration()
        access = try container.decodeIfPresent(
            EventAccessPolicy.self,
            forKey: .access
        ) ?? EventAccessPolicy()
        parts = try container.decodeIfPresent([EventPart].self, forKey: .parts) ?? []
        participantResponses = try container.decodeIfPresent(
            [ParticipantResponse].self,
            forKey: .participantResponses
        ) ?? []
        tasks = try container.decodeIfPresent([EventTask].self, forKey: .tasks) ?? []
        activity = try container.decodeIfPresent(
            [EventActivityRecord].self,
            forKey: .activity
        ) ?? []
        dismissedAssistantActionKeys = try container.decodeIfPresent(
            Set<String>.self,
            forKey: .dismissedAssistantActionKeys
        ) ?? []
    }

    static func initial(for eventType: EventType) -> Self {
        Self(features: eventType.defaultFeatures)
    }

    mutating func removeParticipant(_ participantId: UUID) {
        participantResponses.removeAll { $0.participantId == participantId }

        for index in parts.indices {
            parts[index].participantIds.remove(participantId)
        }

        for index in tasks.indices {
            tasks[index].assigneeParticipantIds.remove(participantId)
        }

        for index in access.members.indices where access.members[index].participantId == participantId {
            access.members[index].participantId = nil
        }
    }

    mutating func recordActivity(
        targetType: String,
        targetId: UUID? = nil,
        actionKey: String,
        details: [String: String] = [:],
        actorMemberId: UUID? = nil,
        source: EventActivitySource = .local
    ) {
        activity.append(
            EventActivityRecord(
                actorMemberId: actorMemberId,
                targetType: targetType,
                targetId: targetId,
                actionKey: actionKey,
                details: details,
                source: source
            )
        )

        if activity.count > 500 {
            activity.removeFirst(activity.count - 500)
        }
    }

    func duplicated(
        using participantMap: [UUID: UUID],
        partMap: [UUID: UUID]
    ) -> Self {
        let duplicatedParts = parts.map { part in
            var copy = part
            copy.id = partMap[part.id] ?? UUID()
            copy.participantIds = Set(part.participantIds.compactMap { participantMap[$0] })
            return copy
        }
        let duplicatedTasks = tasks.map { task in
            EventTask(
                title: task.title,
                notes: task.notes,
                dueAt: task.dueAt,
                assigneeParticipantIds: Set(
                    task.assigneeParticipantIds.compactMap { participantMap[$0] }
                ),
                partId: task.partId.flatMap { partMap[$0] },
                isPrivate: task.isPrivate
            )
        }

        return Self(
            features: features,
            parts: duplicatedParts,
            tasks: duplicatedTasks
        )
    }
}
