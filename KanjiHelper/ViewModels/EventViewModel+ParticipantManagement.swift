import Foundation

enum ParticipantRemovalIssue: Equatable {
    case lastParticipant
    case payer(expenseTitles: [String])
    case onlyIncludedParticipant(expenseTitles: [String])
}

extension EventViewModel {
    func saveParticipantNames(_ names: [UUID: String], in eventId: UUID) {
        guard canEdit(eventId), let eventIndex = indexOfEvent(eventId) else { return }

        var changed = false

        for i in events[eventIndex].participants.indices {
            let id = events[eventIndex].participants[i].id
            guard let name = names[id] else { continue }

            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard events[eventIndex].participants[i].name != trimmed else { continue }

            events[eventIndex].participants[i].name = trimmed
            changed = true
        }

        if changed { saveEvents() }
    }

    func participantRemovalIssue(participantId: UUID, from eventId: UUID) -> ParticipantRemovalIssue? {
        guard let event = event(for: eventId),
              event.participants.contains(where: { $0.id == participantId })
        else { return nil }

        guard event.participants.count > 1 else { return .lastParticipant }

        let payerExpenses = event.expenses.filter { $0.payerId == participantId }

        if !payerExpenses.isEmpty {
            return .payer(expenseTitles: payerExpenses.map(\.title))
        }

        let remaining = event.participants.filter { $0.id != participantId }

        let blocked = event.expenses.filter { expense in
            isParticipant(participantId, includedIn: expense) &&
            !remaining.contains { isParticipant($0.id, includedIn: expense) }
        }

        return blocked.isEmpty
            ? nil
            : .onlyIncludedParticipant(expenseTitles: blocked.map(\.title))
    }

    func removeParticipantFromEvent(participantId: UUID, from eventId: UUID) -> Bool {
        guard canEdit(eventId),
              participantRemovalIssue(participantId: participantId, from: eventId) == nil,
              let eventIndex = indexOfEvent(eventId),
              let participantIndex = events[eventIndex].participants.firstIndex(where: { $0.id == participantId })
        else { return false }

        events[eventIndex].participants.remove(at: participantIndex)

        for i in events[eventIndex].expenses.indices {
            events[eventIndex].expenses[i].conditions.removeAll { $0.participantId == participantId }
            events[eventIndex].expenses[i].remainderParticipantIds.removeAll { $0 == participantId }
        }

        events[eventIndex].expectedParticipantCount = max(events[eventIndex].participants.count, 1)
        events[eventIndex].transfers = []

        prepareRandomOrders(at: eventIndex)
        saveEvents()
        return true
    }

    private func isParticipant(_ participantId: UUID, includedIn expense: Expense) -> Bool {
        expense.conditions.first { $0.participantId == participantId }?.isIncluded ?? true
    }
}
