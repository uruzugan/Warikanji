import Foundation

enum EventBudgetText: Int {
    case budget
    case description
    case currentSpend
    case totalBudget
    case perPersonBudget
    case currentPerPerson
    case remaining
    case overBudget
    case notSet
    case organizerAdvance
    case organizer
    case selectOrganizer
    case advanceLimit
    case companySubsidy
    case estimatedSubsidy
    case afterSubsidy
    case subsidyMode
    case totalAmount
    case perParticipant
    case subsidyTargets
    case allParticipants
    case budgetApproval
    case notRequired
    case pending
    case approved
    case rejected
    case notes
    case invalidAmount
}

private let eventBudgetTexts: [[String]] = [
    ["予算管理", "Budget", "预算管理", "預算管理", "예산 관리", "Presupuesto", "Orçamento"],
    ["現在の費用と上限・補助をまとめて確認", "Track spending, limits, and subsidies", "统一确认支出、上限与补助", "統一確認支出、上限與補助", "지출·한도·지원을 한눈에 확인", "Controla gastos, límites y ayudas", "Acompanhe gastos, limites e subsídios"],
    ["現在の費用", "Current Spend", "当前费用", "目前費用", "현재 비용", "Gasto actual", "Despesa atual"],
    ["総予算", "Total Budget", "总预算", "總預算", "총예산", "Presupuesto total", "Orçamento total"],
    ["1人あたり予算", "Budget per Person", "人均预算", "每人預算", "1인 예산", "Presupuesto por persona", "Orçamento por pessoa"],
    ["現在の1人あたり", "Current per Person", "当前人均", "目前每人", "현재 1인당", "Actual por persona", "Atual por pessoa"],
    ["残り", "Remaining", "剩余", "剩餘", "남음", "Restante", "Restante"],
    ["予算超過", "Over Budget", "超出预算", "超出預算", "예산 초과", "Sobre el presupuesto", "Acima do orçamento"],
    ["未設定", "Not Set", "未设置", "未設定", "미설정", "Sin definir", "Não definido"],
    ["幹事の立替", "Organizer Advance", "组织者垫付", "主辦人墊付", "주최자 선결제", "Adelanto del organizador", "Adiantamento do organizador"],
    ["幹事", "Organizer", "组织者", "主辦人", "주최자", "Organizador", "Organizador"],
    ["幹事を選択", "Select Organizer", "选择组织者", "選擇主辦人", "주최자 선택", "Seleccionar organizador", "Selecionar organizador"],
    ["立替上限", "Advance Limit", "垫付上限", "墊付上限", "선결제 한도", "Límite de adelanto", "Limite de adiantamento"],
    ["会社補助・会社負担", "Company Subsidy", "公司补助", "公司補助", "회사 지원", "Ayuda de la empresa", "Subsídio da empresa"],
    ["補助見込み", "Estimated Subsidy", "预计补助", "預估補助", "예상 지원", "Ayuda estimada", "Subsídio estimado"],
    ["補助後の見込み", "After Subsidy", "补助后预计", "補助後預估", "지원 후 예상", "Estimado tras la ayuda", "Estimado após subsídio"],
    ["補助方式", "Subsidy Mode", "补助方式", "補助方式", "지원 방식", "Tipo de ayuda", "Modo do subsídio"],
    ["総額", "Total Amount", "总额", "總額", "총액", "Importe total", "Valor total"],
    ["1人あたり", "Per Participant", "每人", "每人", "1인당", "Por persona", "Por pessoa"],
    ["補助対象", "Subsidy Recipients", "补助对象", "補助對象", "지원 대상", "Beneficiarios", "Beneficiários"],
    ["全員", "All Participants", "所有人", "所有人", "전원", "Todos", "Todos"],
    ["予算承認", "Budget Approval", "预算审批", "預算審批", "예산 승인", "Aprobación del presupuesto", "Aprovação do orçamento"],
    ["承認不要", "Not Required", "无需审批", "無需審批", "승인 불필요", "No requerida", "Não necessária"],
    ["承認待ち", "Pending", "待审批", "待審批", "승인 대기", "Pendiente", "Pendente"],
    ["承認済み", "Approved", "已批准", "已核准", "승인됨", "Aprobado", "Aprovado"],
    ["却下", "Rejected", "已拒绝", "已拒絕", "반려됨", "Rechazado", "Rejeitado"],
    ["メモ", "Notes", "备注", "備註", "메모", "Notas", "Notas"],
    ["正しい金額を入力してください", "Enter a valid amount", "请输入有效金额", "請輸入有效金額", "올바른 금액을 입력하세요", "Introduce un importe válido", "Insira um valor válido"]
]

extension AppLanguage {
    func budgetText(_ key: EventBudgetText) -> String {
        eventBudgetTexts[key.rawValue][budgetTextIndex]
    }

    private var budgetTextIndex: Int {
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

extension BudgetApprovalStatus {
    func displayName(for language: AppLanguage) -> String {
        switch self {
        case .notRequired: return language.budgetText(.notRequired)
        case .pending: return language.budgetText(.pending)
        case .approved: return language.budgetText(.approved)
        case .rejected: return language.budgetText(.rejected)
        }
    }
}

extension CompanySubsidyMode {
    func displayName(for language: AppLanguage) -> String {
        switch self {
        case .total: return language.budgetText(.totalAmount)
        case .perParticipant: return language.budgetText(.perParticipant)
        }
    }
}
