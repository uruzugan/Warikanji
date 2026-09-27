import SwiftUI

private enum HomeSortOption: String, CaseIterable, Identifiable {
    case dateAscending, dateDescending, nameAscending, nameDescending, amountDescending, amountAscending
    var id: String { rawValue }
}

struct HomeView: View {
    @EnvironmentObject private var viewModel: EventViewModel
    @EnvironmentObject private var profileStore: ProfileStore
    @ObservedObject private var lifecycleStore = EventLifecycleStore.shared

    @State private var isShowingCreateSheet = false
    @State private var isShowingSettings = false
    @State private var eventPendingDeletion: Event?
    @State private var showingArchived = false
    @State private var searchText = ""
    @State private var selectedEventType: EventType?
    @State private var sortOption: HomeSortOption = .dateAscending

    private var language: AppLanguage { profileStore.activeLanguage }
    private var referenceCurrency: AppCurrency { profileStore.activeReferenceCurrency }
    private var userName: String { profileStore.activeProfile?.name.trimmingCharacters(in: .whitespacesAndNewlines) ?? "" }
    private var sortStorageKey: String { "homeSortOption.\(profileStore.activeProfile?.id.uuidString ?? "default")" }
    private var scopeEvents: [Event] { viewModel.events.filter { lifecycleStore.isArchived($0.id) == showingArchived } }

    private var visibleEvents: [Event] {
        let filtered = scopeEvents.filter { event in
            let typeMatches = selectedEventType == nil || event.eventType == selectedEventType
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !query.isEmpty else { return typeMatches }

            return typeMatches &&
                [event.displayTitle(for: language), event.location, event.memo, event.eventType.displayName(for: language)]
                .contains { $0.localizedCaseInsensitiveContains(query) }
        }

        return filtered.sorted(by: sortEvents)
    }

    private var usesReferenceConversion: Bool {
        visibleEvents.contains { $0.currency != referenceCurrency && $0.totalExpenseAmount > 0 }
    }

    private var isFiltering: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedEventType != nil
    }

    private func t(_ ja: String, _ en: String, _ zhHans: String, _ zhHant: String, _ ko: String, _ es: String, _ pt: String) -> String {
        language.text(ja: ja, en: en, zhHans: zhHans, zhHant: zhHant, ko: ko, es: es, pt: pt)
    }

    private var greetingText: String {
        guard !userName.isEmpty else {
            return t("こんにちは！", "Hello!", "你好！", "你好！", "안녕하세요!", "¡Hola!", "Olá!")
        }

        return t("こんにちは、\(userName)さん！", "Hello, \(userName)!", "你好，\(userName)！", "你好，\(userName)！", "안녕하세요, \(userName)님!", "¡Hola, \(userName)!", "Olá, \(userName)!")
    }

    private var searchPrompt: String {
        t("イベントを検索", "Search events", "搜索活动", "搜尋活動", "이벤트 검색", "Buscar eventos", "Pesquisar eventos")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                if viewModel.events.isEmpty {
                    emptyStateView
                } else {
                    eventListView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: searchPrompt)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { isShowingSettings = true } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(AppTheme.primary)
                    }
                    .accessibilityLabel(language.t(.settings))

                    Button { isShowingCreateSheet = true } label: {
                        Image(systemName: "plus")
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .frame(width: 34, height: 34)
                            .background(AppTheme.gradient)
                            .clipShape(Circle())
                    }
                    .accessibilityLabel(language.eventText(.newEvent))
                }
            }
            .sheet(isPresented: $isShowingCreateSheet) {
                EventCreateView()
                    .environmentObject(viewModel)
                    .environmentObject(profileStore)
            }
            .sheet(isPresented: $isShowingSettings) {
                AppSettingsView()
                    .environmentObject(profileStore)
            }
            .confirmationDialog(
                deleteDialogTitle,
                isPresented: Binding(
                    get: { eventPendingDeletion != nil },
                    set: { if !$0 { eventPendingDeletion = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button(t("削除する", "Delete", "删除", "刪除", "삭제", "Eliminar", "Excluir"), role: .destructive) {
                    if let event = eventPendingDeletion { viewModel.deleteEvent(event) }
                    eventPendingDeletion = nil
                }

                Button(t("キャンセル", "Cancel", "取消", "取消", "취소", "Cancelar", "Cancelar"), role: .cancel) {
                    eventPendingDeletion = nil
                }
            }
            .onAppear { loadSortOption() }
            .onChange(of: profileStore.activeProfile?.id) { loadSortOption() }
            .onChange(of: sortOption) { saveSortOption() }
            .tint(AppTheme.primary)
        }
    }

    private var deleteDialogTitle: String {
        let title = eventPendingDeletion?.displayTitle(for: language) ?? ""
        return t("「\(title)」を削除しますか？", "Delete “\(title)”?", "删除“\(title)”吗？", "刪除「\(title)」嗎？", "“\(title)”을 삭제하시겠습니까?", "¿Eliminar «\(title)»?", "Excluir “\(title)”?")
    }

    private var brandHeader: some View {
        HStack(spacing: 13) {
            Image(systemName: "person.3.sequence.fill")
                .font(.system(size: 21, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 50, height: 50)
                .background(AppTheme.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 15))

            VStack(alignment: .leading, spacing: 2) {
                Text(language.appName)
                    .font(.system(size: 27, weight: .bold, design: .rounded))

                Text(language.tagline)
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    private var eventListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                brandHeader
                welcomeCard

                Picker("", selection: $showingArchived) {
                    Text(t("進行中", "Active", "进行中", "進行中", "진행 중", "Activos", "Ativos")).tag(false)
                    Text(t("アーカイブ", "Archived", "已归档", "已封存", "보관됨", "Archivados", "Arquivados")).tag(true)
                }
                .pickerStyle(.segmented)

                HStack {
                    Text(showingArchived
                         ? t("アーカイブ", "Archived", "已归档", "已封存", "보관됨", "Archivados", "Arquivados")
                         : t("イベント", "Events", "活动", "活動", "이벤트", "Eventos", "Eventos"))
                        .font(.title3.bold())

                    Spacer()

                    Text(eventCountText)
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    eventTypeFilter
                    sortMenu
                }

                if visibleEvents.isEmpty {
                    filteredEmptyCard
                } else {
                    ForEach(visibleEvents) { event in
                        eventRow(event)
                    }
                }

                if usesReferenceConversion {
                    Link(destination: URL(string: "https://www.exchangerate-api.com")!) {
                        HStack(spacing: 4) {
                            Text("Rates By Exchange Rate API")
                            Image(systemName: "arrow.up.right")
                        }
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .padding(.bottom, 30)
        }
    }

    private var eventTypeFilter: some View {
        Menu {
            Button {
                selectedEventType = nil
            } label: {
                Label(
                    t("すべて", "All", "全部", "全部", "전체", "Todos", "Todos"),
                    systemImage: selectedEventType == nil ? "checkmark" : "circle"
                )
            }

            Divider()

            ForEach(EventType.allCases) { type in
                Button {
                    selectedEventType = type
                } label: {
                    Label(
                        type.displayName(for: language),
                        systemImage: selectedEventType == type ? "checkmark" : type.symbolName
                    )
                }
            }
        } label: {
            Image(systemName: selectedEventType == nil
                  ? "line.3.horizontal.decrease.circle"
                  : "line.3.horizontal.decrease.circle.fill")
                .font(.title3)
                .foregroundStyle(AppTheme.primary)
        }
    }

    private var sortMenu: some View {
        Menu {
            sortButton(.dateAscending, t("開催日が早い順", "Date: Earliest First", "日期：从早到晚", "日期：由早到晚", "날짜: 빠른 순", "Fecha: más próxima", "Data: mais próxima"), "calendar")
            sortButton(.dateDescending, t("開催日が遅い順", "Date: Latest First", "日期：从晚到早", "日期：由晚到早", "날짜: 늦은 순", "Fecha: más lejana", "Data: mais distante"), "calendar.badge.clock")

            Divider()

            sortButton(.nameAscending, t("名前 A→Z", "Name A→Z", "名称 A→Z", "名稱 A→Z", "이름 A→Z", "Nombre A→Z", "Nome A→Z"), "textformat")
            sortButton(.nameDescending, t("名前 Z→A", "Name Z→A", "名称 Z→A", "名稱 Z→A", "이름 Z→A", "Nombre Z→A", "Nome Z→A"), "textformat.size")

            Divider()

            sortButton(.amountDescending, t("金額が高い順", "Amount: High to Low", "金额：从高到低", "金額：由高到低", "금액: 높은 순", "Importe: mayor a menor", "Valor: maior para menor"), "banknote.fill")
            sortButton(.amountAscending, t("金額が安い順", "Amount: Low to High", "金额：从低到高", "金額：由低到高", "금액: 낮은 순", "Importe: menor a mayor", "Valor: menor para maior"), "banknote")

            Divider()

            Label(
                t("この並び順は保存されます", "This sort order is saved", "此排序方式会被保存", "此排序方式會被儲存", "이 정렬 순서는 저장됩니다", "Este orden se guarda", "Esta ordenação é salva"),
                systemImage: "pin.fill"
            )
        } label: {
            Image(systemName: "arrow.up.arrow.down.circle.fill")
                .font(.title3)
                .foregroundStyle(AppTheme.primary)
        }
    }

    @ViewBuilder
    private func sortButton(_ option: HomeSortOption, _ title: String, _ symbol: String) -> some View {
        Button {
            sortOption = option
        } label: {
            Label(title, systemImage: sortOption == option ? "checkmark" : symbol)
        }
    }

    private func eventRow(_ event: Event) -> some View {
        let isLocked = lifecycleStore.isLocked(event.id)

        return NavigationLink {
            EventDetailView(eventId: event.id)
                .environmentObject(viewModel)
                .environmentObject(profileStore)
        } label: {
            EventHomeCard(
                event: event,
                language: language,
                referenceCurrency: referenceCurrency,
                isLocked: isLocked,
                isArchived: showingArchived
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                lifecycleStore.setArchived(!showingArchived, for: event.id)
            } label: {
                Label(
                    showingArchived
                    ? t("アーカイブから戻す", "Restore", "恢复", "還原", "복원", "Restaurar", "Restaurar")
                    : t("アーカイブ", "Archive", "归档", "封存", "보관", "Archivar", "Arquivar"),
                    systemImage: showingArchived ? "tray.and.arrow.up" : "archivebox"
                )
            }

            if !isLocked {
                Button(role: .destructive) {
                    eventPendingDeletion = event
                } label: {
                    Label(t("イベントを削除", "Delete Event", "删除活动", "刪除活動", "이벤트 삭제", "Eliminar evento", "Excluir evento"), systemImage: "trash")
                }
            }
        }
    }

    private func sortEvents(_ lhs: Event, _ rhs: Event) -> Bool {
        switch sortOption {
        case .dateAscending:
            return lhs.date == rhs.date
                ? lhs.displayTitle(for: language).localizedStandardCompare(rhs.displayTitle(for: language)) == .orderedAscending
                : lhs.date < rhs.date

        case .dateDescending:
            return lhs.date == rhs.date
                ? lhs.displayTitle(for: language).localizedStandardCompare(rhs.displayTitle(for: language)) == .orderedAscending
                : lhs.date > rhs.date

        case .nameAscending:
            let comparison = lhs.displayTitle(for: language).localizedStandardCompare(rhs.displayTitle(for: language))
            return comparison == .orderedSame ? lhs.date < rhs.date : comparison == .orderedAscending

        case .nameDescending:
            let comparison = lhs.displayTitle(for: language).localizedStandardCompare(rhs.displayTitle(for: language))
            return comparison == .orderedSame ? lhs.date < rhs.date : comparison == .orderedDescending

        case .amountDescending:
            return lhs.totalExpenseAmount == rhs.totalExpenseAmount
                ? lhs.date < rhs.date
                : lhs.totalExpenseAmount > rhs.totalExpenseAmount

        case .amountAscending:
            return lhs.totalExpenseAmount == rhs.totalExpenseAmount
                ? lhs.date < rhs.date
                : lhs.totalExpenseAmount < rhs.totalExpenseAmount
        }
    }

    private func loadSortOption() {
        let saved = UserDefaults.standard.string(forKey: sortStorageKey)
        sortOption = saved.flatMap(HomeSortOption.init(rawValue:)) ?? .dateAscending
    }

    private func saveSortOption() {
        UserDefaults.standard.set(sortOption.rawValue, forKey: sortStorageKey)
    }

    private var eventCountText: String {
        let count = visibleEvents.count
        return t("\(count)件", "\(count)", "\(count)个", "\(count)個", "\(count)개", "\(count)", "\(count)")
    }

    private var filteredEmptyCard: some View {
        VStack(spacing: 12) {
            Image(systemName: isFiltering ? "magnifyingglass" : (showingArchived ? "archivebox" : "calendar"))
                .font(.system(size: 32))
                .foregroundStyle(AppTheme.primary)

            Text(emptyMessage)
                .font(.headline)
                .multilineTextAlignment(.center)

            if isFiltering {
                Button {
                    searchText = ""
                    selectedEventType = nil
                } label: {
                    Label(
                        t("検索・絞り込みを解除", "Clear Search & Filters", "清除搜索和筛选", "清除搜尋和篩選", "검색 및 필터 해제", "Quitar búsqueda y filtros", "Limpar pesquisa e filtros"),
                        systemImage: "xmark.circle"
                    )
                    .font(.subheadline.bold())
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .appCard()
    }

    private var emptyMessage: String {
        if isFiltering {
            return t("条件に合うイベントがありません", "No matching events", "没有符合条件的活动", "沒有符合條件的活動", "조건에 맞는 이벤트가 없습니다", "No hay eventos que coincidan", "Nenhum evento corresponde aos filtros")
        }

        return showingArchived
            ? t("アーカイブされたイベントはありません", "No archived events", "没有已归档的活动", "沒有已封存的活動", "보관된 이벤트가 없습니다", "No hay eventos archivados", "Não há eventos arquivados")
            : t("進行中のイベントはありません", "No active events", "没有进行中的活动", "沒有進行中的活動", "진행 중인 이벤트가 없습니다", "No hay eventos activos", "Não há eventos ativos")
    }

    private var welcomeCard: some View {
        HStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 23, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 58, height: 58)
                .background(.white.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(greetingText)
                    .font(.title3.bold())
                    .foregroundStyle(.white)

                Text(t("今日も幹事の仕事をサクッと片付けよう", "Let's make organizing simple today.", "今天也轻松搞定活动安排吧。", "今天也輕鬆搞定活動安排吧。", "오늘도 모임 준비를 간단하게 끝내봐요.", "Organicemos todo de forma sencilla hoy.", "Vamos organizar tudo de forma simples hoje."))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }

            Spacer()
        }
        .padding(18)
        .background(AppTheme.gradient)
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private var emptyStateView: some View {
        ScrollView {
            VStack(spacing: 24) {
                brandHeader
                welcomeCard

                VStack(spacing: 16) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 40))
                        .foregroundStyle(AppTheme.primary)
                        .frame(width: 100, height: 100)
                        .background(AppTheme.primary.opacity(0.1))
                        .clipShape(Circle())

                    Text(t("イベントを作ってみよう", "Create your first event", "创建你的第一个活动", "建立你的第一個活動", "첫 이벤트를 만들어 보세요", "Crea tu primer evento", "Crie seu primeiro evento"))
                        .font(.title3.bold())

                    Button { isShowingCreateSheet = true } label: {
                        Label(
                            t("イベントを作成", "Create Event", "创建活动", "建立活動", "이벤트 만들기", "Crear evento", "Criar evento"),
                            systemImage: "plus"
                        )
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppTheme.gradient)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                }
                .appCard()
            }
            .padding()
        }
    }
}

private struct EventHomeCard: View {
    let event: Event
    let language: AppLanguage
    let referenceCurrency: AppCurrency
    let isLocked: Bool
    let isArchived: Bool

    @State private var referenceAmount: Int?
    @State private var isLoadingReference = false
    @State private var referenceFailed = false

    private var conversionKey: String {
        "\(event.currency.code)-\(referenceCurrency.code)-\(event.totalExpenseAmount)"
    }

    private var needsReferenceConversion: Bool {
        event.currency != referenceCurrency && event.totalExpenseAmount > 0
    }

    private var paidCount: Int { event.transfers.filter(\.isPaid).count }

    private var statusColor: Color {
        if event.transfers.isEmpty { return AppTheme.warning }
        return event.transfers.allSatisfy(\.isPaid) ? AppTheme.success : AppTheme.primary
    }

    private var statusSymbol: String {
        if event.transfers.isEmpty { return "clock.fill" }
        return event.transfers.allSatisfy(\.isPaid) ? "checkmark.circle.fill" : "arrow.triangle.2.circlepath"
    }

    private var settlementText: String {
        event.transfers.isEmpty
            ? event.settlementStatusText(for: language)
            : "\(paidCount)/\(event.transfers.count)"
    }

    private func t(_ ja: String, _ en: String, _ zhHans: String, _ zhHant: String, _ ko: String, _ es: String, _ pt: String) -> String {
        language.text(ja: ja, en: en, zhHans: zhHans, zhHant: zhHant, ko: ko, es: es, pt: pt)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: event.eventType.symbolName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AppTheme.primary)
                    .frame(width: 48, height: 48)
                    .background(AppTheme.primary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 6) {
                        Text(event.displayTitle(for: language))
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        if isLocked {
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundStyle(AppTheme.primary)
                        }

                        if event.hasEnded && !isArchived {
                            Text(t("終了済み", "Ended", "已结束", "已結束", "종료됨", "Finalizado", "Encerrado"))
                                .font(.caption2.bold())
                                .foregroundStyle(AppTheme.warning)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(AppTheme.warning.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }

                    Label(event.scheduleText(for: language), systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    if !event.location.isEmpty {
                        Label(event.location, systemImage: "mappin")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.tertiary)
            }

            Divider()

            HStack {
                stat(
                    "\(event.calculationParticipantCount) \(language.participantUnit(for: event.calculationParticipantCount))",
                    symbol: "person.2.fill",
                    color: AppTheme.primary
                )

                Spacer()

                VStack(spacing: 3) {
                    stat(
                        event.currency.formatted(minorUnits: event.totalExpenseAmount),
                        symbol: "banknote.fill",
                        color: AppTheme.success
                    )

                    referenceStatus
                }

                Spacer()

                stat(settlementText, symbol: statusSymbol, color: statusColor)
            }
        }
        .appCard()
        .task(id: conversionKey) {
            await loadReferenceAmount()
        }
    }

    @ViewBuilder
    private var referenceStatus: some View {
        if needsReferenceConversion {
            if isLoadingReference {
                ProgressView()
                    .controlSize(.mini)

            } else if let referenceAmount {
                Text("≈ \(referenceCurrency.formatted(minorUnits: referenceAmount))")
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)

            } else if referenceFailed {
                Image(systemName: "exclamationmark.circle")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @MainActor
    private func loadReferenceAmount() async {
        referenceAmount = nil
        referenceFailed = false

        guard needsReferenceConversion else {
            isLoadingReference = false
            return
        }

        isLoadingReference = true

        do {
            referenceAmount = try await ExchangeRateService.shared.convert(
                minorUnits: event.totalExpenseAmount,
                from: event.currency,
                to: referenceCurrency
            )
        } catch {
            referenceFailed = true
        }

        isLoadingReference = false
    }

    private func stat(_ value: String, symbol: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: symbol)

            Text(value)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .font(.caption.bold())
        .foregroundStyle(color)
    }
}

#Preview {
    HomeView()
        .environmentObject(EventViewModel())
        .environmentObject(ProfileStore())
}
