import Foundation

extension EventViewModel {
    @discardableResult
    func prepareReception(in eventId: UUID) -> Bool {
        guard canEdit(eventId),
              let eventIndex = indexOfEvent(eventId) else { return false }

        let previousEvent = events[eventIndex]
        let participantIds = events[eventIndex].participants.map(\.id)
        events[eventIndex].planning.receptionPlan.synchronize(
            with: participantIds
        )
        guard events[eventIndex] != previousEvent else { return true }

        guard saveEvents() else {
            events[eventIndex] = previousEvent
            return false
        }
        return true
    }

    @discardableResult
    func setReceptionCheckIn(
        participantId: UUID,
        checkedIn: Bool,
        in eventId: UUID
    ) -> Bool {
        guard canEdit(eventId),
              let eventIndex = indexOfEvent(eventId),
              events[eventIndex].participants.contains(where: {
                  $0.id == participantId
              }) else { return false }

        let previousEvent = events[eventIndex]
        events[eventIndex].planning.receptionPlan.synchronize(
            with: events[eventIndex].participants.map(\.id)
        )
        guard let entryIndex = events[eventIndex].planning.receptionPlan.entries
            .firstIndex(where: { $0.participantId == participantId }) else {
            events[eventIndex] = previousEvent
            return false
        }

        events[eventIndex].planning.receptionPlan.entries[entryIndex].checkedInAt =
            checkedIn ? Date() : nil
        events[eventIndex].planning.recordActivity(
            targetType: "receptionEntry",
            targetId: participantId,
            actionKey: checkedIn ? "reception.checkedIn" : "reception.checkInCleared"
        )
        return persistReceptionChange(at: eventIndex, restoring: previousEvent)
    }

    @discardableResult
    func checkInFromQRCode(_ payload: String, in eventId: UUID) -> Bool {
        guard canEdit(eventId),
              let eventIndex = indexOfEvent(eventId),
              let token = ReceptionEntry.token(
                  from: payload,
                  eventId: eventId
              ) else { return false }

        let previousEvent = events[eventIndex]
        events[eventIndex].planning.receptionPlan.synchronize(
            with: events[eventIndex].participants.map(\.id)
        )
        guard let entryIndex = events[eventIndex].planning.receptionPlan.entries
            .firstIndex(where: { $0.token == token }) else {
            events[eventIndex] = previousEvent
            return false
        }

        let participantId = events[eventIndex].planning.receptionPlan
            .entries[entryIndex].participantId
        events[eventIndex].planning.receptionPlan.entries[entryIndex].checkedInAt = Date()
        events[eventIndex].planning.recordActivity(
            targetType: "receptionEntry",
            targetId: participantId,
            actionKey: "reception.checkedInByQR"
        )
        return persistReceptionChange(at: eventIndex, restoring: previousEvent)
    }

    private func persistReceptionChange(
        at eventIndex: Int,
        restoring previousEvent: Event
    ) -> Bool {
        guard saveEvents() else {
            events[eventIndex] = previousEvent
            return false
        }
        return true
    }
}
