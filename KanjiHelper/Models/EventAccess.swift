import Foundation

enum EventMemberRole: String, Codable, CaseIterable, Identifiable {
    case owner
    case coOrganizer
    case participant
    case viewer

    var id: String { rawValue }

    var defaultPermissions: Set<EventPermission> {
        switch self {
        case .owner:
            return Set(EventPermission.allKnown)
        case .coOrganizer:
            return [
                .editEventDetails, .manageParticipants, .manageResponses,
                .manageVenueCandidates, .manageReservations, .addExpenses,
                .editExpenses, .calculateSettlement, .manageTasks,
                .sendAnnouncements, .submitOwnResponses
            ]
        case .participant:
            return [.submitOwnResponses]
        case .viewer:
            return []
        }
    }
}

struct EventPermission: RawRepresentable, Codable, Hashable, Identifiable {
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

    var id: String { rawValue }

    static let editEventDetails = Self(rawValue: "editEventDetails")
    static let manageParticipants = Self(rawValue: "manageParticipants")
    static let manageResponses = Self(rawValue: "manageResponses")
    static let manageVenueCandidates = Self(rawValue: "manageVenueCandidates")
    static let manageReservations = Self(rawValue: "manageReservations")
    static let addExpenses = Self(rawValue: "addExpenses")
    static let approveExpenses = Self(rawValue: "approveExpenses")
    static let editExpenses = Self(rawValue: "editExpenses")
    static let calculateSettlement = Self(rawValue: "calculateSettlement")
    static let updatePaymentStatus = Self(rawValue: "updatePaymentStatus")
    static let manageSettlementLock = Self(rawValue: "manageSettlementLock")
    static let manageTasks = Self(rawValue: "manageTasks")
    static let sendAnnouncements = Self(rawValue: "sendAnnouncements")
    static let manageAccess = Self(rawValue: "manageAccess")
    static let submitOwnResponses = Self(rawValue: "submitOwnResponses")

    static let allKnown: [Self] = [
        .editEventDetails, .manageParticipants, .manageResponses,
        .manageVenueCandidates, .manageReservations, .addExpenses,
        .approveExpenses, .editExpenses, .calculateSettlement,
        .updatePaymentStatus, .manageSettlementLock, .manageTasks,
        .sendAnnouncements, .manageAccess, .submitOwnResponses
    ]
}

struct EventAccessMember: Identifiable, Codable, Equatable {
    var id: UUID
    var participantId: UUID?
    var role: EventMemberRole
    var allowedPermissions: Set<EventPermission>
    var deniedPermissions: Set<EventPermission>

    init(
        id: UUID = UUID(),
        participantId: UUID? = nil,
        role: EventMemberRole,
        allowedPermissions: Set<EventPermission> = [],
        deniedPermissions: Set<EventPermission> = []
    ) {
        self.id = id
        self.participantId = participantId
        self.role = role
        self.allowedPermissions = allowedPermissions
        self.deniedPermissions = deniedPermissions
    }

    var effectivePermissions: Set<EventPermission> {
        role.defaultPermissions
            .union(allowedPermissions)
            .subtracting(deniedPermissions)
    }
}

struct EventAccessPolicy: Codable, Equatable {
    var ownerMemberId: UUID?
    var members: [EventAccessMember]
    var expenseApprovalRequired: Bool
    var joinApprovalRequired: Bool

    init(
        ownerMemberId: UUID? = nil,
        members: [EventAccessMember] = [],
        expenseApprovalRequired: Bool = false,
        joinApprovalRequired: Bool = false
    ) {
        self.ownerMemberId = ownerMemberId
        self.members = members
        self.expenseApprovalRequired = expenseApprovalRequired
        self.joinApprovalRequired = joinApprovalRequired
    }

    private enum CodingKeys: String, CodingKey {
        case ownerMemberId, members, expenseApprovalRequired, joinApprovalRequired
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        ownerMemberId = try container.decodeIfPresent(UUID.self, forKey: .ownerMemberId)
        members = try container.decodeIfPresent([EventAccessMember].self, forKey: .members) ?? []
        expenseApprovalRequired = try container.decodeIfPresent(
            Bool.self,
            forKey: .expenseApprovalRequired
        ) ?? false
        joinApprovalRequired = try container.decodeIfPresent(
            Bool.self,
            forKey: .joinApprovalRequired
        ) ?? false
    }

    func permissions(for memberId: UUID) -> Set<EventPermission> {
        if memberId == ownerMemberId {
            return Set(EventPermission.allKnown)
        }
        return members.first { $0.id == memberId }?.effectivePermissions ?? []
    }

    func can(_ permission: EventPermission, memberId: UUID) -> Bool {
        permissions(for: memberId).contains(permission)
    }
}
