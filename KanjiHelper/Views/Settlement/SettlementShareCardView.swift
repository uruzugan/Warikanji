import SwiftUI
import UIKit

struct SettlementShareCardView: View {
    let event: Event
    let result: SettlementResult
    let language: AppLanguage

    private var transfers: [Transfer] {
        guard result.isTotalShareConsistent, result.isBalanceConsistent, !result.hasBlockingCalculationError else { return [] }
        return TransferCalculator.calculate(settlements: result.settlements)
    }

    private func t(_ ja: String, _ en: String, _ zhHans: String, _ zhHant: String, _ ko: String, _ es: String, _ pt: String) -> String {
        language.text(ja: ja, en: en, zhHans: zhHans, zhHant: zhHant, ko: ko, es: es, pt: pt)
    }

    var body: some View {
        ZStack {
            AppTheme.gradient

            Circle()
                .fill(.white.opacity(0.08))
                .frame(width: 300, height: 300)
                .offset(x: 190, y: -220)

            VStack(alignment: .leading, spacing: 22) {
                header

                VStack(alignment: .leading, spacing: 5) {
                    Text(event.title).font(.system(size: 28, weight: .bold, design: .rounded)).lineLimit(2)
                    Text(language.settlementText(.resultTitle)).font(.subheadline.bold()).opacity(0.75)
                }

                totalCard
                if event.hasDatedExpenses { expenseSection }
                participantSection
                paymentSection

                Text(t("ワリカンジで精算", "Settled with Warikanji", "使用 Warikanji 结算", "使用 Warikanji 結算", "Warikanji로 정산", "Liquidado con Warikanji", "Acertado com Warikanji"))
                    .font(.caption.bold()).opacity(0.65).padding(.top, 4)
            }
            .foregroundStyle(.white)
            .padding(28)
        }
        .frame(width: 420)
        .fixedSize(horizontal: false, vertical: true)
        .clipShape(RoundedRectangle(cornerRadius: 32))
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "person.3.sequence.fill")
                .font(.headline.bold()).frame(width: 40, height: 40)
                .background(.white.opacity(0.18)).clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 1) {
                Text(language.appName).font(.headline.bold())
                Text(language.tagline).font(.caption2).opacity(0.7)
            }

            Spacer()
            Image(systemName: "checkmark.seal.fill").font(.title2).opacity(0.8)
        }
    }

    private var totalCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(language.settlementText(.totalBill)).font(.caption).opacity(0.7)

                Text(event.currency.formatted(minorUnits: event.totalExpenseAmount))
                    .font(.system(size: 30, weight: .bold, design: .rounded))
            }

            Spacer()
            Image(systemName: "banknote.fill").font(.title2)
        }
        .padding(16)
        .background(.white.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var expenseSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(
                t("日別費用", "Expenses by Day", "每日费用", "每日費用", "날짜별 비용", "Gastos por día", "Despesas por dia"),
                systemImage: "calendar"
            )
            .font(.subheadline.bold())

            VStack(spacing: 10) {
                ForEach(event.datedExpenseGroups) { group in
                    VStack(spacing: 4) {
                        HStack {
                            Text(event.expenseGroupTitle(for: group.date, language: language)).fontWeight(.bold)
                            Spacer()
                            Text(event.currency.formatted(minorUnits: group.totalAmount)).fontWeight(.bold)
                        }

                        ForEach(group.expenses) { expense in
                            expenseRow(expense)
                        }
                    }
                }

                if !event.undatedExpenses.isEmpty {
                    VStack(spacing: 4) {
                        Text(t("日付なし", "No Date", "无日期", "無日期", "날짜 없음", "Sin fecha", "Sem data"))
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        ForEach(event.undatedExpenses) { expense in
                            expenseRow(expense)
                        }
                    }
                }
            }
            .font(.caption)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 17))
        }
    }

    private func expenseRow(_ expense: Expense) -> some View {
        HStack {
            Text("• \(expense.title)").lineLimit(1)
            Spacer()
            Text(event.currency.formatted(minorUnits: expense.amount))
        }
        .opacity(0.75)
    }

    private var participantSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(language.settlementText(.participantSettlement), systemImage: "person.2.fill")
                .font(.subheadline.bold())

            VStack(spacing: 0) {
                ForEach(result.settlements) { settlement in
                    participantRow(settlement)

                    if settlement.id != result.settlements.last?.id {
                        Divider().overlay(.white.opacity(0.15))
                    }
                }
            }
            .padding(.horizontal, 14)
            .background(.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 17))
        }
    }

    private func participantRow(_ settlement: Settlement) -> some View {
        HStack {
            Text(event.displayName(for: settlement.participantId, language: language))
                .font(.subheadline.bold())
                .lineLimit(1)

            Spacer()

            Text(settlementStatus(settlement))
                .font(.caption.bold())
        }
        .padding(.vertical, 11)
    }

    private var paymentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(language.settlementText(.paymentRoute), systemImage: "arrow.left.arrow.right")
                .font(.subheadline.bold())

            VStack(spacing: 0) {
                if transfers.isEmpty {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text(language.settlementText(.noAdditionalPayments))
                        Spacer()
                    }
                    .font(.caption.bold())
                    .padding(.vertical, 12)

                } else {
                    ForEach(transfers) { transfer in
                        transferRow(transfer)

                        if transfer.id != transfers.last?.id {
                            Divider().overlay(.white.opacity(0.15))
                        }
                    }
                }
            }
            .padding(.horizontal, 14)
            .background(.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 17))
        }
    }

    private func transferRow(_ transfer: Transfer) -> some View {
        HStack {
            Text(event.displayName(for: transfer.fromParticipantId, language: language)).lineLimit(1)

            Image(systemName: "arrow.right")
                .opacity(0.65)

            Text(event.displayName(for: transfer.toParticipantId, language: language)).lineLimit(1)

            Spacer()

            Text(event.currency.formatted(minorUnits: transfer.amount))
                .fontWeight(.bold)
        }
        .font(.caption)
        .padding(.vertical, 10)
    }

    private func settlementStatus(_ settlement: Settlement) -> String {
        if settlement.balance > 0 {
            return "\(language.settlementText(.receive)) \(event.currency.formatted(minorUnits: settlement.balance))"
        }

        if settlement.balance < 0 {
            return "\(language.settlementText(.pay)) \(event.currency.formatted(minorUnits: abs(settlement.balance)))"
        }

        return language.settlementText(.settled)
    }
}

@MainActor
enum SettlementShareCardRenderer {
    static func makeImage(event: Event, result: SettlementResult, language: AppLanguage) -> UIImage? {
        let card = SettlementShareCardView(event: event, result: result, language: language)
            .environment(\.colorScheme, .light)

        let renderer = ImageRenderer(content: card)
        renderer.scale = 3
        return renderer.uiImage
    }
}
