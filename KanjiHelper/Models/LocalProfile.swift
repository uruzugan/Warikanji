import Foundation

struct LocalProfile: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var createdAt: Date
    var language: AppLanguage
    var homeCurrency: AppCurrency
    var referenceCurrency: AppCurrency

    init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = Date(),
        language: AppLanguage = .deviceDefault,
        homeCurrency: AppCurrency? = nil,
        referenceCurrency: AppCurrency? = nil
    ) {
        let defaultCurrency = homeCurrency
            ?? AppCurrency.deviceDefault(for: language)

        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.language = language
        self.homeCurrency = defaultCurrency
        self.referenceCurrency = referenceCurrency
            ?? defaultCurrency
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case createdAt
        case language
        case homeCurrency
        case referenceCurrency
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(
            keyedBy: CodingKeys.self
        )

        id = try container.decode(
            UUID.self,
            forKey: .id
        )

        name = try container.decode(
            String.self,
            forKey: .name
        )

        createdAt = try container.decodeIfPresent(
            Date.self,
            forKey: .createdAt
        ) ?? Date()

        language = try container.decodeIfPresent(
            AppLanguage.self,
            forKey: .language
        ) ?? .deviceDefault

        let defaultCurrency = AppCurrency.deviceDefault(
            for: language
        )

        homeCurrency = try container.decodeIfPresent(
            AppCurrency.self,
            forKey: .homeCurrency
        ) ?? defaultCurrency

        referenceCurrency = try container.decodeIfPresent(
            AppCurrency.self,
            forKey: .referenceCurrency
        ) ?? homeCurrency
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(
            keyedBy: CodingKeys.self
        )

        try container.encode(
            id,
            forKey: .id
        )

        try container.encode(
            name,
            forKey: .name
        )

        try container.encode(
            createdAt,
            forKey: .createdAt
        )

        try container.encode(
            language,
            forKey: .language
        )

        try container.encode(
            homeCurrency,
            forKey: .homeCurrency
        )

        try container.encode(
            referenceCurrency,
            forKey: .referenceCurrency
        )
    }
}
