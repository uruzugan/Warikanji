import Foundation
import SwiftUI

extension EventViewModel {
    @discardableResult
    func savePreparationItem(
        _ item: EventPreparationItem,
        in eventId: UUID
    ) -> Bool {
        guard canEdit(eventId),
              let eventIndex = indexOfEvent(eventId) else { return false }

        let previousEvent = events[eventIndex]
        let isNew = !events[eventIndex].planning.preparationItems.contains {
            $0.id == item.id
        }
        let updated = sanitized(item, for: events[eventIndex])
        if let itemIndex = events[eventIndex].planning.preparationItems
            .firstIndex(where: { $0.id == updated.id }) {
            events[eventIndex].planning.preparationItems[itemIndex] = updated
        } else {
            events[eventIndex].planning.preparationItems.append(updated)
        }
        events[eventIndex].planning.recordActivity(
            targetType: "preparationItem",
            targetId: updated.id,
            actionKey: isNew ? "item.added" : "item.updated"
        )
        return persistOrganizerChange(at: eventIndex, restoring: previousEvent)
    }

    @discardableResult
    func deletePreparationItems(
        at offsets: IndexSet,
        from eventId: UUID
    ) -> Bool {
        guard canEdit(eventId),
              let eventIndex = indexOfEvent(eventId) else { return false }
        let validOffsets = IndexSet(offsets.filter {
            events[eventIndex].planning.preparationItems.indices.contains($0)
        })
        guard !validOffsets.isEmpty else { return false }

        let previousEvent = events[eventIndex]
        let removedIds = validOffsets.map {
            events[eventIndex].planning.preparationItems[$0].id
        }
        events[eventIndex].planning.preparationItems.remove(atOffsets: validOffsets)
        removedIds.forEach {
            events[eventIndex].planning.recordActivity(
                targetType: "preparationItem",
                targetId: $0,
                actionKey: "item.removed"
            )
        }
        return persistOrganizerChange(at: eventIndex, restoring: previousEvent)
    }

    @discardableResult
    func saveTimelineEntry(
        _ entry: EventTimelineEntry,
        in eventId: UUID
    ) -> Bool {
        guard canEdit(eventId),
              let eventIndex = indexOfEvent(eventId) else { return false }

        let previousEvent = events[eventIndex]
        let isNew = !events[eventIndex].planning.timelineEntries.contains {
            $0.id == entry.id
        }
        let updated = sanitized(entry, for: events[eventIndex])
        if let entryIndex = events[eventIndex].planning.timelineEntries
            .firstIndex(where: { $0.id == updated.id }) {
            events[eventIndex].planning.timelineEntries[entryIndex] = updated
        } else {
            events[eventIndex].planning.timelineEntries.append(updated)
        }
        events[eventIndex].planning.timelineEntries.sort {
            $0.startAt < $1.startAt
        }
        events[eventIndex].planning.recordActivity(
            targetType: "timelineEntry",
            targetId: updated.id,
            actionKey: isNew ? "timeline.added" : "timeline.updated"
        )
        return persistOrganizerChange(at: eventIndex, restoring: previousEvent)
    }

    @discardableResult
    func deleteTimelineEntries(
        at offsets: IndexSet,
        from eventId: UUID
    ) -> Bool {
        guard canEdit(eventId),
              let eventIndex = indexOfEvent(eventId) else { return false }
        let validOffsets = IndexSet(offsets.filter {
            events[eventIndex].planning.timelineEntries.indices.contains($0)
        })
        guard !validOffsets.isEmpty else { return false }

        let previousEvent = events[eventIndex]
        let removedIds = validOffsets.map {
            events[eventIndex].planning.timelineEntries[$0].id
        }
        events[eventIndex].planning.timelineEntries.remove(atOffsets: validOffsets)
        removedIds.forEach {
            events[eventIndex].planning.recordActivity(
                targetType: "timelineEntry",
                targetId: $0,
                actionKey: "timeline.removed"
            )
        }
        return persistOrganizerChange(at: eventIndex, restoring: previousEvent)
    }

    private func sanitized(
        _ item: EventPreparationItem,
        for event: Event
    ) -> EventPreparationItem {
        var updated = item
        updated.title = updated.title.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.notes = updated.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.quantity = max(updated.quantity, 1)
        updated.assigneeParticipantIds.formIntersection(
            Set(event.participants.map(\.id))
        )
        if updated.partId.map({ partId in
            !event.planning.parts.contains { $0.id == partId }
        }) == true {
            updated.partId = nil
        }
        if updated.status == .assigned && updated.assigneeParticipantIds.isEmpty {
            updated.status = .needed
        }
        return updated
    }

    private func sanitized(
        _ entry: EventTimelineEntry,
        for event: Event
    ) -> EventTimelineEntry {
        var updated = entry
        updated.title = updated.title.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.location = updated.location.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.notes = updated.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.assigneeParticipantIds.formIntersection(
            Set(event.participants.map(\.id))
        )
        if let endAt = updated.endAt, endAt < updated.startAt {
            updated.endAt = updated.startAt
        }
        if updated.partId.map({ partId in
            !event.planning.parts.contains { $0.id == partId }
        }) == true {
            updated.partId = nil
        }
        return updated
    }

    private func persistOrganizerChange(
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
