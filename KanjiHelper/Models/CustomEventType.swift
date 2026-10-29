import Foundation

struct CustomEventTypeDefinition: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var symbolName: String
    var features: EventFeatureConfiguration
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        symbolName: String = "star.fill",
        features: EventFeatureConfiguration = EventType.other.defaultFeatures,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.symbolName = Self.allowedSymbolNames.contains(symbolName)
            ? symbolName
            : "star.fill"
        self.features = features
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var snapshot: EventCustomTypeSnapshot {
        EventCustomTypeSnapshot(id: id, name: name, symbolName: symbolName)
    }

    static let allowedSymbolNames = [
        "star.fill", "sparkles", "person.3.fill", "fork.knife",
        "cup.and.saucer.fill", "music.note", "film.fill", "theatermasks.fill",
        "sportscourt.fill", "figure.run", "gamecontroller.fill", "book.fill",
        "paintpalette.fill", "camera.fill", "gift.fill", "heart.fill",
        "airplane", "car.fill", "tram.fill", "bicycle",
        "tent.fill", "flame.fill", "house.fill", "building.2.fill"
    ]

    private enum CodingKeys: String, CodingKey {
        case id, name, symbolName, features, createdAt, updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        let savedSymbol = try container.decodeIfPresent(
            String.self,
            forKey: .symbolName
        ) ?? "star.fill"
        symbolName = Self.allowedSymbolNames.contains(savedSymbol)
            ? savedSymbol
            : "star.fill"
        features = try container.decodeIfPresent(
            EventFeatureConfiguration.self,
            forKey: .features
        ) ?? EventType.other.defaultFeatures
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
            ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
            ?? createdAt
    }
}

struct EventCustomTypeSnapshot: Codable, Equatable {
    var id: UUID
    var name: String
    var symbolName: String
}
