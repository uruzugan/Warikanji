import Foundation

struct Settlement: Identifiable, Codable, Equatable {
    var id: UUID
    var participantId: UUID
    var totalShare: Int
    var paidAmount: Int
    var balance: Int

    init(id: UUID = UUID(), participantId: UUID, totalShare: Int, paidAmount: Int) {
        self.id = id
        self.participantId = participantId
        self.totalShare = totalShare
        self.paidAmount = paidAmount
        self.balance = paidAmount - totalShare
    }
}

enum CalculationWarningType: Equatable {
    case noParticipants
    case noExpenses
    case payerNotSet(String)
    case noParticipantsToShare(String)
    case ratioNotSet(String)
}

struct CalculationWarning: Identifiable, Equatable {
    var id = UUID()
    var type: CalculationWarningType

    func message(for language: AppLanguage) -> String {
        func expenseTitle(_ rawTitle: String) -> String {
            let trimmed = rawTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? Expense.untitledName(for: language) : trimmed
        }

        switch type {
        case .noParticipants:
            return language.text(
                ja: "参加者がいません", en: "There are no participants.",
                zhHans: "没有参与者。", zhHant: "沒有參加者。",
                ko: "참가자가 없습니다.", es: "No hay participantes.", pt: "Não há participantes."
            )

        case .noExpenses:
            return language.text(
                ja: "費用が登録されていません", en: "No expenses have been added.",
                zhHans: "尚未添加费用。", zhHant: "尚未新增費用。",
                ko: "등록된 비용이 없습니다.", es: "No se han añadido gastos.", pt: "Nenhuma despesa foi adicionada."
            )

        case .payerNotSet(let rawTitle):
            let title = expenseTitle(rawTitle)
            return language.text(
                ja: "「\(title)」の支払者が未設定です",
                en: "The payer for “\(title)” is not set.",
                zhHans: "“\(title)”尚未设置付款人。",
                zhHant: "「\(title)」尚未設定付款人。",
                ko: "“\(title)”의 결제자가 설정되지 않았습니다.",
                es: "No se ha definido quién pagó «\(title)».",
                pt: "O pagador de “\(title)” não foi definido."
            )

        case .noParticipantsToShare(let rawTitle):
            let title = expenseTitle(rawTitle)
            return language.text(
                ja: "「\(title)」に負担対象者がいません",
                en: "“\(title)” has no participants included in the split.",
                zhHans: "“\(title)”没有分摊对象。",
                zhHant: "「\(title)」沒有分攤對象。",
                ko: "“\(title)”에 부담 대상자가 없습니다.",
                es: "«\(title)» no tiene participantes incluidos en el reparto.",
                pt: "“\(title)” não possui participantes incluídos na divisão."
            )

        case .ratioNotSet(let rawTitle):
            let title = expenseTitle(rawTitle)
            return language.text(
                ja: "「\(title)」の負担比率を設定してください",
                en: "Set the share ratios for “\(title)”.",
                zhHans: "请设置“\(title)”的分摊比例。",
                zhHant: "請設定「\(title)」的分攤比例。",
                ko: "“\(title)”의 부담 비율을 설정하세요.",
                es: "Define las proporciones de «\(title)».",
                pt: "Defina as proporções de “\(title)”."
            )
        }
    }
}

struct SettlementResult {
    var settlements: [Settlement]
    var warnings: [CalculationWarning]
    var isTotalShareConsistent: Bool
    var isBalanceConsistent: Bool
    var hasBlockingCalculationError = false
}
