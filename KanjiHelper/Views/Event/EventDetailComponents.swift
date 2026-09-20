import SwiftUI

struct EventDetailHero: View {
    @EnvironmentObject private var profileStore: ProfileStore

    let event: Event

    private var language: AppLanguage { profileStore.activeLanguage }

    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: event.eventType.symbolName)
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 58, height: 58)
                .background(.white.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 18))

            VStack(alignment: .leading, spacing: 5) {
                Text(event.eventType.displayName(for: language))
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.8))

                Text(event.title)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "sparkles")
                .foregroundStyle(.white.opacity(0.65))
        }
        .padding(18)
        .background(AppTheme.gradient)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

struct EventDetailSummary: View {
    @EnvironmentObject private var profileStore: ProfileStore

    let event: Event

    @State private var referenceAmount: Int?
    @State private var isLoadingReference = false
    @State private var referenceFailed = false

    private var language: AppLanguage { profileStore.activeLanguage }
    private var referenceCurrency: AppCurrency { profileStore.activeReferenceCurrency }

    private var conversionKey: String {
        "\(event.currency.code)-\(referenceCurrency.code)-\(event.totalExpenseAmount)"
    }

    private var needsReferenceConversion: Bool {
        event.currency != referenceCurrency && event.totalExpenseAmount > 0
    }

    private var statusText: String {
        event.settlementStatusText(for: language)
    }

    private var statusColor: Color {
        if event.transfers.isEmpty { return AppTheme.warning }
        return event.transfers.allSatisfy(\.isPaid) ? AppTheme.success : AppTheme.primary
    }

    private var statusSymbol: String {
        if event.transfers.isEmpty { return "clock.fill" }
        return event.transfers.allSatisfy(\.isPaid)
            ? "checkmark.circle.fill"
            : "arrow.triangle.2.circlepath"
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 0) {
                item(
                    language.eventText(.participants),
                    "\(event.participants.count) \(language.participantUnit(for: event.participants.count))",
                    "person.2.fill",
                    AppTheme.primary
                )

                Divider().frame(height: 46)

                item(
                    language.detail(.totalExpenses),
                    event.currency.formatted(minorUnits: event.totalExpenseAmount),
                    "banknote.fill",
                    AppTheme.success
                )

                Divider().frame(height: 46)

                item(
                    language.detail(.settlementStatus),
                    statusText,
                    statusSymbol,
                    statusColor
                )
            }

            if needsReferenceConversion {
                Divider()
                referenceConversionRow
            }
        }
        .appCard()
        .task(id: conversionKey) {
            await loadReferenceAmount()
        }
    }

    @ViewBuilder
    private var referenceConversionRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.left.arrow.right")
                .foregroundStyle(AppTheme.primary)

            if isLoadingReference {
                ProgressView()
                    .controlSize(.small)

                Text(language.detail(.converting))
                    .font(.caption)
                    .foregroundStyle(.secondary)

            } else if let referenceAmount {
                Text(
                    "≈ \(referenceCurrency.formatted(minorUnits: referenceAmount))"
                )
                .font(.subheadline.bold())
                .monospacedDigit()

                Spacer()

                Link(
                    "Rates By Exchange Rate API",
                    destination: URL(string: "https://www.exchangerate-api.com")!
                )
                .font(.caption2)
                .foregroundStyle(.secondary)

            } else if referenceFailed {
                Text(language.detail(.conversionUnavailable))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    Task {
                        await loadReferenceAmount()
                    }
                } label: {
                    Label(
                        language.detail(.retry),
                        systemImage: "arrow.clockwise"
                    )
                    .font(.caption.bold())
                }
                .buttonStyle(.borderless)
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

    private func item(
        _ title: String,
        _ value: String,
        _ symbol: String,
        _ color: Color
    ) -> some View {
        VStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.headline)
                .foregroundStyle(color)

            Text(value)
                .font(.subheadline.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct EventDetailInfo: View {
    @EnvironmentObject private var profileStore: ProfileStore

    let event: Event
    let onEdit: () -> Void

    private var language: AppLanguage { profileStore.activeLanguage }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(
                    language.detail(.eventInfo),
                    systemImage: "info.circle.fill"
                )
                .font(.headline)
                .foregroundStyle(AppTheme.primary)

                Spacer()

                Button(action: onEdit) {
                    Label(
                        language.detail(.edit),
                        systemImage: "pencil"
                    )
                    .font(.subheadline.bold())
                    .padding(.horizontal, 11)
                    .padding(.vertical, 7)
                    .background(AppTheme.primary.opacity(0.1))
                    .clipShape(Capsule())
                }
            }

            VStack(spacing: 0) {
                row(
                    language.eventText(.dateTime),
                    event.scheduleText(
                        for: language,
                        includeYear: true
                    ),
                    "calendar"
                )

                Divider().padding(.leading, 42)

                row(
                    language.eventText(.location),
                    event.location.isEmpty
                        ? language.detail(.notSet)
                        : event.location,
                    "mappin.and.ellipse"
                )

                if !event.memo.isEmpty {
                    Divider().padding(.leading, 42)

                    row(
                        language.eventText(.memo),
                        event.memo,
                        "note.text"
                    )
                }
            }
            .appCard()
        }
    }

    private func row(
        _ title: String,
        _ value: String,
        _ symbol: String
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.caption.bold())
                .foregroundStyle(AppTheme.primary)
                .frame(width: 30, height: 30)
                .background(AppTheme.primary.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.subheadline)
            }

            Spacer()
        }
        .padding(.vertical, 10)
    }
}

struct EventDetailMenu: View {
    @EnvironmentObject private var profileStore: ProfileStore

    let event: Event
    let eventId: UUID

    private var language: AppLanguage { profileStore.activeLanguage }
    private var paidCount: Int { event.transfers.filter(\.isPaid).count }
    private var registeredParticipantCount: Int { event.participants.filter(\.hasCustomName).count }

    private var participantSubtitle: String {
        switch language {
        case .japanese: return "登録済み \(registeredParticipantCount)人・予定 \(event.participants.count)人"
        case .english: return "\(registeredParticipantCount) registered · \(event.participants.count) planned"
        case .simplifiedChinese: return "已登记 \(registeredParticipantCount) 人・预计 \(event.participants.count) 人"
        case .traditionalChinese: return "已登記 \(registeredParticipantCount) 人・預計 \(event.participants.count) 人"
        case .korean: return "등록 \(registeredParticipantCount)명 · 예정 \(event.participants.count)명"
        case .spanish: return "\(registeredParticipantCount) registrados · \(event.participants.count) previstos"
        case .portuguese: return "\(registeredParticipantCount) cadastrados · \(event.participants.count) previstos"
        }
    }

    private var expenseSubtitle: String {
        if event.expenses.isEmpty {
            return language.detail(.addExpenses)
        }

        let total = event.currency.formatted(
            minorUnits: event.totalExpenseAmount
        )

        switch language {
        case .japanese: return "\(event.expenses.count)件・合計 \(total)"
        case .english: return "\(event.expenses.count) items · \(total)"
        case .simplifiedChinese: return "\(event.expenses.count)笔 · 合计 \(total)"
        case .traditionalChinese: return "\(event.expenses.count)筆 · 合計 \(total)"
        case .korean: return "\(event.expenses.count)건 · 합계 \(total)"
        case .spanish: return "\(event.expenses.count) gastos · \(total)"
        case .portuguese: return "\(event.expenses.count) despesas · \(total)"
        }
    }

    private var paymentSubtitle: String {
        if event.transfers.isEmpty {
            return language.detail(.managePayments)
        }

        switch language {
        case .japanese: return "\(paidCount) / \(event.transfers.count)件 支払い済み"
        case .english: return "\(paidCount) / \(event.transfers.count) paid"
        case .simplifiedChinese: return "已支付 \(paidCount) / \(event.transfers.count) 笔"
        case .traditionalChinese: return "已支付 \(paidCount) / \(event.transfers.count) 筆"
        case .korean: return "\(paidCount) / \(event.transfers.count)건 결제 완료"
        case .spanish: return "\(paidCount) / \(event.transfers.count) pagados"
        case .portuguese: return "\(paidCount) / \(event.transfers.count) pagos"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(
                language.detail(.management),
                systemImage: "square.grid.2x2.fill"
            )
            .font(.headline)
            .foregroundStyle(AppTheme.primary)

            NavigationLink {
                ParticipantManagementView(
                    eventId: eventId
                )
            } label: {
                card(
                    language.detail(.participantManagement),
                    participantSubtitle,
                    "person.3.fill",
                    AppTheme.primary
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                ExpenseListView(
                    eventId: eventId
                )
            } label: {
                card(
                    language.detail(.expenses),
                    expenseSubtitle,
                    "banknote.fill",
                    AppTheme.success
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                SettlementResultView(
                    eventId: eventId
                )
            } label: {
                card(
                    language.detail(.settlement),
                    event.expenses.isEmpty
                        ? language.detail(.addExpensesToCalculate)
                        : language.detail(.checkShares),
                    "arrow.left.arrow.right.circle.fill",
                    AppTheme.secondary
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                PaymentManagementView(
                    eventId: eventId
                )
            } label: {
                card(
                    language.detail(.payments),
                    paymentSubtitle,
                    "checkmark.seal.fill",
                    AppTheme.primary
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func card(
        _ title: String,
        _ subtitle: String,
        _ symbol: String,
        _ color: Color
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(color.gradient)
                .clipShape(
                    RoundedRectangle(cornerRadius: 15)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.tertiary)
        }
        .appCard()
    }
}

private enum DetailText: Int {
    case totalExpenses, settlementStatus, eventInfo, edit, notSet
    case management, participantManagement, expenses, settlement, payments
    case addExpenses, managePayments, addExpensesToCalculate, checkShares
    case converting, conversionUnavailable, retry
}

private let detailTexts: [[String]] = [
    ["費用合計", "Total Expenses", "费用总计", "費用總計", "총비용", "Gastos totales", "Despesas totais"],
    ["精算状況", "Settlement", "结算状态", "結算狀態", "정산 상태", "Liquidación", "Acerto"],
    ["イベント情報", "Event Information", "活动信息", "活動資訊", "이벤트 정보", "Información del evento", "Informações do evento"],
    ["編集", "Edit", "编辑", "編輯", "편집", "Editar", "Editar"],
    ["未設定", "Not Set", "未设置", "未設定", "미설정", "Sin definir", "Não definido"],
    ["管理メニュー", "Management", "管理菜单", "管理選單", "관리 메뉴", "Gestión", "Gerenciamento"],
    ["参加者管理", "Participants", "参与者管理", "參加者管理", "참가자 관리", "Participantes", "Participantes"],
    ["費用管理", "Expenses", "费用管理", "費用管理", "비용 관리", "Gastos", "Despesas"],
    ["精算", "Settlement", "结算", "結算", "정산", "Liquidación", "Acerto"],
    ["支払い管理", "Payments", "付款管理", "付款管理", "결제 관리", "Pagos", "Pagamentos"],
    ["費用を追加して記録", "Add and track expenses", "添加并记录费用", "新增並記錄費用", "비용 추가 및 기록", "Añade y registra gastos", "Adicione e registre despesas"],
    ["精算後の支払いを管理", "Manage payments after settlement", "管理结算后的付款", "管理結算後的付款", "정산 후 결제를 관리", "Gestiona los pagos tras la liquidación", "Gerencie os pagamentos após o acerto"],
    ["費用を登録すると計算できます", "Add expenses to calculate", "添加费用后即可计算", "新增費用後即可計算", "비용을 등록하면 계산할 수 있습니다", "Añade gastos para calcular", "Adicione despesas para calcular"],
    ["それぞれの負担額を確認", "Check each person's share", "查看每个人的分摊金额", "查看每個人的分攤金額", "각자의 부담액 확인", "Consulta la parte de cada persona", "Veja a parte de cada pessoa"],
    ["換算中…", "Converting…", "正在换算…", "正在換算…", "환산 중…", "Convirtiendo…", "Convertendo…"],
    ["換算額を取得できませんでした", "Conversion unavailable", "无法获取换算金额", "無法取得換算金額", "환산 금액을 불러올 수 없습니다", "Conversión no disponible", "Conversão indisponível"],
    ["再試行", "Retry", "重试", "重試", "다시 시도", "Reintentar", "Tentar novamente"]
]

extension AppLanguage {
    fileprivate func detail(_ key: DetailText) -> String {
        detailTexts[key.rawValue][detailIndex]
    }

    fileprivate var detailIndex: Int {
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
