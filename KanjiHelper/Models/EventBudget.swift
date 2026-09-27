import Foundation

enum BudgetApprovalStatus: String, Codable, CaseIterable {
    case notRequired
    case pending
    case approved
    case rejected
}

enum CompanySubsidyMode: String, Codable, CaseIterable {
    case total
    case perParticipant
}

struct EventBudgetPlan: Codable, Equatable {
    var totalLimitMinorUnits: Int?
    var perParticipantLimitMinorUnits: Int?
    var organizerParticipantId: UUID?
    var organizerAdvanceLimitMinorUnits: Int?
    var companySubsidyMinorUnits: Int?
    var companySubsidyMode: CompanySubsidyMode
    var companySubsidyAppliesToAll: Bool
    var subsidizedParticipantIds: Set<UUID>
    var approvalStatus: BudgetApprovalStatus
    var notes: String

    init(
        totalLimitMinorUnits: Int? = nil,
        perParticipantLimitMinorUnits: Int? = nil,
        organizerParticipantId: UUID? = nil,
        organizerAdvanceLimitMinorUnits: Int? = nil,
        companySubsidyMinorUnits: Int? = nil,
        companySubsidyMode: CompanySubsidyMode = .total,
        companySubsidyAppliesToAll: Bool = true,
        subsidizedParticipantIds: Set<UUID> = [],
        approvalStatus: BudgetApprovalStatus = .notRequired,
        notes: String = ""
    ) {
        self.totalLimitMinorUnits = totalLimitMinorUnits
        self.perParticipantLimitMinorUnits = perParticipantLimitMinorUnits
        self.organizerParticipantId = organizerParticipantId
        self.organizerAdvanceLimitMinorUnits = organizerAdvanceLimitMinorUnits
        self.companySubsidyMinorUnits = companySubsidyMinorUnits
        self.companySubsidyMode = companySubsidyMode
        self.companySubsidyAppliesToAll = companySubsidyAppliesToAll
        self.subsidizedParticipantIds = subsidizedParticipantIds
        self.approvalStatus = approvalStatus
        self.notes = notes
    }

    private enum CodingKeys: String, CodingKey {
        case totalLimitMinorUnits, perParticipantLimitMinorUnits
        case organizerParticipantId, organizerAdvanceLimitMinorUnits
        case companySubsidyMinorUnits, companySubsidyMode
        case companySubsidyAppliesToAll, subsidizedParticipantIds
        case approvalStatus, notes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        totalLimitMinorUnits = try container.decodeIfPresent(
            Int.self,
            forKey: .totalLimitMinorUnits
        )
        perParticipantLimitMinorUnits = try container.decodeIfPresent(
            Int.self,
            forKey: .perParticipantLimitMinorUnits
        )
        organizerParticipantId = try container.decodeIfPresent(
            UUID.self,
            forKey: .organizerParticipantId
        )
        organizerAdvanceLimitMinorUnits = try container.decodeIfPresent(
            Int.self,
            forKey: .organizerAdvanceLimitMinorUnits
        )
        companySubsidyMinorUnits = try container.decodeIfPresent(
            Int.self,
            forKey: .companySubsidyMinorUnits
        )
        companySubsidyMode = try container.decodeIfPresent(
            CompanySubsidyMode.self,
            forKey: .companySubsidyMode
        ) ?? .total
        companySubsidyAppliesToAll = try container.decodeIfPresent(
            Bool.self,
            forKey: .companySubsidyAppliesToAll
        ) ?? true
        subsidizedParticipantIds = try container.decodeIfPresent(
            Set<UUID>.self,
            forKey: .subsidizedParticipantIds
        ) ?? []
        approvalStatus = try container.decodeIfPresent(
            BudgetApprovalStatus.self,
            forKey: .approvalStatus
        ) ?? .notRequired
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
    }

    mutating func removeParticipant(_ participantId: UUID) {
        if organizerParticipantId == participantId {
            organizerParticipantId = nil
        }
        subsidizedParticipantIds.remove(participantId)
    }

    func duplicated(using participantMap: [UUID: UUID]) -> Self {
        var copy = self
        copy.organizerParticipantId = organizerParticipantId.flatMap {
            participantMap[$0]
        }
        copy.subsidizedParticipantIds = Set(
            subsidizedParticipantIds.compactMap { participantMap[$0] }
        )
        copy.approvalStatus = approvalStatus == .approved ? .pending : approvalStatus
        return copy
    }

    func estimatedCompanySubsidy(participantCount: Int) -> Int {
        guard let amount = companySubsidyMinorUnits, amount > 0 else { return 0 }
        switch companySubsidyMode {
        case .total:
            return amount
        case .perParticipant:
            let count = companySubsidyAppliesToAll
                ? participantCount
                : subsidizedParticipantIds.count
            return amount * max(count, 0)
        }
    }
}
