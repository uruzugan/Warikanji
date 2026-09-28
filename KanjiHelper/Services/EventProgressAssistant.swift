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

        if event.planning.features.contains(.schedulingPoll) {
            let poll = event.planning.schedulePoll

            if poll.options.isEmpty {
                actions.append(
                    action(
                        id: "schedule.options.empty",
                        priority: .normal,
                        symbol: "calendar.badge.plus",
                        title: language.text(
                            ja: "候補日を追加", en: "Add date options",
                            zhHans: "添加候选日期", zhHant: "新增候選日期",
                            ko: "후보 날짜 추가", es: "Añade fechas",
                            pt: "Adicione datas"
                        ),
                        detail: language.text(
                            ja: "日程投票を始める候補日を設定します。",
                            en: "Set the options needed to start a date poll.",
                            zhHans: "设置开始日期投票所需的候选日期。",
                            zhHant: "設定開始日期投票所需的候選日期。",
                            ko: "일정 투표를 시작할 후보 날짜를 설정하세요.",
                            es: "Configura las opciones para iniciar la votación.",
                            pt: "Configure as opções para iniciar a votação."
                        ),
                        destination: "schedule"
                    )
                )
            } else if poll.finalizedOptionId == nil {
                let answeredIds = Set(
                    poll.responses.filter { response in
                        response.optionResponses.contains {
                            $0.choice != .unanswered
                        }
                    }.map(\.participantId)
                )
                let unanswered = namedParticipants.filter {
                    !answeredIds.contains($0.id)
                }.count

                if unanswered > 0 {
                    let deadlinePassed = poll.responseDeadline.map { $0 < now } ?? false
                    actions.append(
                        action(
                            id: "schedule.responses.missing",
                            priority: deadlinePassed ? .critical : .high,
                            symbol: "calendar.badge.questionmark",
                            title: language.text(
                                ja: "日程回答を確認", en: "Check date poll responses",
                                zhHans: "确认日期投票回答", zhHant: "確認日期投票回答",
                                ko: "일정 응답 확인", es: "Revisa las respuestas",
                                pt: "Verifique as respostas"
                            ),
                            detail: countText(
                                unanswered,
                                language: language,
                                ja: "未回答：%d人", en: "%d people have not answered",
                                zhHans: "%d人尚未回答", zhHant: "%d人尚未回答",
                                ko: "미응답 %d명", es: "%d personas sin responder",
                                pt: "%d pessoas não responderam"
                            ),
                            destination: "schedule"
                        )
                    )
                }
            }
        }

        if event.planning.features.contains(.venueCandidates),
           event.planning.venuePlanning.candidates.isEmpty {
            actions.append(
                action(
                    id: "venue.candidates.empty",
                    priority: .normal,
                    symbol: "mappin.and.ellipse",
                    title: language.text(
                        ja: "店・場所候補を追加", en: "Add venue candidates",
                        zhHans: "添加地点候选", zhHant: "新增地點候選",
                        ko: "장소 후보 추가", es: "Añade lugares",
                        pt: "Adicione locais"
                    ),
                    detail: language.text(
                        ja: "候補への回答と予約準備をまとめられます。",
                        en: "Collect responses and prepare reservation details.",
                        zhHans: "汇总候选地点的回答并准备预约。",
                        zhHant: "彙整候選地點的回答並準備預約。",
                        ko: "장소 응답과 예약 준비를 한곳에서 관리하세요.",
                        es: "Reúne respuestas y prepara la reserva.",
                        pt: "Reúna respostas e prepare a reserva."
                    ),
                    destination: "venue"
                )
            )
        }

        if event.planning.features.contains(.reservations) {
            let venuePlanning = event.planning.venuePlanning
            if venuePlanning.reservation == nil,
               venuePlanning.selectedCandidateId != nil {
                actions.append(
                    action(
                        id: "reservation.missing",
                        priority: .high,
                        symbol: "checkmark.seal",
                        title: language.text(
                            ja: "予約内容を記録", en: "Record reservation details",
                            zhHans: "记录预约信息", zhHant: "記錄預約資訊",
                            ko: "예약 정보 기록", es: "Registra la reserva",
                            pt: "Registre a reserva"
                        ),
                        detail: language.text(
                            ja: "決定した場所の予約状況と期限を確認します。",
                            en: "Track booking status and cancellation deadlines.",
                            zhHans: "确认已选地点的预约状态和取消期限。",
                            zhHant: "確認已選地點的預約狀態和取消期限。",
                            ko: "선택한 장소의 예약 상태와 취소 기한을 확인하세요.",
                            es: "Controla el estado y el límite de cancelación.",
                            pt: "Acompanhe o status e o prazo de cancelamento."
                        ),
                        destination: "venue"
                    )
                )
            } else if let reservation = venuePlanning.reservation,
                      let deadline = reservation.cancellationDeadline,
                      reservation.status != .cancelled,
                      deadline.timeIntervalSince(now) < 86_400 {
                actions.append(
                    action(
                        id: "reservation.cancellationDeadline",
                        priority: .critical,
                        symbol: "hourglass.badge.exclamationmark",
                        title: language.text(
                            ja: "キャンセル期限を確認", en: "Check cancellation deadline",
                            zhHans: "确认取消期限", zhHant: "確認取消期限",
                            ko: "취소 기한 확인", es: "Revisa el límite de cancelación",
                            pt: "Verifique o prazo de cancelamento"
                        ),
                        detail: deadline.formatted(date: .abbreviated, time: .shortened),
                        destination: "venue"
                    )
                )
            }
        }

        if event.planning.features.contains(.firstDrink) {
            let plan = event.planning.firstDrinkPlan
            if plan.options.count < 2 {
                actions.append(
                    action(
                        id: "firstDrink.options.missing",
                        priority: .normal,
                        symbol: "wineglass",
                        title: language.text(
                            ja: "ドリンク候補を追加", en: "Add drink options",
                            zhHans: "添加饮品选项", zhHant: "新增飲品選項",
                            ko: "음료 후보 추가", es: "Añade opciones de bebida",
                            pt: "Adicione opções de bebida"
                        ),
                        detail: language.text(
                            ja: "第1・第2希望を選べるように2件以上登録します。",
                            en: "Add at least two drinks for first and second choices.",
                            zhHans: "请至少添加两种饮品，以便选择第一和第二志愿。",
                            zhHant: "請至少新增兩種飲品，以便選擇第一和第二志願。",
                            ko: "1·2순위를 고를 수 있도록 음료를 2개 이상 추가하세요.",
                            es: "Añade al menos dos bebidas para la primera y segunda opción.",
                            pt: "Adicione ao menos duas bebidas para a primeira e segunda opção."
                        ),
                        destination: "firstDrink"
                    )
                )
            } else {
                let answeredIds = Set(
                    plan.selections.filter(\.isAnswered).map(\.participantId)
                )
                let unansweredCount = namedParticipants.filter {
                    !answeredIds.contains($0.id)
                }.count

                if unansweredCount > 0 {
                    let deadlinePassed = plan.responseDeadline.map { $0 < now } ?? false
                    actions.append(
                        action(
                            id: "firstDrink.responses.missing",
                            priority: deadlinePassed ? .critical : .high,
                            symbol: "wineglass.fill",
                            title: language.text(
                                ja: "一杯目の回答を確認", en: "Check first-drink choices",
                                zhHans: "确认第一杯饮品选择", zhHant: "確認第一杯飲品選擇",
                                ko: "첫 잔 응답 확인", es: "Revisa las primeras bebidas",
                                pt: "Verifique as primeiras bebidas"
                            ),
                            detail: countText(
                                unansweredCount,
                                language: language,
                                ja: "未回答：%d人", en: "%d people have not answered",
                                zhHans: "%d人尚未回答", zhHant: "%d人尚未回答",
                                ko: "미응답 %d명", es: "%d personas sin responder",
                                pt: "%d pessoas não responderam"
                            ),
                            destination: "firstDrink"
                        )
                    )
                }
            }
        }

        if event.planning.features.contains(.meetingAndArrival),
           !event.planning.meetingPlan.isConfigured {
            actions.append(
                action(
                    id: "meeting.point.missing",
                    priority: .normal,
                    symbol: "location.circle",
                    title: language.text(
                        ja: "集合場所を設定", en: "Set a meeting point",
                        zhHans: "设置集合地点", zhHant: "設定集合地點",
                        ko: "집합 장소 설정", es: "Define el punto de encuentro",
                        pt: "Defina o ponto de encontro"
                    ),
                    detail: language.text(
                        ja: "目印や写真を登録して迷いにくくします。",
                        en: "Add landmarks and a photo so everyone can find it.",
                        zhHans: "添加地标和照片，方便大家找到集合地点。",
                        zhHant: "新增地標和照片，方便大家找到集合地點。",
                        ko: "표시와 사진을 추가해 쉽게 찾을 수 있게 하세요.",
                        es: "Añade referencias y una foto para que sea fácil encontrarlo.",
                        pt: "Adicione referências e uma foto para facilitar o encontro."
                    ),
                    destination: "meeting"
                )
            )
        }

        if event.planning.features.contains(.seating) {
            let plan = event.planning.seatingPlan
            if plan.tables.isEmpty {
                actions.append(
                    action(
                        id: "seating.tables.empty",
                        priority: .normal,
                        symbol: "chair.lounge",
                        title: language.text(
                            ja: "席順を作成", en: "Create a seating plan",
                            zhHans: "创建座位安排", zhHant: "建立座位安排",
                            ko: "좌석 배치 만들기", es: "Crea la distribución de asientos",
                            pt: "Crie a disposição dos lugares"
                        ),
                        detail: language.planningText(.seatingDescription),
                        destination: "seating"
                    )
                )
            } else if plan.totalSeatCount < namedParticipants.count {
                actions.append(
                    action(
                        id: "seating.seats.insufficient",
                        priority: .high,
                        symbol: "chair.lounge.fill",
                        title: language.planningText(.notEnoughSeats),
                        detail: "\(plan.totalSeatCount) / \(namedParticipants.count)",
                        destination: "seating"
                    )
                )
            } else {
                let unassigned = namedParticipants.filter {
                    !plan.assignedParticipantIds.contains($0.id)
                }.count
                if unassigned > 0 {
                    actions.append(
                        action(
                            id: "seating.participants.unassigned",
                            priority: .normal,
                            symbol: "person.crop.circle.badge.questionmark",
                            title: language.planningText(.unassignedParticipants),
                            detail: countText(
                                unassigned,
                                language: language,
                                ja: "未配置：%d人", en: "%d people need seats",
                                zhHans: "%d人尚未安排", zhHant: "%d人尚未安排",
                                ko: "미배치 %d명", es: "%d personas sin asiento",
                                pt: "%d pessoas sem lugar"
                            ),
                            destination: "seating"
                        )
                    )
                }
            }
        }

        if event.planning.features.contains(.reception),
           !event.participants.isEmpty {
            let reception = event.planning.receptionPlan
            if reception.entries.isEmpty {
                actions.append(
                    action(
                        id: "reception.prepare",
                        priority: .normal,
                        symbol: "qrcode.viewfinder",
                        title: language.planningText(.prepareReception),
                        detail: language.planningText(.receptionDescription),
                        destination: "reception"
                    )
                )
            } else {
                let checkedIn = reception.checkedInParticipantIds
                let notCheckedIn = event.participants.filter {
                    !checkedIn.contains($0.id)
                }.count
                let receptionWindowEnd = max(event.date, event.endDate)
                    .addingTimeInterval(12 * 60 * 60)
                let isReceptionTime = now >= event.date.addingTimeInterval(-2 * 60 * 60)
                    && now <= receptionWindowEnd

                if isReceptionTime, notCheckedIn > 0 {
                    actions.append(
                        action(
                            id: "reception.pending",
                            priority: .high,
                            symbol: "person.crop.circle.badge.questionmark",
                            title: language.planningText(.notCheckedIn),
                            detail: countText(
                                notCheckedIn,
                                language: language,
                                ja: "未受付：%d人", en: "%d people have not checked in",
                                zhHans: "%d人尚未签到", zhHant: "%d人尚未報到",
                                ko: "미접수 %d명", es: "%d personas sin registrar",
                                pt: "%d pessoas sem check-in"
                            ),
                            destination: "reception"
                        )
                    )
                }
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

        if event.planning.features.contains(.budget) {
            let plan = event.planning.budgetPlan
            let spent = event.totalExpenseAmount
            let participantCount = max(event.participants.count, 1)
            let perPerson = spent / participantCount

            if let limit = plan.totalLimitMinorUnits, spent > limit {
                actions.append(
                    action(
                        id: "budget.totalExceeded",
                        priority: .critical,
                        symbol: "chart.line.uptrend.xyaxis.circle.fill",
                        title: language.text(
                            ja: "総予算を超過", en: "Total budget exceeded",
                            zhHans: "已超出总预算", zhHant: "已超出總預算",
                            ko: "총예산 초과", es: "Presupuesto total superado",
                            pt: "Orçamento total excedido"
                        ),
                        detail: "\(event.currency.formatted(minorUnits: spent)) / \(event.currency.formatted(minorUnits: limit))",
                        destination: "budget"
                    )
                )
            }

            if let limit = plan.perParticipantLimitMinorUnits,
               perPerson > limit {
                actions.append(
                    action(
                        id: "budget.perPersonExceeded",
                        priority: .high,
                        symbol: "person.crop.circle.badge.exclamationmark",
                        title: language.text(
                            ja: "1人予算を超過", en: "Per-person budget exceeded",
                            zhHans: "已超出人均预算", zhHant: "已超出每人預算",
                            ko: "1인 예산 초과", es: "Presupuesto por persona superado",
                            pt: "Orçamento por pessoa excedido"
                        ),
                        detail: "\(event.currency.formatted(minorUnits: perPerson)) / \(event.currency.formatted(minorUnits: limit))",
                        destination: "budget"
                    )
                )
            }

            if let organizerId = plan.organizerParticipantId,
               let limit = plan.organizerAdvanceLimitMinorUnits {
                let advanced = event.expenses
                    .filter { $0.payerId == organizerId }
                    .reduce(0) { $0 + $1.amount }
                if advanced > limit {
                    actions.append(
                        action(
                            id: "budget.advanceExceeded",
                            priority: .high,
                            symbol: "person.crop.circle.badge.exclamationmark",
                            title: language.text(
                                ja: "幹事の立替上限を超過", en: "Organizer advance limit exceeded",
                                zhHans: "组织者垫付已超限", zhHant: "主辦人墊付已超限",
                                ko: "주최자 선결제 한도 초과", es: "Límite de adelanto superado",
                                pt: "Limite de adiantamento excedido"
                            ),
                            detail: "\(event.currency.formatted(minorUnits: advanced)) / \(event.currency.formatted(minorUnits: limit))",
                            destination: "budget"
                        )
                    )
                }
            }

            if plan.totalLimitMinorUnits == nil,
               plan.perParticipantLimitMinorUnits == nil {
                actions.append(
                    action(
                        id: "budget.unset",
                        priority: .normal,
                        symbol: "chart.pie",
                        title: language.text(
                            ja: "予算を設定", en: "Set a budget",
                            zhHans: "设置预算", zhHant: "設定預算",
                            ko: "예산 설정", es: "Define un presupuesto",
                            pt: "Defina um orçamento"
                        ),
                        detail: language.text(
                            ja: "総額または1人あたりの目安を決めます。",
                            en: "Set a total or per-person spending target.",
                            zhHans: "设置总额或人均支出目标。",
                            zhHant: "設定總額或每人支出目標。",
                            ko: "총액 또는 1인당 지출 목표를 정하세요.",
                            es: "Define un objetivo total o por persona.",
                            pt: "Defina uma meta total ou por pessoa."
                        ),
                        destination: "budget"
                    )
                )
            }
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

        if event.planning.features.contains(.tasksAndItems) {
            let unassignedItems = event.planning.preparationItems.filter {
                $0.status != .ready && $0.assigneeParticipantIds.isEmpty
            }
            if !unassignedItems.isEmpty {
                actions.append(
                    action(
                        id: "items.unassigned",
                        priority: .high,
                        symbol: "shippingbox.and.arrow.backward.fill",
                        title: language.text(
                            ja: "持ち物の担当を決定", en: "Assign preparation items",
                            zhHans: "分配物品负责人", zhHant: "分配物品負責人",
                            ko: "준비물 담당자 지정", es: "Asigna los objetos",
                            pt: "Atribua os itens"
                        ),
                        detail: countText(
                            unassignedItems.count,
                            language: language,
                            ja: "担当未定：%d件", en: "%d items need an owner",
                            zhHans: "%d项物品未分配", zhHant: "%d項物品未分配",
                            ko: "담당 미정 %d개", es: "%d objetos sin responsable",
                            pt: "%d itens sem responsável"
                        ),
                        destination: "checklist"
                    )
                )
            }
        }

        if event.planning.features.contains(.timeline),
           event.planning.timelineEntries.isEmpty {
            actions.append(
                action(
                    id: "timeline.empty",
                    priority: .normal,
                    symbol: "clock.badge.plus",
                    title: language.text(
                        ja: "当日の流れを作成", en: "Create the event timeline",
                        zhHans: "创建当天时间线", zhHant: "建立當天時間軸",
                        ko: "당일 일정 만들기", es: "Crea el cronograma",
                        pt: "Crie o cronograma"
                    ),
                    detail: language.text(
                        ja: "集合・乾杯・写真・会計などを時系列で整理します。",
                        en: "Organize arrival, opening, photos, and payment in order.",
                        zhHans: "按顺序整理集合、开场、拍照和结账。",
                        zhHant: "依序整理集合、開場、拍照與結帳。",
                        ko: "집합·시작·사진·결제를 시간순으로 정리하세요.",
                        es: "Ordena llegada, apertura, fotos y pago.",
                        pt: "Organize chegada, abertura, fotos e pagamento."
                    ),
                    destination: "timeline"
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
