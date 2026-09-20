import SwiftUI

struct SettlementHeroCard: View {
    @EnvironmentObject private var profileStore: ProfileStore

    let event: Event
    let result: SettlementResult

    private var language: AppLanguage { profileStore.activeLanguage }

    private var transferCount: Int {
        guard result.isTotalShareConsistent,
              result.isBalanceConsistent,
              !result.hasBlockingCalculationError else { return 0 }

        return TransferCalculator.calculate(
            settlements: result.settlements
        ).count
    }

    private var statusText: String {
        if result.hasBlockingCalculationError {
            return language.settlementText(.needsCheck)
        }

        return result.isTotalShareConsistent && result.isBalanceConsistent
            ? language.settlementText(.calculationOK)
            : language.settlementText(.inconsistent)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(language.settlementText(.totalBill))
                        .font(.subheadline)
                        .opacity(0.85)

                    Text(
                        event.currency.formatted(
                            minorUnits: event.totalExpenseAmount
                        )
                    )
                    .font(.system(size: 34, weight: .bold))
                }

                Spacer()

                Image(systemName: "banknote.fill")
                    .font(.system(size: 42))
                    .opacity(0.9)
            }

            HStack(spacing: 0) {
                stat(
                    "\(event.participants.count) \(language.participantUnit(for: event.participants.count))",
                    language.settlementText(.participants)
                )

                Divider().overlay(.white.opacity(0.35))

                stat(
                    statusText,
                    language.settlementText(.calculationStatus)
                )

                Divider().overlay(.white.opacity(0.35))

                stat(
                    language.settlementCount(transferCount),
                    language.settlementText(.payments)
                )
            }
            .frame(height: 45)
        }
        .foregroundStyle(.white)
        .padding(20)
        .background(AppTheme.gradient)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private func stat(_ value: String, _ title: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.subheadline.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(title)
                .font(.caption2)
                .opacity(0.75)
        }
        .frame(maxWidth: .infinity)
    }
}

struct SettlementParticipantCard: View {
    @EnvironmentObject private var profileStore: ProfileStore

    let settlement: Settlement
    let name: String
    let currency: AppCurrency

    private var language: AppLanguage { profileStore.activeLanguage }

    private var status: SettlementBalanceStatus {
        if settlement.balance > 0 { return .receive }
        if settlement.balance < 0 { return .pay }
        return .settled
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: status.icon)
                .font(.title3.bold())
                .foregroundStyle(status.color)
                .frame(width: 46, height: 46)
                .background(status.color.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text(name)
                    .font(.headline)

                HStack(spacing: 10) {
                    Text(
                        "\(language.settlementText(.share)) \(currency.formatted(minorUnits: settlement.totalShare))"
                    )

                    Text(
                        "\(language.settlementText(.paid)) \(currency.formatted(minorUnits: settlement.paidAmount))"
                    )
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(status.title(for: language))
                    .font(.caption.bold())
                    .foregroundStyle(status.color)

                Text(
                    currency.formatted(
                        minorUnits: abs(settlement.balance)
                    )
                )
                .font(.headline.monospacedDigit())
                .foregroundStyle(status.color)
            }
        }
        .appCard()
    }
}

struct SettlementTransferPreview: View {
    @EnvironmentObject private var profileStore: ProfileStore

    let transfer: Transfer
    let event: Event

    private var language: AppLanguage { profileStore.activeLanguage }

    var body: some View {
        HStack(spacing: 12) {
            person(
                event.displayName(
                    for: transfer.fromParticipantId,
                    language: language
                ),
                icon: "person.fill"
            )

            Spacer()

            VStack(spacing: 3) {
                Text(
                    event.currency.formatted(
                        minorUnits: transfer.amount
                    )
                )
                .font(.headline.monospacedDigit())
                .foregroundStyle(AppTheme.primary)

                Image(systemName: "arrow.right")
                    .foregroundStyle(AppTheme.primary)
            }

            Spacer()

            person(
                event.displayName(
                    for: transfer.toParticipantId,
                    language: language
                ),
                icon: "person.fill.checkmark"
            )
        }
        .appCard()
    }

    private func person(_ name: String, icon: String) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(AppTheme.primary)

            Text(name)
                .font(.caption.bold())
                .lineLimit(1)
        }
        .frame(maxWidth: 100)
    }
}

private enum SettlementBalanceStatus {
    case receive
    case pay
    case settled

    func title(for language: AppLanguage) -> String {
        switch self {
        case .receive:
            return language.settlementText(.receive)
        case .pay:
            return language.settlementText(.pay)
        case .settled:
            return language.settlementText(.settled)
        }
    }

    var icon: String {
        switch self {
        case .receive: return "arrow.down.circle.fill"
        case .pay: return "arrow.up.circle.fill"
        case .settled: return "checkmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .receive: return AppTheme.success
        case .pay: return AppTheme.danger
        case .settled: return .secondary
        }
    }
}
