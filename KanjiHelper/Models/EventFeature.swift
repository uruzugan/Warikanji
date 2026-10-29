import Foundation

struct EventFeature: RawRepresentable, Codable, Hashable, Identifiable {
    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }

    init(from decoder: Decoder) throws {
        rawValue = try decoder.singleValueContainer().decode(String.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    var id: String { rawValue }

    static let expenseTracking = Self(rawValue: "expenseTracking")
    static let settlement = Self(rawValue: "settlement")
    static let attendance = Self(rawValue: "attendance")
    static let schedulingPoll = Self(rawValue: "schedulingPoll")
    static let venueCandidates = Self(rawValue: "venueCandidates")
    static let reservations = Self(rawValue: "reservations")
    static let multipleParts = Self(rawValue: "multipleParts")
    static let dietaryNeeds = Self(rawValue: "dietaryNeeds")
    static let firstDrink = Self(rawValue: "firstDrink")
    static let meetingAndArrival = Self(rawValue: "meetingAndArrival")
    static let announcements = Self(rawValue: "announcements")
    static let weatherAndFallback = Self(rawValue: "weatherAndFallback")
    static let seating = Self(rawValue: "seating")
    static let reception = Self(rawValue: "reception")
    static let prepaidCollection = Self(rawValue: "prepaidCollection")
    static let budget = Self(rawValue: "budget")
    static let tasksAndItems = Self(rawValue: "tasksAndItems")
    static let timeline = Self(rawValue: "timeline")
    static let surprise = Self(rawValue: "surprise")
    static let sharedAlbum = Self(rawValue: "sharedAlbum")
    static let postEventSummary = Self(rawValue: "postEventSummary")
    static let groupMemory = Self(rawValue: "groupMemory")
    static let travel = Self(rawValue: "travel")
    static let vehicles = Self(rawValue: "vehicles")
    static let lodging = Self(rawValue: "lodging")
    static let bbqAndCamp = Self(rawValue: "bbqAndCamp")
    static let tickets = Self(rawValue: "tickets")
    static let clubActivities = Self(rawValue: "clubActivities")
    static let studySession = Self(rawValue: "studySession")
    static let games = Self(rawValue: "games")

    static let allKnown: [Self] = [
        .expenseTracking, .settlement, .attendance, .schedulingPoll,
        .venueCandidates, .reservations, .multipleParts, .dietaryNeeds,
        .firstDrink, .meetingAndArrival, .announcements, .weatherAndFallback,
        .seating, .reception, .prepaidCollection, .budget, .tasksAndItems,
        .timeline, .surprise, .sharedAlbum, .postEventSummary, .groupMemory,
        .travel, .vehicles, .lodging, .bbqAndCamp, .tickets, .clubActivities,
        .studySession, .games
    ]

    func displayName(for language: AppLanguage) -> String {
        guard let values = Self.localizedNames[rawValue] else { return rawValue }
        return values[language.featureNameIndex]
    }

    var symbolName: String {
        switch self {
        case .expenseTracking: return "banknote.fill"
        case .settlement: return "arrow.left.arrow.right.circle.fill"
        case .attendance: return "person.crop.circle.badge.checkmark"
        case .schedulingPoll: return "calendar.badge.questionmark"
        case .venueCandidates: return "mappin.and.ellipse"
        case .reservations: return "checkmark.seal.fill"
        case .multipleParts: return "square.stack.3d.up.fill"
        case .dietaryNeeds: return "fork.knife.circle.fill"
        case .firstDrink: return "wineglass.fill"
        case .meetingAndArrival: return "location.circle.fill"
        case .announcements: return "megaphone.fill"
        case .weatherAndFallback: return "cloud.sun.rain.fill"
        case .seating: return "chair.lounge.fill"
        case .reception: return "qrcode.viewfinder"
        case .prepaidCollection: return "creditcard.fill"
        case .budget: return "chart.pie.fill"
        case .tasksAndItems: return "checklist"
        case .timeline: return "clock.fill"
        case .surprise: return "gift.fill"
        case .sharedAlbum: return "photo.stack.fill"
        case .postEventSummary: return "chart.bar.fill"
        case .groupMemory: return "person.3.fill"
        case .travel: return "airplane"
        case .vehicles: return "car.fill"
        case .lodging: return "bed.double.fill"
        case .bbqAndCamp: return "flame.fill"
        case .tickets: return "ticket.fill"
        case .clubActivities: return "sportscourt.fill"
        case .studySession: return "book.fill"
        case .games: return "gamecontroller.fill"
        default: return "square.grid.2x2.fill"
        }
    }

    private static let localizedNames: [String: [String]] = [
        "expenseTracking": ["費用管理", "Expenses", "费用管理", "費用管理", "비용 관리", "Gastos", "Despesas"],
        "settlement": ["精算", "Settlement", "结算", "結算", "정산", "Liquidación", "Acerto"],
        "attendance": ["出欠確認", "Attendance", "出席确认", "出席確認", "참석 확인", "Asistencia", "Presença"],
        "schedulingPoll": ["日程投票", "Date Poll", "日期投票", "日期投票", "일정 투표", "Votación de fecha", "Votação de data"],
        "venueCandidates": ["店・場所候補", "Venue Candidates", "地点候选", "地點候選", "장소 후보", "Lugares candidatos", "Locais candidatos"],
        "reservations": ["予約管理", "Reservations", "预约管理", "預約管理", "예약 관리", "Reservas", "Reservas"],
        "multipleParts": ["一次会・二次会など", "Multiple Parts", "多个环节", "多個環節", "1차·2차 등", "Varias partes", "Várias etapas"],
        "dietaryNeeds": ["食事制限", "Dietary Needs", "饮食限制", "飲食限制", "식이 제한", "Necesidades alimentarias", "Restrições alimentares"],
        "firstDrink": ["一杯目", "First Drink", "第一杯饮品", "第一杯飲品", "첫 잔", "Primera bebida", "Primeira bebida"],
        "meetingAndArrival": ["集合・到着", "Meeting & Arrival", "集合・到达", "集合・到達", "집합·도착", "Encuentro y llegada", "Encontro e chegada"],
        "announcements": ["一斉連絡", "Announcements", "群发通知", "群發通知", "전체 공지", "Avisos", "Comunicados"],
        "weatherAndFallback": ["天気・代替案", "Weather & Fallback", "天气・备选方案", "天氣・備選方案", "날씨·대안", "Tiempo y alternativa", "Clima e alternativa"],
        "seating": ["席順", "Seating", "座位安排", "座位安排", "좌석 배치", "Asientos", "Lugares"],
        "reception": ["受付", "Check-in", "签到", "報到", "접수", "Registro", "Check-in"],
        "prepaidCollection": ["事前徴収", "Prepayment", "预收费用", "預收費用", "사전 징수", "Cobro anticipado", "Cobrança antecipada"],
        "budget": ["予算管理", "Budget", "预算管理", "預算管理", "예산 관리", "Presupuesto", "Orçamento"],
        "tasksAndItems": ["タスク・持ち物", "Tasks & Items", "任务・物品", "任務・物品", "작업·준비물", "Tareas y objetos", "Tarefas e itens"],
        "timeline": ["タイムライン", "Timeline", "时间线", "時間軸", "타임라인", "Cronograma", "Cronograma"],
        "surprise": ["サプライズ", "Surprise", "惊喜", "驚喜", "서프라이즈", "Sorpresa", "Surpresa"],
        "sharedAlbum": ["共有アルバム", "Shared Album", "共享相册", "共享相簿", "공유 앨범", "Álbum compartido", "Álbum compartilhado"],
        "postEventSummary": ["終了後まとめ", "Event Summary", "活动总结", "活動總結", "이벤트 요약", "Resumen del evento", "Resumo do evento"],
        "groupMemory": ["グループ・店舗履歴", "Group History", "群组・地点历史", "群組・地點記錄", "그룹·장소 기록", "Historial del grupo", "Histórico do grupo"],
        "travel": ["旅行", "Travel", "旅行", "旅行", "여행", "Viaje", "Viagem"],
        "vehicles": ["車・移動", "Vehicles", "车辆・移动", "車輛・移動", "차량·이동", "Vehículos", "Veículos"],
        "lodging": ["宿泊・部屋割り", "Lodging", "住宿・房间", "住宿・房間", "숙박·방 배정", "Alojamiento", "Hospedagem"],
        "bbqAndCamp": ["BBQ・キャンプ", "BBQ & Camp", "烧烤・露营", "烤肉・露營", "BBQ·캠프", "Barbacoa y campamento", "Churrasco e acampamento"],
        "tickets": ["チケット", "Tickets", "票券", "票券", "티켓", "Entradas", "Ingressos"],
        "clubActivities": ["サークル・部活", "Club Activities", "社团活动", "社團活動", "동아리 활동", "Actividades de club", "Atividades de clube"],
        "studySession": ["勉強会", "Study Session", "学习会", "學習會", "스터디", "Sesión de estudio", "Sessão de estudo"],
        "games": ["ゲーム会", "Games", "游戏会", "遊戲會", "게임 모임", "Juegos", "Jogos"]
    ]
}

private extension AppLanguage {
    var featureNameIndex: Int {
        switch self {
        case .japanese: return 0
        case .english: return 1
        case .simplifiedChinese: return 2
        case .traditionalChinese: return 3
        case .korean: return 4
        case .spanish: return 5
        case .portuguese: return 6
        }
    }
}

struct EventFeatureConfiguration: Codable, Equatable {
    var enabled: Set<EventFeature>

    init(enabled: Set<EventFeature> = []) {
        self.enabled = enabled
    }

    func contains(_ feature: EventFeature) -> Bool {
        enabled.contains(feature)
    }

    mutating func set(_ feature: EventFeature, enabled isEnabled: Bool) {
        if isEnabled {
            enabled.insert(feature)
        } else {
            enabled.remove(feature)
        }
    }

    mutating func useRecommendedFeatures(for eventType: EventType) {
        let knownFeatures = Set(EventFeature.allKnown)
        let unknownFeatures = enabled.subtracting(knownFeatures)
        enabled = unknownFeatures.union(eventType.defaultFeatures.enabled)
    }
}

extension EventType {
    var defaultFeatures: EventFeatureConfiguration {
        let core: Set<EventFeature> = [.expenseTracking, .settlement, .attendance]
        let coordination: Set<EventFeature> = [
            .schedulingPoll, .tasksAndItems, .timeline, .announcements,
            .meetingAndArrival, .postEventSummary
        ]
        let venue: Set<EventFeature> = [
            .venueCandidates, .reservations, .dietaryNeeds, .budget
        ]

        let enabled: Set<EventFeature>

        switch self {
        case .drinkingParty:
            enabled = core.union(coordination).union(venue).union([
                .multipleParts, .firstDrink, .seating, .prepaidCollection,
                .groupMemory
            ])
        case .meal:
            enabled = core.union(coordination).union(venue).union([
                .seating, .groupMemory
            ])
        case .travel:
            enabled = core.union(coordination).union([
                .multipleParts, .dietaryNeeds, .weatherAndFallback, .budget,
                .travel, .vehicles, .lodging, .sharedAlbum
            ])
        case .drive:
            enabled = core.union(coordination).union([
                .weatherAndFallback, .budget, .vehicles
            ])
        case .bbq, .camp:
            enabled = core.union(coordination).union(venue).union([
                .weatherAndFallback, .vehicles, .bbqAndCamp, .sharedAlbum
            ])
        case .party, .birthday, .farewell, .weddingAfterParty:
            enabled = core.union(coordination).union(venue).union([
                .multipleParts, .seating, .reception, .prepaidCollection,
                .surprise, .sharedAlbum
            ])
        case .liveEvent:
            enabled = core.union(coordination).union([
                .multipleParts, .meetingAndArrival, .budget, .tickets,
                .travel, .sharedAlbum
            ])
        case .reunion:
            enabled = core.union(coordination).union(venue).union([
                .multipleParts, .seating, .reception, .prepaidCollection,
                .sharedAlbum, .groupMemory
            ])
        case .studySession:
            enabled = core.union(coordination).union(venue).union([
                .studySession
            ])
        case .gameNight:
            enabled = core.union(coordination).union(venue).union([
                .games, .seating
            ])
        case .family:
            enabled = core.union(coordination).union([
                .dietaryNeeds, .vehicles, .travel, .sharedAlbum
            ])
        case .clubSports:
            enabled = core.union(coordination).union([
                .weatherAndFallback, .vehicles, .clubActivities, .budget
            ])
        case .other, .custom:
            enabled = core.union([.tasksAndItems, .timeline, .postEventSummary])
        }

        return EventFeatureConfiguration(enabled: enabled)
    }
}
