import Foundation

enum PaymentText: Int {
    case settlementComplete, paymentStatus, allTransfersComplete
    case checkoutComplete, eventSettlementComplete
    case managementTitle, allPaymentsComplete, checkPayments
    case allSettlementDone, checkCompletedPayments, paymentList
    case noPayments, noPaymentsBody, help, eventNotFound
    case paid, unpaid, send, sentAmount, amountToSend, markUnpaid, markPaid
}

private let paymentTexts: [[String]] = [
    ["精算完了", "Settlement Complete", "结算完成", "結算完成", "정산 완료", "Liquidación completada", "Acerto concluído"],
    ["支払い状況", "Payment Status", "付款状态", "付款狀態", "결제 상태", "Estado de pagos", "Status dos pagamentos"],
    ["すべての送金が完了しました", "All transfers are complete.", "所有转账已完成", "所有轉帳已完成", "모든 송금이 완료되었습니다", "Todas las transferencias están completas.", "Todas as transferências foram concluídas."],
    ["お会計終了！", "All settled!", "结算完成！", "結算完成！", "정산 완료!", "¡Todo liquidado!", "Tudo acertado!"],
    ["このイベントの精算はすべて完了しています。", "This event is fully settled.", "此活动的结算已全部完成。", "此活動的結算已全部完成。", "이 이벤트의 정산이 모두 완료되었습니다.", "La liquidación de este evento está completa.", "O acerto deste evento foi concluído."],
    ["支払い管理", "Payments", "付款管理", "付款管理", "결제 관리", "Pagos", "Pagamentos"],
    ["みんなの支払い完了！", "Everyone has paid!", "所有人都已付款！", "所有人都已付款！", "모두 결제 완료!", "¡Todos han pagado!", "Todos pagaram!"],
    ["支払いを確認しよう", "Check Payments", "确认付款情况", "確認付款情況", "결제를 확인하세요", "Revisa los pagos", "Confira os pagamentos"],
    ["今回の精算はすべて完了しています", "This settlement is complete.", "本次结算已全部完成", "本次結算已全部完成", "이번 정산이 모두 완료되었습니다", "Esta liquidación está completa.", "Este acerto foi concluído."],
    ["完了した支払いをチェックできます", "Track completed payments.", "可以确认已完成的付款", "可以確認已完成的付款", "완료된 결제를 확인할 수 있습니다", "Puedes comprobar los pagos completados.", "Você pode conferir os pagamentos concluídos."],
    ["支払い一覧", "Payment List", "付款列表", "付款列表", "결제 목록", "Lista de pagos", "Lista de pagamentos"],
    ["支払いはありません", "No Payments", "没有需要付款的项目", "沒有需要付款的項目", "결제할 항목이 없습니다", "No hay pagos", "Não há pagamentos"],
    ["全員の立替額と負担額が一致しているか、精算結果を確認してください。", "Check the settlement results to confirm everyone's paid and owed amounts.", "请查看结算结果，确认每个人的垫付额和分摊额。", "請查看結算結果，確認每個人的代墊額和分攤額。", "모두의 결제액과 부담액이 맞는지 정산 결과를 확인하세요.", "Comprueba que los importes pagados y adeudados coincidan.", "Confira se os valores pagos e devidos estão corretos."],
    ["実際に送金・現金での受け渡しが終わったら、その支払いを完了にしてください。", "Mark a payment complete after the money has actually been transferred.", "实际完成转账或现金交付后，请将付款标记为完成。", "實際完成轉帳或現金交付後，請將付款標記為完成。", "실제로 송금이나 현금 전달이 끝나면 결제 완료로 표시하세요.", "Marca el pago como completado cuando se haya entregado el dinero.", "Marque como concluído quando o dinheiro tiver sido entregue."],
    ["イベントが見つかりません", "Event Not Found", "未找到活动", "找不到活動", "이벤트를 찾을 수 없습니다", "Evento no encontrado", "Evento não encontrado"],
    ["支払い済み", "Paid", "已支付", "已支付", "결제 완료", "Pagado", "Pago"],
    ["未払い", "Unpaid", "未支付", "未支付", "미결제", "Pendiente", "Pendente"],
    ["送る", "Send", "支付", "支付", "보내기", "Enviar", "Enviar"],
    ["送金済み金額", "Amount Sent", "已支付金额", "已支付金額", "송금 완료 금액", "Importe enviado", "Valor enviado"],
    ["送金する金額", "Amount to Send", "应支付金额", "應支付金額", "보낼 금액", "Importe a enviar", "Valor a enviar"],
    ["未払いに戻す", "Mark Unpaid", "恢复为未支付", "恢復為未支付", "미결제로 되돌리기", "Marcar como pendiente", "Marcar como pendente"],
    ["支払い完了にする", "Mark as Paid", "标记为已支付", "標記為已支付", "결제 완료로 표시", "Marcar como pagado", "Marcar como pago"]
]

extension AppLanguage {
    func payment(_ key: PaymentText) -> String {
        paymentTexts[key.rawValue][paymentIndex]
    }

    func paymentProgress(_ paid: Int, _ total: Int) -> String {
        switch self {
        case .japanese: return "\(paid) / \(total)件 支払い済み"
        case .english: return "\(paid) / \(total) paid"
        case .simplifiedChinese: return "\(paid) / \(total)笔已支付"
        case .traditionalChinese: return "\(paid) / \(total)筆已支付"
        case .korean: return "\(paid) / \(total)건 결제 완료"
        case .spanish: return "\(paid) / \(total) pagados"
        case .portuguese: return "\(paid) / \(total) pagos"
        }
    }

    func paymentCompleted(_ count: Int) -> String {
        switch self {
        case .japanese: return "\(count)件 完了"
        case .english: return "\(count) completed"
        case .simplifiedChinese: return "\(count)笔完成"
        case .traditionalChinese: return "\(count)筆完成"
        case .korean: return "\(count)건 완료"
        case .spanish: return "\(count) completados"
        case .portuguese: return "\(count) concluídos"
        }
    }

    func paymentRemaining(_ count: Int) -> String {
        switch self {
        case .japanese: return "\(count)件 残り"
        case .english: return "\(count) remaining"
        case .simplifiedChinese: return "剩余\(count)笔"
        case .traditionalChinese: return "剩餘\(count)筆"
        case .korean: return "\(count)건 남음"
        case .spanish: return "\(count) restantes"
        case .portuguese: return "\(count) restantes"
        }
    }

    private var paymentIndex: Int {
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
