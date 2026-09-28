import Foundation
import SwiftUI

extension EventViewModel {
    @discardableResult
    func saveSeatingTable(_ table: SeatingTable, in eventId: UUID) -> Bool {
        guard canEdit(eventId),
              let eventIndex = indexOfEvent(eventId) else { return false }

        let previousEvent = events[eventIndex]
        var updated = table
        updated.name = updated.name.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.seatCount = max(1, min(updated.seatCount, 100))
        guard !updated.name.isEmpty else { return false }
        updated = sanitizedSeatingTable(updated, in: events[eventIndex])

        let isNew = !events[eventIndex].planning.seatingPlan.tables.contains {
            $0.id == updated.id
        }
        if let tableIndex = events[eventIndex].planning.seatingPlan.tables
            .firstIndex(where: { $0.id == updated.id }) {
            events[eventIndex].planning.seatingPlan.tables[tableIndex] = updated
        } else {
            events[eventIndex].planning.seatingPlan.tables.append(updated)
        }
        events[eventIndex].planning.recordActivity(
            targetType: "seatingTable",
            targetId: updated.id,
            actionKey: isNew ? "seating.tableAdded" : "seating.tableUpdated"
        )
        return persistSeatingChange(at: eventIndex, restoring: previousEvent)
    }

    @discardableResult
    func saveSeatingAssignments(
        _ assignments: [SeatingAssignment],
        for tableId: UUID,
        in eventId: UUID
    ) -> Bool {
        guard canEdit(eventId),
              let eventIndex = indexOfEvent(eventId),
              let tableIndex = events[eventIndex].planning.seatingPlan.tables
                .firstIndex(where: { $0.id == tableId }) else { return false }

        let previousEvent = events[eventIndex]
        var table = events[eventIndex].planning.seatingPlan.tables[tableIndex]
        table.assignments = assignments
        table = sanitizedSeatingTable(table, in: events[eventIndex])
        events[eventIndex].planning.seatingPlan.tables[tableIndex] = table
        events[eventIndex].planning.recordActivity(
            targetType: "seatingTable",
            targetId: tableId,
            actionKey: "seating.assignmentsUpdated"
        )
        return persistSeatingChange(at: eventIndex, restoring: previousEvent)
    }

    @discardableResult
    func deleteSeatingTables(at offsets: IndexSet, from eventId: UUID) -> Bool {
        guard canEdit(eventId),
              let eventIndex = indexOfEvent(eventId) else { return false }
        let validOffsets = IndexSet(offsets.filter {
            events[eventIndex].planning.seatingPlan.tables.indices.contains($0)
        })
        guard !validOffsets.isEmpty else { return false }

        let previousEvent = events[eventIndex]
        let removedIds = validOffsets.map {
            events[eventIndex].planning.seatingPlan.tables[$0].id
        }
        events[eventIndex].planning.seatingPlan.tables.remove(atOffsets: validOffsets)
        removedIds.forEach {
            events[eventIndex].planning.recordActivity(
                targetType: "seatingTable",
                targetId: $0,
                actionKey: "seating.tableRemoved"
            )
        }
        return persistSeatingChange(at: eventIndex, restoring: previousEvent)
    }

    @discardableResult
    func randomizeSeating(in eventId: UUID) -> Bool {
        guard canEdit(eventId),
              let eventIndex = indexOfEvent(eventId),
              events[eventIndex].planning.seatingPlan.totalSeatCount
                >= events[eventIndex].participants.count else { return false }

        let previousEvent = events[eventIndex]
        let participantIds = events[eventIndex].participants.map(\.id).shuffled()
        events[eventIndex].planning.seatingPlan.assignParticipants(participantIds)
        events[eventIndex].planning.recordActivity(
            targetType: "seatingPlan",
            targetId: eventId,
            actionKey: "seating.randomized"
        )
        return persistSeatingChange(at: eventIndex, restoring: previousEvent)
    }

    private func sanitizedSeatingTable(
        _ table: SeatingTable,
        in event: Event
    ) -> SeatingTable {
        var updated = table
        let validParticipantIds = Set(event.participants.map(\.id))
        let reservedParticipantIds = Set(
            event.planning.seatingPlan.tables
                .filter { $0.id != table.id }
                .flatMap(\.assignments)
                .map(\.participantId)
        )
        var usedSeats = Set<Int>()
        var usedParticipants = reservedParticipantIds
        updated.assignments = updated.assignments
            .filter { assignment in
                guard (1...updated.seatCount).contains(assignment.seatNumber),
                      validParticipantIds.contains(assignment.participantId),
                      !usedSeats.contains(assignment.seatNumber),
                      !usedParticipants.contains(assignment.participantId) else {
                    return false
                }
                usedSeats.insert(assignment.seatNumber)
                usedParticipants.insert(assignment.participantId)
                return true
            }
            .sorted { $0.seatNumber < $1.seatNumber }
        return updated
    }

    private func persistSeatingChange(
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
