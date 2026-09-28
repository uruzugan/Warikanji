import XCTest
@testable import KanjiHelper

final class CompatibilityTests: XCTestCase {
    func testLegacyEventGetsCurrentDefaults() throws {
        let id = UUID()
        let json = """
        {
          "id": "\(id.uuidString)",
          "title": "Legacy event",
          "date": "2024-01-02T03:04:05Z",
          "participants": [],
          "expenses": [],
          "transfers": []
        }
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let event = try decoder.decode(Event.self, from: Data(json.utf8))

        XCTAssertEqual(event.id, id)
        XCTAssertEqual(event.endDate, event.date)
        XCTAssertEqual(event.currency, .jpy)
        XCTAssertEqual(event.eventType, .other)
        XCTAssertEqual(event.expectedParticipantCount, 1)
        XCTAssertTrue(event.location.isEmpty)
        XCTAssertTrue(event.memo.isEmpty)
        XCTAssertEqual(event.planning.formatVersion, 1)
        XCTAssertTrue(event.planning.features.contains(.expenseTracking))
        XCTAssertTrue(event.planning.features.contains(.settlement))
    }

    func testLegacyExpenseGetsReceiptAndDateDefaults() throws {
        let id = UUID()
        let json = """
        {
          "id": "\(id.uuidString)",
          "title": "Legacy expense",
          "amount": 1500
        }
        """

        let expense = try JSONDecoder().decode(Expense.self, from: Data(json.utf8))

        XCTAssertEqual(expense.category, .other)
        XCTAssertEqual(expense.splitMethod, .equal)
        XCTAssertEqual(expense.rounding, .exact)
        XCTAssertTrue(expense.conditions.isEmpty)
        XCTAssertTrue(expense.receiptImages.isEmpty)
        XCTAssertNil(expense.date)
        XCTAssertNil(expense.partId)
    }

    func testLegacyProfileKeepsReferenceCurrencyInSync() throws {
        let id = UUID()
        let json = """
        {
          "id": "\(id.uuidString)",
          "name": "Legacy profile",
          "language": "japanese",
          "homeCurrency": "JPY"
        }
        """

        let profile = try JSONDecoder().decode(LocalProfile.self, from: Data(json.utf8))

        XCTAssertEqual(profile.id, id)
        XCTAssertEqual(profile.homeCurrency, .jpy)
        XCTAssertEqual(profile.referenceCurrency, .jpy)
    }

    func testPlanningSavedBeforeCoordinationGetsEmptyDefaults() throws {
        let json = """
        {
          "formatVersion": 1,
          "features": { "enabled": ["expenseTracking"] },
          "access": {
            "members": [],
            "expenseApprovalRequired": false,
            "joinApprovalRequired": false
          },
          "parts": [],
          "participantResponses": [],
          "tasks": [],
          "activity": [],
          "dismissedAssistantActionKeys": []
        }
        """

        let planning = try JSONDecoder().decode(
            EventPlanningState.self,
            from: Data(json.utf8)
        )

        XCTAssertTrue(planning.schedulePoll.options.isEmpty)
        XCTAssertTrue(planning.schedulePoll.responses.isEmpty)
        XCTAssertTrue(planning.venuePlanning.candidates.isEmpty)
        XCTAssertNil(planning.venuePlanning.reservation)
        XCTAssertNil(planning.budgetPlan.totalLimitMinorUnits)
        XCTAssertNil(planning.budgetPlan.organizerParticipantId)
        XCTAssertEqual(planning.budgetPlan.approvalStatus, .notRequired)
        XCTAssertTrue(planning.firstDrinkPlan.options.isEmpty)
        XCTAssertTrue(planning.firstDrinkPlan.selections.isEmpty)
        XCTAssertNil(planning.firstDrinkPlan.responseDeadline)
        XCTAssertFalse(planning.meetingPlan.isConfigured)
        XCTAssertNil(planning.meetingPlan.meetingAt)
        XCTAssertNil(planning.meetingPlan.photoData)
        XCTAssertTrue(planning.preparationItems.isEmpty)
        XCTAssertTrue(planning.timelineEntries.isEmpty)
    }
}
