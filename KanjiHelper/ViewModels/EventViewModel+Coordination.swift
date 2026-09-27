import Foundation
import SwiftUI

extension EventViewModel {
    @discardableResult
    func saveScheduleOptionDetails(
        _ option: ScheduleOption,
        choices: [UUID: CoordinationChoice],
        in eventId: UUID
    ) -> Bool {
        guard canEdit(eventId),
              let eventIndex = indexOfEvent(eventId) else { return false }

        let previousEvent = events[eventIndex]
        let isNew = !events[eventIndex].planning.schedulePoll.options.contains {
            $0.id == option.id
        }
        if let optionIndex = events[eventIndex].planning.schedulePoll.options
            .firstIndex(where: { $0.id == option.id }) {
            events[eventIndex].planning.schedulePoll.options[optionIndex] = option
        } else {
            events[eventIndex].planning.schedulePoll.options.append(option)
        }
        events[eventIndex].planning.schedulePoll.options.sort {
            $0.startAt < $1.startAt
        }

        let validParticipantIds = Set(events[eventIndex].participants.map(\.id))
        for (participantId, choice) in choices
        where validParticipantIds.contains(participantId) {
            let responseIndex: Int
            if let existingIndex = events[eventIndex].planning.schedulePoll.responses
                .firstIndex(where: { $0.participantId == participantId }) {
                responseIndex = existingIndex
            } else {
                events[eventIndex].planning.schedulePoll.responses.append(
                    SchedulePollResponse(participantId: participantId)
                )
                responseIndex = events[eventIndex].planning.schedulePoll.responses.count - 1
            }

            var response = events[eventIndex].planning.schedulePoll.responses[responseIndex]
            if let choiceIndex = response.optionResponses.firstIndex(where: {
                $0.optionId == option.id
            }) {
                response.optionResponses[choiceIndex].choice = choice
            } else {
                response.optionResponses.append(
                    ScheduleOptionResponse(optionId: option.id, choice: choice)
                )
            }
            response.updatedAt = Date()
            events[eventIndex].planning.schedulePoll.responses[responseIndex] = response
        }

        events[eventIndex].planning.recordActivity(
            targetType: "scheduleOption",
            targetId: option.id,
            actionKey: isNew ? "scheduleOption.added" : "scheduleOption.updated"
        )
        return persistChange(at: eventIndex, restoring: previousEvent)
    }

    @discardableResult
    func deleteScheduleOptions(at offsets: IndexSet, from eventId: UUID) -> Bool {
        guard canEdit(eventId),
              let eventIndex = indexOfEvent(eventId) else { return false }

        let validOffsets = IndexSet(offsets.filter {
            events[eventIndex].planning.schedulePoll.options.indices.contains($0)
        })
        guard !validOffsets.isEmpty else { return false }

        let previousEvent = events[eventIndex]
        let removedIds = validOffsets.map {
            events[eventIndex].planning.schedulePoll.options[$0].id
        }
        removedIds.forEach {
            events[eventIndex].planning.schedulePoll.removeOption($0)
            events[eventIndex].planning.recordActivity(
                targetType: "scheduleOption",
                targetId: $0,
                actionKey: "scheduleOption.removed"
            )
        }
        return persistChange(at: eventIndex, restoring: previousEvent)
    }

    @discardableResult
    func updateSchedulePollSettings(
        deadline: Date?,
        finalizedOptionId: UUID?,
        in eventId: UUID
    ) -> Bool {
        guard canEdit(eventId),
              let eventIndex = indexOfEvent(eventId),
              finalizedOptionId == nil || events[eventIndex].planning.schedulePoll
                .options.contains(where: { $0.id == finalizedOptionId }) else {
            return false
        }

        let previousEvent = events[eventIndex]
        events[eventIndex].planning.schedulePoll.responseDeadline = deadline
        events[eventIndex].planning.schedulePoll.finalizedOptionId = finalizedOptionId
        events[eventIndex].planning.recordActivity(
            targetType: "schedulePoll",
            targetId: eventId,
            actionKey: "schedulePoll.settingsUpdated"
        )
        return persistChange(at: eventIndex, restoring: previousEvent)
    }

    @discardableResult
    func saveVenueCandidateDetails(
        _ candidate: VenueCandidate,
        isSelected: Bool,
        in eventId: UUID
    ) -> Bool {
        guard canEdit(eventId),
              let eventIndex = indexOfEvent(eventId) else { return false }

        let previousEvent = events[eventIndex]
        var updated = candidate
        let validParticipantIds = Set(events[eventIndex].participants.map(\.id))
        updated.votes.removeAll {
            !validParticipantIds.contains($0.participantId)
        }

        let isNew = !events[eventIndex].planning.venuePlanning.candidates
            .contains(where: { $0.id == updated.id })
        if let candidateIndex = events[eventIndex].planning.venuePlanning
            .candidates.firstIndex(where: { $0.id == updated.id }) {
            events[eventIndex].planning.venuePlanning.candidates[candidateIndex] = updated
        } else {
            events[eventIndex].planning.venuePlanning.candidates.append(updated)
        }

        if isSelected {
            events[eventIndex].planning.venuePlanning.selectedCandidateId = updated.id
        } else if events[eventIndex].planning.venuePlanning.selectedCandidateId == updated.id {
            events[eventIndex].planning.venuePlanning.selectedCandidateId = nil
        }

        events[eventIndex].planning.recordActivity(
            targetType: "venueCandidate",
            targetId: updated.id,
            actionKey: isNew ? "venueCandidate.added" : "venueCandidate.updated"
        )
        return persistChange(at: eventIndex, restoring: previousEvent)
    }

    @discardableResult
    func deleteVenueCandidates(at offsets: IndexSet, from eventId: UUID) -> Bool {
        guard canEdit(eventId),
              let eventIndex = indexOfEvent(eventId) else { return false }

        let validOffsets = IndexSet(offsets.filter {
            events[eventIndex].planning.venuePlanning.candidates.indices.contains($0)
        })
        guard !validOffsets.isEmpty else { return false }

        let previousEvent = events[eventIndex]
        let removedIds = validOffsets.map {
            events[eventIndex].planning.venuePlanning.candidates[$0].id
        }
        removedIds.forEach {
            events[eventIndex].planning.venuePlanning.removeCandidate($0)
            events[eventIndex].planning.recordActivity(
                targetType: "venueCandidate",
                targetId: $0,
                actionKey: "venueCandidate.removed"
            )
        }
        return persistChange(at: eventIndex, restoring: previousEvent)
    }

    @discardableResult
    func saveReservation(_ reservation: EventReservation?, in eventId: UUID) -> Bool {
        guard canEdit(eventId),
              let eventIndex = indexOfEvent(eventId) else { return false }

        let previousEvent = events[eventIndex]
        var updated = reservation
        if let candidateId = updated?.candidateId,
           !events[eventIndex].planning.venuePlanning.candidates.contains(where: {
               $0.id == candidateId
           }) {
            updated?.candidateId = nil
        }
        events[eventIndex].planning.venuePlanning.reservation = updated
        events[eventIndex].planning.recordActivity(
            targetType: "reservation",
            targetId: eventId,
            actionKey: updated == nil ? "reservation.removed" : "reservation.updated"
        )
        return persistChange(at: eventIndex, restoring: previousEvent)
    }

    private func persistChange(at eventIndex: Int, restoring previousEvent: Event) -> Bool {
        guard saveEvents() else {
            events[eventIndex] = previousEvent
            return false
        }
        return true
    }
}
