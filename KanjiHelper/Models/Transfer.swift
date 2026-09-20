import Foundation

struct Transfer: Identifiable, Codable, Equatable {
    var id: UUID
    var fromParticipantId: UUID
    var toParticipantId: UUID
    var amount: Int
    var isPaid: Bool

    init(
        id: UUID = UUID(),
        fromParticipantId: UUID,
        toParticipantId: UUID,
        amount: Int,
        isPaid: Bool = false
    ) {
        self.id = id
        self.fromParticipantId = fromParticipantId
        self.toParticipantId = toParticipantId
        self.amount = amount
        self.isPaid = isPaid
    }
}
