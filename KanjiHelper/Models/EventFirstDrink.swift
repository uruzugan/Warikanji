import Foundation

struct DrinkOption: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var isAlcoholic: Bool
    var isToastOption: Bool

    init(
        id: UUID = UUID(),
        name: String,
        isAlcoholic: Bool = false,
        isToastOption: Bool = true
    ) {
        self.id = id
        self.name = name
        self.isAlcoholic = isAlcoholic
        self.isToastOption = isToastOption
    }
}

struct FirstDrinkSelection: Identifiable, Codable, Equatable {
    var id: UUID
    var participantId: UUID
    var firstChoiceId: UUID?
    var secondChoiceId: UUID?
    var thirdChoiceId: UUID?
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        participantId: UUID,
        firstChoiceId: UUID? = nil,
        secondChoiceId: UUID? = nil,
        thirdChoiceId: UUID? = nil,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.participantId = participantId
        self.firstChoiceId = firstChoiceId
        self.secondChoiceId = secondChoiceId
        self.thirdChoiceId = thirdChoiceId
        self.updatedAt = updatedAt
    }

    var isAnswered: Bool {
        firstChoiceId != nil
            && secondChoiceId != nil
            && firstChoiceId != secondChoiceId
    }
}

struct EventFirstDrinkPlan: Codable, Equatable {
    var options: [DrinkOption]
    var selections: [FirstDrinkSelection]
    var responseDeadline: Date?

    init(
        options: [DrinkOption] = [],
        selections: [FirstDrinkSelection] = [],
        responseDeadline: Date? = nil
    ) {
        self.options = options
        self.selections = selections
        self.responseDeadline = responseDeadline
    }

    mutating func removeOption(_ optionId: UUID) {
        options.removeAll { $0.id == optionId }
        for index in selections.indices {
            if selections[index].firstChoiceId == optionId {
                selections[index].firstChoiceId = nil
            }
            if selections[index].secondChoiceId == optionId {
                selections[index].secondChoiceId = nil
            }
            if selections[index].thirdChoiceId == optionId {
                selections[index].thirdChoiceId = nil
            }
        }
    }

    mutating func removeParticipant(_ participantId: UUID) {
        selections.removeAll { $0.participantId == participantId }
    }

    func duplicated() -> Self {
        Self(
            options: options.map {
                DrinkOption(
                    name: $0.name,
                    isAlcoholic: $0.isAlcoholic,
                    isToastOption: $0.isToastOption
                )
            },
            responseDeadline: responseDeadline
        )
    }
}
