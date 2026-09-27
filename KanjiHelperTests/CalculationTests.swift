import XCTest
@testable import KanjiHelper

final class CalculationTests: XCTestCase {
    func testExactEqualSplitUsesSavedRemainderRecipient() {
        let participants = [
            EventParticipant(name: "A"),
            EventParticipant(name: "B"),
            EventParticipant(name: "C")
        ]
        let expense = Expense(
            title: "Dinner",
            amount: 100,
            payerId: participants[0].id,
            remainderParticipantIds: [participants[1].id]
        )

        let shares = ExpenseShareCalculator.calculate(
            expense: expense,
            participants: participants
        )

        XCTAssertEqual(shares[participants[0].id], 33)
        XCTAssertEqual(shares[participants[1].id], 34)
        XCTAssertEqual(shares[participants[2].id], 33)
        XCTAssertEqual(shares.values.reduce(0, +), expense.amount)
    }

    func testCustomSplitExcludesUncheckedParticipant() {
        let participants = [
            EventParticipant(name: "A"),
            EventParticipant(name: "B"),
            EventParticipant(name: "C")
        ]
        let expenseId = UUID()
        let expense = Expense(
            id: expenseId,
            title: "Hotel",
            amount: 900,
            payerId: participants[0].id,
            splitMethod: .custom,
            conditions: [
                ExpenseCondition(
                    expenseId: expenseId,
                    participantId: participants[0].id,
                    customWeight: 1
                ),
                ExpenseCondition(
                    expenseId: expenseId,
                    participantId: participants[1].id,
                    customWeight: 2
                ),
                ExpenseCondition(
                    expenseId: expenseId,
                    participantId: participants[2].id,
                    isIncluded: false
                )
            ]
        )

        let shares = ExpenseShareCalculator.calculate(
            expense: expense,
            participants: participants
        )

        XCTAssertEqual(shares[participants[0].id], 300)
        XCTAssertEqual(shares[participants[1].id], 600)
        XCTAssertEqual(shares[participants[2].id], 0)
        XCTAssertEqual(shares.values.reduce(0, +), expense.amount)
    }

    func testSettlementAndTransfersStayBalanced() {
        let participants = [
            EventParticipant(name: "A"),
            EventParticipant(name: "B"),
            EventParticipant(name: "C")
        ]
        let event = Event(
            title: "Trip",
            participants: participants,
            expenses: [
                Expense(
                    title: "Taxi",
                    amount: 900,
                    payerId: participants[0].id
                )
            ]
        )

        let result = SettlementCalculator.calculate(event: event)
        let transfers = TransferCalculator.calculate(settlements: result.settlements)

        XCTAssertTrue(result.isTotalShareConsistent)
        XCTAssertTrue(result.isBalanceConsistent)
        XCTAssertEqual(transfers.count, 2)
        XCTAssertEqual(transfers.reduce(0) { $0 + $1.amount }, 600)
        XCTAssertTrue(transfers.allSatisfy {
            $0.toParticipantId == participants[0].id && $0.amount == 300
        })
    }

    func testCurrencyInputSupportsCommonSeparators() {
        XCTAssertEqual(AppCurrency.usd.minorUnits(from: "US$1,234.56"), 123_456)
        XCTAssertEqual(AppCurrency.eur.minorUnits(from: "1.234,56"), 123_456)
        XCTAssertEqual(AppCurrency.jpy.minorUnits(from: "¥1,234"), 1_234)
        XCTAssertNil(AppCurrency.usd.minorUnits(from: "0"))
        XCTAssertNil(AppCurrency.usd.minorUnits(from: "abc"))
    }
}
