import Foundation

enum SplitMethod: String, Codable, CaseIterable, Identifiable {
    case equal = "均等"
    case custom = "カスタム"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .equal: return "equal.circle.fill"
        case .custom: return "slider.horizontal.3"
        }
    }

    func displayName(for language: AppLanguage) -> String {
        switch self {
        case .equal:
            return language.text(
                ja: "均等",
                en: "Equal",
                zhHans: "均分",
                zhHant: "均分",
                ko: "균등",
                es: "Igual",
                pt: "Igual"
            )

        case .custom:
            return language.text(
                ja: "カスタム",
                en: "Custom",
                zhHans: "自定义",
                zhHant: "自訂",
                ko: "사용자 지정",
                es: "Personalizado",
                pt: "Personalizado"
            )
        }
    }
}

struct ExpenseCondition: Identifiable, Codable, Equatable {
    var id: UUID
    var expenseId: UUID
    var participantId: UUID
    var isIncluded: Bool
    var customWeight: Double

    init(
        id: UUID = UUID(),
        expenseId: UUID,
        participantId: UUID,
        isIncluded: Bool = true,
        customWeight: Double = 1.0
    ) {
        self.id = id
        self.expenseId = expenseId
        self.participantId = participantId
        self.isIncluded = isIncluded
        self.customWeight = customWeight
    }
}
