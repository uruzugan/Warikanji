import Foundation

enum SettlementText: Int {
    case resultTitle, eventNotFound, needsAttention, calculationMethod
    case randomRemainder, roundedExpense, participantSettlement
    case paymentRoute, noAdditionalPayments
    case totalBill, participants, calculationStatus, payments
    case needsCheck, calculationOK, inconsistent
    case share, paid, receive, pay, settled
}

private let settlementTexts: [[String]] = [
    ["精算結果", "Settlement Results", "结算结果", "結算結果", "정산 결과", "Resultado de liquidación", "Resultado do acerto"],
    ["イベントが見つかりません", "Event Not Found", "未找到活动", "找不到活動", "이벤트를 찾을 수 없습니다", "Evento no encontrado", "Evento não encontrado"],
    ["確認が必要です", "Needs Attention", "需要确认", "需要確認", "확인이 필요합니다", "Requiere atención", "Requer atenção"],
    ["計算方法", "Calculation", "计算方式", "計算方式", "계산 방법", "Cálculo", "Cálculo"],
    ["均等に割り切れない最小通貨単位の端数は、負担対象者へランダムに振り分けています。", "Indivisible smallest currency units are distributed randomly among participants.", "无法平均分配的最小货币单位会随机分配给参与者。", "無法平均分配的最小貨幣單位會隨機分配給參加者。", "균등하게 나눌 수 없는 최소 통화 단위는 참가자에게 무작위로 배분됩니다.", "Las unidades monetarias mínimas que no puedan dividirse se reparten al azar.", "As menores unidades monetárias que não puderem ser divididas são distribuídas aleatoriamente."],
    ["指定した集金単位に近い負担額へ調整し、差額は一部の参加者へ反映します。", "Shares are adjusted to the selected collection unit, with any difference assigned to some participants.", "分摊金额会调整至接近所选收款单位，差额将分配给部分参与者。", "分攤金額會調整至接近所選收款單位，差額將分配給部分參加者。", "선택한 정산 단위에 맞게 부담액을 조정하고 차액은 일부 참가자에게 반영합니다.", "Las partes se ajustan a la unidad elegida y la diferencia se asigna a algunos participantes.", "As partes são ajustadas à unidade escolhida e a diferença é atribuída a alguns participantes."],
    ["参加者ごとの精算", "Settlement by Participant", "参与者结算", "參加者結算", "참가자별 정산", "Liquidación por participante", "Acerto por participante"],
    ["支払いルート", "Payment Route", "付款路线", "付款路線", "결제 경로", "Ruta de pagos", "Rota de pagamentos"],
    ["追加の支払いはありません", "No additional payments", "无需额外付款", "無需額外付款", "추가 결제가 없습니다", "No hay pagos adicionales", "Não há pagamentos adicionais"],
    ["今回のお会計", "Total Bill", "本次账单", "本次帳單", "이번 총액", "Total de la cuenta", "Total da conta"],
    ["参加者", "Participants", "参与者", "參加者", "참가자", "Participantes", "Participantes"],
    ["計算状態", "Calculation", "计算状态", "計算狀態", "계산 상태", "Cálculo", "Cálculo"],
    ["支払い", "Payments", "付款", "付款", "결제", "Pagos", "Pagamentos"],
    ["要確認", "Check", "需确认", "需確認", "확인 필요", "Revisar", "Verificar"],
    ["計算OK", "OK", "计算正常", "計算正常", "계산 OK", "Correcto", "OK"],
    ["不整合あり", "Mismatch", "存在不一致", "存在不一致", "불일치", "Hay diferencias", "Há diferenças"],
    ["負担", "Share", "分摊", "分攤", "부담", "Parte", "Parte"],
    ["立替", "Paid", "垫付", "代墊", "결제", "Pagado", "Pago"],
    ["受け取る", "Receive", "收款", "收款", "받기", "Recibir", "Receber"],
    ["支払う", "Pay", "付款", "付款", "지불", "Pagar", "Pagar"],
    ["精算済み", "Settled", "已结算", "已結算", "정산 완료", "Liquidado", "Acertado"]
]

extension AppLanguage {
    func settlementText(_ key: SettlementText) -> String {
        settlementTexts[key.rawValue][settlementIndex]
    }

    func settlementCount(_ count: Int) -> String {
        switch self {
        case .japanese: return "\(count)件"
        case .english: return "\(count)"
        case .simplifiedChinese: return "\(count)笔"
        case .traditionalChinese: return "\(count)筆"
        case .korean: return "\(count)건"
        case .spanish, .portuguese: return "\(count)"
        }
    }

    private var settlementIndex: Int {
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
