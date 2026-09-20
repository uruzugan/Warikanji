import Foundation

enum TransferCalculator {
    private struct RemainingBalance {
        let participantId: UUID
        var amount: Int
    }

    static func calculate(settlements: [Settlement]) -> [Transfer] {
        var payers = settlements
            .filter { $0.balance < 0 }
            .map { RemainingBalance(participantId: $0.participantId, amount: -$0.balance) }

        var receivers = settlements
            .filter { $0.balance > 0 }
            .map { RemainingBalance(participantId: $0.participantId, amount: $0.balance) }

        var transfers: [Transfer] = []

        while !payers.isEmpty && !receivers.isEmpty {
            payers.sort { $0.amount > $1.amount }
            receivers.sort { $0.amount > $1.amount }

            let amount = min(payers[0].amount, receivers[0].amount)

            if amount > 0 {
                transfers.append(
                    Transfer(
                        fromParticipantId: payers[0].participantId,
                        toParticipantId: receivers[0].participantId,
                        amount: amount
                    )
                )
            }

            payers[0].amount -= amount
            receivers[0].amount -= amount

            if payers[0].amount <= 0 { payers.removeFirst() }
            if receivers[0].amount <= 0 { receivers.removeFirst() }
        }

        return transfers
    }
}
