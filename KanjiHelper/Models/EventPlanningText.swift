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
    ["期限切れ", "Overdue", "已逾期", "已逾期", "기한 지남", "Vencida", "Atrasada"]
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
