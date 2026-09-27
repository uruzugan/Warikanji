import XCTest
@testable import KanjiHelper

final class EventFoundationTests: XCTestCase {
    func testUnknownFeatureSurvivesRoundTrip() throws {
        let futureFeature = EventFeature(rawValue: "future.feature")
        var event = Event(title: "Future")
        event.planning.features.enabled.insert(futureFeature)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let restored = try decoder.decode(
            Event.self,
            from: encoder.encode(event)
        )

        XCTAssertTrue(restored.planning.features.contains(futureFeature))
    }

    func testRecommendedFeaturesPreserveUnknownFeature() {
        let futureFeature = EventFeature(rawValue: "future.feature")
        var configuration = EventFeatureConfiguration(
            enabled: [futureFeature, .games]
        )

        configuration.useRecommendedFeatures(for: .travel)

        XCTAssertTrue(configuration.contains(futureFeature))
        XCTAssertTrue(configuration.contains(.travel))
        XCTAssertFalse(configuration.contains(.games))
    }

    func testParticipantCannotChangePaymentStatusByDefault() {
        let participant = EventAccessMember(role: .participant)
        let policy = EventAccessPolicy(members: [participant])

        XCTAssertTrue(policy.can(.submitOwnResponses, memberId: participant.id))
        XCTAssertFalse(policy.can(.updatePaymentStatus, memberId: participant.id))
        XCTAssertFalse(policy.can(.editExpenses, memberId: participant.id))
    }

    func testDeniedPermissionOverridesRoleAndExplicitGrant() {
        let member = EventAccessMember(
            role: .coOrganizer,
            allowedPermissions: [.updatePaymentStatus],
            deniedPermissions: [.editExpenses, .updatePaymentStatus]
        )
        let policy = EventAccessPolicy(members: [member])

        XCTAssertTrue(policy.can(.manageTasks, memberId: member.id))
        XCTAssertFalse(policy.can(.editExpenses, memberId: member.id))
        XCTAssertFalse(policy.can(.updatePaymentStatus, memberId: member.id))
    }

    func testRemovingParticipantCleansPlanningReferences() {
        let participantId = UUID()
        let memberId = UUID()
        var planning = EventPlanningState(
            features: EventType.travel.defaultFeatures,
            access: EventAccessPolicy(
                members: [
                    EventAccessMember(
                        id: memberId,
                        participantId: participantId,
                        role: .participant
                    )
                ]
            ),
            parts: [
                EventPart(
                    title: "Day 1",
                    participantIds: [participantId]
                )
            ],
            participantResponses: [
                ParticipantResponse(
                    participantId: participantId,
                    attendance: .attending
                )
            ],
            tasks: [
                EventTask(
                    title: "Tickets",
                    assigneeParticipantIds: [participantId]
                )
            ]
        )

        planning.removeParticipant(participantId)

        XCTAssertTrue(planning.participantResponses.isEmpty)
        XCTAssertTrue(planning.parts[0].participantIds.isEmpty)
        XCTAssertTrue(planning.tasks[0].assigneeParticipantIds.isEmpty)
        XCTAssertNil(planning.access.members[0].participantId)
    }

    func testActivityHistoryKeepsNewestFiveHundredRecords() {
        var planning = EventPlanningState(
            features: EventType.other.defaultFeatures
        )

        for index in 0..<510 {
            planning.recordActivity(
                targetType: "event",
                actionKey: "event.\(index)"
            )
        }

        XCTAssertEqual(planning.activity.count, 500)
        XCTAssertEqual(planning.activity.first?.actionKey, "event.10")
        XCTAssertEqual(planning.activity.last?.actionKey, "event.509")
    }

    func testRemovingPartClearsAllPartReferences() {
        let participantId = UUID()
        let removedPartId = UUID()
        let retainedPartId = UUID()
        var event = Event(
            title: "Trip",
            participants: [EventParticipant(id: participantId, name: "A")],
            expenses: [
                Expense(title: "Hotel", amount: 1_000, partId: removedPartId),
                Expense(title: "Train", amount: 500, partId: retainedPartId)
            ]
        )
        event.planning.parts = [
            EventPart(id: removedPartId, title: "Day 1", order: 0),
            EventPart(id: retainedPartId, title: "Day 2", order: 1)
        ]
        event.planning.participantResponses = [
            ParticipantResponse(
                participantId: participantId,
                partAttendance: [
                    PartAttendanceResponse(
                        partId: removedPartId,
                        status: .attending
                    ),
                    PartAttendanceResponse(
                        partId: retainedPartId,
                        status: .attending
                    )
                ]
            )
        ]
        event.planning.tasks = [
            EventTask(title: "Removed", partId: removedPartId),
            EventTask(title: "Retained", partId: retainedPartId)
        ]

        event.removePlanningParts([removedPartId])

        XCTAssertEqual(event.planning.parts.map(\.id), [retainedPartId])
        XCTAssertEqual(event.planning.parts[0].order, 0)
        XCTAssertEqual(
            event.planning.participantResponses[0].partAttendance.map(\.partId),
            [retainedPartId]
        )
        XCTAssertNil(event.planning.tasks[0].partId)
        XCTAssertEqual(event.planning.tasks[1].partId, retainedPartId)
        XCTAssertNil(event.expenses[0].partId)
        XCTAssertEqual(event.expenses[1].partId, retainedPartId)
    }

    func testAssistantPrioritizesOverdueTaskAndUnpaidTransfer() {
        let participants = [
            EventParticipant(name: "A"),
            EventParticipant(name: "B")
        ]
        var event = Event(
            title: "Dinner",
            date: Date(timeIntervalSince1970: 1_000),
            endDate: Date(timeIntervalSince1970: 2_000),
            participants: participants,
            expenses: [
                Expense(
                    title: "Food",
                    amount: 1_000,
                    payerId: participants[0].id
                )
            ],
            transfers: [
                Transfer(
                    fromParticipantId: participants[1].id,
                    toParticipantId: participants[0].id,
                    amount: 500
                )
            ]
        )
        event.planning.participantResponses = participants.map {
            ParticipantResponse(
                participantId: $0.id,
                attendance: .attending
            )
        }
        event.planning.tasks = [
            EventTask(
                title: "Confirm booking",
                dueAt: Date(timeIntervalSince1970: 3_000)
            )
        ]

        let actions = EventProgressAssistant.actions(
            for: event,
            language: .english,
            now: Date(timeIntervalSince1970: 4_000)
        )

        XCTAssertEqual(actions.first?.id, "tasks.overdue")
        XCTAssertTrue(actions.contains { $0.id == "payments.unpaid" })
        XCTAssertFalse(actions.contains { $0.id == "attendance.unanswered" })
    }

    func testDuplicatePlanningDropsResponsesAccessAndHistory() {
        let oldParticipantId = UUID()
        let newParticipantId = UUID()
        let oldPartId = UUID()
        let newPartId = UUID()
        let planning = EventPlanningState(
            features: EventType.party.defaultFeatures,
            access: EventAccessPolicy(
                members: [EventAccessMember(role: .owner)]
            ),
            parts: [
                EventPart(
                    id: oldPartId,
                    title: "Main",
                    participantIds: [oldParticipantId]
                )
            ],
            participantResponses: [
                ParticipantResponse(
                    participantId: oldParticipantId,
                    attendance: .attending
                )
            ],
            tasks: [
                EventTask(
                    title: "Cake",
                    assigneeParticipantIds: [oldParticipantId],
                    partId: oldPartId,
                    status: .completed,
                    completedAt: Date()
                )
            ],
            activity: [
                EventActivityRecord(
                    targetType: "task",
                    actionKey: "completed"
                )
            ]
        )

        let copy = planning.duplicated(
            using: [oldParticipantId: newParticipantId],
            partMap: [oldPartId: newPartId]
        )

        XCTAssertEqual(copy.parts[0].id, newPartId)
        XCTAssertEqual(copy.parts[0].participantIds, [newParticipantId])
        XCTAssertEqual(copy.tasks[0].assigneeParticipantIds, [newParticipantId])
        XCTAssertEqual(copy.tasks[0].partId, newPartId)
        XCTAssertEqual(copy.tasks[0].status, .pending)
        XCTAssertTrue(copy.participantResponses.isEmpty)
        XCTAssertTrue(copy.access.members.isEmpty)
        XCTAssertTrue(copy.activity.isEmpty)
    }
}
