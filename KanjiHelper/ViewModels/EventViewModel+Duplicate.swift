import Foundation

extension EventViewModel {
    @discardableResult
    func duplicateEvent(_ source: Event, title: String? = nil) -> Event {
        let participantMap = Dictionary(
            uniqueKeysWithValues: source.participants.map { ($0.id, UUID()) }
        )

        let participants = source.participants.map {
            EventParticipant(id: participantMap[$0.id]!, name: $0.name)
        }

        let expenses = source.expenses.map { expense in
            let newExpenseId = UUID()

            let conditions = expense.conditions.compactMap { condition -> ExpenseCondition? in
                guard let participantId = participantMap[condition.participantId] else { return nil }

                return ExpenseCondition(
                    expenseId: newExpenseId,
                    participantId: participantId,
                    isIncluded: condition.isIncluded,
                    customWeight: condition.customWeight
                )
            }

            return Expense(
                id: newExpenseId,
                title: expense.title,
                category: expense.category,
                amount: expense.amount,
                payerId: expense.payerId.flatMap { participantMap[$0] },
                splitMethod: expense.splitMethod,
                conditions: conditions,
                rounding: expense.rounding,
                remainderParticipantIds: expense.remainderParticipantIds.compactMap { participantMap[$0] },
                date: expense.date
            )
        }

        let copy = Event(
            title: title ?? source.title,
            date: source.date,
            endDate: source.endDate,
            location: source.location,
            memo: source.memo,
            eventType: source.eventType,
            currency: source.currency,
            expectedParticipantCount: source.expectedParticipantCount,
            participants: participants,
            expenses: expenses,
            transfers: []
        )

        addEvent(copy)
        return copy
    }
}
