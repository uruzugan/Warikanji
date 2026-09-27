import SwiftUI

struct EventEditView: View {
    @EnvironmentObject private var viewModel: EventViewModel
    @EnvironmentObject private var profileStore: ProfileStore
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?

    let eventId: UUID

    @State private var title = ""
    @State private var eventType: EventType = .other
    @State private var date = Date()
    @State private var endDate = Date()
    @State private var location = ""
    @State private var memo = ""
    @State private var participantCount = 1
    @State private var hasLoaded = false
    @State private var showDateRangeWarning = false

    private enum Field { case title, location, memo }
    private let columns = Array(repeating: GridItem(.flexible()), count: 3)

    private var event: Event? { viewModel.event(for: eventId) }
    private var language: AppLanguage { profileStore.activeLanguage }
    private var registeredParticipantCount: Int { event?.registeredParticipantCount ?? 0 }
    private var minimumParticipantCount: Int { event?.minimumParticipantCount ?? 1 }
    private var unnamedCount: Int { max(participantCount - registeredParticipantCount, 0) }
    private var isSaveDisabled: Bool { endDate < date }

    private var expensesOutsideSelectedPeriod: [Expense] {
        guard let event else { return [] }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.startOfDay(for: endDate)

        return event.expenses.filter {
            guard let expenseDate = $0.date else { return false }
            let expenseDay = calendar.startOfDay(for: expenseDate)
            return expenseDay < start || expenseDay > end
        }
    }

    private var outsideExpensePreview: String {
        let expenses = expensesOutsideSelectedPeriod
        let names = expenses.prefix(3).map { $0.displayTitle(for: language) }.joined(separator: "、")
        let remaining = expenses.count - min(expenses.count, 3)
        return remaining > 0 ? "\(names) ＋\(remaining)" : names
    }

    private func t(_ ja: String, _ en: String, _ zhHans: String, _ zhHant: String, _ ko: String, _ es: String, _ pt: String) -> String {
        language.text(ja: ja, en: en, zhHans: zhHans, zhHant: zhHant, ko: ko, es: es, pt: pt)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    heroCard
                    eventInfoCard
                    if !expensesOutsideSelectedPeriod.isEmpty { dateRangeWarningCard }
                    typeCard
                    participantCard
                    memoCard
                    saveButton
                }
                .padding()
            }
            .background(AppTheme.background)
            .navigationTitle(language.eventText(.editEvent))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(language.t(.cancel)) { dismiss() }
                }

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(language.t(.done)) { focusedField = nil }
                }
            }
            .onAppear { loadIfNeeded() }
            .confirmationDialog(
                t(
                    "期間外の費用があります",
                    "Some expenses are outside the event dates",
                    "有费用超出活动日期",
                    "有費用超出活動日期",
                    "이벤트 기간 밖의 비용이 있습니다",
                    "Hay gastos fuera de las fechas del evento",
                    "Há despesas fora das datas do evento"
                ),
                isPresented: $showDateRangeWarning,
                titleVisibility: .visible
            ) {
                Button(
                    t(
                        "このまま保存",
                        "Save Anyway",
                        "仍然保存",
                        "仍然儲存",
                        "그대로 저장",
                        "Guardar de todos modos",
                        "Salvar mesmo assim"
                    )
                ) {
                    save()
                }

                Button(
                    t("キャンセル", "Cancel", "取消", "取消", "취소", "Cancelar", "Cancelar"),
                    role: .cancel
                ) {}
            } message: {
                Text(
                    t(
                        "期間外の日付が設定された費用が\(expensesOutsideSelectedPeriod.count)件あります。費用の日付は変更・削除されません。",
                        "\(expensesOutsideSelectedPeriod.count) expenses have dates outside the selected event period. Their dates will not be changed or deleted.",
                        "有\(expensesOutsideSelectedPeriod.count)笔费用的日期超出所选活动期间。费用日期不会被修改或删除。",
                        "有\(expensesOutsideSelectedPeriod.count)筆費用的日期超出所選活動期間。費用日期不會被修改或刪除。",
                        "선택한 이벤트 기간 밖의 날짜가 설정된 비용이 \(expensesOutsideSelectedPeriod.count)건 있습니다. 비용 날짜는 변경되거나 삭제되지 않습니다.",
                        "Hay \(expensesOutsideSelectedPeriod.count) gastos con fechas fuera del periodo seleccionado. Sus fechas no se modificarán ni eliminarán.",
                        "Há \(expensesOutsideSelectedPeriod.count) despesas com datas fora do período selecionado. As datas não serão alteradas nem excluídas."
                    )
                )
            }
        }
        .tint(AppTheme.primary)
    }

    private var heroCard: some View {
        HStack(spacing: 14) {
            Image(systemName: eventType.symbolName)
                .font(.system(size: 25, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(.white.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 18))

            VStack(alignment: .leading, spacing: 4) {
                Text(language.eventText(.editEvent))
                    .font(.headline)
                    .foregroundStyle(.white)

                Text(
                    t(
                        "イベントの内容を変更できます",
                        "Update the event details",
                        "可以修改活动内容",
                        "可以修改活動內容",
                        "이벤트 내용을 변경할 수 있습니다",
                        "Actualiza los detalles del evento",
                        "Atualize os detalhes do evento"
                    )
                )
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.82))
            }

            Spacer()
        }
        .padding(18)
        .background(AppTheme.gradient)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private var eventInfoCard: some View {
        VStack(spacing: 0) {
            inputRow(icon: "pencil", title: language.eventText(.eventName)) {
                TextField(language.eventText(.optional), text: $title)
                    .multilineTextAlignment(.trailing)
                    .focused($focusedField, equals: .title)
            }

            Divider().padding(.leading, 42)

            inputRow(
                icon: "calendar.badge.clock",
                title: t("開始日時", "Starts", "开始时间", "開始時間", "시작 일시", "Inicio", "Início")
            ) {
                DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
                    .environment(\.locale, Locale(identifier: language.localeIdentifier))
            }

            Divider().padding(.leading, 42)

            inputRow(
                icon: "calendar.badge.checkmark",
                title: t("終了日時", "Ends", "结束时间", "結束時間", "종료 일시", "Fin", "Fim")
            ) {
                DatePicker("", selection: $endDate, in: date..., displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
                    .environment(\.locale, Locale(identifier: language.localeIdentifier))
            }

            Divider().padding(.leading, 42)

            inputRow(icon: "mappin.and.ellipse", title: language.eventText(.location)) {
                TextField(language.eventText(.optional), text: $location)
                    .multilineTextAlignment(.trailing)
                    .focused($focusedField, equals: .location)
            }
        }
        .appCard()
        .onChange(of: date) {
            if endDate < date { endDate = date }
        }
    }

    private var dateRangeWarningCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.title3)
                .foregroundStyle(AppTheme.warning)
                .frame(width: 38, height: 38)
                .background(AppTheme.warning.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text(
                    t(
                        "期間外の費用があります",
                        "Expenses Outside Event Dates",
                        "有费用超出活动日期",
                        "有費用超出活動日期",
                        "기간 밖의 비용이 있습니다",
                        "Hay gastos fuera del periodo",
                        "Há despesas fora do período"
                    )
                )
                .font(.subheadline.bold())

                Text(
                    t(
                        "\(expensesOutsideSelectedPeriod.count)件の費用の日付が、現在選択している開催期間に含まれていません。",
                        "\(expensesOutsideSelectedPeriod.count) expense dates are outside the selected event period.",
                        "有\(expensesOutsideSelectedPeriod.count)笔费用的日期不在当前选择的活动期间内。",
                        "有\(expensesOutsideSelectedPeriod.count)筆費用的日期不在目前選擇的活動期間內。",
                        "\(expensesOutsideSelectedPeriod.count)건의 비용 날짜가 현재 선택한 이벤트 기간에 포함되지 않습니다.",
                        "\(expensesOutsideSelectedPeriod.count) gastos tienen fechas fuera del periodo seleccionado.",
                        "\(expensesOutsideSelectedPeriod.count) despesas têm datas fora do período selecionado."
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                if !outsideExpensePreview.isEmpty {
                    Text(outsideExpensePreview)
                        .font(.caption.bold())
                        .foregroundStyle(AppTheme.warning)
                        .lineLimit(2)
                }

                Text(
                    t(
                        "保存しても費用の日付は自動変更されません。",
                        "Saving will not automatically change the expense dates.",
                        "保存后费用日期不会自动更改。",
                        "儲存後費用日期不會自動更改。",
                        "저장해도 비용 날짜는 자동으로 변경되지 않습니다.",
                        "Guardar no cambiará automáticamente las fechas de los gastos.",
                        "Salvar não alterará automaticamente as datas das despesas."
                    )
                )
                .font(.caption2)
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(14)
        .background(AppTheme.warning.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.warning.opacity(0.25), lineWidth: 1)
        }
    }

    private var typeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(language.eventText(.eventType), systemImage: "square.grid.2x2.fill")
                .font(.headline)
                .foregroundStyle(AppTheme.primary)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(EventType.allCases) { type in
                    Button {
                        eventType = type
                    } label: {
                        VStack(spacing: 7) {
                            Image(systemName: type.symbolName).font(.title2)

                            Text(type.displayName(for: language))
                                .font(.caption)
                                .fontWeight(.medium)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .foregroundStyle(eventType == type ? AppTheme.primary : Color.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 72)
                        .background(
                            eventType == type
                            ? AppTheme.primary.opacity(0.12)
                            : Color(uiColor: .tertiarySystemGroupedBackground)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(eventType == type ? AppTheme.primary : Color.clear, lineWidth: 1.5)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .appCard()
    }

    private var participantCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                Image(systemName: "person.2.fill")
                    .foregroundStyle(AppTheme.primary)
                    .frame(width: 42, height: 42)
                    .background(AppTheme.primary.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(language.eventText(.participants)).font(.headline)

                    Text(participantBreakdown)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Stepper(
                    "\(participantCount) \(language.participantUnit(for: participantCount))",
                    value: $participantCount,
                    in: minimumParticipantCount...999
                )
                .fixedSize()
            }

            if unnamedCount > 0 {
                Label(
                    unnamedParticipantText,
                    systemImage: "person.crop.circle.badge.questionmark"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            if participantCount == minimumParticipantCount && minimumParticipantCount > 1 {
                Text(
                    t(
                        "名前を登録済み、または費用・精算で使用中の参加者がいるため、これ以上は減らせません。",
                        "You can't reduce the count further because some participants have names or are used in expenses or settlement.",
                        "部分参与者已登记姓名或正在费用、结算中使用，因此无法继续减少人数。",
                        "部分參加者已登記姓名或正在費用、結算中使用，因此無法繼續減少人數。",
                        "이름이 등록되었거나 비용·정산에 사용 중인 참가자가 있어 더 줄일 수 없습니다.",
                        "No puedes reducir más el número porque algunos participantes tienen nombre o se usan en gastos o liquidación.",
                        "Não é possível reduzir mais porque alguns participantes têm nome ou são usados em despesas ou no acerto."
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .appCard()
    }

    private var participantBreakdown: String {
        switch language {
        case .japanese: return "登録済み \(registeredParticipantCount)人・予定 \(participantCount)人"
        case .english: return "\(registeredParticipantCount) registered · \(participantCount) planned"
        case .simplifiedChinese: return "已登记 \(registeredParticipantCount) 人・预计 \(participantCount) 人"
        case .traditionalChinese: return "已登記 \(registeredParticipantCount) 人・預計 \(participantCount) 人"
        case .korean: return "등록 \(registeredParticipantCount)명 · 예정 \(participantCount)명"
        case .spanish: return "\(registeredParticipantCount) registrados · \(participantCount) previstos"
        case .portuguese: return "\(registeredParticipantCount) cadastrados · \(participantCount) previstos"
        }
    }

    private var unnamedParticipantText: String {
        switch language {
        case .japanese: return "名前未登録の参加者：\(unnamedCount)人"
        case .english: return "\(unnamedCount) participants without names"
        case .simplifiedChinese: return "\(unnamedCount) 名参与者尚未登记姓名"
        case .traditionalChinese: return "\(unnamedCount) 名參加者尚未登記姓名"
        case .korean: return "이름 미등록 참가자 \(unnamedCount)명"
        case .spanish: return "\(unnamedCount) participantes sin nombre"
        case .portuguese: return "\(unnamedCount) participantes sem nome"
        }
    }

    private var memoCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(language.eventText(.memo), systemImage: "note.text")
                .font(.headline)
                .foregroundStyle(AppTheme.primary)

            TextField(language.eventText(.memoPlaceholder), text: $memo, axis: .vertical)
                .lineLimit(3...6)
                .focused($focusedField, equals: .memo)
                .padding(12)
                .background(Color(uiColor: .tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .appCard()
    }

    private var saveButton: some View {
        Button(action: attemptSave) {
            Label(language.eventText(.saveChanges), systemImage: "checkmark")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(AppTheme.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 17))
        }
        .buttonStyle(.plain)
        .disabled(isSaveDisabled)
        .opacity(isSaveDisabled ? 0.45 : 1)
        .padding(.bottom, 10)
    }

    private func inputRow<Content: View>(
        icon: String,
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.primary)
                .frame(width: 26)

            Text(title).fontWeight(.medium)
            Spacer()
            content()
        }
        .padding(.vertical, 12)
    }

    private func loadIfNeeded() {
        guard !hasLoaded, let event else { return }

        title = event.title
        eventType = event.eventType
        date = event.date
        endDate = event.endDate
        location = event.location
        memo = event.memo
        participantCount = max(event.expectedParticipantCount, event.participants.count, 1)
        hasLoaded = true
    }

    private func attemptSave() {
        focusedField = nil

        if expensesOutsideSelectedPeriod.isEmpty {
            save()
        } else {
            showDateRangeWarning = true
        }
    }

    private func save() {
        guard var updated = event else { return }

        updated.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.eventType = eventType
        updated.date = date
        updated.endDate = max(endDate, date)
        updated.location = location.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.memo = memo.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.setParticipantCount(participantCount)

        if viewModel.updateEvent(updated) {
            dismiss()
        }
    }
}

#Preview {
    EventEditView(eventId: UUID())
        .environmentObject(EventViewModel())
        .environmentObject(ProfileStore())
}
