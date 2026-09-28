import Foundation

extension EventViewModel {
    @discardableResult
    func saveMeetingPlan(_ plan: EventMeetingPlan, in eventId: UUID) -> Bool {
        guard canEdit(eventId),
              let eventIndex = indexOfEvent(eventId) else { return false }

        var updated = plan
        updated.name = updated.name.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.instructions = updated.instructions.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard updated.isConfigured else { return false }

        let previousEvent = events[eventIndex]
        events[eventIndex].planning.meetingPlan = updated
        events[eventIndex].planning.recordActivity(
            targetType: "meetingPlan",
            targetId: eventId,
            actionKey: "meeting.updated"
        )

        guard saveEvents() else {
            events[eventIndex] = previousEvent
            return false
        }
        return true
    }
}
