import SwiftUI

struct ParticipantManagementView: View {
    @EnvironmentObject private var viewModel: EventViewModel
    @EnvironmentObject private var profileStore: ProfileStore

    let eventId: UUID

    @State private var names: [UUID: String] = [:]
    @State private var pendingRemovalId: UUID?
    @State private var blockedTitle = ""
    @State private var blockedMessage = ""
    @State private var showBlockedAlert = false
    @State private var showSaved = false
    @State private var hasLoaded = false

    @FocusState private var focusedParticipantId: UUID?

    private var event: Event? { viewModel.event(for: eventId) }
    private var language: AppLanguage { profileStore.activeLanguage }
    private var isLocked: Bool { !viewModel.canEdit(eventId) }
    private var registeredCount: Int { event?.participants.filter(\.hasCustomName).count ?? 0 }

    private var hasChanges: Bool {
        guard let event else { return false }

        return event.participants.contains { participant in
            let current = participant.name.trimmingCharacters(in: .whitespacesAndNewlines)
            let edited = names[participant.id, default: participant.name]
                .trimmingCharacters(in: .whitespacesAndNewlines)

            return current != edited
        }
    }

    private func t(
        _ ja: String, _ en: String, _ zhHans: String, _ zhHant: String,
        _ ko: String, _ es: String, _ pt: String
    ) -> String {
        language.text(
            ja: ja, en: en, zhHans: zhHans, zhHant: zhHant,
            ko: ko, es: es, pt: pt
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let event {
                    summaryCard(event)

                    if isLocked { lockCard }

                    infoCard

                    VStack(spacing: 0) {
                        ForEach(Array(event.participants.enumerated()), id: \.element.id) { index, participant in
                            participantRow(participant, number: index + 1)

                            if participant.id != event.participants.last?.id {
                                Divider().padding(.leading, 54)
                            }
                        }
                    }
                    .appCard()

                    if !isLocked { saveButton }
                } else {
                    ContentUnavailableView(
                        t("イベントが見つかりません", "Event Not Found", "未找到活动", "找不到活動", "이벤트를 찾을 수 없습니다", "Evento no encontrado", "Evento não encontrado"),
                        systemImage: "person.3.fill"
                    )
                }
            }
            .padding()
            .padding(.bottom, 24)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle(
            t("参加者管理", "Participants", "参与者管理", "參加者管理", "참가자 관리", "Participantes", "Participantes")
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()

                Button(
                    t("完了", "Done", "完成", "完成", "완료", "Listo", "Concluído")
                ) {
                    focusedParticipantId = nil
                }
            }
        }
        .onAppear {
            loadNamesIfNeeded()
        }
        .alert(blockedTitle, isPresented: $showBlockedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(blockedMessage)
        }
        .alert(
            t("保存しました", "Saved", "已保存", "已儲存", "저장했습니다", "Guardado", "Salvo"),
            isPresented: $showSaved
        ) {
            Button("OK", role: .cancel) {}
        }
        .confirmationDialog(
            removalTitle,
            isPresented: Binding(
                get: { pendingRemovalId != nil },
                set: { if !$0 { pendingRemovalId = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(
                t("参加者から外す", "Remove Participant", "移除参与者", "移除參加者", "참가자 제외", "Eliminar participante", "Remover participante"),
                role: .destructive
            ) {
                removePendingParticipant()
            }

            Button(
                t("キャンセル", "Cancel", "取消", "取消", "취소", "Cancelar", "Cancelar"),
                role: .cancel
            ) {
                pendingRemovalId = nil
            }
        } message: {
            Text(removalMessage)
        }
        .tint(AppTheme.primary)
    }

    private func summaryCard(_ event: Event) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "person.3.fill")
                .font(.title2.bold())
                .foregroundStyle(.white)
                .frame(width: 54, height: 54)
                .background(.white.opacity(0.18))
                .clipShape(RoundedRectangle(cornerRadius: 17))

            VStack(alignment: .leading, spacing: 4) {
                Text(event.displayTitle(for: language))
                    .font(.headline)
                    .lineLimit(1)

                Text(participantSummary(total: event.participants.count))
                    .font(.caption)
                    .opacity(0.82)
            }

            Spacer()
        }
        .foregroundStyle(.white)
        .padding(18)
        .background(AppTheme.gradient)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private var lockCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lock.fill")
                .foregroundStyle(AppTheme.primary)
                .frame(width: 38, height: 38)
                .background(AppTheme.primary.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(
                    t("精算確定済み", "Settlement Finalized", "结算已确定", "結算已確定", "정산 확정됨", "Liquidación finalizada", "Acerto finalizado")
                )
                .font(.subheadline.bold())

                Text(
                    t(
                        "参加者は閲覧のみです。変更する場合は精算確定を解除してください。", "Participants are read-only. Unlock the settlement to make changes.",
                        "参与者仅可查看。如需修改，请先解除结算锁定。", "參加者僅可查看。如需修改，請先解除結算鎖定。",
                        "참가자는 읽기 전용입니다. 변경하려면 정산 확정을 해제하세요.", "Los participantes son de solo lectura. Desbloquea la liquidación para modificarlos.",
                        "Os participantes estão somente para leitura. Desbloqueie o acerto para alterá-los."
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .appCard()
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(
                t("名前と人数について", "Names & Headcount", "姓名与人数", "姓名與人數", "이름과 인원", "Nombres y número", "Nomes e quantidade"),
                systemImage: "info.circle.fill"
            )
            .font(.subheadline.bold())
            .foregroundStyle(AppTheme.primary)

            Text(
                t(
                    "名前は空欄のままでも使えます。予定人数だけ減らす場合はイベント編集の「−」を使い、特定の参加者が途中で抜ける場合はここから外してください。",
                    "Names can stay blank. Use “−” in Event Edit to reduce only the planned headcount, or remove a specific person here if they drop out.",
                    "姓名可以留空。仅减少预计人数时请在活动编辑中使用“−”；特定参与者退出时请在此处移除。",
                    "姓名可以留空。僅減少預計人數時請在活動編輯中使用「−」；特定參加者退出時請在此處移除。",
                    "이름은 비워 둘 수 있습니다. 예정 인원만 줄일 때는 이벤트 편집의 ‘−’를 사용하고, 특정 참가자가 빠질 때는 여기서 제외하세요.",
                    "Los nombres pueden quedar vacíos. Usa “−” en Editar evento para reducir solo el número previsto, o elimina aquí a una persona concreta si deja el evento.",
                    "Os nomes podem ficar em branco. Use “−” em Editar evento para reduzir apenas a quantidade prevista ou remova aqui uma pessoa específica se ela sair."
                )
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard()
    }

    private func participantRow(_ participant: EventParticipant, number: Int) -> some View {
        HStack(spacing: 12) {
            Text("\(number)")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(AppTheme.primary)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(defaultParticipantName(number))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if isLocked {
                    Text(displayName(for: participant, number: number))
                        .font(.body)
                } else {
                    TextField(
                        t("名前を入力（任意）", "Name (optional)", "输入姓名（可选）", "輸入姓名（選填）", "이름 입력 (선택)", "Nombre (opcional)", "Nome (opcional)"),
                        text: nameBinding(for: participant)
                    )
                    .textInputAutocapitalization(.words)
                    .focused($focusedParticipantId, equals: participant.id)
                    .submitLabel(.done)
                }
            }

            Spacer(minLength: 8)

            if !isLocked {
                Button {
                    requestRemoval(participant)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(AppTheme.danger)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    t("参加者から外す", "Remove Participant", "移除参与者", "移除參加者", "참가자 제외", "Eliminar participante", "Remover participante")
                )
            }
        }
        .padding(.vertical, 10)
    }

    private var saveButton: some View {
        Button {
            saveNames(showConfirmation: true)
        } label: {
            Label(
                t("参加者名を保存", "Save Participant Names", "保存参与者姓名", "儲存參加者姓名", "참가자 이름 저장", "Guardar nombres", "Salvar nomes"),
                systemImage: "checkmark"
            )
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(AppTheme.gradient)
            .clipShape(RoundedRectangle(cornerRadius: 17))
        }
        .buttonStyle(.plain)
        .disabled(!hasChanges)
        .opacity(hasChanges ? 1 : 0.45)
    }

    private func nameBinding(for participant: EventParticipant) -> Binding<String> {
        Binding(
            get: { names[participant.id, default: participant.name] },
            set: { names[participant.id] = $0 }
        )
    }

    private func loadNamesIfNeeded() {
        guard !hasLoaded, let event else { return }

        names = Dictionary(
            uniqueKeysWithValues: event.participants.map {
                ($0.id, $0.name)
            }
        )

        hasLoaded = true
    }

    private func saveNames(showConfirmation: Bool) {
        focusedParticipantId = nil

        viewModel.saveParticipantNames(names, in: eventId)

        if let event {
            names = Dictionary(
                uniqueKeysWithValues: event.participants.map {
                    ($0.id, $0.name)
                }
            )
        }

        if showConfirmation { showSaved = true }
    }

    private func requestRemoval(_ participant: EventParticipant) {
        focusedParticipantId = nil

        switch viewModel.participantRemovalIssue(
            participantId: participant.id,
            from: eventId
        ) {
        case .lastParticipant:
            showBlock(
                title: t("参加者を外せません", "Can't Remove Participant", "无法移除参与者", "無法移除參加者", "참가자를 제외할 수 없습니다", "No se puede eliminar", "Não é possível remover"),
                message: t(
                    "イベントには最低1人の参加者が必要です。", "An event needs at least one participant.",
                    "活动至少需要1名参与者。", "活動至少需要1名參加者。",
                    "이벤트에는 최소 1명의 참가자가 필요합니다.", "El evento necesita al menos un participante.",
                    "O evento precisa de pelo menos um participante."
                )
            )

        case .payer(let expenseTitles):
            showBlock(
                title: t("先に支払者を変更してください", "Change the Payer First", "请先更改付款人", "請先更改付款人", "먼저 결제자를 변경하세요", "Cambia primero el pagador", "Altere primeiro o pagador"),
                message: blockedExpenseMessage(expenseTitles, payer: true)
            )

        case .onlyIncludedParticipant(let expenseTitles):
            showBlock(
                title: t("先に負担条件を変更してください", "Change the Split First", "请先更改分摊条件", "請先更改分攤條件", "먼저 부담 조건을 변경하세요", "Cambia primero el reparto", "Altere primeiro a divisão"),
                message: blockedExpenseMessage(expenseTitles, payer: false)
            )

        case nil:
            pendingRemovalId = participant.id
        }
    }

    private func removePendingParticipant() {
        guard let id = pendingRemovalId else { return }

        saveNames(showConfirmation: false)

        if viewModel.removeParticipantFromEvent(
            participantId: id,
            from: eventId
        ) {
            names.removeValue(forKey: id)

            if let event {
                names = Dictionary(
                    uniqueKeysWithValues: event.participants.map {
                        ($0.id, $0.name)
                    }
                )
            }
        }

        pendingRemovalId = nil
    }

    private func showBlock(title: String, message: String) {
        blockedTitle = title
        blockedMessage = message
        showBlockedAlert = true
    }

    private var removalTitle: String {
        guard let id = pendingRemovalId,
              let event,
              event.participants.contains(where: { $0.id == id }) else {
            return t("参加者を外しますか？", "Remove participant?", "移除参与者吗？", "移除參加者嗎？", "참가자를 제외할까요?", "¿Eliminar participante?", "Remover participante?")
        }

        let name = event.displayName(for: id, language: language)

        return t(
            "「\(name)」を外しますか？", "Remove “\(name)”?", "移除“\(name)”吗？",
            "移除「\(name)」嗎？", "‘\(name)’ 참가자를 제외할까요?",
            "¿Eliminar a «\(name)»?", "Remover “\(name)”?"
        )
    }

    private var removalMessage: String {
        guard let id = pendingRemovalId, let event else { return "" }

        let affected = event.expenses.filter {
            isParticipant(id, includedIn: $0)
        }.count

        if affected > 0 {
            return t(
                "予定人数も1人減ります。\(affected)件の費用の負担対象から外れ、精算結果は再計算されます。",
                "The planned headcount will also decrease by one. This person will be removed from \(affected) expenses and settlement will be recalculated.",
                "预计人数也会减少1人。该参与者将从\(affected)笔费用的分摊对象中移除，并重新计算结算结果。",
                "預計人數也會減少1人。該參加者將從\(affected)筆費用的分攤對象中移除，並重新計算結算結果。",
                "예정 인원도 1명 줄어듭니다. \(affected)건의 비용 부담 대상에서 제외되고 정산 결과가 다시 계산됩니다.",
                "El número previsto también bajará en uno. Se quitará a esta persona de \(affected) gastos y se recalculará la liquidación.",
                "A quantidade prevista também diminuirá em uma pessoa. Ela será removida de \(affected) despesas e o acerto será recalculado."
            )
        }

        return t(
            "予定人数も1人減ります。この操作は元に戻せません。",
            "The planned headcount will also decrease by one. This action can't be undone.",
            "预计人数也会减少1人。此操作无法撤销。", "預計人數也會減少1人。此操作無法復原。",
            "예정 인원도 1명 줄어듭니다. 이 작업은 되돌릴 수 없습니다。",
            "El número previsto también bajará en uno. Esta acción no se puede deshacer.",
            "A quantidade prevista também diminuirá em uma pessoa. Esta ação não pode ser desfeita."
        )
    }

    private func participantSummary(total: Int) -> String {
        switch language {
        case .japanese: return "登録済み \(registeredCount)人・予定 \(total)人"
        case .english: return "\(registeredCount) registered · \(total) planned"
        case .simplifiedChinese: return "已登记 \(registeredCount) 人・预计 \(total) 人"
        case .traditionalChinese: return "已登記 \(registeredCount) 人・預計 \(total) 人"
        case .korean: return "등록 \(registeredCount)명 · 예정 \(total)명"
        case .spanish: return "\(registeredCount) registrados · \(total) previstos"
        case .portuguese: return "\(registeredCount) cadastrados · \(total) previstos"
        }
    }

    private func defaultParticipantName(_ number: Int) -> String {
        switch language {
        case .japanese: return "参加者\(number)"
        case .english: return "Participant \(number)"
        case .simplifiedChinese: return "参与者\(number)"
        case .traditionalChinese: return "參加者\(number)"
        case .korean: return "참가자 \(number)"
        case .spanish, .portuguese: return "Participante \(number)"
        }
    }

    private func displayName(for participant: EventParticipant, number: Int) -> String {
        let trimmed = participant.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? defaultParticipantName(number) : trimmed
    }

    private func blockedExpenseMessage(_ titles: [String], payer: Bool) -> String {
        let preview = titles.prefix(3).joined(separator: "、")
        let suffix = titles.count > 3 ? " +\(titles.count - 3)" : ""

        if payer {
            return t(
                "この参加者は「\(preview)\(suffix)」の支払者です。先に各費用の支払者を変更してください。",
                "This participant is the payer for “\(preview)\(suffix)”. Change the payer on those expenses first.",
                "该参与者是“\(preview)\(suffix)”的付款人。请先更改这些费用的付款人。",
                "該參加者是「\(preview)\(suffix)」的付款人。請先更改這些費用的付款人。",
                "이 참가자는 ‘\(preview)\(suffix)’의 결제자입니다. 먼저 해당 비용의 결제자를 변경하세요.",
                "Esta persona es quien pagó «\(preview)\(suffix)». Cambia primero el pagador de esos gastos.",
                "Esta pessoa é a pagadora de “\(preview)\(suffix)”. Altere primeiro o pagador dessas despesas."
            )
        }

        return t(
            "「\(preview)\(suffix)」で、この参加者を外すと負担者が0人になります。先に費用の負担条件を変更してください。",
            "Removing this participant would leave “\(preview)\(suffix)” with no one sharing the cost. Change the split first.",
            "移除此参与者后，“\(preview)\(suffix)”将没有任何分摊人。请先更改费用分摊条件。",
            "移除此參加者後，「\(preview)\(suffix)」將沒有任何分攤人。請先更改費用分攤條件。",
            "이 참가자를 제외하면 ‘\(preview)\(suffix)’의 부담자가 0명이 됩니다. 먼저 비용 부담 조건을 변경하세요.",
            "Al eliminar a esta persona, «\(preview)\(suffix)» se quedaría sin nadie que asuma el gasto. Cambia primero el reparto.",
            "Ao remover esta pessoa, “\(preview)\(suffix)” ficaria sem ninguém para dividir a despesa. Altere primeiro a divisão."
        )
    }

    private func isParticipant(_ participantId: UUID, includedIn expense: Expense) -> Bool {
        expense.conditions.first {
            $0.participantId == participantId
        }?.isIncluded ?? true
    }
}

#Preview {
    NavigationStack {
        ParticipantManagementView(eventId: UUID())
            .environmentObject(EventViewModel())
            .environmentObject(ProfileStore())
    }
}
