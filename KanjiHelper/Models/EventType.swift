import Foundation

enum EventType: String, Codable, CaseIterable, Identifiable {
    case drinkingParty = "飲み会"
    case meal = "食事会"
    case travel = "旅行"
    case drive = "ドライブ"
    case bbq = "BBQ"
    case camp = "合宿"
    case party = "パーティー"
    case liveEvent = "ライブ・観戦"
    case reunion = "同窓会"
    case studySession = "勉強会・作業会"
    case gameNight = "ゲーム会"
    case birthday = "誕生日会"
    case farewell = "送別会"
    case weddingAfterParty = "結婚式二次会"
    case family = "家族イベント"
    case clubSports = "サークル・部活"
    case other = "その他"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .drinkingParty: return "wineglass.fill"
        case .meal: return "fork.knife"
        case .travel: return "airplane"
        case .drive: return "car.fill"
        case .bbq: return "flame.fill"
        case .camp: return "tent.fill"
        case .party: return "party.popper.fill"
        case .liveEvent: return "ticket.fill"
        case .reunion: return "person.3.fill"
        case .studySession: return "book.fill"
        case .gameNight: return "gamecontroller.fill"
        case .birthday: return "birthday.cake.fill"
        case .farewell: return "hands.clap.fill"
        case .weddingAfterParty: return "heart.fill"
        case .family: return "figure.2.and.child.holdinghands"
        case .clubSports: return "sportscourt.fill"
        case .other: return "calendar"
        }
    }

    func displayName(for language: AppLanguage) -> String {
        switch self {
        case .drinkingParty:
            return language.text(
                ja: "飲み会",
                en: "Drinking Party",
                zhHans: "聚会饮酒",
                zhHant: "聚會飲酒",
                ko: "술자리",
                es: "Reunión con bebidas",
                pt: "Encontro com bebidas"
            )

        case .meal:
            return language.text(
                ja: "食事会",
                en: "Meal",
                zhHans: "聚餐",
                zhHant: "聚餐",
                ko: "식사 모임",
                es: "Comida",
                pt: "Refeição"
            )

        case .travel:
            return language.text(
                ja: "旅行",
                en: "Trip",
                zhHans: "旅行",
                zhHant: "旅行",
                ko: "여행",
                es: "Viaje",
                pt: "Viagem"
            )

        case .drive:
            return language.text(
                ja: "ドライブ",
                en: "Drive",
                zhHans: "自驾",
                zhHant: "自駕",
                ko: "드라이브",
                es: "Paseo en coche",
                pt: "Passeio de carro"
            )

        case .bbq:
            return "BBQ"

        case .camp:
            return language.text(
                ja: "合宿",
                en: "Camp",
                zhHans: "露营",
                zhHant: "露營",
                ko: "캠프",
                es: "Campamento",
                pt: "Acampamento"
            )

        case .party:
            return language.text(
                ja: "パーティー",
                en: "Party",
                zhHans: "派对",
                zhHant: "派對",
                ko: "파티",
                es: "Fiesta",
                pt: "Festa"
            )

        case .liveEvent:
            return language.text(
                ja: "ライブ・観戦", en: "Live Event",
                zhHans: "演出・观赛", zhHant: "表演・觀賽",
                ko: "공연·관람", es: "Evento en vivo", pt: "Evento ao vivo"
            )

        case .reunion:
            return language.text(
                ja: "同窓会", en: "Reunion",
                zhHans: "同学会", zhHant: "同學會",
                ko: "동창회", es: "Reencuentro", pt: "Reencontro"
            )

        case .studySession:
            return language.text(
                ja: "勉強会・作業会", en: "Study Session",
                zhHans: "学习・工作会", zhHant: "學習・工作會",
                ko: "스터디·작업 모임", es: "Sesión de estudio", pt: "Sessão de estudo"
            )

        case .gameNight:
            return language.text(
                ja: "ゲーム会", en: "Game Night",
                zhHans: "游戏聚会", zhHant: "遊戲聚會",
                ko: "게임 모임", es: "Noche de juegos", pt: "Noite de jogos"
            )

        case .birthday:
            return language.text(
                ja: "誕生日会", en: "Birthday",
                zhHans: "生日会", zhHant: "生日會",
                ko: "생일 파티", es: "Cumpleaños", pt: "Aniversário"
            )

        case .farewell:
            return language.text(
                ja: "送別会", en: "Farewell Party",
                zhHans: "欢送会", zhHant: "歡送會",
                ko: "송별회", es: "Despedida", pt: "Despedida"
            )

        case .weddingAfterParty:
            return language.text(
                ja: "結婚式二次会", en: "Wedding After-party",
                zhHans: "婚礼二次会", zhHant: "婚禮二次會",
                ko: "결혼식 2차", es: "Fiesta posboda", pt: "Festa pós-casamento"
            )

        case .family:
            return language.text(
                ja: "家族イベント", en: "Family Event",
                zhHans: "家庭活动", zhHant: "家庭活動",
                ko: "가족 행사", es: "Evento familiar", pt: "Evento familiar"
            )

        case .clubSports:
            return language.text(
                ja: "サークル・部活", en: "Club & Sports",
                zhHans: "社团・运动队", zhHant: "社團・運動隊",
                ko: "동아리·부활동", es: "Club y deporte", pt: "Clube e esporte"
            )

        case .other:
            return language.text(
                ja: "その他",
                en: "Other",
                zhHans: "其他",
                zhHant: "其他",
                ko: "기타",
                es: "Otro",
                pt: "Outro"
            )
        }
    }

    func customSplitDescription(
        for language: AppLanguage
    ) -> String {
        switch self {
        case .drinkingParty:
            return language.text(
                ja: "飲酒量・食事量・途中参加などを考慮して、負担比率を調整できます。",
                en: "Adjust shares based on drinks, food and attendance time.",
                zhHans: "可根据饮酒量、食量和参加时间调整分摊比例。",
                zhHant: "可根據飲酒量、食量和參加時間調整分攤比例。",
                ko: "음주량, 식사량, 참여 시간에 따라 부담 비율을 조정할 수 있습니다.",
                es: "Ajusta el reparto según bebidas, comida y tiempo de asistencia.",
                pt: "Ajuste a divisão conforme bebidas, comida e tempo de participação."
            )

        case .meal:
            return language.text(
                ja: "食事量・注文内容・途中参加などを考慮して、負担比率を調整できます。",
                en: "Adjust shares based on food, orders and attendance time.",
                zhHans: "可根据食量、点餐内容和参加时间调整分摊比例。",
                zhHant: "可根據食量、點餐內容和參加時間調整分攤比例。",
                ko: "식사량, 주문 내용, 참여 시간에 따라 부담 비율을 조정할 수 있습니다.",
                es: "Ajusta el reparto según comida, pedidos y tiempo de asistencia.",
                pt: "Ajuste a divisão conforme comida, pedidos e tempo de participação."
            )

        case .drive:
            return language.text(
                ja: "運転・ガソリン代・高速代・乗車距離などを考慮して、負担比率を調整できます。",
                en: "Adjust shares based on driving, fuel, tolls and distance.",
                zhHans: "可根据驾驶、油费、过路费和距离调整分摊比例。",
                zhHant: "可根據駕駛、油費、過路費和距離調整分攤比例。",
                ko: "운전, 연료비, 통행료, 이동 거리에 따라 부담 비율을 조정할 수 있습니다.",
                es: "Ajusta el reparto según conducción, combustible, peajes y distancia.",
                pt: "Ajuste a divisão conforme direção, combustível, pedágios e distância."
            )

        case .travel:
            return language.text(
                ja: "宿泊・交通・運転・参加日数などを考慮して、負担比率を調整できます。",
                en: "Adjust shares based on lodging, transport and trip length.",
                zhHans: "可根据住宿、交通和参加天数调整分摊比例。",
                zhHant: "可根據住宿、交通和參加天數調整分攤比例。",
                ko: "숙박, 교통, 여행 기간에 따라 부담 비율을 조정할 수 있습니다.",
                es: "Ajusta el reparto según alojamiento, transporte y duración del viaje.",
                pt: "Ajuste a divisão conforme hospedagem, transporte e duração da viagem."
            )

        case .bbq, .camp, .party, .liveEvent, .reunion, .studySession,
             .gameNight, .birthday, .farewell, .weddingAfterParty,
             .family, .clubSports, .other:
            return language.text(
                ja: "イベントの内容に合わせて、負担比率を自由に調整できます。",
                en: "Adjust each person's share to match the event.",
                zhHans: "可根据活动情况自由调整每个人的分摊比例。",
                zhHant: "可根據活動情況自由調整每個人的分攤比例。",
                ko: "행사 상황에 맞게 각자의 부담 비율을 조정할 수 있습니다.",
                es: "Ajusta libremente la parte de cada persona según el evento.",
                pt: "Ajuste livremente a parte de cada pessoa conforme o evento."
            )
        }
    }
}
