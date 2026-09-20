import Foundation
import SwiftUI
import Combine

@MainActor
final class EventViewModel: ObservableObject {
    @Published var events: [Event] = []

    private let storage = JSONStorageService.shared
    private var activeProfileId: UUID?

    private var storageFilename: String? {
        guard let activeProfileId else { return nil }
        return "events-\(activeProfileId.uuidString).json"
    }

    init() {}

    func switchProfile(to profileId: UUID) {
        activeProfileId = profileId
        loadEvents()
    }

    func unloadProfile() {
        activeProfileId = nil
        events = []
    }

    func loadEvents() {
        guard let storageFilename else {
            events = []
            return
        }

        if let profileEvents = storage.load(
            [Event].self,
            filename: storageFilename
        ) {
            events = profileEvents
            return
        }

        if let legacyEvents = storage.load(
            [Event].self,
            filename: "events.json"
        ) {
            events = legacyEvents
            storage.save(
                legacyEvents,
                filename: storageFilename
            )
            storage.delete(filename: "events.json")
            return
        }

        events = []
    }

    func saveEvents() {
        guard let storageFilename else { return }
        storage.save(events, filename: storageFilename)
    }

    func isEventLocked(_ eventId: UUID) -> Bool {
        EventLifecycleStore.shared.isLocked(eventId)
    }

    func canEdit(_ eventId: UUID) -> Bool {
        !isEventLocked(eventId)
    }

    func indexOfEvent(_ eventId: UUID) -> Int? {
        events.firstIndex { $0.id == eventId }
    }

    func indexOfExpense(_ expenseId: UUID, in eventIndex: Int) -> Int? {
        events[eventIndex].expenses.firstIndex { $0.id == expenseId }
    }

    func addEvent(_ event: Event) {
        var updated = event
        updated.expectedParticipantCount = max(
            updated.expectedParticipantCount,
            updated.participants.count,
            1
        )

        events.append(updated)
        saveEvents()
    }

    func updateEvent(_ event: Event) {
        guard canEdit(event.id),
              let index = indexOfEvent(event.id) else { return }

        var updated = event
        updated.expectedParticipantCount = max(
            updated.expectedParticipantCount,
            updated.participants.count,
            1
        )

        events[index] = updated
        saveEvents()
    }

    func deleteEvent(_ event: Event) {
        guard canEdit(event.id) else { return }

        deleteReceiptImages(in: event)
        events.removeAll { $0.id == event.id }
        EventLifecycleStore.shared.removeState(for: event.id)
        saveEvents()
    }

    func deleteEvents(at offsets: IndexSet) {
        let allowed = IndexSet(
            offsets.filter {
                events.indices.contains($0) &&
                canEdit(events[$0].id)
            }
        )

        let deletingEvents = allowed.compactMap {
            events.indices.contains($0) ? events[$0] : nil
        }

        deletingEvents.forEach {
            deleteReceiptImages(in: $0)
            EventLifecycleStore.shared.removeState(for: $0.id)
        }

        events.remove(atOffsets: allowed)
        saveEvents()
    }

    func binding(for eventId: UUID) -> Binding<Event> {
        Binding(
            get: {
                self.event(for: eventId) ?? Event(title: "")
            },
            set: { newValue in
                self.updateEvent(newValue)
            }
        )
    }

    func event(for eventId: UUID) -> Event? {
        events.first { $0.id == eventId }
    }

    func addParticipant(_ participant: EventParticipant, to eventId: UUID) {
        guard canEdit(eventId),
              let index = indexOfEvent(eventId) else { return }

        events[index].participants.append(participant)
        events[index].expectedParticipantCount = max(
            events[index].expectedParticipantCount,
            events[index].participants.count,
            1
        )

        events[index].transfers = []
        prepareRandomOrders(at: index)
        saveEvents()
    }

    func updateParticipant(_ participant: EventParticipant, in eventId: UUID) {
        guard canEdit(eventId),
              let eventIndex = indexOfEvent(eventId),
              let participantIndex = events[eventIndex].participants.firstIndex(
                where: { $0.id == participant.id }
              ) else { return }

        events[eventIndex].participants[participantIndex] = participant
        saveEvents()
    }

    func deleteParticipant(participantId: UUID, from eventId: UUID) {
        guard canEdit(eventId),
              let eventIndex = indexOfEvent(eventId) else { return }

        events[eventIndex].participants.removeAll { $0.id == participantId }
        events[eventIndex].transfers = []
        prepareRandomOrders(at: eventIndex)
        saveEvents()
    }

    func deleteParticipants(at offsets: IndexSet, from eventId: UUID) {
        guard canEdit(eventId),
              let eventIndex = indexOfEvent(eventId) else { return }

        events[eventIndex].participants.remove(atOffsets: offsets)
        events[eventIndex].transfers = []
        prepareRandomOrders(at: eventIndex)
        saveEvents()
    }

    func participantName(for participantId: UUID?, in eventId: UUID) -> String {
        guard let participantId else { return "未設定" }
        guard let event = event(for: eventId) else { return "不明な参加者" }
        guard let participant = event.participants.first(
            where: { $0.id == participantId }
        ) else {
            return "不明な参加者"
        }

        return participant.name.isEmpty
            ? "不明な参加者"
            : participant.name
    }

    private func deleteReceiptImages(in event: Event) {
        let fileNames = event.expenses.flatMap(\.receiptImages)
        ReceiptImageStorage.shared.delete(fileNames)
    }
}
