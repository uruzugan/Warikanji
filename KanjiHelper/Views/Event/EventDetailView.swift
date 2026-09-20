import SwiftUI

struct EventDetailView: View {
    @EnvironmentObject private var viewModel: EventViewModel
    @EnvironmentObject private var profileStore: ProfileStore
    @Environment(\.dismiss) private var dismiss

    @ObservedObject private var lifecycleStore = EventLifecycleStore.shared

    let eventId: UUID

    @State private var isShowingEdit = false
    @State private var isShowingDeleteConfirmation = false
    @State private var isShowingLockConfirmation = false
    @State private var isShowingCalendarEditor = false
    @State private var shareImageItem: ShareImageItem?

    private var event: Event? { viewModel.event(for: eventId) }
    private var language: AppLanguage { profileStore.activeLanguage }

    private func t(_ ja: String, _ en: String, _ zhHans: String, _ zhHant: String, _ ko: String, _ es: String, _ pt: String) -> String {
        language.text(ja: ja, en: en, zhHans: zhHans, zhHant: zhHant, ko: ko, es: es, pt: pt)
    }

    var body: some View {
        Group {
            if let event {
                content(event)
            } else {
                ContentUnavailableView(
                    t("イベントが見つかりません", "Event Not Found", "找不到活动", "找不到活動", "이벤트를 찾을 수 없습니다", "Evento no encontrado", "Evento não encontrado"),
                    systemImage: "calendar.badge.exclamationmark"
                )
            }
        }
    }

    private func content(_ event: Event) -> some View {
        let isLocked = lifecycleStore.isLocked(event.id)

        return ScrollView {
            VStack(spacing: 18) {
                if isLocked { lockBanner }

                if event.hasEnded && !lifecycleStore.isArchived(event.id) {
                    endedBanner(event)
                }

                EventDetailHero(event: event)
                EventDetailSummary(event: event)

                EventDetailInfo(event: event) {
                    guard !isLocked else { return }
                    isShowingEdit = true
                }
                .allowsHitTesting(!isLocked)
                .opacity(isLocked ? 0.78 : 1)

                EventDetailMenu(event: event, eventId: eventId)
            }
            .padding()
            .padding(.bottom, 30)
        }
        .background(AppTheme.background)
        .navigationTitle(event.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                eventMenu(event, isLocked: isLocked)
            }
        }
        .sheet(isPresented: $isShowingEdit) {
            EventEditView(eventId: event.id)
                .environmentObject(viewModel)
                .environmentObject(profileStore)
        }
        .sheet(isPresented: $isShowingCalendarEditor) {
            CalendarEventEditView(event: event)
        }
        .sheet(item: $shareImageItem) { item in
            ActivityShareView(activityItems: [item.image])
        }
        .confirmationDialog(
            t("精算を確定しますか？", "Finalize settlement?", "确定结算吗？", "確定結算嗎？", "정산을 확정하시겠습니까?", "¿Finalizar la liquidación?", "Finalizar o acerto?"),
            isPresented: $isShowingLockConfirmation,
            titleVisibility: .visible
        ) {
            Button(t("精算を確定", "Finalize", "确定结算", "確定結算", "정산 확정", "Finalizar", "Finalizar")) {
                viewModel.recalculateTransfers(for: event.id)
                lifecycleStore.lock(event.id)
            }

            Button(t("キャンセル", "Cancel", "取消", "取消", "취소", "Cancelar", "Cancelar"), role: .cancel) {}
        } message: {
            Text(t(
                "確定後はイベント情報・参加者・費用・精算条件を変更できなくなります。支払い状況は引き続き更新できます。",
                "Event details, participants, expenses and settlement settings will be locked. Payment status can still be updated.",
                "确定后将无法修改活动信息、参与者、费用和结算设置，但仍可更新付款状态。",
                "確定後將無法修改活動資訊、參加者、費用和結算設定，但仍可更新付款狀態。",
                "확정 후에는 이벤트 정보, 참가자, 비용 및 정산 설정을 변경할 수 없습니다. 결제 상태는 계속 변경할 수 있습니다.",
                "Tras finalizar, no podrás modificar el evento, participantes, gastos ni la liquidación. Los pagos sí podrán actualizarse.",
                "Após finalizar, evento, participantes, despesas e acerto não poderão ser alterados. Os pagamentos ainda poderão ser atualizados."
            ))
        }
        .confirmationDialog(
            deleteDialogTitle(event),
            isPresented: $isShowingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(t("削除する", "Delete", "删除", "刪除", "삭제", "Eliminar", "Excluir"), role: .destructive) {
                viewModel.deleteEvent(event)
                dismiss()
            }

            Button(t("キャンセル", "Cancel", "取消", "取消", "취소", "Cancelar", "Cancelar"), role: .cancel) {}
        }
        .tint(AppTheme.primary)
    }

    private func eventMenu(_ event: Event, isLocked: Bool) -> some View {
        let isArchived = lifecycleStore.isArchived(event.id)

        return Menu {
            ShareLink(item: shareText(for: event)) {
                Label(t("予定を共有", "Share Plan", "分享计划", "分享行程", "일정 공유", "Compartir plan", "Compartilhar plano"), systemImage: "text.bubble")
            }

            Button { createShareCard(for: event) } label: {
                Label(t("共有カードを送る", "Share Card", "分享卡片", "分享卡片", "공유 카드 보내기", "Compartir tarjeta", "Compartilhar cartão"), systemImage: "photo.on.rectangle.angled")
            }

            Button { isShowingCalendarEditor = true } label: {
                Label(t("カレンダーに追加", "Add to Calendar", "添加到日历", "加入行事曆", "캘린더에 추가", "Añadir al calendario", "Adicionar ao calendário"), systemImage: "calendar.badge.plus")
            }

            Divider()

            Button {
                viewModel.duplicateEvent(event, title: duplicateTitle(for: event))
            } label: {
                Label(t("イベントを複製", "Duplicate Event", "复制活动", "複製活動", "이벤트 복제", "Duplicar evento", "Duplicar evento"), systemImage: "plus.square.on.square")
            }

            Button {
                lifecycleStore.setArchived(!isArchived, for: event.id)
                dismiss()
            } label: {
                Label(
                    isArchived
                        ? t("アーカイブから戻す", "Restore from Archive", "从归档中恢复", "從封存中還原", "보관함에서 복원", "Restaurar del archivo", "Restaurar do arquivo")
                        : t("アーカイブする", "Archive", "归档", "封存", "보관", "Archivar", "Arquivar"),
                    systemImage: isArchived ? "tray.and.arrow.up" : "archivebox"
                )
            }

            Divider()

            if isLocked {
                Button { lifecycleStore.unlock(event.id) } label: {
                    Label(t("精算確定を解除", "Unlock Settlement", "解除结算锁定", "解除結算鎖定", "정산 확정 해제", "Desbloquear liquidación", "Desbloquear acerto"), systemImage: "lock.open.fill")
                }
            } else {
                Button { isShowingEdit = true } label: {
                    Label(t("イベントを編集", "Edit Event", "编辑活动", "編輯活動", "이벤트 편집", "Editar evento", "Editar evento"), systemImage: "pencil")
                }

                Button { isShowingLockConfirmation = true } label: {
                    Label(t("精算を確定", "Finalize Settlement", "确定结算", "確定結算", "정산 확정", "Finalizar liquidación", "Finalizar acerto"), systemImage: "lock.fill")
                }
                .disabled(!canLock(event))

                Button(role: .destructive) {
                    isShowingDeleteConfirmation = true
                } label: {
                    Label(t("イベントを削除", "Delete Event", "删除活动", "刪除活動", "이벤트 삭제", "Eliminar evento", "Excluir evento"), systemImage: "trash")
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }

    private func endedBanner(_ event: Event) -> some View {
        let allPaid = !event.transfers.isEmpty && event.transfers.allSatisfy(\.isPaid)
        let hasUnpaid = event.transfers.contains { !$0.isPaid }

        let message: String

        if allPaid {
            message = t(
                "開催期間は終了しています。支払いも完了しているので、必要ならアーカイブできます。",
                "This event has ended and all payments are complete. You can archive it when you're ready.",
                "活动已结束且付款已完成，需要时可以归档。",
                "活動已結束且付款已完成，需要時可以封存。",
                "이벤트가 종료되었고 결제도 완료되었습니다. 필요하면 보관할 수 있습니다.",
                "El evento ha terminado y todos los pagos están completos. Puedes archivarlo cuando quieras.",
                "O evento terminou e todos os pagamentos foram concluídos. Você pode arquivá-lo quando quiser."
            )
        } else if hasUnpaid {
            message = t(
                "開催期間は終了しています。未完了の支払いがあります。",
                "This event has ended, but some payments are still incomplete.",
                "活动已结束，但仍有未完成的付款。",
                "活動已結束，但仍有未完成的付款。",
                "이벤트가 종료되었지만 아직 완료되지 않은 결제가 있습니다.",
                "El evento ha terminado, pero aún hay pagos pendientes.",
                "O evento terminou, mas ainda há pagamentos pendentes."
            )
        } else {
            message = t(
                "開催期間は終了しています。費用や精算内容を確認しましょう。",
                "This event has ended. Check the expenses and settlement details.",
                "活动已结束，请确认费用和结算内容。",
                "活動已結束，請確認費用和結算內容。",
                "이벤트가 종료되었습니다. 비용과 정산 내용을 확인하세요.",
                "El evento ha terminado. Revisa los gastos y la liquidación.",
                "O evento terminou. Verifique as despesas e o acerto."
            )
        }

        return HStack(spacing: 12) {
            Image(systemName: allPaid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(allPaid ? AppTheme.success : AppTheme.warning)

            VStack(alignment: .leading, spacing: 2) {
                Text(t("開催期間終了", "Event Ended", "活动已结束", "活動已結束", "이벤트 종료", "Evento finalizado", "Evento encerrado"))
                    .font(.subheadline.bold())

                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(14)
        .background((allPaid ? AppTheme.success : AppTheme.warning).opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var lockBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .foregroundStyle(AppTheme.primary)

            VStack(alignment: .leading, spacing: 2) {
                Text(t("精算確定済み", "Settlement Finalized", "结算已确定", "結算已確定", "정산 확정됨", "Liquidación finalizada", "Acerto finalizado"))
                    .font(.subheadline.bold())

                Text(t(
                    "内容はロックされています。支払い状況のみ変更できます。",
                    "Event data is locked. Only payment status can be changed.",
                    "内容已锁定，仅可修改付款状态。",
                    "內容已鎖定，僅可修改付款狀態。",
                    "내용이 잠겨 있습니다. 결제 상태만 변경할 수 있습니다.",
                    "El contenido está bloqueado. Solo pueden cambiarse los pagos.",
                    "O conteúdo está bloqueado. Apenas os pagamentos podem ser alterados."
                ))
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(14)
        .background(AppTheme.primary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func canLock(_ event: Event) -> Bool {
        guard !event.expenses.isEmpty else { return false }

        let result = SettlementCalculator.calculate(event: event)
        return result.isTotalShareConsistent &&
            result.isBalanceConsistent &&
            !result.hasBlockingCalculationError
    }

    private func duplicateTitle(for event: Event) -> String {
        t(
            "\(event.title)のコピー", "\(event.title) Copy",
            "\(event.title) 副本", "\(event.title) 副本",
            "\(event.title) 복사본", "\(event.title) - copia", "\(event.title) - cópia"
        )
    }

    @MainActor
    private func createShareCard(for event: Event) {
        guard let image = EventShareCardRenderer.makeImage(event: event, language: language) else { return }
        shareImageItem = ShareImageItem(image: image)
    }

    private func shareText(for event: Event) -> String {
        let schedule = event.scheduleText(for: language, includeYear: true)
        let location = event.location.trimmingCharacters(in: .whitespacesAndNewlines)
        let memo = event.memo.trimmingCharacters(in: .whitespacesAndNewlines)

        var lines = [
            "【\(event.title)】",
            "",
            "\(t("日時", "Date", "日期", "日期", "날짜", "Fecha", "Data"))：\(schedule)"
        ]

        if !location.isEmpty {
            lines.append("\(t("場所", "Location", "地点", "地點", "장소", "Lugar", "Local"))：\(location)")
        }

        if !memo.isEmpty {
            lines += ["", "\(t("メモ", "Note", "备注", "備註", "메모", "Nota", "Nota"))：\(memo)"]
        }

        if event.hasDatedExpenses {
            lines += [""] + event.expenseBreakdownLines(for: language)
        }

        lines += [
            "",
            t("ワリカンジで共有", "Shared with Warikanji", "通过 Warikanji 分享", "透過 Warikanji 分享", "Warikanji에서 공유", "Compartido con Warikanji", "Compartilhado com Warikanji")
        ]

        return lines.joined(separator: "\n")
    }

    private func deleteDialogTitle(_ event: Event) -> String {
        t(
            "「\(event.title)」を削除しますか？",
            "Delete “\(event.title)”?",
            "删除“\(event.title)”吗？",
            "刪除「\(event.title)」嗎？",
            "“\(event.title)”을 삭제하시겠습니까?",
            "¿Eliminar «\(event.title)»?",
            "Excluir “\(event.title)”?"
        )
    }
}
