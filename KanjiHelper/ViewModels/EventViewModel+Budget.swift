import Foundation

extension EventViewModel {
    @discardableResult
    func saveBudgetPlan(_ plan: EventBudgetPlan, in eventId: UUID) -> Bool {
        guard canEdit(eventId),
              let eventIndex = indexOfEvent(eventId) else { return false }

        let previousEvent = events[eventIndex]
        let participantIds = Set(events[eventIndex].participants.map(\.id))
        var updated = plan
        updated.totalLimitMinorUnits = positive(updated.totalLimitMinorUnits)
        updated.perParticipantLimitMinorUnits = positive(
            updated.perParticipantLimitMinorUnits
        )
        updated.organizerAdvanceLimitMinorUnits = positive(
            updated.organizerAdvanceLimitMinorUnits
        )
        updated.companySubsidyMinorUnits = positive(
            updated.companySubsidyMinorUnits
        )
        if updated.organizerParticipantId.map(participantIds.contains) != true {
            updated.organizerParticipantId = nil
            updated.organizerAdvanceLimitMinorUnits = nil
        }
        updated.subsidizedParticipantIds.formIntersection(participantIds)
        if updated.companySubsidyMinorUnits == nil
            || updated.companySubsidyMode == .total
            || updated.companySubsidyAppliesToAll {
            updated.subsidizedParticipantIds = []
        }
        updated.notes = updated.notes.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        events[eventIndex].planning.budgetPlan = updated
        events[eventIndex].planning.recordActivity(
            targetType: "budget",
            targetId: eventId,
            actionKey: "budget.updated"
        )

        guard saveEvents() else {
            events[eventIndex] = previousEvent
            return false
        }
        return true
    }

    private func positive(_ amount: Int?) -> Int? {
        amount.flatMap { $0 > 0 ? $0 : nil }
    }
}
