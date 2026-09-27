import Foundation

enum ExpenseCategory: String, Codable, CaseIterable, Identifiable {
    case food = "食事代"
    case alcohol = "酒代"
    case transport = "交通費・旅費"
    case accommodation = "宿泊費"
    case venue = "会場費"
    case gift = "プレゼント代"
    case taxi = "タクシー代"
    case other = "その他"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .food: return "fork.knife"
        case .alcohol: return "wineglass"
        case .transport: return "tram.fill"
        case .accommodation: return "bed.double.fill"
        case .venue: return "building.2.fill"
        case .gift: return "gift.fill"
        case .taxi: return "car.fill"
        case .other: return "banknote.fill"
        }
    }

    func displayName(for language: AppLanguage) -> String {
        switch self {
        case .food:
            return language.text(
                ja: "食事代", en: "Food",
                zhHans: "餐饮费", zhHant: "餐飲費",
                ko: "식비", es: "Comida", pt: "Alimentação"
            )
        case .alcohol:
            return language.text(
                ja: "酒代", en: "Drinks",
                zhHans: "酒水费", zhHant: "酒水費",
                ko: "술값", es: "Bebidas", pt: "Bebidas"
            )
        case .transport:
            return language.text(
                ja: "交通費・旅費", en: "Transport & Travel",
                zhHans: "交通・旅行费", zhHant: "交通・旅費",
                ko: "교통·여행비", es: "Transporte y viaje", pt: "Transporte e viagem"
            )
        case .accommodation:
            return language.text(
                ja: "宿泊費", en: "Accommodation",
                zhHans: "住宿费", zhHant: "住宿費",
                ko: "숙박비", es: "Alojamiento", pt: "Hospedagem"
            )
        case .venue:
            return language.text(
                ja: "会場費", en: "Venue",
                zhHans: "场地费", zhHant: "場地費",
                ko: "장소 대여비", es: "Local", pt: "Local"
            )
        case .gift:
            return language.text(
                ja: "プレゼント代", en: "Gift",
                zhHans: "礼物费", zhHant: "禮物費",
                ko: "선물비", es: "Regalo", pt: "Presente"
            )
        case .taxi:
            return language.text(
                ja: "タクシー代", en: "Taxi",
                zhHans: "出租车费", zhHant: "計程車費",
                ko: "택시비", es: "Taxi", pt: "Táxi"
            )
        case .other:
            return language.text(
                ja: "その他", en: "Other",
                zhHans: "其他", zhHant: "其他",
                ko: "기타", es: "Otros", pt: "Outros"
            )
        }
    }
}

enum SettlementRounding: Int, Codable, CaseIterable, Identifiable {
    case exact = 1
    case hundred = 100
    case fiveHundred = 500
    case thousand = 1000

    var id: Int { rawValue }
}

struct Expense: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var category: ExpenseCategory
    var amount: Int
    var payerId: UUID?
    var splitMethod: SplitMethod
    var conditions: [ExpenseCondition]
    var rounding: SettlementRounding
    var remainderParticipantIds: [UUID]
    var receiptImageFileNames: [String]?
    var date: Date?

    var receiptImages: [String] { receiptImageFileNames ?? [] }

    static func untitledName(for language: AppLanguage) -> String {
        language.text(
            ja: "費用名未設定", en: "Untitled Expense",
            zhHans: "未命名费用", zhHant: "未命名費用",
            ko: "이름 없는 비용", es: "Gasto sin nombre", pt: "Despesa sem nome"
        )
    }

    func displayTitle(for language: AppLanguage) -> String {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedTitle.isEmpty ? Self.untitledName(for: language) : trimmedTitle
    }

    init(
        id: UUID = UUID(),
        title: String,
        category: ExpenseCategory = .other,
        amount: Int,
        payerId: UUID? = nil,
        splitMethod: SplitMethod = .equal,
        conditions: [ExpenseCondition] = [],
        rounding: SettlementRounding = .exact,
        remainderParticipantIds: [UUID] = [],
        receiptImageFileNames: [String]? = nil,
        date: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.amount = amount
        self.payerId = payerId
        self.splitMethod = splitMethod
        self.conditions = conditions
        self.rounding = rounding
        self.remainderParticipantIds = remainderParticipantIds
        self.receiptImageFileNames = receiptImageFileNames
        self.date = date
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, category, amount, payerId, splitMethod, conditions
        case rounding, remainderParticipantIds, receiptImageFileNames, date
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        category = try container.decodeIfPresent(ExpenseCategory.self, forKey: .category) ?? .other
        amount = try container.decode(Int.self, forKey: .amount)
        payerId = try container.decodeIfPresent(UUID.self, forKey: .payerId)
        splitMethod = try container.decodeIfPresent(SplitMethod.self, forKey: .splitMethod) ?? .equal
        conditions = try container.decodeIfPresent([ExpenseCondition].self, forKey: .conditions) ?? []
        rounding = try container.decodeIfPresent(SettlementRounding.self, forKey: .rounding) ?? .exact
        remainderParticipantIds = try container.decodeIfPresent([UUID].self, forKey: .remainderParticipantIds) ?? []
        receiptImageFileNames = try container.decodeIfPresent([String].self, forKey: .receiptImageFileNames)
        date = try container.decodeIfPresent(Date.self, forKey: .date)
    }
}
