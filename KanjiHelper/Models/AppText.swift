import Foundation

enum AppText: Int {
    case done, settings
    case organizingEasier, trackExpenses, adjustShares, calculatePayments, trackPaymentStatus
    case yourAccount, currentAccount, name, localAccountDescription, nameChangeDescription
    case languageAndCurrency, homeCurrency, referenceCurrency
    case overseasCurrencyDescription, currencySettingsDescription
    case startWarikanji, general, saveSettings, settingsSaved
    case account, switchAccountDescription, switchAccount
    case deleteAccount, deleteThisAccount, deleteAccountDescription
    case deleteAccountConfirmation, deleteAccountWarning, cancel
}

enum EventText: Int {
    case newEvent, editEvent, cancel, createEvent, saveChanges
    case event, createPrompt, type, participants, date
    case basicInfo, eventName, eventNameExample, dateTime, location, optional
    case eventType, chooseEventType
    case howManyPeople, participantMinimum, participantHelp, oneAtATime
    case memo, memoHelp, memoPlaceholder
}

private let appTexts: [[String]] = [
    ["完了", "Done", "完成", "完成", "완료", "Listo", "Concluído"],
    ["設定", "Settings", "设置", "設定", "설정", "Ajustes", "Configurações"],

    ["幹事をもっとシンプルに", "Make organizing easier", "让组织活动更简单", "讓組織活動更簡單", "모임 관리를 더 간단하게", "Organiza de forma más sencilla", "Organize de forma mais simples"],
    ["費用をまとめて記録", "Track group expenses", "统一记录活动费用", "統一記錄活動費用", "모임 비용을 한곳에 기록", "Registra los gastos del grupo", "Registre as despesas do grupo"],
    ["負担額をかんたん調整", "Adjust each person's share", "轻松调整每个人的分摊", "輕鬆調整每個人的分攤", "각자의 부담액을 쉽게 조정", "Ajusta la parte de cada persona", "Ajuste a parte de cada pessoa"],
    ["誰が誰に払うか自動計算", "Calculate who pays whom", "自动计算谁该付给谁", "自動計算誰該付給誰", "누가 누구에게 낼지 자동 계산", "Calcula quién paga a quién", "Calcule quem paga a quem"],
    ["支払い状況まで確認", "Track payment status", "确认付款状态", "確認付款狀態", "결제 상태까지 확인", "Controla el estado de los pagos", "Acompanhe o status dos pagamentos"],

    ["あなたのアカウント", "Your Account", "你的账户", "你的帳戶", "내 계정", "Tu cuenta", "Sua conta"],
    ["現在のアカウント", "Current Account", "当前账户", "目前帳戶", "현재 계정", "Cuenta actual", "Conta atual"],
    ["名前", "Name", "姓名", "姓名", "이름", "Nombre", "Nome"],
    ["端末内に保存されるローカルアカウントです。", "This account is stored locally on this device.", "此账户仅保存在本设备上。", "此帳戶僅儲存在本裝置上。", "이 계정은 이 기기에만 저장됩니다.", "Esta cuenta se guarda en este dispositivo.", "Esta conta é armazenada neste dispositivo."],
    ["名前はいつでも変更できます。", "You can change your name at any time.", "你可以随时更改姓名。", "你可以隨時更改姓名。", "이름은 언제든지 변경할 수 있습니다.", "Puedes cambiar tu nombre cuando quieras.", "Você pode alterar seu nome quando quiser."],

    ["言語と通貨", "Language & Currency", "语言与货币", "語言與貨幣", "언어 및 통화", "Idioma y moneda", "Idioma e moeda"],
    ["イベントの初期通貨", "Default Event Currency", "活动默认货币", "活動預設貨幣", "이벤트 기본 통화", "Moneda predeterminada del evento", "Moeda padrão do evento"],
    ["参考換算先", "Reference Currency", "参考换算货币", "參考換算貨幣", "참고 환산 통화", "Moneda de referencia", "Moeda de referência"],

    [
        "海外イベントでは現地通貨の合計と、参考換算額を表示できます。",
        "For overseas events, Warikanji can show the local total and an approximate converted value.",
        "海外活动可同时显示当地货币总额和参考换算金额。",
        "海外活動可同時顯示當地貨幣總額和參考換算金額。",
        "해외 이벤트에서는 현지 통화 합계와 참고 환산 금액을 표시할 수 있습니다.",
        "En eventos en el extranjero se puede mostrar el total local y una conversión aproximada.",
        "Em eventos no exterior é possível mostrar o total local e uma conversão aproximada."
    ],
    [
        "イベントの初期通貨は、新規イベントで最初に選ばれる通貨です。参考換算先はホームとイベント詳細に概算額を表示するために使います。",
        "The default event currency is selected initially for new events. The reference currency shows approximate converted totals on Home and Event Details.",
        "活动默认货币是新建活动时最初选择的货币。参考货币用于在主页和活动详情中显示概算换算金额。",
        "活動預設貨幣是新增活動時最初選取的貨幣。參考貨幣用於在首頁和活動詳情中顯示概算換算金額。",
        "이벤트 기본 통화는 새 이벤트에서 처음 선택되는 통화입니다. 참고 통화는 홈과 이벤트 상세에서 대략적인 환산 금액을 표시할 때 사용됩니다.",
        "La moneda predeterminada del evento se selecciona inicialmente al crear uno. La moneda de referencia muestra conversiones aproximadas en Inicio y en los detalles.",
        "A moeda padrão do evento é selecionada inicialmente ao criar um evento. A moeda de referência mostra conversões aproximadas na tela inicial e nos detalhes."
    ],

    ["ワリカンジをはじめる", "Start Warikanji", "开始使用 Warikanji", "開始使用 Warikanji", "Warikanji 시작하기", "Empezar con Warikanji", "Começar com Warikanji"],
    ["一般", "General", "常规", "一般", "일반", "General", "Geral"],
    ["設定を保存", "Save Settings", "保存设置", "儲存設定", "설정 저장", "Guardar ajustes", "Salvar configurações"],
    ["設定が保存されました。", "Settings saved.", "设置已保存。", "設定已儲存。", "설정이 저장되었습니다.", "Los ajustes se han guardado.", "As configurações foram salvas."],

    ["アカウント", "Account", "账户", "帳戶", "계정", "Cuenta", "Conta"],
    ["別のローカルアカウントへ切り替えます。", "Switch to another local account.", "切换到其他本地账户。", "切換至其他本機帳戶。", "다른 로컬 계정으로 전환합니다.", "Cambia a otra cuenta local.", "Alterne para outra conta local."],
    ["アカウントを切り替える", "Switch Account", "切换账户", "切換帳戶", "계정 전환", "Cambiar cuenta", "Trocar conta"],

    ["アカウントを削除", "Delete Account", "删除账户", "刪除帳戶", "계정 삭제", "Eliminar cuenta", "Excluir conta"],
    ["このアカウントを削除", "Delete This Account", "删除此账户", "刪除此帳戶", "이 계정 삭제", "Eliminar esta cuenta", "Excluir esta conta"],
    ["このアカウントに保存されているイベントデータも削除されます。", "All event data saved under this account will also be deleted.", "此账户保存的活动数据也会被删除。", "此帳戶儲存的活動資料也會被刪除。", "이 계정의 이벤트 데이터도 함께 삭제됩니다.", "También se eliminarán los eventos guardados en esta cuenta.", "Os eventos salvos nesta conta também serão excluídos."],
    ["このアカウントを削除しますか？", "Delete this account?", "要删除此账户吗？", "要刪除此帳戶嗎？", "이 계정을 삭제하시겠습니까?", "¿Eliminar esta cuenta?", "Excluir esta conta?"],
    ["イベント・費用・精算データも削除されます。この操作は取り消せません。", "Events, expenses and settlement data will also be deleted. This cannot be undone.", "活动、费用和结算数据也会被删除。此操作无法撤销。", "活動、費用和結算資料也會被刪除。此操作無法復原。", "이벤트, 비용 및 정산 데이터도 삭제됩니다. 되돌릴 수 없습니다.", "También se eliminarán los eventos, gastos y liquidaciones. No se puede deshacer.", "Eventos, despesas e acertos também serão excluídos. Não é possível desfazer."],
    ["キャンセル", "Cancel", "取消", "取消", "취소", "Cancelar", "Cancelar"]
]

private let eventTexts: [[String]] = [
    ["新規イベント", "New Event", "新建活动", "新增活動", "새 이벤트", "Nuevo evento", "Novo evento"],
    ["イベントを編集", "Edit Event", "编辑活动", "編輯活動", "이벤트 편집", "Editar evento", "Editar evento"],
    ["キャンセル", "Cancel", "取消", "取消", "취소", "Cancelar", "Cancelar"],
    ["イベントを作成", "Create Event", "创建活动", "建立活動", "이벤트 만들기", "Crear evento", "Criar evento"],
    ["変更を保存", "Save Changes", "保存更改", "儲存變更", "변경 사항 저장", "Guardar cambios", "Salvar alterações"],

    ["イベント", "Event", "活动", "活動", "이벤트", "Evento", "Evento"],
    ["イベントを作ろう！", "Let's create an event!", "创建一个活动吧！", "建立一個活動吧！", "이벤트를 만들어 보세요!", "¡Crea un evento!", "Crie um evento!"],
    ["種類", "Type", "类型", "類型", "유형", "Tipo", "Tipo"],
    ["参加人数", "Participants", "参与人数", "參加人數", "참여 인원", "Participantes", "Participantes"],
    ["開催日", "Date", "日期", "日期", "날짜", "Fecha", "Data"],

    ["基本情報", "Basic Information", "基本信息", "基本資訊", "기본 정보", "Información básica", "Informações básicas"],
    ["イベント名", "Event Name", "活动名称", "活動名稱", "이벤트 이름", "Nombre del evento", "Nome do evento"],
    ["例：忘年会", "e.g. Year-end party", "例如：年终聚会", "例如：年終聚會", "예: 송년회", "Ej.: Fiesta de fin de año", "Ex.: Festa de fim de ano"],
    ["開催日時", "Date & Time", "日期和时间", "日期與時間", "날짜 및 시간", "Fecha y hora", "Data e hora"],
    ["場所", "Location", "地点", "地點", "장소", "Lugar", "Local"],
    ["任意", "Optional", "可选", "選填", "선택 사항", "Opcional", "Opcional"],

    ["イベントの種類", "Event Type", "活动类型", "活動類型", "이벤트 유형", "Tipo de evento", "Tipo de evento"],
    ["内容に近いものを選んでください", "Choose the closest match.", "请选择最接近的类型。", "請選擇最接近的類型。", "가장 가까운 유형을 선택하세요.", "Elige la opción más parecida.", "Escolha a opção mais próxima."],

    ["何人で参加しますか？", "How many people are joining?", "有多少人参加？", "有多少人參加？", "몇 명이 참여하나요?", "¿Cuántas personas participan?", "Quantas pessoas vão participar?"],
    ["登録済みの参加者より少なくすることはできません。", "You can't set a number below the registered participants.", "人数不能少于已登记的参与者。", "人數不能少於已登記的參加者。", "등록된 참여자 수보다 적게 설정할 수 없습니다.", "No puedes elegir menos personas que las registradas.", "Não é possível definir menos pessoas do que as cadastradas."],
    ["名前の登録は不要です。人数はあとから変更できます。", "Names are optional. You can change the number later.", "无需先填写姓名，人数之后也可以更改。", "不必先填姓名，人數之後也可以更改。", "이름은 나중에 입력해도 됩니다. 인원 수도 변경할 수 있습니다.", "No hace falta añadir nombres ahora. Puedes cambiar el número después.", "Não é preciso adicionar nomes agora. O número pode ser alterado depois."],
    ["1人ずつ", "1 at a time", "每次 1 人", "每次 1 人", "1명씩", "De 1 en 1", "De 1 em 1"],

    ["メモ", "Memo", "备注", "備註", "메모", "Notas", "Notas"],
    ["必要なときだけ書けばOKです", "Add notes only if you need them.", "需要时再填写即可。", "需要時再填寫即可。", "필요할 때만 작성하면 됩니다.", "Añade notas solo si las necesitas.", "Adicione notas apenas se precisar."],
    ["集合場所や持ち物など（任意）", "Meeting point, things to bring, etc. (optional)", "集合地点、携带物品等（可选）", "集合地點、攜帶物品等（選填）", "집합 장소, 준비물 등 (선택 사항)", "Punto de encuentro, cosas que llevar, etc. (opcional)", "Ponto de encontro, itens para levar etc. (opcional)"]
]

extension AppLanguage {
    private var textIndex: Int {
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

    func t(_ key: AppText) -> String {
        appTexts[key.rawValue][textIndex]
    }

    func eventText(_ key: EventText) -> String {
        eventTexts[key.rawValue][textIndex]
    }

    func participantUnit(for count: Int) -> String {
        switch self {
        case .japanese, .simplifiedChinese, .traditionalChinese:
            return "人"
        case .korean:
            return "명"
        case .english:
            return count == 1 ? "person" : "people"
        case .spanish:
            return count == 1 ? "persona" : "personas"
        case .portuguese:
            return count == 1 ? "pessoa" : "pessoas"
        }
    }
}
