import Foundation

extension EventViewModel {
    func recalculateTransfers(for eventId: UUID) {
        guard canEdit(eventId), let index = indexOfEvent(eventId) else { return }

        prepareRandomOrders(at: index)

        let event = events[index]
        let result = SettlementCalculator.calculate(event: event)

        guard result.isTotalShareConsistent,
              result.isBalanceConsistent,
              !result.hasBlockingCalculationError else {
            updateTransfers([], for: eventId)
            return
        }

        let calculated = TransferCalculator.calculate(settlements: result.settlements)

        let merged = calculated.map { transfer -> Transfer in
            guard let old = event.transfers.first(where: {
                $0.fromParticipantId == transfer.fromParticipantId &&
                $0.toParticipantId == transfer.toParticipantId &&
                $0.amount == transfer.amount
            }) else { return transfer }

            var updated = transfer
            updated.id = old.id
            updated.isPaid = old.isPaid
            return updated
        }

        updateTransfers(merged, for: eventId)
    }

    func updateTransfers(_ transfers: [Transfer], for eventId: UUID) {
        guard canEdit(eventId), let index = indexOfEvent(eventId) else { return }
        events[index].transfers = transfers
        saveEvents()
    }

    func setTransferPaid(transferId: UUID, isPaid: Bool, in eventId: UUID) {
        guard let eventIndex = indexOfEvent(eventId),
              let transferIndex = events[eventIndex].transfers.firstIndex(where: { $0.id == transferId })
        else { return }

        events[eventIndex].transfers[transferIndex].isPaid = isPaid
        saveEvents()
    }
}
