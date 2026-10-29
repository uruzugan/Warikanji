import SwiftUI

struct CustomEventTypesView: View {
    @EnvironmentObject private var profileStore: ProfileStore

    private var language: AppLanguage { profileStore.activeLanguage }
    private var definitions: [CustomEventTypeDefinition] {
        profileStore.activeCustomEventTypes
    }

    var body: some View {
        List {
            Section {
                if definitions.isEmpty {
                    ContentUnavailableView(
                        text(
                            "カスタム種類はありません", "No Custom Types",
                            "暂无自定义类型", "尚無自訂類型",
                            "사용자 설정 유형이 없습니다", "No hay tipos personalizados",
                            "Não há tipos personalizados"
                        ),
                        systemImage: "slider.horizontal.3",
                        description: Text(
                            text(
                                "名前・アイコン・使用機能を決めて再利用できます。",
                                "Save a name, icon, and feature set for reuse.",
                                "保存名称、图标和功能组合以便重复使用。",
                                "儲存名稱、圖示與功能組合以便重複使用。",
                                "이름, 아이콘과 기능 구성을 저장해 재사용할 수 있습니다.",
                                "Guarda un nombre, icono y conjunto de funciones.",
                                "Salve nome, ícone e conjunto de recursos."
                            )
                        )
                    )
                } else {
                    ForEach(definitions) { definition in
                        NavigationLink {
                            CustomEventTypeEditView(definition: definition)
                        } label: {
                            Label(definition.name, systemImage: definition.symbolName)
                        }
                    }
                    .onDelete(perform: delete)
                }
            } footer: {
                Text(
                    text(
                        "種類を削除しても、作成済みイベントの名前・アイコン・データは残ります。",
                        "Deleting a type does not change existing events.",
                        "删除类型不会更改已创建的活动。",
                        "刪除類型不會變更已建立的活動。",
                        "유형을 삭제해도 기존 이벤트는 변경되지 않습니다.",
                        "Eliminar un tipo no cambia los eventos existentes.",
                        "Excluir um tipo não altera eventos existentes."
                    )
                )
            }
        }
        .navigationTitle(
            text(
                "カスタムイベント種類", "Custom Event Types",
                "自定义活动类型", "自訂活動類型",
                "사용자 설정 이벤트 유형", "Tipos de evento personalizados",
                "Tipos de evento personalizados"
            )
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    CustomEventTypeEditView(definition: nil)
                } label: {
                    Label(
                        text(
                            "追加", "Add", "添加", "新增", "추가", "Añadir", "Adicionar"
                        ),
                        systemImage: "plus"
                    )
                }
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        let ids = offsets.compactMap {
            definitions.indices.contains($0) ? definitions[$0].id : nil
        }
        for id in ids {
            profileStore.deleteCustomEventType(id: id)
        }
    }

    private func text(
        _ ja: String, _ en: String, _ zhHans: String, _ zhHant: String,
        _ ko: String, _ es: String, _ pt: String
    ) -> String {
        language.text(
            ja: ja, en: en, zhHans: zhHans, zhHant: zhHant,
            ko: ko, es: es, pt: pt
        )
    }
}

private struct CustomEventTypeEditView: View {
    @EnvironmentObject private var profileStore: ProfileStore
    @Environment(\.dismiss) private var dismiss

    private let id: UUID
    private let createdAt: Date

    @State private var name: String
    @State private var symbolName: String
    @State private var enabledFeatures: Set<EventFeature>

    private var language: AppLanguage { profileStore.activeLanguage }
    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    private let columns = Array(repeating: GridItem(.flexible()), count: 4)

    init(definition: CustomEventTypeDefinition?) {
        id = definition?.id ?? UUID()
        createdAt = definition?.createdAt ?? Date()
        _name = State(initialValue: definition?.name ?? "")
        _symbolName = State(initialValue: definition?.symbolName ?? "star.fill")
        _enabledFeatures = State(
            initialValue: definition?.features.enabled
                ?? EventType.other.defaultFeatures.enabled
        )
    }

    var body: some View {
        Form {
            Section(
                text("基本情報", "Basics", "基本信息", "基本資訊", "기본 정보", "Información básica", "Informações básicas")
            ) {
                TextField(
                    text("種類名", "Type Name", "类型名称", "類型名稱", "유형 이름", "Nombre del tipo", "Nome do tipo"),
                    text: $name
                )
            }

            Section(
                text("アイコン", "Icon", "图标", "圖示", "아이콘", "Icono", "Ícone")
            ) {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(CustomEventTypeDefinition.allowedSymbolNames, id: \.self) { symbol in
                        Button {
                            symbolName = symbol
                        } label: {
                            Image(systemName: symbol)
                                .font(.title2)
                                .foregroundStyle(
                                    symbolName == symbol ? .white : AppTheme.primary
                                )
                                .frame(maxWidth: .infinity)
                                .frame(height: 46)
                                .background(
                                    symbolName == symbol
                                        ? AppTheme.primary
                                        : AppTheme.primary.opacity(0.1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }

            Section {
                NavigationLink {
                    EventFeatureSettingsView(
                        enabledFeatures: $enabledFeatures,
                        eventType: .custom,
                        language: language
                    )
                } label: {
                    LabeledContent(
                        text(
                            "使用する機能", "Event Features", "活动功能", "活動功能",
                            "이벤트 기능", "Funciones", "Recursos"
                        ),
                        value: "\(enabledFeatures.intersection(Set(EventFeature.allKnown)).count)"
                    )
                }
            } footer: {
                Text(
                    text(
                        "この種類から新規作成するイベントの初期設定になります。",
                        "These become the defaults for new events of this type.",
                        "这些设置将成为此类型新活动的默认值。",
                        "這些設定將成為此類型新活動的預設值。",
                        "이 유형으로 만드는 새 이벤트의 기본 설정입니다.",
                        "Serán los valores iniciales de los nuevos eventos.",
                        "Serão os padrões dos novos eventos."
                    )
                )
            }
        }
        .navigationTitle(
            text(
                "カスタム種類", "Custom Type", "自定义类型", "自訂類型",
                "사용자 설정 유형", "Tipo personalizado", "Tipo personalizado"
            )
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(text("保存", "Save", "保存", "儲存", "저장", "Guardar", "Salvar")) {
                    save()
                }
                .disabled(trimmedName.isEmpty)
            }
        }
    }

    private func save() {
        let definition = CustomEventTypeDefinition(
            id: id,
            name: trimmedName,
            symbolName: symbolName,
            features: EventFeatureConfiguration(enabled: enabledFeatures),
            createdAt: createdAt
        )
        if profileStore.saveCustomEventType(definition) {
            dismiss()
        }
    }

    private func text(
        _ ja: String, _ en: String, _ zhHans: String, _ zhHant: String,
        _ ko: String, _ es: String, _ pt: String
    ) -> String {
        language.text(
            ja: ja, en: en, zhHans: zhHans, zhHant: zhHant,
            ko: ko, es: es, pt: pt
        )
    }
}
