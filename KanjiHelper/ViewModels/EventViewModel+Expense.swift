import Foundation
import SwiftUI

extension EventViewModel {
    func addExpense(_ expense: Expense, to eventId: UUID) {
        guard canEdit(eventId),
              let index = indexOfEvent(eventId) else { return }

        var expense = expense
        prepareRandomOrder(for: &expense, participants: events[index].participants)

        events[index].expenses.append(expense)
        events[index].transfers = []
        saveEvents()
    }

    func updateExpense(_ expense: Expense, in eventId: UUID) {
        guard canEdit(eventId),
              let eventIndex = indexOfEvent(eventId),
              let expenseIndex = indexOfExpense(expense.id, in: eventIndex) else { return }

        let old = events[eventIndex].expenses[expenseIndex]
        var updated = expense

        let calculationChanged =
            old.amount != updated.amount ||
            old.splitMethod != updated.splitMethod ||
            old.conditions != updated.conditions ||
            old.rounding != updated.rounding

        if calculationChanged {
            updated.remainderParticipantIds = []
        }

        prepareRandomOrder(for: &updated, participants: events[eventIndex].participants)
        events[eventIndex].expenses[expenseIndex] = updated

        if calculationChanged || old.payerId != updated.payerId {
            events[eventIndex].transfers = []
        }

        saveEvents()
    }

    func updateExpenseConditions(
        eventId: UUID,
        expenseId: UUID,
        splitMethod: SplitMethod,
        conditions: [ExpenseCondition]
    ) {
        guard canEdit(eventId),
              let eventIndex = indexOfEvent(eventId),
              let expenseIndex = indexOfExpense(expenseId, in: eventIndex) else { return }

        var expense = events[eventIndex].expenses[expenseIndex]

        let changed =
            expense.splitMethod != splitMethod ||
            expense.conditions != conditions

        expense.splitMethod = splitMethod
        expense.conditions = conditions

        if changed {
            expense.remainderParticipantIds = []
        }

        prepareRandomOrder(for: &expense, participants: events[eventIndex].participants)
        events[eventIndex].expenses[expenseIndex] = expense

        if changed {
            events[eventIndex].transfers = []
        }

        saveEvents()
    }

    func deleteExpense(expenseId: UUID, from eventId: UUID) {
        guard canEdit(eventId),
              let eventIndex = indexOfEvent(eventId),
              let expenseIndex = indexOfExpense(expenseId, in: eventIndex) else { return }

        let expense = events[eventIndex].expenses[expenseIndex]

        ReceiptImageStorage.shared.delete(expense.receiptImages)
        events[eventIndex].expenses.remove(at: expenseIndex)
        events[eventIndex].transfers = []
        saveEvents()
    }

    func deleteExpenses(at offsets: IndexSet, from eventId: UUID) {
        guard canEdit(eventId),
              let eventIndex = indexOfEvent(eventId) else { return }

        let validOffsets = IndexSet(offsets.filter {
            events[eventIndex].expenses.indices.contains($0)
        })

        let deletingExpenses = validOffsets.map {
            events[eventIndex].expenses[$0]
        }

        deletingExpenses.forEach {
            ReceiptImageStorage.shared.delete($0.receiptImages)
        }

        events[eventIndex].expenses.remove(atOffsets: validOffsets)
        events[eventIndex].transfers = []
        saveEvents()
    }

    func expense(for expenseId: UUID, in eventId: UUID) -> Expense? {
        event(for: eventId)?.expenses.first { $0.id == expenseId }
    }

    func prepareRandomOrders(at eventIndex: Int) {
        let participants = events[eventIndex].participants

        for index in events[eventIndex].expenses.indices {
            prepareRandomOrder(
                for: &events[eventIndex].expenses[index],
                participants: participants
            )
        }
    }

    private func prepareRandomOrder(
        for expense: inout Expense,
        participants: [EventParticipant]
    ) {
        let included = participants.filter { participant in
            expense.conditions.first {
                $0.participantId == participant.id
            }?.isIncluded ?? true
        }

        guard !included.isEmpty else {
            expense.remainderParticipantIds = []
            return
        }

        let allowed = Set(included.map(\.id))
        var seen: Set<UUID> = []

        let saved = expense.remainderParticipantIds.filter {
            allowed.contains($0) && seen.insert($0).inserted
        }

        if expense.rounding == .exact && expense.splitMethod == .equal {
            let remainder = expense.amount % included.count

            guard remainder > 0 else {
                expense.remainderParticipantIds = []
                return
            }

            if saved.count == remainder {
                expense.remainderParticipantIds = saved
            } else {
                expense.remainderParticipantIds = Array(
                    included.shuffled().prefix(remainder).map(\.id)
                )
            }

            return
        }

        if saved.count == included.count {
            expense.remainderParticipantIds = saved
        } else {
            expense.remainderParticipantIds = included.shuffled().map(\.id)
        }
    }
}
