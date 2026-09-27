import SwiftUI

struct EventFeatureSummaryCard: View {
    @Binding var enabledFeatures: Set<EventFeature>

    let eventType: EventType
    let language: AppLanguage

    var body: some View {
        NavigationLink {
            EventFeatureSettingsView(
                enabledFeatures: $enabledFeatures,
                eventType: eventType,
                language: language
            )
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "switch.2")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(AppTheme.primary.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 15))

                VStack(alignment: .leading, spacing: 3) {
                    Text(
                        language.text(
                            ja: "使用する機能", en: "Event Features",
                            zhHans: "活动功能", zhHant: "活動功能",
                            ko: "이벤트 기능", es: "Funciones del evento",
                            pt: "Recursos do evento"
                        )
                    )
                    .font(.headline)

                    Text(enabledCountText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.tertiary)
            }
            .appCard()
        }
        .buttonStyle(.plain)
    }

    private var enabledCountText: String {
        let count = enabledFeatures.intersection(Set(EventFeature.allKnown)).count

        return language.text(
            ja: "\(count)個を有効化中",
            en: "\(count) enabled",
            zhHans: "已启用\(count)项",
            zhHant: "已啟用\(count)項",
            ko: "\(count)개 활성화",
            es: "\(count) activadas",
            pt: "\(count) ativados"
        )
    }
}

struct EventFeatureSettingsView: View {
    @Binding var enabledFeatures: Set<EventFeature>

    let eventType: EventType
    let language: AppLanguage

    var body: some View {
        List {
            Section {
                Button(action: useRecommendedFeatures) {
                    Label(
                        language.text(
                            ja: "この種類のおすすめに戻す",
                            en: "Use Recommended Features",
                            zhHans: "恢复此类型的推荐设置",
                            zhHant: "恢復此類型的建議設定",
                            ko: "이 유형의 추천 기능 사용",
                            es: "Usar funciones recomendadas",
                            pt: "Usar recursos recomendados"
                        ),
                        systemImage: "wand.and.stars"
                    )
                }
            } footer: {
                Text(
                    language.text(
                        ja: "機能をOFFにしても入力済みデータは削除されません。",
                        en: "Turning off a feature does not delete its saved data.",
                        zhHans: "关闭功能不会删除已保存的数据。",
                        zhHant: "關閉功能不會刪除已儲存的資料。",
                        ko: "기능을 꺼도 저장된 데이터는 삭제되지 않습니다.",
                        es: "Desactivar una función no elimina sus datos guardados.",
                        pt: "Desativar um recurso não exclui os dados salvos."
                    )
                )
            }

            ForEach(featureGroups) { group in
                Section(group.title(for: language)) {
                    ForEach(group.features) { feature in
                        Toggle(isOn: binding(for: feature)) {
                            Label(
                                feature.displayName(for: language),
                                systemImage: feature.symbolName
                            )
                        }
                    }
                }
            }
        }
        .navigationTitle(
            language.text(
                ja: "使用する機能", en: "Event Features",
                zhHans: "活动功能", zhHant: "活動功能",
                ko: "이벤트 기능", es: "Funciones",
                pt: "Recursos"
            )
        )
        .navigationBarTitleDisplayMode(.inline)
    }

    private func binding(for feature: EventFeature) -> Binding<Bool> {
        Binding(
            get: { enabledFeatures.contains(feature) },
            set: { enabled in
                if enabled {
                    enabledFeatures.insert(feature)
                } else {
                    enabledFeatures.remove(feature)
                }
            }
        )
    }

    private func useRecommendedFeatures() {
        var configuration = EventFeatureConfiguration(enabled: enabledFeatures)
        configuration.useRecommendedFeatures(for: eventType)
        enabledFeatures = configuration.enabled
    }

    private var featureGroups: [EventFeatureGroup] {
        [
            EventFeatureGroup(
                id: "planning",
                names: ["準備・回答", "Planning & Responses", "准备・回答", "準備・回答", "준비·응답", "Preparación y respuestas", "Preparação e respostas"],
                features: [
                    .attendance, .schedulingPoll, .venueCandidates, .reservations,
                    .multipleParts, .dietaryNeeds, .firstDrink
                ]
            ),
            EventFeatureGroup(
                id: "dayOf",
                names: ["当日の進行", "Event Day", "当天进程", "當天進行", "당일 진행", "Día del evento", "Dia do evento"],
                features: [
                    .meetingAndArrival, .announcements, .weatherAndFallback,
                    .seating, .reception, .timeline
                ]
            ),
            EventFeatureGroup(
                id: "money",
                names: ["費用・支払い", "Money", "费用・付款", "費用・付款", "비용·결제", "Gastos y pagos", "Despesas e pagamentos"],
                features: [
                    .expenseTracking, .settlement, .prepaidCollection, .budget
                ]
            ),
            EventFeatureGroup(
                id: "organization",
                names: ["運営・終了後", "Organization & Follow-up", "运营・活动后", "營運・活動後", "운영·종료 후", "Organización y seguimiento", "Organização e acompanhamento"],
                features: [
                    .tasksAndItems, .surprise, .sharedAlbum, .postEventSummary,
                    .groupMemory
                ]
            ),
            EventFeatureGroup(
                id: "packs",
                names: ["イベント別機能", "Event Packs", "活动专用功能", "活動專用功能", "이벤트별 기능", "Funciones por evento", "Recursos por evento"],
                features: [
                    .travel, .vehicles, .lodging, .bbqAndCamp, .tickets,
                    .clubActivities, .studySession, .games
                ]
            )
        ]
    }
}

private struct EventFeatureGroup: Identifiable {
    let id: String
    let names: [String]
    let features: [EventFeature]

    func title(for language: AppLanguage) -> String {
        names[language.featureGroupIndex]
    }
}

private extension AppLanguage {
    var featureGroupIndex: Int {
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
