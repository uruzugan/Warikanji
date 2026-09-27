import Foundation
import SwiftUI

extension EventViewModel {
    @discardableResult
    func saveDrinkOption(_ option: DrinkOption, in eventId: UUID) -> Bool {
        guard canEdit(eventId),
              let eventIndex = indexOfEvent(eventId) else { return false }

        let previousEvent = events[eventIndex]
        var updated = option
        updated.name = updated.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !updated.name.isEmpty else { return false }
        let isNew = !events[eventIndex].planning.firstDrinkPlan.options.contains {
            $0.id == updated.id
        }
        if let optionIndex = events[eventIndex].planning.firstDrinkPlan.options
            .firstIndex(where: { $0.id == updated.id }) {
            events[eventIndex].planning.firstDrinkPlan.options[optionIndex] = updated
        } else {
            events[eventIndex].planning.firstDrinkPlan.options.append(updated)
        }
        events[eventIndex].planning.recordActivity(
            targetType: "drinkOption",
            targetId: updated.id,
            actionKey: isNew ? "drinkOption.added" : "drinkOption.updated"
        )
        return persistFirstDrinkChange(at: eventIndex, restoring: previousEvent)
    }

    @discardableResult
    func deleteDrinkOptions(at offsets: IndexSet, from eventId: UUID) -> Bool {
        guard canEdit(eventId),
              let eventIndex = indexOfEvent(eventId) else { return false }
        let validOffsets = IndexSet(offsets.filter {
            events[eventIndex].planning.firstDrinkPlan.options.indices.contains($0)
        })
        guard !validOffsets.isEmpty else { return false }

        let previousEvent = events[eventIndex]
        let removedIds = validOffsets.map {
            events[eventIndex].planning.firstDrinkPlan.options[$0].id
        }
        removedIds.forEach {
            events[eventIndex].planning.firstDrinkPlan.removeOption($0)
            events[eventIndex].planning.recordActivity(
                targetType: "drinkOption",
                targetId: $0,
                actionKey: "drinkOption.removed"
            )
        }
        return persistFirstDrinkChange(at: eventIndex, restoring: previousEvent)
    }

    @discardableResult
    func saveFirstDrinkSelection(
        _ selection: FirstDrinkSelection,
        in eventId: UUID
    ) -> Bool {
        guard canEdit(eventId),
              let eventIndex = indexOfEvent(eventId),
              events[eventIndex].participants.contains(where: {
                  $0.id == selection.participantId
              }) else { return false }

        let previousEvent = events[eventIndex]
        let validOptionIds = Set(
            events[eventIndex].planning.firstDrinkPlan.options.map(\.id)
        )
        var updated = selection
        updated.firstChoiceId = validChoice(
            updated.firstChoiceId,
            in: validOptionIds
        )
        updated.secondChoiceId = validChoice(
            updated.secondChoiceId,
            in: validOptionIds
        )
        updated.thirdChoiceId = validChoice(
            updated.thirdChoiceId,
            in: validOptionIds
        )
        if updated.secondChoiceId == updated.firstChoiceId {
            updated.secondChoiceId = nil
        }
        if updated.thirdChoiceId == updated.firstChoiceId
            || updated.thirdChoiceId == updated.secondChoiceId {
            updated.thirdChoiceId = nil
        }
        guard updated.firstChoiceId != nil,
              updated.secondChoiceId != nil else { return false }
        updated.updatedAt = Date()

        if let selectionIndex = events[eventIndex].planning.firstDrinkPlan.selections
            .firstIndex(where: { $0.participantId == updated.participantId }) {
            events[eventIndex].planning.firstDrinkPlan.selections[selectionIndex] = updated
        } else {
            events[eventIndex].planning.firstDrinkPlan.selections.append(updated)
        }
        events[eventIndex].planning.recordActivity(
            targetType: "firstDrinkSelection",
            targetId: updated.id,
            actionKey: "firstDrinkSelection.updated",
            details: ["participantId": updated.participantId.uuidString]
        )
        return persistFirstDrinkChange(at: eventIndex, restoring: previousEvent)
    }

    @discardableResult
    func updateFirstDrinkDeadline(_ deadline: Date?, in eventId: UUID) -> Bool {
        guard canEdit(eventId),
              let eventIndex = indexOfEvent(eventId) else { return false }
        let previousEvent = events[eventIndex]
        events[eventIndex].planning.firstDrinkPlan.responseDeadline = deadline
        events[eventIndex].planning.recordActivity(
            targetType: "firstDrinkPlan",
            targetId: eventId,
            actionKey: "firstDrink.deadlineUpdated"
        )
        return persistFirstDrinkChange(at: eventIndex, restoring: previousEvent)
    }

    private func validChoice(_ choice: UUID?, in validIds: Set<UUID>) -> UUID? {
        choice.flatMap { validIds.contains($0) ? $0 : nil }
    }

    private func persistFirstDrinkChange(
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
