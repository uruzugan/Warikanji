import Foundation

enum EventAssistantPriority: Int, Comparable {
    case low
    case normal
    case high
    case critical

    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

struct EventAssistantAction: Identifiable, Equatable {
    let id: String
    let priority: EventAssistantPriority
    let symbolName: String
    let title: String
    let detail: String
    let destinationKey: String
}

enum EventProgressAssistant {
    static func actions(
        for event: Event,
        language: AppLanguage,
        now: Date = Date()
    ) -> [EventAssistantAction] {
        var actions: [EventAssistantAction] = []
        let namedParticipants = event.participants.filter(\.hasCustomName)
        let unnamedCount = event.participants.count - namedParticipants.count

        if unnamedCount > 0 {
            actions.append(
                action(
                    id: "participants.names",
                    priority: .high,
                    symbol: "person.crop.circle.badge.questionmark",
                    title: language.text(
                        ja: "参加者名を確認", en: "Confirm participant names",
                        zhHans: "确认参与者姓名", zhHant: "確認參加者姓名",
                        ko: "참가자 이름 확인", es: "Confirma los nombres",
                        pt: "Confirme os nomes"
                    ),
                    detail: countText(
                        unnamedCount,
                        language: language,
                        ja: "名前未設定：%d人", en: "%d names are missing",
                        zhHans: "%d人未设置姓名", zhHant: "%d人尚未設定姓名",
                        ko: "이름 미설정 %d명", es: "Faltan %d nombres",
                        pt: "Faltam %d nomes"
                    ),
                    destination: "participants"
                )
            )
        }

        if event.planning.features.contains(.attendance) {
            let answeredIds = Set(
                event.planning.participantResponses
                    .filter { $0.attendance != .unanswered }
                    .map(\.participantId)
            )
            let unansweredCount = namedParticipants.filter {
                !answeredIds.contains($0.id)
            }.count

            if unansweredCount > 0 {
                actions.append(
                    action(
                        id: "attendance.unanswered",
                        priority: .high,
                        symbol: "person.2.badge.questionmark",
                        title: language.text(
                            ja: "出欠を確認", en: "Check attendance",
                            zhHans: "确认出席情况", zhHant: "確認出席狀況",
                            ko: "참석 여부 확인", es: "Revisa la asistencia",
                            pt: "Verifique a presença"
                        ),
                        detail: countText(
                            unansweredCount,
                            language: language,
                            ja: "未回答：%d人", en: "%d people have not answered",
                            zhHans: "%d人尚未回答", zhHant: "%d人尚未回答",
                            ko: "미응답 %d명", es: "%d personas sin responder",
                            pt: "%d pessoas não responderam"
                        ),
                        destination: "attendance"
                    )
                )
            }
        }

        if event.planning.features.contains(.multipleParts), event.planning.parts.isEmpty {
            actions.append(
                action(
                    id: "parts.empty",
                    priority: .normal,
                    symbol: "square.stack.3d.up",
                    title: language.text(
                        ja: "イベントの部を設定", en: "Set up event parts",
                        zhHans: "设置活动环节", zhHant: "設定活動環節",
                        ko: "이벤트 순서 설정", es: "Configura las partes",
                        pt: "Configure as etapas"
                    ),
                    detail: language.text(
                        ja: "一次会・二次会などを分けて管理できます。",
                        en: "Organize separate parts such as the main event and after-party.",
                        zhHans: "可分别管理主活动和二次会等环节。",
                        zhHant: "可分別管理主活動和二次會等環節。",
                        ko: "1차와 2차 등을 나누어 관리할 수 있습니다.",
                        es: "Gestiona por separado el evento principal y lo que venga después.",
                        pt: "Gerencie separadamente o evento principal e as etapas seguintes."
                    ),
                    destination: "parts"
                )
            )
        }

        let overdueTasks = event.planning.tasks.filter {
            $0.status != .completed && ($0.dueAt.map { $0 < now } ?? false)
        }
        if !overdueTasks.isEmpty {
            actions.append(
                action(
                    id: "tasks.overdue",
                    priority: .critical,
                    symbol: "exclamationmark.circle.fill",
                    title: language.text(
                        ja: "期限切れのタスク", en: "Overdue tasks",
                        zhHans: "逾期任务", zhHant: "逾期任務",
                        ko: "기한이 지난 작업", es: "Tareas vencidas",
                        pt: "Tarefas atrasadas"
                    ),
                    detail: countText(
                        overdueTasks.count,
                        language: language,
                        ja: "%d件を確認してください", en: "Review %d tasks",
                        zhHans: "请确认%d项任务", zhHant: "請確認%d項任務",
                        ko: "%d개 작업을 확인하세요", es: "Revisa %d tareas",
                        pt: "Revise %d tarefas"
                    ),
                    destination: "tasks"
                )
            )
        }

        if event.planning.features.contains(.settlement),
           !event.expenses.isEmpty,
           event.transfers.isEmpty {
            actions.append(
                action(
                    id: "settlement.calculate",
                    priority: now > event.endDate ? .high : .normal,
                    symbol: "arrow.left.arrow.right.circle.fill",
                    title: language.text(
                        ja: "精算を計算", en: "Calculate settlement",
                        zhHans: "计算结算", zhHant: "計算結算",
                        ko: "정산 계산", es: "Calcula la liquidación",
                        pt: "Calcule o acerto"
                    ),
                    detail: language.text(
                        ja: "費用は登録済みですが、送金方法が未確定です。",
                        en: "Expenses are recorded, but transfers are not finalized.",
                        zhHans: "费用已记录，但转账方式尚未确定。",
                        zhHant: "費用已記錄，但轉帳方式尚未確定。",
                        ko: "비용은 등록되었지만 송금 방법이 확정되지 않았습니다.",
                        es: "Hay gastos registrados, pero faltan las transferencias.",
                        pt: "Há despesas registradas, mas faltam as transferências."
                    ),
                    destination: "settlement"
                )
            )
        }

        let unpaidCount = event.transfers.filter { !$0.isPaid }.count
        if event.planning.features.contains(.settlement), unpaidCount > 0 {
            actions.append(
                action(
                    id: "payments.unpaid",
                    priority: .high,
                    symbol: "creditcard.trianglebadge.exclamationmark",
                    title: language.text(
                        ja: "未払いを確認", en: "Review unpaid transfers",
                        zhHans: "确认未付款项", zhHant: "確認未付款項",
                        ko: "미지급 확인", es: "Revisa los pagos pendientes",
                        pt: "Revise os pagamentos pendentes"
                    ),
                    detail: countText(
                        unpaidCount,
                        language: language,
                        ja: "未払い：%d件", en: "%d transfers are unpaid",
                        zhHans: "%d笔尚未支付", zhHant: "%d筆尚未支付",
                        ko: "미지급 %d건", es: "%d transferencias pendientes",
                        pt: "%d transferências pendentes"
                    ),
                    destination: "payments"
                )
            )
        }

        return actions
            .filter { !event.planning.dismissedAssistantActionKeys.contains($0.id) }
            .sorted {
                if $0.priority == $1.priority { return $0.id < $1.id }
                return $0.priority > $1.priority
            }
    }

    private static func action(
        id: String,
        priority: EventAssistantPriority,
        symbol: String,
        title: String,
        detail: String,
        destination: String
    ) -> EventAssistantAction {
        EventAssistantAction(
            id: id,
            priority: priority,
            symbolName: symbol,
            title: title,
            detail: detail,
            destinationKey: destination
        )
    }

    private static func countText(
        _ count: Int,
        language: AppLanguage,
        ja: String,
        en: String,
        zhHans: String,
        zhHant: String,
        ko: String,
        es: String,
        pt: String
    ) -> String {
        String(
            format: language.text(
                ja: ja, en: en, zhHans: zhHans, zhHant: zhHant,
                ko: ko, es: es, pt: pt
            ),
            locale: Locale(identifier: language.localeIdentifier),
            count
        )
    }
}
