import SwiftUI

struct PaymentManagementView: View {
    @EnvironmentObject private var viewModel: EventViewModel
    @EnvironmentObject private var profileStore: ProfileStore
    @ObservedObject private var lifecycleStore = EventLifecycleStore.shared

    let eventId: UUID

    private var event: Event? { viewModel.event(for: eventId) }
    private var language: AppLanguage { profileStore.activeLanguage }
    private var transfers: [Transfer] { event?.transfers ?? [] }
    private var paidCount: Int { transfers.filter(\.isPaid).count }
    private var totalCount: Int { transfers.count }
    private var isLocked: Bool { lifecycleStore.isLocked(eventId) }
    private var progress: Double { totalCount == 0 ? 0 : Double(paidCount) / Double(totalCount) }
    private var progressPercentText: String { "\(Int((progress * 100).rounded()))%" }
    private var allPaid: Bool { !transfers.isEmpty && transfers.allSatisfy(\.isPaid) }

    private var lockedText: String {
        language.text(
            ja: "精算は確定済みです。支払い状況だけ更新できます。",
            en: "Settlement is finalized. You can still update payment status.",
            zhHans: "结算已确定，仍可更新付款状态。",
            zhHant: "結算已確定，仍可更新付款狀態。",
            ko: "정산이 확정되었습니다. 결제 상태는 계속 변경할 수 있습니다.",
            es: "La liquidación está finalizada. Aún puedes actualizar los pagos.",
            pt: "O acerto está finalizado. Você ainda pode atualizar os pagamentos."
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let event {
                    hero

                    if isLocked {
                        Label(lockedText, systemImage: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .background(AppTheme.primary.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    PaymentSummaryCard(
                        paidCount: paidCount,
                        totalCount: totalCount,
                        progress: progress,
                        progressPercentText: progressPercentText,
                        isAllPaid: allPaid
                    )

                    if transfers.isEmpty {
                        emptyState
                    } else {
                        transferList(event)
                    }

                    helpCard
                } else {
                    ContentUnavailableView(
                        language.payment(.eventNotFound),
                        systemImage: "exclamationmark.triangle"
                    )
                }
            }
            .padding()
        }
        .background(AppTheme.background)
        .navigationTitle(language.payment(.managementTitle))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if !isLocked {
                viewModel.recalculateTransfers(for: eventId)
            }
        }
    }

    private var hero: some View {
        HStack(spacing: 16) {
            Image(systemName: allPaid ? "checkmark.circle.fill" : "wallet.bifold.fill")
                .font(.system(size: 38))
                .frame(width: 60, height: 60)
                .background(.white.opacity(0.17))
                .clipShape(RoundedRectangle(cornerRadius: 19))

            VStack(alignment: .leading, spacing: 5) {
                Text(language.payment(allPaid ? .allPaymentsComplete : .checkPayments))
                    .font(.title3.bold())

                Text(language.payment(allPaid ? .allSettlementDone : .checkCompletedPayments))
                    .font(.caption)
                    .opacity(0.82)
            }

            Spacer()
        }
        .foregroundStyle(.white)
        .padding(20)
        .background(AppTheme.gradient)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private func transferList(_ event: Event) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(language.payment(.paymentList), systemImage: "arrow.left.arrow.right")
                .font(.headline)
                .padding(.horizontal, 4)

            ForEach(transfers) { transfer in
                TransferCard(
                    fromName: event.displayName(
                        for: transfer.fromParticipantId,
                        language: language
                    ),
                    toName: event.displayName(
                        for: transfer.toParticipantId,
                        language: language
                    ),
                    transfer: transfer,
                    currency: event.currency
                ) {
                    viewModel.setTransferPaid(
                        transferId: transfer.id,
                        isPaid: !transfer.isPaid,
                        in: eventId
                    )
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 42))
                .foregroundStyle(AppTheme.success)

            Text(language.payment(.noPayments))
                .font(.headline)

            Text(language.payment(.noPaymentsBody))
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .appCard()
    }

    private var helpCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(AppTheme.warning)

            Text(language.payment(.help))
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .appCard()
    }
}
