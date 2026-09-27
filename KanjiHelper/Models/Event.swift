import Foundation

struct Event: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var date: Date
    var endDate: Date
    var location: String
    var memo: String
    var eventType: EventType
    var currency: AppCurrency
    var expectedParticipantCount: Int
    var participants: [EventParticipant]
    var expenses: [Expense]
    var transfers: [Transfer]

    init(
        id: UUID = UUID(),
        title: String,
        date: Date = Date(),
        endDate: Date? = nil,
        location: String = "",
        memo: String = "",
        eventType: EventType = .other,
        currency: AppCurrency = .jpy,
        expectedParticipantCount: Int = 1,
        participants: [EventParticipant] = [],
        expenses: [Expense] = [],
        transfers: [Transfer] = []
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.endDate = max(endDate ?? date, date)
        self.location = location
        self.memo = memo
        self.eventType = eventType
        self.currency = currency
        self.expectedParticipantCount = max(1, expectedParticipantCount)
        self.participants = participants
        self.expenses = expenses
        self.transfers = transfers
        normalizeParticipantSlots()
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, date, endDate, location, memo, eventType, currency
        case expectedParticipantCount, participants, expenses, transfers
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        date = try container.decode(Date.self, forKey: .date)

        let savedEndDate = try container.decodeIfPresent(Date.self, forKey: .endDate)
        endDate = max(savedEndDate ?? date, date)

        location = try container.decodeIfPresent(String.self, forKey: .location) ?? ""
        memo = try container.decodeIfPresent(String.self, forKey: .memo) ?? ""
        eventType = try container.decodeIfPresent(EventType.self, forKey: .eventType) ?? .other
        currency = try container.decodeIfPresent(AppCurrency.self, forKey: .currency) ?? .jpy
        participants = try container.decodeIfPresent([EventParticipant].self, forKey: .participants) ?? []
        expenses = try container.decodeIfPresent([Expense].self, forKey: .expenses) ?? []
        transfers = try container.decodeIfPresent([Transfer].self, forKey: .transfers) ?? []

        let savedCount = try container.decodeIfPresent(Int.self, forKey: .expectedParticipantCount)
        expectedParticipantCount = max(1, savedCount ?? participants.count, participants.count)

        normalizeParticipantSlots()
    }

    var totalExpenseAmount: Int {
        expenses.reduce(0) { $0 + $1.amount }
    }

    static func untitledName(for language: AppLanguage) -> String {
        language.text(
            ja: "名称未設定", en: "Untitled Event",
            zhHans: "未命名活动", zhHant: "未命名活動",
            ko: "이름 없는 이벤트", es: "Evento sin nombre", pt: "Evento sem nome"
        )
    }

    func displayTitle(for language: AppLanguage) -> String {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedTitle.isEmpty ? Self.untitledName(for: language) : trimmedTitle
    }

    var calculationParticipantCount: Int {
        participants.count
    }

    var registeredParticipantCount: Int {
        participants.filter(\.hasCustomName).count
    }

    var minimumParticipantCount: Int {
        max(participantIdsInUse.count, 1)
    }

    private var participantIdsInUse: Set<UUID> {
        var ids = Set(participants.filter(\.hasCustomName).map(\.id))

        for expense in expenses {
            if let payerId = expense.payerId {
                ids.insert(payerId)
            }

            ids.formUnion(
                expense.conditions
                    .filter(\.isIncluded)
                    .map(\.participantId)
            )

            ids.formUnion(expense.remainderParticipantIds)
        }

        return ids
    }

    var canChangeCurrency: Bool {
        expenses.isEmpty
    }

    func settlementStatusText(for language: AppLanguage) -> String {
        if transfers.isEmpty {
            return expenses.isEmpty
                ? language.text(
                    ja: "未精算", en: "Not Settled",
                    zhHans: "未结算", zhHant: "未結算",
                    ko: "미정산", es: "Sin liquidar", pt: "Não acertado"
                )
                : language.text(
                    ja: "精算待ち", en: "Pending",
                    zhHans: "待结算", zhHant: "待結算",
                    ko: "정산 대기", es: "Pendiente", pt: "Pendente"
                )
        }

        return transfers.allSatisfy(\.isPaid)
            ? language.text(
                ja: "精算完了", en: "Settled",
                zhHans: "结算完成", zhHant: "結算完成",
                ko: "정산 완료", es: "Liquidado", pt: "Acertado"
            )
            : language.text(
                ja: "精算中", en: "In Progress",
                zhHans: "结算中", zhHant: "結算中",
                ko: "정산 중", es: "En proceso", pt: "Em andamento"
            )
    }

    func displayName(for participantId: UUID, language: AppLanguage) -> String {
        guard let index = participants.firstIndex(where: { $0.id == participantId }) else {
            return language.text(
                ja: "不明な参加者", en: "Unknown Participant",
                zhHans: "未知参与者", zhHant: "未知參加者",
                ko: "알 수 없는 참가자",
                es: "Participante desconocido",
                pt: "Participante desconhecido"
            )
        }

        let name = participants[index].name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard name.isEmpty else { return name }

        let number = index + 1

        switch language {
        case .japanese: return "参加者\(number)"
        case .english: return "Participant \(number)"
        case .simplifiedChinese: return "参与者\(number)"
        case .traditionalChinese: return "參加者\(number)"
        case .korean: return "참가자 \(number)"
        case .spanish, .portuguese: return "Participante \(number)"
        }
    }

    mutating func setParticipantCount(_ count: Int) {
        let targetCount = max(count, minimumParticipantCount, 1)
        let protectedIds = participantIdsInUse
        var removedIds = Set<UUID>()

        while participants.count > targetCount {
            guard let index = participants.lastIndex(where: { !protectedIds.contains($0.id) }) else {
                break
            }

            removedIds.insert(participants[index].id)
            participants.remove(at: index)
        }

        if !removedIds.isEmpty {
            for index in expenses.indices {
                expenses[index].conditions.removeAll { removedIds.contains($0.participantId) }
                expenses[index].remainderParticipantIds.removeAll { removedIds.contains($0) }
            }

            transfers = []
        }

        if participants.count < targetCount {
            participants += (participants.count..<targetCount).map { _ in EventParticipant() }
        }

        expectedParticipantCount = participants.count
    }

    mutating func normalizeParticipantSlots() {
        expectedParticipantCount = max(1, expectedParticipantCount)

        if participants.count < expectedParticipantCount {
            participants += (participants.count..<expectedParticipantCount).map { _ in
                EventParticipant()
            }
        }

        if participants.count > expectedParticipantCount {
            expectedParticipantCount = participants.count
        }
    }
}
