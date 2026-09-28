import Foundation

struct EventMeetingPlan: Codable, Equatable {
    var name: String
    var instructions: String
    var meetingAt: Date?
    var photoData: Data?

    init(
        name: String = "",
        instructions: String = "",
        meetingAt: Date? = nil,
        photoData: Data? = nil
    ) {
        self.name = name
        self.instructions = instructions
        self.meetingAt = meetingAt
        self.photoData = photoData
    }

    var isConfigured: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
