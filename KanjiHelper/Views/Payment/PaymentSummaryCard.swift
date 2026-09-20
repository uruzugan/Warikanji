import SwiftUI

struct PaymentSummaryCard: View {
    @EnvironmentObject private var profileStore: ProfileStore

    let paidCount: Int
    let totalCount: Int
    let progress: Double
    let progressPercentText: String
    let isAllPaid: Bool

    private var language: AppLanguage { profileStore.activeLanguage }
    private var remainingCount: Int { max(totalCount - paidCount, 0) }
    private var tint: Color { isAllPaid ? AppTheme.success : AppTheme.primary }

    var body: some View {
        VStack(spacing: 18) {
            HStack(spacing: 14) {
                Image(systemName: isAllPaid ? "checkmark.seal.fill" : "chart.bar.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 52, height: 52)
                    .background(tint.opacity(0.11))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(language.payment(isAllPaid ? .settlementComplete : .paymentStatus))
                        .font(.headline)

                    Text(
                        isAllPaid
                        ? language.payment(.allTransfersComplete)
                        : language.paymentProgress(paidCount, totalCount)
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Text(progressPercentText)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(tint)
                    .monospacedDigit()
            }

            VStack(spacing: 9) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule().fill(tint.opacity(0.1))

                        Capsule()
                            .fill(isAllPaid ? AnyShapeStyle(AppTheme.success) : AnyShapeStyle(AppTheme.gradient))
                            .frame(width: geometry.size.width * min(max(progress, 0), 1))
                    }
                }
                .frame(height: 10)

                HStack {
                    Label(language.paymentCompleted(paidCount), systemImage: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.success)

                    Spacer()

                    Label(language.paymentRemaining(remainingCount), systemImage: "clock.fill")
                        .foregroundStyle(remainingCount == 0 ? AppTheme.success : AppTheme.warning)
                }
                .font(.caption.bold())
            }

            if isAllPaid {
                HStack(spacing: 10) {
                    Image(systemName: "party.popper.fill")
                        .foregroundStyle(AppTheme.success)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(language.payment(.checkoutComplete))
                            .font(.subheadline.bold())

                        Text(language.payment(.eventSettlementComplete))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding(12)
                .background(AppTheme.success.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .appCard()
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(tint.opacity(0.12), lineWidth: 1)
        }
    }
}

#Preview {
    PaymentSummaryCard(
        paidCount: 2,
        totalCount: 3,
        progress: 2.0 / 3.0,
        progressPercentText: "67%",
        isAllPaid: false
    )
    .padding()
    .background(AppTheme.background)
    .environmentObject(ProfileStore())
}
