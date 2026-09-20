import Foundation

enum SettlementCalculator {
    static func calculate(event: Event) -> SettlementResult {
        guard !event.participants.isEmpty else {
            return result(warning: .noParticipants)
        }

        guard !event.expenses.isEmpty else {
            return result(warning: .noExpenses)
        }

        var shares = zeroTotals(event.participants)
        var paid = zeroTotals(event.participants)
        var warnings: [CalculationWarning] = []

        for expense in event.expenses {
            let calculated = ExpenseShareCalculator.calculate(
                expense: expense,
                participants: event.participants
            )

            for (id, amount) in calculated {
                shares[id, default: 0] += amount
            }

            if let payerId = expense.payerId, paid[payerId] != nil {
                paid[payerId, default: 0] += expense.amount
            } else {
                warnings.append(
                    CalculationWarning(type: .payerNotSet(expense.title))
                )
            }

            validate(
                expense: expense,
                participants: event.participants,
                warnings: &warnings
            )
        }

        let settlements = event.participants.map {
            Settlement(
                participantId: $0.id,
                totalShare: shares[$0.id] ?? 0,
                paidAmount: paid[$0.id] ?? 0
            )
        }

        let totalShare = settlements.reduce(0) { $0 + $1.totalShare }
        let totalPaid = settlements.reduce(0) { $0 + $1.paidAmount }
        let expenseTotal = event.totalExpenseAmount

        return SettlementResult(
            settlements: settlements,
            warnings: warnings,
            isTotalShareConsistent: totalShare == expenseTotal,
            isBalanceConsistent:
                totalShare == totalPaid &&
                settlements.reduce(0) { $0 + $1.balance } == 0
        )
    }

    private static func validate(
        expense: Expense,
        participants: [EventParticipant],
        warnings: inout [CalculationWarning]
    ) {
        let included = participants.filter { participant in
            expense.conditions.first {
                $0.participantId == participant.id
            }?.isIncluded ?? true
        }

        if included.isEmpty {
            warnings.append(
                CalculationWarning(type: .noParticipantsToShare(expense.title))
            )
        }

        if expense.splitMethod == .custom {
            let totalWeight = included.reduce(0.0) { total, participant in
                total + max(
                    expense.conditions.first {
                        $0.participantId == participant.id
                    }?.customWeight ?? 1,
                    0
                )
            }

            if totalWeight <= 0 {
                warnings.append(
                    CalculationWarning(type: .ratioNotSet(expense.title))
                )
            }
        }
    }

    private static func zeroTotals(_ participants: [EventParticipant]) -> [UUID: Int] {
        Dictionary(uniqueKeysWithValues: participants.map { ($0.id, 0) })
    }

    private static func result(warning: CalculationWarningType) -> SettlementResult {
        SettlementResult(
            settlements: [],
            warnings: [CalculationWarning(type: warning)],
            isTotalShareConsistent: true,
            isBalanceConsistent: true
        )
    }
}
