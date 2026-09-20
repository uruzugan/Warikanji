import SwiftUI

struct SettlementResultView: View {
    @EnvironmentObject private var viewModel: EventViewModel
    @EnvironmentObject private var profileStore: ProfileStore

    let eventId: UUID

    @State private var shareImageItem: ShareImageItem?

    private var event: Event? { viewModel.event(for: eventId) }
    private var language: AppLanguage { profileStore.activeLanguage }

    private var result: SettlementResult? {
        guard let event else { return nil }
        return SettlementCalculator.calculate(event: event)
    }

    private var hasRandomRemainder: Bool {
        event?.expenses.contains {
            $0.rounding == .exact &&
            $0.splitMethod == .equal &&
            !$0.remainderParticipantIds.isEmpty
        } ?? false
    }

    private var hasRoundedExpense: Bool {
        event?.expenses.contains { $0.rounding != .exact } ?? false
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let event, let result {
                    SettlementHeroCard(event: event, result: result)

                    if !result.warnings.isEmpty {
                        warningCard(result.warnings)
                    }

                    if hasRandomRemainder || hasRoundedExpense {
                        calculationInfo
                    }

                    settlementSection(event, result)
                    transferSection(event, result)
                } else {
                    ContentUnavailableView(
                        language.settlementText(.eventNotFound),
                        systemImage: "exclamationmark.triangle"
                    )
                }
            }
            .padding()
        }
        .background(AppTheme.background)
        .navigationTitle(language.settlementText(.resultTitle))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let event, let result {
                ToolbarItem(placement: .topBarTrailing) {
                    shareMenu(event, result)
                }
            }
        }
        .sheet(item: $shareImageItem) { item in
            ActivityShareView(activityItems: [item.image])
        }
    }

    private func shareMenu(_ event: Event, _ result: SettlementResult) -> some View {
        Menu {
            ShareLink(item: shareText(event: event, result: result)) {
                Label(
                    language.text(
                        ja: "テキストで共有", en: "Share as Text",
                        zhHans: "以文字分享", zhHant: "以文字分享",
                        ko: "텍스트로 공유", es: "Compartir como texto", pt: "Compartilhar como texto"
                    ),
                    systemImage: "text.bubble"
                )
            }

            Button {
                createShareCard(event: event, result: result)
            } label: {
                Label(
                    language.text(
                        ja: "画像で共有", en: "Share as Image",
                        zhHans: "以图片分享", zhHant: "以圖片分享",
                        ko: "이미지로 공유", es: "Compartir como imagen", pt: "Compartilhar como imagem"
                    ),
                    systemImage: "photo"
                )
            }
        } label: {
            Image(systemName: "square.and.arrow.up")
        }
    }

    private func warningCard(_ warnings: [CalculationWarning]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(language.settlementText(.needsAttention), systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(AppTheme.warning)

            ForEach(Array(warnings.enumerated()), id: \.offset) { _, warning in
                Text("• \(warning.message(for: language))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard()
    }

    private var calculationInfo: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(language.settlementText(.calculationMethod), systemImage: "info.circle.fill")
                .font(.headline)
                .foregroundStyle(AppTheme.primary)

            if hasRandomRemainder {
                Text(language.settlementText(.randomRemainder))
            }

            if hasRoundedExpense {
                Text(language.settlementText(.roundedExpense))
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard()
    }

    private func settlementSection(_ event: Event, _ result: SettlementResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(language.settlementText(.participantSettlement), systemImage: "person.3.fill")
                .font(.headline)
                .padding(.horizontal, 4)

            ForEach(result.settlements) { settlement in
                SettlementParticipantCard(
                    settlement: settlement,
                    name: event.displayName(for: settlement.participantId, language: language),
                    currency: event.currency
                )
            }
        }
    }

    @ViewBuilder
    private func transferSection(_ event: Event, _ result: SettlementResult) -> some View {
        if result.isTotalShareConsistent &&
            result.isBalanceConsistent &&
            !result.hasBlockingCalculationError {

            let transfers = TransferCalculator.calculate(settlements: result.settlements)

            VStack(alignment: .leading, spacing: 12) {
                Label(language.settlementText(.paymentRoute), systemImage: "arrow.left.arrow.right")
                    .font(.headline)
                    .padding(.horizontal, 4)

                if transfers.isEmpty {
                    Label(language.settlementText(.noAdditionalPayments), systemImage: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.success)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .appCard()
                } else {
                    ForEach(transfers) { transfer in
                        SettlementTransferPreview(transfer: transfer, event: event)
                    }
                }
            }
        }
    }

    @MainActor
    private func createShareCard(event: Event, result: SettlementResult) {
        guard let image = SettlementShareCardRenderer.makeImage(
            event: event,
            result: result,
            language: language
        ) else { return }

        shareImageItem = ShareImageItem(image: image)
    }

    private func shareText(event: Event, result: SettlementResult) -> String {
        var lines = [
            "【\(event.title)】",
            language.settlementText(.resultTitle),
            "",
            "\(language.settlementText(.totalBill))：\(event.currency.formatted(minorUnits: event.totalExpenseAmount))"
        ]

        if event.hasDatedExpenses {
            lines += [""] + event.expenseBreakdownLines(for: language)
        }

        lines += ["", language.settlementText(.participantSettlement)]

        for settlement in result.settlements {
            let name = event.displayName(for: settlement.participantId, language: language)
            lines.append("・\(name)：\(settlementLine(settlement, currency: event.currency))")
        }

        if result.isTotalShareConsistent &&
            result.isBalanceConsistent &&
            !result.hasBlockingCalculationError {

            let transfers = TransferCalculator.calculate(settlements: result.settlements)
            lines += ["", language.settlementText(.paymentRoute)]

            if transfers.isEmpty {
                lines.append("・\(language.settlementText(.noAdditionalPayments))")
            } else {
                for transfer in transfers {
                    let from = event.displayName(for: transfer.fromParticipantId, language: language)
                    let to = event.displayName(for: transfer.toParticipantId, language: language)

                    lines.append("・\(from) → \(to)：\(event.currency.formatted(minorUnits: transfer.amount))")
                }
            }
        }

        lines += [
            "",
            language.text(
                ja: "ワリカンジで精算", en: "Settled with Warikanji",
                zhHans: "使用 Warikanji 结算", zhHant: "使用 Warikanji 結算",
                ko: "Warikanji로 정산", es: "Liquidado con Warikanji", pt: "Acertado com Warikanji"
            )
        ]

        return lines.joined(separator: "\n")
    }

    private func settlementLine(_ settlement: Settlement, currency: AppCurrency) -> String {
        if settlement.balance > 0 {
            return "\(language.settlementText(.receive)) \(currency.formatted(minorUnits: settlement.balance))"
        }

        if settlement.balance < 0 {
            return "\(language.settlementText(.pay)) \(currency.formatted(minorUnits: abs(settlement.balance)))"
        }

        return language.settlementText(.settled)
    }
}
