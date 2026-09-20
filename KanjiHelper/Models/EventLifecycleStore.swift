import Foundation
import Combine

struct EventLifecycleState: Codable, Equatable {
    var lockedAt: Date?
    var isArchived = false

    var isLocked: Bool { lockedAt != nil }
}

@MainActor
final class EventLifecycleStore: ObservableObject {
    static let shared = EventLifecycleStore()

    @Published private var states: [String: EventLifecycleState] = [:]

    private let key = "eventLifecycleStates"

    private init() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let saved = try? JSONDecoder().decode(
                [String: EventLifecycleState].self,
                from: data
              ) else {
            return
        }

        states = saved
    }

    func state(for eventId: UUID) -> EventLifecycleState {
        states[eventId.uuidString] ?? EventLifecycleState()
    }

    func isLocked(_ eventId: UUID) -> Bool {
        state(for: eventId).isLocked
    }

    func lockedAt(_ eventId: UUID) -> Date? {
        state(for: eventId).lockedAt
    }

    func lock(_ eventId: UUID) {
        var state = state(for: eventId)
        state.lockedAt = Date()
        states[eventId.uuidString] = state
        save()
    }

    func unlock(_ eventId: UUID) {
        var state = state(for: eventId)
        state.lockedAt = nil
        states[eventId.uuidString] = state
        save()
    }

    func isArchived(_ eventId: UUID) -> Bool {
        state(for: eventId).isArchived
    }

    func setArchived(_ archived: Bool, for eventId: UUID) {
        var state = state(for: eventId)
        state.isArchived = archived
        states[eventId.uuidString] = state
        save()
    }

    func removeState(for eventId: UUID) {
        states.removeValue(forKey: eventId.uuidString)
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(states) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
