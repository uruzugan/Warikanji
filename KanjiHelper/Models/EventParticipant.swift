import Foundation

struct EventParticipant: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String

    init(id: UUID = UUID(), name: String = "") {
        self.id = id
        self.name = name
    }

    var hasCustomName: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
