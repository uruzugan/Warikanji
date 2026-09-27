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
}
