import SwiftUI

struct TransferCard: View {
    @EnvironmentObject private var profileStore: ProfileStore

    let fromName: String
    let toName: String
    let transfer: Transfer
    let currency: AppCurrency
    let onTogglePaid: () -> Void

    private var language: AppLanguage { profileStore.activeLanguage }
    private var tint: Color { transfer.isPaid ? AppTheme.success : AppTheme.primary }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Label(
                    language.payment(transfer.isPaid ? .paid : .unpaid),
                    systemImage: transfer.isPaid ? "checkmark.circle.fill" : "clock.fill"
                )
                .font(.caption.bold())
                .foregroundStyle(tint)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(tint.opacity(0.1))
                .clipShape(Capsule())

                Spacer()

                if transfer.isPaid {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title3)
                        .foregroundStyle(AppTheme.success)
                }
            }

            HStack(spacing: 10) {
                participantView(name: fromName, symbol: "person.fill")

                VStack(spacing: 3) {
                    Image(systemName: "arrow.right")
                        .font(.headline.bold())
                        .foregroundStyle(tint)

                    Text(language.payment(.send))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                participantView(name: toName, symbol: "person.fill.checkmark")
            }

            VStack(spacing: 4) {
                Text(language.payment(transfer.isPaid ? .sentAmount : .amountToSend))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(currency.formatted(minorUnits: transfer.amount))
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(transfer.isPaid ? Color.secondary : AppTheme.primary)
                    .monospacedDigit()
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                transfer.isPaid
                    ? Color(uiColor: .tertiarySystemGroupedBackground)
                    : AppTheme.primary.opacity(0.06)
            )
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))

            Button(action: onTogglePaid) {
                Label(
                    language.payment(transfer.isPaid ? .markUnpaid : .markPaid),
                    systemImage: transfer.isPaid ? "arrow.uturn.backward" : "checkmark.circle.fill"
                )
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .foregroundStyle(transfer.isPaid ? AppTheme.primary : .white)
                .background {
                    if transfer.isPaid {
                        AppTheme.primary.opacity(0.09)
                    } else {
                        AppTheme.gradient
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .appCard()
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(tint.opacity(0.16), lineWidth: 1)
        }
        .opacity(transfer.isPaid ? 0.78 : 1)
    }

    private func participantView(name: String, symbol: String) -> some View {
        VStack(spacing: 7) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 42, height: 42)
                .background(tint.opacity(0.1))
                .clipShape(Circle())

            Text(name)
                .font(.subheadline.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    TransferCard(
        fromName: "参加者2",
        toName: "田中",
        transfer: Transfer(
            fromParticipantId: UUID(),
            toParticipantId: UUID(),
            amount: 3500
        ),
        currency: .jpy,
        onTogglePaid: {}
    )
    .padding()
    .background(AppTheme.background)
    .environmentObject(ProfileStore())
}
