import Foundation

enum ProfileText: Int {
    case selectAccount, selectDescription, addAccount, localOnly
    case continueAccount, displayName, newAccount, separateData
    case createAccount, create, cancel
}

private let profileTexts: [[String]] = [
    ["アカウントを選択", "Choose an Account", "选择账户", "選擇帳戶", "계정 선택", "Elegir cuenta", "Escolher conta"],
    ["使うアカウントを選んでください。イベントや精算データはアカウントごとに分けて保存されます。", "Choose the account you want to use. Event and settlement data are stored separately for each account.", "请选择要使用的账户。活动和结算数据会按账户分别保存。", "請選擇要使用的帳戶。活動和結算資料會按帳戶分開儲存。", "사용할 계정을 선택하세요. 이벤트와 정산 데이터는 계정별로 따로 저장됩니다.", "Elige la cuenta que quieres usar. Los eventos y liquidaciones se guardan por separado.", "Escolha a conta que deseja usar. Eventos e acertos são salvos separadamente."],
    ["アカウントを追加", "Add Account", "添加账户", "新增帳戶", "계정 추가", "Añadir cuenta", "Adicionar conta"],
    ["アカウント情報はこの端末内に保存されます。", "Account information is stored on this device.", "账户信息保存在此设备上。", "帳戶資訊儲存在此裝置上。", "계정 정보는 이 기기에 저장됩니다.", "La información de la cuenta se guarda en este dispositivo.", "As informações da conta são salvas neste dispositivo."],
    ["このアカウントで続ける", "Continue with this account", "使用此账户继续", "使用此帳戶繼續", "이 계정으로 계속", "Continuar con esta cuenta", "Continuar com esta conta"],
    ["表示名", "Display Name", "显示名称", "顯示名稱", "표시 이름", "Nombre visible", "Nome de exibição"],
    ["新しいアカウント", "New Account", "新账户", "新帳戶", "새 계정", "Nueva cuenta", "Nova conta"],
    ["イベントや精算データは他のアカウントと分けて保存されます。", "Event and settlement data are stored separately from other accounts.", "活动和结算数据会与其他账户分开保存。", "活動和結算資料會與其他帳戶分開儲存。", "이벤트와 정산 데이터는 다른 계정과 분리되어 저장됩니다.", "Los eventos y liquidaciones se guardan separados de otras cuentas.", "Eventos e acertos são salvos separadamente das outras contas."],
    ["アカウントを追加", "Add Account", "添加账户", "新增帳戶", "계정 추가", "Añadir cuenta", "Adicionar conta"],
    ["作成", "Create", "创建", "建立", "만들기", "Crear", "Criar"],
    ["キャンセル", "Cancel", "取消", "取消", "취소", "Cancelar", "Cancelar"]
]

extension AppLanguage {
    func profileText(_ key: ProfileText) -> String {
        profileTexts[key.rawValue][profileTextIndex]
    }

    func remainingProfiles(_ count: Int) -> String {
        switch self {
        case .japanese: return "あと\(count)個作成できます"
        case .english: return "\(count) more \(count == 1 ? "account" : "accounts") available"
        case .simplifiedChinese: return "还可以创建\(count)个账户"
        case .traditionalChinese: return "還可以建立\(count)個帳戶"
        case .korean: return "\(count)개 더 만들 수 있습니다"
        case .spanish: return "Puedes crear \(count) \(count == 1 ? "cuenta más" : "cuentas más")"
        case .portuguese: return "Você pode criar mais \(count) \(count == 1 ? "conta" : "contas")"
        }
    }

    private var profileTextIndex: Int {
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
