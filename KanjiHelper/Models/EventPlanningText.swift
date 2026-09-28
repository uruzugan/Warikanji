import Foundation

enum EventPlanningText: Int {
    case attendance
    case attendanceSummary
    case unanswered
    case attending
    case notAttending
    case maybe
    case companions
    case addCompanion
    case companionName
    case adult
    case child
    case preschooler
    case otherCategory
    case dietaryNotes
    case dietaryPlaceholder
    case arrivalStatus
    case notShared
    case onTheWay
    case arrived
    case delayed
    case attendingFrom
    case leavingAt
    case save
    case eventParts
    case partsDescription
    case addPart
    case noParts
    case partTitle
    case startTime
    case endTime
    case location
    case participants
    case tasks
    case tasksDescription
    case addTask
    case noTasks
    case taskTitle
    case notes
    case dueDate
    case assignees
    case status
    case pending
    case inProgress
    case completed
    case privateTask
    case newPart
    case editPart
    case newTask
    case editTask
    case cancel
    case delete
    case responseDetails
    case partAttendance
    case optional
    case allParticipants
    case overdue
    case datePoll
    case datePollDescription
    case addDateOption
    case noDateOptions
    case responseDeadline
    case finalChoice
    case notFinalized
    case dateOption
    case newDateOption
    case editDateOption
    case yes
    case no
    case venuePlanning
    case venueDescription
    case addVenue
    case noVenues
    case venueName
    case webURL
    case priceNote
    case selectVenue
    case selected
    case reservation
    case reservationStatus
    case planned
    case requested
    case confirmed
    case cancelled
    case confirmationNumber
    case reservationDate
    case partySize
    case contactName
    case cancellationDeadline
    case clearReservation
    case openLink
    case preparationItems
    case itemsDescription
    case addItem
    case noItems
    case itemTitle
    case quantity
    case needed
    case assigned
    case ready
    case newItem
    case editItem
    case timeline
    case timelineDescription
    case addTimelineEntry
    case noTimelineEntries
    case timelineTitle
    case newTimelineEntry
    case editTimelineEntry
    case completedTimeline
    case firstDrinkTitle
    case firstDrinkDescription
    case drinkMenu
    case addDrink
    case noDrinks
    case drinkName
    case alcoholic
    case nonAlcoholic
    case toastOption
    case firstChoice
    case secondChoice
    case thirdChoice
    case answered
    case aggregate
    case newDrink
    case editDrink
    case selectionIncomplete
    case meetingAndArrivalTitle
    case meetingAndArrivalDescription
    case meetingPoint
    case meetingPointName
    case meetingInstructions
    case meetingTime
    case editMeetingPoint
    case noMeetingPoint
    case choosePhoto
    case takePhoto
    case removePhoto
    case meetingPhoto
    case arrivalSummary
}

private let eventPlanningTexts: [[String]] = [
    ["出欠確認", "Attendance", "出席确认", "出席確認", "참석 확인", "Asistencia", "Presença"],
    ["参加状況を入力・確認", "Record and review attendance", "填写并确认出席情况", "填寫並確認出席狀況", "참석 상태 입력 및 확인", "Registra y revisa la asistencia", "Registre e revise a presença"],
    ["未回答", "Unanswered", "未回答", "未回答", "미응답", "Sin respuesta", "Sem resposta"],
    ["参加", "Attending", "参加", "參加", "참석", "Asiste", "Participa"],
    ["不参加", "Not Attending", "不参加", "不參加", "불참", "No asiste", "Não participa"],
    ["未定", "Maybe", "待定", "未定", "미정", "Quizá", "Talvez"],
    ["同伴者", "Companions", "同行者", "同行者", "동반자", "Acompañantes", "Acompanhantes"],
    ["同伴者を追加", "Add Companion", "添加同行者", "新增同行者", "동반자 추가", "Añadir acompañante", "Adicionar acompanhante"],
    ["同伴者名", "Companion Name", "同行者姓名", "同行者姓名", "동반자 이름", "Nombre", "Nome"],
    ["大人", "Adult", "成人", "成人", "성인", "Adulto", "Adulto"],
    ["子ども", "Child", "儿童", "兒童", "어린이", "Niño", "Criança"],
    ["未就学児", "Preschooler", "学龄前儿童", "學齡前兒童", "미취학 아동", "Preescolar", "Pré-escolar"],
    ["その他", "Other", "其他", "其他", "기타", "Otro", "Outro"],
    ["食事制限・アレルギー", "Dietary Needs & Allergies", "饮食限制・过敏", "飲食限制・過敏", "식이 제한·알레르기", "Dieta y alergias", "Dieta e alergias"],
    ["必要な配慮だけを入力", "Enter only what organizers need to know", "仅填写组织者需要了解的信息", "僅填寫主辦方需要了解的資訊", "주최자에게 필요한 정보만 입력", "Incluye solo lo necesario", "Informe apenas o necessário"],
    ["到着状況", "Arrival Status", "到达状态", "抵達狀況", "도착 상태", "Estado de llegada", "Status de chegada"],
    ["共有なし", "Not Shared", "不共享", "不分享", "공유 안 함", "Sin compartir", "Não compartilhado"],
    ["移動中", "On the Way", "在路上", "前往中", "이동 중", "En camino", "A caminho"],
    ["到着", "Arrived", "已到达", "已抵達", "도착", "Ha llegado", "Chegou"],
    ["遅延", "Delayed", "延迟", "延誤", "지연", "Con retraso", "Atrasado"],
    ["参加開始", "Attending From", "参加开始", "參加開始", "참석 시작", "Asiste desde", "Participa a partir de"],
    ["退出予定", "Leaving At", "预计离开", "預計離開", "퇴장 예정", "Se va a las", "Sai às"],
    ["保存", "Save", "保存", "儲存", "저장", "Guardar", "Salvar"],
    ["イベントの部", "Event Parts", "活动环节", "活動環節", "이벤트 순서", "Partes del evento", "Etapas do evento"],
    ["一次会・二次会や旅行日程を分けて管理", "Manage separate sessions or trip stages", "分别管理主活动、二次会或旅行日程", "分別管理主活動、二次會或旅行日程", "1차·2차 또는 여행 일정을 나누어 관리", "Separa sesiones o etapas del viaje", "Separe sessões ou etapas da viagem"],
    ["部を追加", "Add Part", "添加环节", "新增環節", "순서 추가", "Añadir parte", "Adicionar etapa"],
    ["まだ部がありません", "No parts yet", "尚无环节", "尚無環節", "아직 순서가 없습니다", "Aún no hay partes", "Ainda não há etapas"],
    ["名称", "Title", "名称", "名稱", "이름", "Título", "Título"],
    ["開始", "Starts", "开始", "開始", "시작", "Inicio", "Início"],
    ["終了", "Ends", "结束", "結束", "종료", "Fin", "Fim"],
    ["場所", "Location", "地点", "地點", "장소", "Lugar", "Local"],
    ["参加者", "Participants", "参与者", "參加者", "참가자", "Participantes", "Participantes"],
    ["タスク・持ち物", "Tasks & Items", "任务・物品", "任務・物品", "작업·준비물", "Tareas y objetos", "Tarefas e itens"],
    ["期限と担当者をまとめて確認", "Track deadlines and assignees", "统一确认期限和负责人", "統一確認期限和負責人", "기한과 담당자를 한눈에 확인", "Controla plazos y responsables", "Acompanhe prazos e responsáveis"],
    ["タスクを追加", "Add Task", "添加任务", "新增任務", "작업 추가", "Añadir tarea", "Adicionar tarefa"],
    ["タスクはありません", "No tasks yet", "暂无任务", "尚無任務", "작업이 없습니다", "Aún no hay tareas", "Ainda não há tarefas"],
    ["タスク名", "Task Title", "任务名称", "任務名稱", "작업 이름", "Título de la tarea", "Título da tarefa"],
    ["メモ", "Notes", "备注", "備註", "메모", "Notas", "Notas"],
    ["期限", "Due Date", "期限", "期限", "기한", "Fecha límite", "Prazo"],
    ["担当者", "Assignees", "负责人", "負責人", "담당자", "Responsables", "Responsáveis"],
    ["状態", "Status", "状态", "狀態", "상태", "Estado", "Status"],
    ["未着手", "Pending", "未开始", "未開始", "대기", "Pendiente", "Pendente"],
    ["進行中", "In Progress", "进行中", "進行中", "진행 중", "En curso", "Em andamento"],
    ["完了", "Completed", "已完成", "已完成", "완료", "Completada", "Concluída"],
    ["幹事だけに表示", "Organizer Only", "仅组织者可见", "僅主辦方可見", "주최자에게만 표시", "Solo organizadores", "Somente organizadores"],
    ["新しい部", "New Part", "新环节", "新環節", "새 순서", "Nueva parte", "Nova etapa"],
    ["部を編集", "Edit Part", "编辑环节", "編輯環節", "순서 편집", "Editar parte", "Editar etapa"],
    ["新しいタスク", "New Task", "新任务", "新任務", "새 작업", "Nueva tarea", "Nova tarefa"],
    ["タスクを編集", "Edit Task", "编辑任务", "編輯任務", "작업 편집", "Editar tarea", "Editar tarefa"],
    ["キャンセル", "Cancel", "取消", "取消", "취소", "Cancelar", "Cancelar"],
    ["削除", "Delete", "删除", "刪除", "삭제", "Eliminar", "Excluir"],
    ["回答内容", "Response Details", "回答内容", "回答內容", "응답 내용", "Detalles de respuesta", "Detalhes da resposta"],
    ["部ごとの出欠", "Attendance by Part", "各环节出席情况", "各環節出席狀況", "순서별 참석", "Asistencia por parte", "Presença por etapa"],
    ["任意", "Optional", "可选", "選填", "선택", "Opcional", "Opcional"],
    ["全員", "Everyone", "所有人", "所有人", "전원", "Todos", "Todos"],
    ["期限切れ", "Overdue", "已逾期", "已逾期", "기한 지남", "Vencida", "Atrasada"],
    ["日程投票", "Date Poll", "日期投票", "日期投票", "일정 투표", "Votación de fecha", "Votação de data"],
    ["候補日ごとの都合をまとめて確認", "Compare availability for each date option", "汇总确认各候选日期的时间", "彙整確認各候選日期的時間", "후보 날짜별 가능 여부 확인", "Compara la disponibilidad de cada fecha", "Compare a disponibilidade de cada data"],
    ["候補日を追加", "Add Date Option", "添加候选日期", "新增候選日期", "후보 날짜 추가", "Añadir fecha", "Adicionar data"],
    ["候補日はありません", "No date options yet", "暂无候选日期", "尚無候選日期", "후보 날짜가 없습니다", "Aún no hay fechas", "Ainda não há datas"],
    ["回答期限", "Response Deadline", "回答期限", "回答期限", "응답 기한", "Fecha límite de respuesta", "Prazo de resposta"],
    ["確定日程", "Final Date", "最终日期", "最終日期", "확정 일정", "Fecha final", "Data final"],
    ["未確定", "Not Finalized", "未确定", "未確定", "미확정", "Sin decidir", "Não definida"],
    ["候補日", "Date Option", "候选日期", "候選日期", "후보 날짜", "Fecha candidata", "Data candidata"],
    ["新しい候補日", "New Date Option", "新候选日期", "新候選日期", "새 후보 날짜", "Nueva fecha", "Nova data"],
    ["候補日を編集", "Edit Date Option", "编辑候选日期", "編輯候選日期", "후보 날짜 편집", "Editar fecha", "Editar data"],
    ["参加可能", "Available", "可以参加", "可以參加", "참석 가능", "Disponible", "Disponível"],
    ["参加不可", "Unavailable", "无法参加", "無法參加", "참석 불가", "No disponible", "Indisponível"],
    ["店・場所候補", "Venue Candidates", "地点候选", "地點候選", "장소 후보", "Lugares candidatos", "Locais candidatos"],
    ["候補への回答と予約内容をまとめて管理", "Manage venue votes and reservation details", "统一管理地点投票与预约信息", "統一管理地點投票與預約資訊", "장소 투표와 예약 정보 관리", "Gestiona votos y reservas", "Gerencie votos e reservas"],
    ["候補を追加", "Add Venue", "添加候选地点", "新增候選地點", "장소 후보 추가", "Añadir lugar", "Adicionar local"],
    ["候補はありません", "No venue candidates yet", "暂无候选地点", "尚無候選地點", "장소 후보가 없습니다", "Aún no hay lugares", "Ainda não há locais"],
    ["店・場所名", "Venue Name", "地点名称", "地點名稱", "장소 이름", "Nombre del lugar", "Nome do local"],
    ["Webリンク", "Web Link", "网页链接", "網頁連結", "웹 링크", "Enlace web", "Link da web"],
    ["料金メモ", "Price Note", "价格备注", "價格備註", "가격 메모", "Nota de precio", "Nota de preço"],
    ["この候補に決定", "Select This Venue", "选择此地点", "選擇此地點", "이 장소로 결정", "Elegir este lugar", "Escolher este local"],
    ["決定済み", "Selected", "已选择", "已選擇", "선택됨", "Seleccionado", "Selecionado"],
    ["予約情報", "Reservation", "预约信息", "預約資訊", "예약 정보", "Reserva", "Reserva"],
    ["予約状態", "Reservation Status", "预约状态", "預約狀態", "예약 상태", "Estado de la reserva", "Status da reserva"],
    ["予約予定", "Planned", "计划预约", "計畫預約", "예약 예정", "Planificada", "Planejada"],
    ["予約依頼中", "Requested", "预约申请中", "預約申請中", "예약 요청 중", "Solicitada", "Solicitada"],
    ["予約確定", "Confirmed", "预约已确认", "預約已確認", "예약 확정", "Confirmada", "Confirmada"],
    ["キャンセル", "Cancelled", "已取消", "已取消", "취소됨", "Cancelada", "Cancelada"],
    ["予約番号", "Confirmation Number", "预约编号", "預約編號", "예약 번호", "Número de confirmación", "Número de confirmação"],
    ["予約日時", "Reservation Date", "预约日期时间", "預約日期時間", "예약 일시", "Fecha de reserva", "Data da reserva"],
    ["予約人数", "Party Size", "预约人数", "預約人數", "예약 인원", "Número de personas", "Número de pessoas"],
    ["予約者名", "Contact Name", "预约人姓名", "預約人姓名", "예약자 이름", "Nombre de contacto", "Nome do contato"],
    ["キャンセル期限", "Cancellation Deadline", "取消期限", "取消期限", "취소 기한", "Límite de cancelación", "Prazo de cancelamento"],
    ["予約情報を削除", "Clear Reservation", "删除预约信息", "刪除預約資訊", "예약 정보 삭제", "Borrar reserva", "Limpar reserva"],
    ["リンクを開く", "Open Link", "打开链接", "開啟連結", "링크 열기", "Abrir enlace", "Abrir link"],
    ["持ち物", "Items", "物品", "物品", "준비물", "Objetos", "Itens"],
    ["必要な物・数量・担当者を管理", "Track items, quantities, and owners", "管理所需物品、数量和负责人", "管理所需物品、數量和負責人", "준비물·수량·담당자 관리", "Controla objetos, cantidades y responsables", "Gerencie itens, quantidades e responsáveis"],
    ["持ち物を追加", "Add Item", "添加物品", "新增物品", "준비물 추가", "Añadir objeto", "Adicionar item"],
    ["持ち物はありません", "No items yet", "暂无物品", "尚無物品", "준비물이 없습니다", "Aún no hay objetos", "Ainda não há itens"],
    ["持ち物名", "Item Name", "物品名称", "物品名稱", "준비물 이름", "Nombre del objeto", "Nome do item"],
    ["数量", "Quantity", "数量", "數量", "수량", "Cantidad", "Quantidade"],
    ["未手配", "Needed", "未安排", "未安排", "미준비", "Pendiente", "Necessário"],
    ["担当決定", "Assigned", "已分配", "已分配", "담당 지정", "Asignado", "Atribuído"],
    ["準備完了", "Ready", "准备完成", "準備完成", "준비 완료", "Listo", "Pronto"],
    ["新しい持ち物", "New Item", "新物品", "新物品", "새 준비물", "Nuevo objeto", "Novo item"],
    ["持ち物を編集", "Edit Item", "编辑物品", "編輯物品", "준비물 편집", "Editar objeto", "Editar item"],
    ["タイムライン", "Timeline", "时间线", "時間軸", "타임라인", "Cronograma", "Cronograma"],
    ["当日の流れ・場所・担当者を時系列で管理", "Track the day's schedule, locations, and owners", "按时间管理当天流程、地点和负责人", "按時間管理當天流程、地點和負責人", "당일 일정·장소·담당자를 시간순으로 관리", "Ordena el programa, lugares y responsables", "Organize horários, locais e responsáveis"],
    ["予定を追加", "Add Timeline Entry", "添加日程", "新增行程", "일정 추가", "Añadir actividad", "Adicionar atividade"],
    ["予定はありません", "No timeline entries yet", "暂无日程", "尚無行程", "일정이 없습니다", "Aún no hay actividades", "Ainda não há atividades"],
    ["予定名", "Timeline Title", "日程名称", "行程名稱", "일정 이름", "Título de la actividad", "Título da atividade"],
    ["新しい予定", "New Timeline Entry", "新日程", "新行程", "새 일정", "Nueva actividad", "Nova atividade"],
    ["予定を編集", "Edit Timeline Entry", "编辑日程", "編輯行程", "일정 편집", "Editar actividad", "Editar atividade"],
    ["実施済み", "Completed", "已完成", "已完成", "완료", "Completada", "Concluída"],
    ["一杯目セレクト", "First Drink", "第一杯饮品", "第一杯飲品", "첫 잔 선택", "Primera bebida", "Primeira bebida"],
    ["第1・第2希望を事前に集めて注文を早くする", "Collect first and second choices before the event", "提前收集第一、第二选择以便快速点单", "事先收集第一、第二選擇以便快速點單", "1·2순위를 미리 모아 주문을 빠르게 진행", "Recoge la primera y segunda opción antes del evento", "Colete a primeira e segunda opção antes do evento"],
    ["ドリンクメニュー", "Drink Menu", "饮品菜单", "飲品選單", "음료 메뉴", "Menú de bebidas", "Menu de bebidas"],
    ["ドリンクを追加", "Add Drink", "添加饮品", "新增飲品", "음료 추가", "Añadir bebida", "Adicionar bebida"],
    ["ドリンクがありません", "No drinks yet", "暂无饮品", "尚無飲品", "음료가 없습니다", "Aún no hay bebidas", "Ainda não há bebidas"],
    ["ドリンク名", "Drink Name", "饮品名称", "飲品名稱", "음료 이름", "Nombre de la bebida", "Nome da bebida"],
    ["アルコール", "Alcoholic", "含酒精", "含酒精", "알코올", "Con alcohol", "Alcoólica"],
    ["ノンアルコール", "Non-Alcoholic", "无酒精", "無酒精", "무알코올", "Sin alcohol", "Sem álcool"],
    ["乾杯用の候補", "Toast Option", "干杯候选", "乾杯候選", "건배 후보", "Opción para brindar", "Opção para brinde"],
    ["第1希望", "First Choice", "第一选择", "第一選擇", "1순위", "Primera opción", "Primeira opção"],
    ["第2希望", "Second Choice", "第二选择", "第二選擇", "2순위", "Segunda opción", "Segunda opção"],
    ["第3希望（任意）", "Third Choice (Optional)", "第三选择（可选）", "第三選擇（選填）", "3순위(선택)", "Tercera opción (opcional)", "Terceira opção (opcional)"],
    ["回答済み", "Answered", "已回答", "已回答", "응답 완료", "Respondido", "Respondido"],
    ["一杯目集計", "First-Choice Totals", "第一选择统计", "第一選擇統計", "1순위 집계", "Totales de primera opción", "Totais da primeira opção"],
    ["新しいドリンク", "New Drink", "新饮品", "新飲品", "새 음료", "Nueva bebida", "Nova bebida"],
    ["ドリンクを編集", "Edit Drink", "编辑饮品", "編輯飲品", "음료 편집", "Editar bebida", "Editar bebida"],
    ["第1・第2希望を選んでください", "Choose first and second choices", "请选择第一和第二选择", "請選擇第一和第二選擇", "1·2순위를 선택하세요", "Elige la primera y segunda opción", "Escolha a primeira e a segunda opção"],
    ["集合・到着", "Meeting & Arrival", "集合与到达", "集合與抵達", "집합·도착", "Encuentro y llegada", "Encontro e chegada"],
    ["集合場所の案内と参加者の到着状況をまとめて確認", "Share meeting instructions and review arrival status", "共享集合地点并确认参与者到达情况", "分享集合地點並確認參加者抵達狀況", "집합 안내와 참가자 도착 상태를 한눈에 확인", "Comparte el punto de encuentro y revisa las llegadas", "Compartilhe o ponto de encontro e acompanhe as chegadas"],
    ["集合場所", "Meeting Point", "集合地点", "集合地點", "집합 장소", "Punto de encuentro", "Ponto de encontro"],
    ["集合場所名", "Meeting Point Name", "集合地点名称", "集合地點名稱", "집합 장소 이름", "Nombre del punto de encuentro", "Nome do ponto de encontro"],
    ["集合方法・目印", "Instructions & Landmarks", "集合说明与地标", "集合說明與地標", "집합 방법·표시", "Indicaciones y referencias", "Instruções e referências"],
    ["集合時刻", "Meeting Time", "集合时间", "集合時間", "집합 시간", "Hora de encuentro", "Horário do encontro"],
    ["集合場所を編集", "Edit Meeting Point", "编辑集合地点", "編輯集合地點", "집합 장소 편집", "Editar punto de encuentro", "Editar ponto de encontro"],
    ["集合場所は未設定です", "No meeting point set", "尚未设置集合地点", "尚未設定集合地點", "집합 장소가 설정되지 않았습니다", "No se ha definido el punto de encuentro", "Ponto de encontro não definido"],
    ["写真を選ぶ", "Choose Photo", "选择照片", "選擇照片", "사진 선택", "Elegir foto", "Escolher foto"],
    ["写真を撮る", "Take Photo", "拍摄照片", "拍攝照片", "사진 촬영", "Tomar foto", "Tirar foto"],
    ["写真を削除", "Remove Photo", "删除照片", "刪除照片", "사진 삭제", "Eliminar foto", "Remover foto"],
    ["集合場所の写真", "Meeting Point Photo", "集合地点照片", "集合地點照片", "집합 장소 사진", "Foto del punto de encuentro", "Foto do ponto de encontro"],
    ["到着状況の集計", "Arrival Summary", "到达情况统计", "抵達狀況統計", "도착 현황", "Resumen de llegadas", "Resumo das chegadas"]
]

extension AppLanguage {
    func planningText(_ key: EventPlanningText) -> String {
        eventPlanningTexts[key.rawValue][planningTextIndex]
    }

    private var planningTextIndex: Int {
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

extension AttendanceStatus {
    func displayName(for language: AppLanguage) -> String {
        switch self {
        case .unanswered: return language.planningText(.unanswered)
        case .attending: return language.planningText(.attending)
        case .notAttending: return language.planningText(.notAttending)
        case .maybe: return language.planningText(.maybe)
        }
    }
}

extension ArrivalStatus {
    func displayName(for language: AppLanguage) -> String {
        switch self {
        case .notShared: return language.planningText(.notShared)
        case .onTheWay: return language.planningText(.onTheWay)
        case .arrived: return language.planningText(.arrived)
        case .delayed: return language.planningText(.delayed)
        }
    }
}

extension ParticipantCategory {
    func displayName(for language: AppLanguage) -> String {
        switch self {
        case .adult: return language.planningText(.adult)
        case .child: return language.planningText(.child)
        case .preschooler: return language.planningText(.preschooler)
        case .other: return language.planningText(.otherCategory)
        }
    }
}

extension EventTaskStatus {
    func displayName(for language: AppLanguage) -> String {
        switch self {
        case .pending: return language.planningText(.pending)
        case .inProgress: return language.planningText(.inProgress)
        case .completed: return language.planningText(.completed)
        }
    }
}

extension CoordinationChoice {
    func displayName(for language: AppLanguage) -> String {
        switch self {
        case .unanswered: return language.planningText(.unanswered)
        case .yes: return language.planningText(.yes)
        case .maybe: return language.planningText(.maybe)
        case .no: return language.planningText(.no)
        }
    }
}

extension ReservationStatus {
    func displayName(for language: AppLanguage) -> String {
        switch self {
        case .planned: return language.planningText(.planned)
        case .requested: return language.planningText(.requested)
        case .confirmed: return language.planningText(.confirmed)
        case .cancelled: return language.planningText(.cancelled)
        }
    }
}

extension PreparationItemStatus {
    func displayName(for language: AppLanguage) -> String {
        switch self {
        case .needed: return language.planningText(.needed)
        case .assigned: return language.planningText(.assigned)
        case .ready: return language.planningText(.ready)
        }
    }
}
