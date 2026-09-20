import Foundation

enum ExpenseShareCalculator {
    static func calculate(
        expense: Expense,
        participants: [EventParticipant]
    ) -> [UUID: Int] {
        let included = includedParticipants(
            expense: expense,
            participants: participants
        )

        guard !included.isEmpty else {
            return zeroShares(participants)
        }

        if expense.splitMethod == .equal &&
            expense.rounding == .exact {
            return exactEqual(
                expense: expense,
                included: included,
                participants: participants
            )
        }

        let theoretical = theoreticalShares(
            expense: expense,
            included: included
        )

        let order = calculationOrder(
            expense: expense,
            included: included
        )

        var result = ShareRoundingCalculator.round(
            theoretical: theoretical,
            total: expense.amount,
            unit: expense.rounding.rawValue,
            order: order
        )

        for participant in participants
        where result[participant.id] == nil {
            result[participant.id] = 0
        }

        return result
    }

    private static func theoreticalShares(
        expense: Expense,
        included: [EventParticipant]
    ) -> [UUID: Double] {
        if expense.splitMethod == .equal {
            let share =
                Double(expense.amount) /
                Double(included.count)

            return Dictionary(
                uniqueKeysWithValues: included.map {
                    ($0.id, share)
                }
            )
        }

        let weights = included.map { participant in
            (
                participant.id,
                max(
                    condition(
                        for: participant.id,
                        in: expense
                    )?.customWeight ?? 1,
                    0
                )
            )
        }

        let totalWeight = weights.reduce(0) {
            $0 + $1.1
        }

        guard totalWeight > 0 else {
            return Dictionary(
                uniqueKeysWithValues: included.map {
                    ($0.id, 0)
                }
            )
        }

        return Dictionary(
            uniqueKeysWithValues: weights.map {
                (
                    $0.0,
                    Double(expense.amount) *
                    $0.1 / totalWeight
                )
            }
        )
    }

    private static func exactEqual(
        expense: Expense,
        included: [EventParticipant],
        participants: [EventParticipant]
    ) -> [UUID: Int] {
        let base = expense.amount / included.count
        let remainder = expense.amount % included.count
        var result = zeroShares(participants)

        for participant in included {
            result[participant.id] = base
        }

        guard remainder > 0 else {
            return result
        }

        let allowed = Set(included.map(\.id))
        var seen: Set<UUID> = []

        let saved = expense.remainderParticipantIds.filter {
            allowed.contains($0) &&
            seen.insert($0).inserted
        }

        let recipients: [UUID]

        if saved.count == remainder {
            recipients = saved
        } else {
            recipients = Array(
                included
                    .shuffled()
                    .prefix(remainder)
                    .map(\.id)
            )
        }

        for id in recipients {
            result[id, default: 0] += 1
        }

        return result
    }

    private static func calculationOrder(
        expense: Expense,
        included: [EventParticipant]
    ) -> [UUID] {
        let includedIds = included.map(\.id)
        let allowed = Set(includedIds)
        var seen: Set<UUID> = []

        let saved = expense.remainderParticipantIds.filter {
            allowed.contains($0) &&
            seen.insert($0).inserted
        }

        if saved.count == includedIds.count {
            return saved
        }

        return includedIds
    }

    private static func includedParticipants(
        expense: Expense,
        participants: [EventParticipant]
    ) -> [EventParticipant] {
        participants.filter { participant in
            condition(
                for: participant.id,
                in: expense
            )?.isIncluded ?? true
        }
    }

    private static func condition(
        for participantId: UUID,
        in expense: Expense
    ) -> ExpenseCondition? {
        expense.conditions.first {
            $0.participantId == participantId
        }
    }

    private static func zeroShares(
        _ participants: [EventParticipant]
    ) -> [UUID: Int] {
        Dictionary(
            uniqueKeysWithValues: participants.map {
                ($0.id, 0)
            }
        )
    }
}
