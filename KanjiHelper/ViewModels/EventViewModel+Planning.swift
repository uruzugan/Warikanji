import Foundation
import SwiftUI

extension EventViewModel {
    @discardableResult
    func saveParticipantResponse(
        _ response: ParticipantResponse,
        in eventId: UUID
    ) -> Bool {
        guard canEdit(eventId),
              let eventIndex = indexOfEvent(eventId),
              events[eventIndex].participants.contains(where: {
                  $0.id == response.participantId
              }) else { return false }

        let previousEvent = events[eventIndex]
        var updated = response
        updated.updatedAt = Date()
        let validPartIds = Set(events[eventIndex].planning.parts.map(\.id))
        updated.partAttendance.removeAll {
            !validPartIds.contains($0.partId)
        }

        if let responseIndex = events[eventIndex].planning.participantResponses
            .firstIndex(where: { $0.participantId == updated.participantId }) {
            events[eventIndex].planning.participantResponses[responseIndex] = updated
        } else {
            events[eventIndex].planning.participantResponses.append(updated)
        }

        events[eventIndex].planning.recordActivity(
            targetType: "participantResponse",
            targetId: updated.id,
            actionKey: "response.updated",
            details: ["participantId": updated.participantId.uuidString]
        )

        guard saveEvents() else {
            events[eventIndex] = previousEvent
            return false
        }
        return true
    }

    @discardableResult
    func addEventPart(_ part: EventPart, to eventId: UUID) -> Bool {
        guard canEdit(eventId),
              let eventIndex = indexOfEvent(eventId),
              !events[eventIndex].planning.parts.contains(where: {
                  $0.id == part.id
              }) else { return false }

        let previousEvent = events[eventIndex]
        var updated = part
        updated.order = events[eventIndex].planning.parts.count
        updated.participantIds.formIntersection(
            Set(events[eventIndex].participants.map(\.id))
        )
        events[eventIndex].planning.parts.append(updated)
        events[eventIndex].planning.recordActivity(
            targetType: "eventPart",
            targetId: updated.id,
            actionKey: "part.added"
        )

        guard saveEvents() else {
            events[eventIndex] = previousEvent
            return false
        }
        return true
    }

    @discardableResult
    func updateEventPart(_ part: EventPart, in eventId: UUID) -> Bool {
        guard canEdit(eventId),
              let eventIndex = indexOfEvent(eventId),
              let partIndex = events[eventIndex].planning.parts.firstIndex(
                  where: { $0.id == part.id }
              ) else { return false }

        let previousEvent = events[eventIndex]
        var updated = part
        updated.participantIds.formIntersection(
            Set(events[eventIndex].participants.map(\.id))
        )
        events[eventIndex].planning.parts[partIndex] = updated
        events[eventIndex].planning.recordActivity(
            targetType: "eventPart",
            targetId: updated.id,
            actionKey: "part.updated"
        )

        guard saveEvents() else {
            events[eventIndex] = previousEvent
            return false
        }
        return true
    }

    @discardableResult
    func deleteEventParts(at offsets: IndexSet, from eventId: UUID) -> Bool {
        guard canEdit(eventId),
              let eventIndex = indexOfEvent(eventId) else { return false }

        let validOffsets = IndexSet(offsets.filter {
            events[eventIndex].planning.parts.indices.contains($0)
        })
        guard !validOffsets.isEmpty else { return false }

        let previousEvent = events[eventIndex]
        let removedIds = Set(validOffsets.map {
            events[eventIndex].planning.parts[$0].id
        })
        events[eventIndex].removePlanningParts(removedIds)

        removedIds.forEach {
            events[eventIndex].planning.recordActivity(
                targetType: "eventPart",
                targetId: $0,
                actionKey: "part.removed"
            )
        }

        guard saveEvents() else {
            events[eventIndex] = previousEvent
            return false
        }
        return true
    }

    @discardableResult
    func moveEventParts(
        from source: IndexSet,
        to destination: Int,
        in eventId: UUID
    ) -> Bool {
        guard canEdit(eventId),
              let eventIndex = indexOfEvent(eventId) else { return false }

        let previousEvent = events[eventIndex]
        events[eventIndex].planning.parts.move(
            fromOffsets: source,
            toOffset: destination
        )
        normalizePartOrder(in: eventIndex)
        events[eventIndex].planning.recordActivity(
            targetType: "eventPart",
            actionKey: "parts.reordered"
        )

        guard saveEvents() else {
            events[eventIndex] = previousEvent
            return false
        }
        return true
    }

    @discardableResult
    func addEventTask(_ task: EventTask, to eventId: UUID) -> Bool {
        guard canEdit(eventId),
              let eventIndex = indexOfEvent(eventId),
              !events[eventIndex].planning.tasks.contains(where: {
                  $0.id == task.id
              }) else { return false }

        let previousEvent = events[eventIndex]
        var updated = sanitized(task, for: events[eventIndex])
        updated.createdAt = Date()
        updated.completedAt = updated.status == .completed ? Date() : nil
        events[eventIndex].planning.tasks.append(updated)
        events[eventIndex].planning.recordActivity(
            targetType: "eventTask",
            targetId: updated.id,
            actionKey: "task.added"
        )

        guard saveEvents() else {
            events[eventIndex] = previousEvent
            return false
        }
        return true
    }

    @discardableResult
    func updateEventTask(_ task: EventTask, in eventId: UUID) -> Bool {
        guard canEdit(eventId),
              let eventIndex = indexOfEvent(eventId),
              let taskIndex = events[eventIndex].planning.tasks.firstIndex(
                  where: { $0.id == task.id }
              ) else { return false }

        let previousEvent = events[eventIndex]
        var updated = sanitized(task, for: events[eventIndex])
        if updated.status == .completed {
            updated.completedAt = updated.completedAt ?? Date()
        } else {
            updated.completedAt = nil
        }
        events[eventIndex].planning.tasks[taskIndex] = updated
        events[eventIndex].planning.recordActivity(
            targetType: "eventTask",
            targetId: updated.id,
            actionKey: "task.updated"
        )

        guard saveEvents() else {
            events[eventIndex] = previousEvent
            return false
        }
        return true
    }

    @discardableResult
    func setEventTaskStatus(
        _ status: EventTaskStatus,
        taskId: UUID,
        in eventId: UUID
    ) -> Bool {
        guard let event = event(for: eventId),
              var task = event.planning.tasks.first(where: {
                  $0.id == taskId
              }) else { return false }

        task.status = status
        task.completedAt = status == .completed ? Date() : nil
        return updateEventTask(task, in: eventId)
    }

    @discardableResult
    func deleteEventTasks(at offsets: IndexSet, from eventId: UUID) -> Bool {
        guard canEdit(eventId),
              let eventIndex = indexOfEvent(eventId) else { return false }

        let validOffsets = IndexSet(offsets.filter {
            events[eventIndex].planning.tasks.indices.contains($0)
        })
        guard !validOffsets.isEmpty else { return false }

        let previousEvent = events[eventIndex]
        let removedIds = validOffsets.map {
            events[eventIndex].planning.tasks[$0].id
        }
        events[eventIndex].planning.tasks.remove(atOffsets: validOffsets)
        removedIds.forEach {
            events[eventIndex].planning.recordActivity(
                targetType: "eventTask",
                targetId: $0,
                actionKey: "task.removed"
            )
        }

        guard saveEvents() else {
            events[eventIndex] = previousEvent
            return false
        }
        return true
    }

    private func normalizePartOrder(in eventIndex: Int) {
        for index in events[eventIndex].planning.parts.indices {
            events[eventIndex].planning.parts[index].order = index
        }
    }

    private func sanitized(_ task: EventTask, for event: Event) -> EventTask {
        var updated = task
        updated.assigneeParticipantIds.formIntersection(
            Set(event.participants.map(\.id))
        )
        if let partId = updated.partId,
           !event.planning.parts.contains(where: { $0.id == partId }) {
            updated.partId = nil
        }
        return updated
    }
}
