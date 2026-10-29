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
        event.planning.preparationItems = [
            EventPreparationItem(title: "Tent", partId: removedPartId)
        ]
        event.planning.timelineEntries = [
            EventTimelineEntry(
                title: "Meet",
                startAt: Date(timeIntervalSince1970: 1_000),
                partId: removedPartId
            )
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
        XCTAssertNil(event.planning.preparationItems[0].partId)
        XCTAssertNil(event.planning.timelineEntries[0].partId)
        XCTAssertNil(event.expenses[0].partId)
        XCTAssertEqual(event.expenses[1].partId, retainedPartId)
    }

    func testRemovingScheduleOptionCleansResponsesAndFinalChoice() {
        let participantId = UUID()
        let removedOptionId = UUID()
        let retainedOptionId = UUID()
        var poll = EventSchedulePoll(
            options: [
                ScheduleOption(
                    id: removedOptionId,
                    startAt: Date(timeIntervalSince1970: 1_000)
                ),
                ScheduleOption(
                    id: retainedOptionId,
                    startAt: Date(timeIntervalSince1970: 2_000)
                )
            ],
            responses: [
                SchedulePollResponse(
                    participantId: participantId,
                    optionResponses: [
                        ScheduleOptionResponse(
                            optionId: removedOptionId,
                            choice: .yes
                        ),
                        ScheduleOptionResponse(
                            optionId: retainedOptionId,
                            choice: .maybe
                        )
                    ]
                )
            ],
            finalizedOptionId: removedOptionId
        )

        poll.removeOption(removedOptionId)

        XCTAssertEqual(poll.options.map(\.id), [retainedOptionId])
        XCTAssertEqual(
            poll.responses[0].optionResponses.map(\.optionId),
            [retainedOptionId]
        )
        XCTAssertNil(poll.finalizedOptionId)
    }

    func testRemovingParticipantCleansPollAndVenueVotes() {
        let participantId = UUID()
        var planning = EventPlanningState(
            features: EventType.meal.defaultFeatures,
            schedulePoll: EventSchedulePoll(
                responses: [SchedulePollResponse(participantId: participantId)]
            ),
            venuePlanning: EventVenuePlanning(
                candidates: [
                    VenueCandidate(
                        name: "Cafe",
                        votes: [
                            VenueVote(
                                participantId: participantId,
                                choice: .yes
                            )
                        ]
                    )
                ]
            )
        )

        planning.removeParticipant(participantId)

        XCTAssertTrue(planning.schedulePoll.responses.isEmpty)
        XCTAssertTrue(planning.venuePlanning.candidates[0].votes.isEmpty)
    }

    func testRemovingParticipantCleansBudgetReferences() {
        let participantId = UUID()
        var planning = EventPlanningState(
            features: EventType.meal.defaultFeatures,
            budgetPlan: EventBudgetPlan(
                organizerParticipantId: participantId,
                companySubsidyMinorUnits: 1_000,
                companySubsidyMode: .perParticipant,
                companySubsidyAppliesToAll: false,
                subsidizedParticipantIds: [participantId]
            )
        )

        planning.removeParticipant(participantId)

        XCTAssertNil(planning.budgetPlan.organizerParticipantId)
        XCTAssertTrue(planning.budgetPlan.subsidizedParticipantIds.isEmpty)
    }

    func testRemovingParticipantCleansOrganizerToolAssignments() {
        let participantId = UUID()
        var planning = EventPlanningState(
            features: EventType.party.defaultFeatures,
            preparationItems: [
                EventPreparationItem(
                    title: "Cake",
                    assigneeParticipantIds: [participantId]
                )
            ],
            timelineEntries: [
                EventTimelineEntry(
                    title: "Toast",
                    startAt: Date(timeIntervalSince1970: 1_000),
                    assigneeParticipantIds: [participantId]
                )
            ]
        )

        planning.removeParticipant(participantId)

        XCTAssertTrue(
            planning.preparationItems[0].assigneeParticipantIds.isEmpty
        )
        XCTAssertTrue(
            planning.timelineEntries[0].assigneeParticipantIds.isEmpty
        )
    }

    func testRemovingDrinkOptionClearsEveryChoiceReference() {
        let participantId = UUID()
        let removedOptionId = UUID()
        let retainedOptionId = UUID()
        var plan = EventFirstDrinkPlan(
            options: [
                DrinkOption(id: removedOptionId, name: "Beer"),
                DrinkOption(id: retainedOptionId, name: "Tea")
            ],
            selections: [
                FirstDrinkSelection(
                    participantId: participantId,
                    firstChoiceId: removedOptionId,
                    secondChoiceId: retainedOptionId,
                    thirdChoiceId: removedOptionId
                )
            ]
        )

        plan.removeOption(removedOptionId)

        XCTAssertEqual(plan.options.map(\.id), [retainedOptionId])
        XCTAssertNil(plan.selections[0].firstChoiceId)
        XCTAssertEqual(plan.selections[0].secondChoiceId, retainedOptionId)
        XCTAssertNil(plan.selections[0].thirdChoiceId)
    }

    func testRemovingParticipantCleansFirstDrinkSelection() {
        let participantId = UUID()
        var planning = EventPlanningState(
            features: EventType.drinkingParty.defaultFeatures,
            firstDrinkPlan: EventFirstDrinkPlan(
                selections: [
                    FirstDrinkSelection(participantId: participantId)
                ]
            )
        )

        planning.removeParticipant(participantId)

        XCTAssertTrue(planning.firstDrinkPlan.selections.isEmpty)
    }

    func testRemovingParticipantCleansSeatingAssignment() {
        let participantId = UUID()
        var planning = EventPlanningState(
            features: EventType.party.defaultFeatures,
            seatingPlan: EventSeatingPlan(
                tables: [
                    SeatingTable(
                        name: "A",
                        assignments: [
                            SeatingAssignment(
                                seatNumber: 1,
                                participantId: participantId
                            )
                        ]
                    )
                ]
            )
        )

        planning.removeParticipant(participantId)

        XCTAssertTrue(planning.seatingPlan.tables[0].assignments.isEmpty)
    }

    func testSeatingPlanAssignsParticipantsInSeatOrder() {
        let participantIds = [UUID(), UUID(), UUID()]
        var plan = EventSeatingPlan(
            tables: [
                SeatingTable(name: "A", seatCount: 2),
                SeatingTable(name: "B", seatCount: 2)
            ]
        )

        plan.assignParticipants(participantIds)

        XCTAssertEqual(
            plan.tables.flatMap(\.assignments).map(\.participantId),
            participantIds
        )
        XCTAssertEqual(plan.tables[0].assignments.map(\.seatNumber), [1, 2])
        XCTAssertEqual(plan.tables[1].assignments.map(\.seatNumber), [1])
    }

    func testDuplicateOrganizerToolsMapsReferencesAndResetsProgress() {
        let oldParticipantId = UUID()
        let newParticipantId = UUID()
        let oldPartId = UUID()
        let newPartId = UUID()
        let planning = EventPlanningState(
            features: EventType.party.defaultFeatures,
            preparationItems: [
                EventPreparationItem(
                    title: "Cake",
                    assigneeParticipantIds: [oldParticipantId],
                    partId: oldPartId,
                    status: .ready
                )
            ],
            timelineEntries: [
                EventTimelineEntry(
                    title: "Toast",
                    startAt: Date(timeIntervalSince1970: 1_000),
                    assigneeParticipantIds: [oldParticipantId],
                    partId: oldPartId,
                    isCompleted: true
                )
            ]
        )

        let copy = planning.duplicated(
            using: [oldParticipantId: newParticipantId],
            partMap: [oldPartId: newPartId]
        )

        XCTAssertEqual(copy.preparationItems[0].status, .assigned)
        XCTAssertEqual(
            copy.preparationItems[0].assigneeParticipantIds,
            [newParticipantId]
        )
        XCTAssertEqual(copy.preparationItems[0].partId, newPartId)
        XCTAssertFalse(copy.timelineEntries[0].isCompleted)
        XCTAssertEqual(
            copy.timelineEntries[0].assigneeParticipantIds,
            [newParticipantId]
        )
        XCTAssertEqual(copy.timelineEntries[0].partId, newPartId)
    }

    func testDuplicateBudgetMapsParticipantsAndReopensApproval() {
        let oldOrganizerId = UUID()
        let oldSubsidizedId = UUID()
        let newOrganizerId = UUID()
        let newSubsidizedId = UUID()
        let planning = EventPlanningState(
            features: EventType.meal.defaultFeatures,
            budgetPlan: EventBudgetPlan(
                totalLimitMinorUnits: 50_000,
                organizerParticipantId: oldOrganizerId,
                organizerAdvanceLimitMinorUnits: 20_000,
                companySubsidyMinorUnits: 1_000,
                companySubsidyMode: .perParticipant,
                companySubsidyAppliesToAll: false,
                subsidizedParticipantIds: [oldSubsidizedId],
                approvalStatus: .approved
            )
        )

        let copy = planning.duplicated(
            using: [
                oldOrganizerId: newOrganizerId,
                oldSubsidizedId: newSubsidizedId
            ],
            partMap: [:]
        )

        XCTAssertEqual(copy.budgetPlan.totalLimitMinorUnits, 50_000)
        XCTAssertEqual(copy.budgetPlan.organizerParticipantId, newOrganizerId)
        XCTAssertEqual(
            copy.budgetPlan.subsidizedParticipantIds,
            [newSubsidizedId]
        )
        XCTAssertEqual(copy.budgetPlan.approvalStatus, .pending)
    }

    func testDuplicateFirstDrinkCopiesMenuAndResetsSelections() {
        let option = DrinkOption(
            name: "Sparkling Water",
            isAlcoholic: false,
            isToastOption: true
        )
        let planning = EventPlanningState(
            features: EventType.drinkingParty.defaultFeatures,
            firstDrinkPlan: EventFirstDrinkPlan(
                options: [option],
                selections: [
                    FirstDrinkSelection(
                        participantId: UUID(),
                        firstChoiceId: option.id,
                        secondChoiceId: option.id
                    )
                ],
                responseDeadline: Date(timeIntervalSince1970: 2_000)
            )
        )

        let copy = planning.duplicated(using: [:], partMap: [:])

        XCTAssertEqual(copy.firstDrinkPlan.options.count, 1)
        XCTAssertEqual(copy.firstDrinkPlan.options[0].name, option.name)
        XCTAssertNotEqual(copy.firstDrinkPlan.options[0].id, option.id)
        XCTAssertTrue(copy.firstDrinkPlan.selections.isEmpty)
        XCTAssertEqual(
            copy.firstDrinkPlan.responseDeadline,
            Date(timeIntervalSince1970: 2_000)
        )
    }

    func testDuplicatePlanningKeepsMeetingInstructionsAndPhoto() {
        let meetingAt = Date(timeIntervalSince1970: 2_000)
        let photo = Data([1, 2, 3])
        let planning = EventPlanningState(
            features: EventType.party.defaultFeatures,
            meetingPlan: EventMeetingPlan(
                name: "Central Gate",
                instructions: "Next to the clock",
                meetingAt: meetingAt,
                photoData: photo
            )
        )

        let copy = planning.duplicated(using: [:], partMap: [:])

        XCTAssertEqual(copy.meetingPlan.name, "Central Gate")
        XCTAssertEqual(copy.meetingPlan.instructions, "Next to the clock")
        XCTAssertEqual(copy.meetingPlan.meetingAt, meetingAt)
        XCTAssertEqual(copy.meetingPlan.photoData, photo)
    }

    func testDuplicateSeatingCopiesTablesAndResetsAssignments() {
        let table = SeatingTable(
            name: "VIP",
            seatCount: 6,
            assignments: [
                SeatingAssignment(seatNumber: 1, participantId: UUID())
            ]
        )
        let planning = EventPlanningState(
            features: EventType.party.defaultFeatures,
            seatingPlan: EventSeatingPlan(tables: [table])
        )

        let copy = planning.duplicated(using: [:], partMap: [:])

        XCTAssertEqual(copy.seatingPlan.tables.count, 1)
        XCTAssertEqual(copy.seatingPlan.tables[0].name, "VIP")
        XCTAssertEqual(copy.seatingPlan.tables[0].seatCount, 6)
        XCTAssertNotEqual(copy.seatingPlan.tables[0].id, table.id)
        XCTAssertTrue(copy.seatingPlan.tables[0].assignments.isEmpty)
    }

    func testDuplicateCoordinationResetsVotesAndReservation() {
        let optionId = UUID()
        let candidateId = UUID()
        let participantId = UUID()
        let planning = EventPlanningState(
            features: EventType.meal.defaultFeatures,
            schedulePoll: EventSchedulePoll(
                options: [
                    ScheduleOption(
                        id: optionId,
                        startAt: Date(timeIntervalSince1970: 1_000)
                    )
                ],
                responses: [SchedulePollResponse(participantId: participantId)],
                finalizedOptionId: optionId
            ),
            venuePlanning: EventVenuePlanning(
                candidates: [
                    VenueCandidate(
                        id: candidateId,
                        name: "Cafe",
                        votes: [
                            VenueVote(participantId: participantId, choice: .yes)
                        ]
                    )
                ],
                selectedCandidateId: candidateId,
                reservation: EventReservation(venueName: "Cafe")
            )
        )

        let copy = planning.duplicated(using: [:], partMap: [:])

        XCTAssertEqual(copy.schedulePoll.options.count, 1)
        XCTAssertNotEqual(copy.schedulePoll.options[0].id, optionId)
        XCTAssertTrue(copy.schedulePoll.responses.isEmpty)
        XCTAssertNil(copy.schedulePoll.finalizedOptionId)
        XCTAssertEqual(copy.venuePlanning.candidates.count, 1)
        XCTAssertNotEqual(copy.venuePlanning.candidates[0].id, candidateId)
        XCTAssertTrue(copy.venuePlanning.candidates[0].votes.isEmpty)
        XCTAssertNil(copy.venuePlanning.selectedCandidateId)
        XCTAssertNil(copy.venuePlanning.reservation)
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

    func testReceptionSynchronizesParticipantsAndPreservesStatus() {
        let firstId = UUID()
        let secondId = UUID()
        let checkedInAt = Date(timeIntervalSince1970: 1_000)
        let token = UUID()
        var reception = EventReceptionPlan(
            entries: [
                ReceptionEntry(
                    participantId: firstId,
                    token: token,
                    checkedInAt: checkedInAt
                )
            ]
        )

        reception.synchronize(with: [firstId, secondId])

        XCTAssertEqual(reception.entries.map(\.participantId), [firstId, secondId])
        XCTAssertEqual(reception.entries[0].token, token)
        XCTAssertEqual(reception.entries[0].checkedInAt, checkedInAt)
        XCTAssertNotEqual(reception.entries[1].token, token)

        let tokens = reception.entries.map(\.token)
        reception.synchronize(with: [firstId, secondId])
        XCTAssertEqual(reception.entries.map(\.token), tokens)
    }

    func testRemovingParticipantCleansReceptionEntry() {
        let participantId = UUID()
        var planning = EventPlanningState(
            features: EventType.party.defaultFeatures,
            receptionPlan: EventReceptionPlan(
                entries: [ReceptionEntry(participantId: participantId)]
            )
        )

        planning.removeParticipant(participantId)

        XCTAssertTrue(planning.receptionPlan.entries.isEmpty)
    }

    func testDuplicateReceptionCreatesFreshPassAndClearsCheckIn() {
        let oldParticipantId = UUID()
        let newParticipantId = UUID()
        let oldEntry = ReceptionEntry(
            participantId: oldParticipantId,
            checkedInAt: Date(timeIntervalSince1970: 1_000)
        )
        let planning = EventPlanningState(
            features: EventType.party.defaultFeatures,
            receptionPlan: EventReceptionPlan(entries: [oldEntry])
        )

        let copy = planning.duplicated(
            using: [oldParticipantId: newParticipantId],
            partMap: [:]
        )

        XCTAssertEqual(copy.receptionPlan.entries.count, 1)
        XCTAssertEqual(
            copy.receptionPlan.entries[0].participantId,
            newParticipantId
        )
        XCTAssertNotEqual(copy.receptionPlan.entries[0].token, oldEntry.token)
        XCTAssertNil(copy.receptionPlan.entries[0].checkedInAt)
    }

    func testReceptionQRCodeOnlyAcceptsMatchingEvent() {
        let eventId = UUID()
        let entry = ReceptionEntry(participantId: UUID())
        let payload = entry.qrPayload(eventId: eventId)

        XCTAssertEqual(
            ReceptionEntry.token(from: payload, eventId: eventId),
            entry.token
        )
        XCTAssertNil(
            ReceptionEntry.token(from: payload, eventId: UUID())
        )
        XCTAssertNil(
            ReceptionEntry.token(from: "https://example.com", eventId: eventId)
        )
    }

    func testCustomEventTypeAppearsAfterOther() {
        XCTAssertEqual(Array(EventType.allCases.suffix(2)), [.other, .custom])
    }

    func testCustomEventTypeRoundTripKeepsTemplateAndEventSnapshot() throws {
        let definition = CustomEventTypeDefinition(
            name: "Movie Night",
            symbolName: "film.fill",
            features: EventFeatureConfiguration(
                enabled: [.attendance, .expenseTracking, .games]
            )
        )
        let profile = LocalProfile(
            name: "Owner",
            customEventTypes: [definition]
        )
        let event = Event(
            title: "Friday",
            eventType: .custom,
            customEventType: definition.snapshot,
            planning: EventPlanningState(features: definition.features)
        )
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let restoredProfile = try decoder.decode(
            LocalProfile.self,
            from: encoder.encode(profile)
        )
        let restoredEvent = try decoder.decode(
            Event.self,
            from: encoder.encode(event)
        )

        XCTAssertEqual(restoredProfile.customEventTypes, [definition])
        XCTAssertEqual(restoredEvent.customEventType, definition.snapshot)
        XCTAssertEqual(restoredEvent.eventTypeDisplayName(for: .english), "Movie Night")
        XCTAssertEqual(restoredEvent.eventTypeSymbolName, "film.fill")
        XCTAssertEqual(restoredEvent.planning.features, definition.features)
    }

    func testCustomEventTypeRejectsUnsupportedSymbol() {
        let definition = CustomEventTypeDefinition(
            name: "Safe",
            symbolName: "not.a.real.symbol"
        )

        XCTAssertEqual(definition.symbolName, "star.fill")
    }

}
