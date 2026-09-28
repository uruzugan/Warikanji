import CoreImage.CIFilterBuiltins
import SwiftUI
import UIKit
import Vision
import VisionKit

struct ReceptionView: View {
    @EnvironmentObject private var viewModel: EventViewModel
    @EnvironmentObject private var profileStore: ProfileStore

    let eventId: UUID

    @State private var isShowingScanner = false
    @State private var alertMessage: String?

    private var event: Event? { viewModel.event(for: eventId) }
    private var language: AppLanguage { profileStore.activeLanguage }
    private var isLocked: Bool { !viewModel.canEdit(eventId) }

    var body: some View {
        Group {
            if let event {
                List {
                    Section {
                        Label(
                            language.planningText(.receptionDescription),
                            systemImage: "qrcode.viewfinder"
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }

                    Section(language.planningText(.checkInSummary)) {
                        summary(event)

                        if !isLocked {
                            Button {
                                openScanner()
                            } label: {
                                scanQRCode
                            }
                        }
                    }

                    Section(language.planningText(.participants)) {
                        if event.participants.isEmpty {
                            ContentUnavailableView(
                                language.planningText(.participants),
                                systemImage: "person.2.slash"
                            )
                        } else {
                            ForEach(event.participants) { participant in
                                participantLink(participant, event: event)
                            }
                        }
                    }
                }
            } else {
                ContentUnavailableView(
                    language.planningText(.receptionTitle),
                    systemImage: "qrcode.viewfinder"
                )
            }
        }
        .navigationTitle(language.planningText(.receptionTitle))
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $isShowingScanner) {
            scannerSheet
        }
        .alert(
            language.planningText(.receptionTitle),
            isPresented: Binding(
                get: { alertMessage != nil },
                set: { if !$0 { alertMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage ?? "")
        }
        .onAppear {
            if !isLocked {
                viewModel.prepareReception(in: eventId)
            }
        }
    }

    private var scanQRCode: some View {
        Label(
            language.planningText(.scanQRCode),
            systemImage: "qrcode.viewfinder"
        )
        .font(.body.bold())
    }

    private var scannerSheet: some View {
        NavigationStack {
            QRCodeScannerView { payload in
                isShowingScanner = false
                if !viewModel.checkInFromQRCode(payload, in: eventId) {
                    alertMessage = language.planningText(.invalidQRCode)
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle(language.planningText(.scanQRCode))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(language.planningText(.cancel)) {
                        isShowingScanner = false
                    }
                }
            }
        }
    }

    private func summary(_ event: Event) -> some View {
        let checkedIn = event.planning.receptionPlan.checkedInParticipantIds
            .intersection(event.participants.map(\.id)).count

        return HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(AppTheme.success)

            VStack(alignment: .leading, spacing: 2) {
                Text(language.planningText(.checkedIn))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(checkedIn) / \(event.participants.count)")
                    .font(.title3.bold().monospacedDigit())
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func participantLink(
        _ participant: EventParticipant,
        event: Event
    ) -> some View {
        NavigationLink {
            ReceptionParticipantView(
                eventId: eventId,
                participantId: participant.id
            )
        } label: {
            HStack(spacing: 12) {
                Image(
                    systemName: isCheckedIn(participant.id, event: event)
                        ? "checkmark.circle.fill"
                        : "circle"
                )
                .font(.title3)
                .foregroundStyle(
                    isCheckedIn(participant.id, event: event)
                        ? AppTheme.success
                        : Color.secondary
                )

                VStack(alignment: .leading, spacing: 3) {
                    Text(event.displayName(for: participant.id, language: language))
                    Text(
                        language.planningText(
                            isCheckedIn(participant.id, event: event)
                                ? .checkedIn
                                : .notCheckedIn
                        )
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func isCheckedIn(_ participantId: UUID, event: Event) -> Bool {
        event.planning.receptionPlan.entries.first {
            $0.participantId == participantId
        }?.isCheckedIn ?? false
    }

    private func openScanner() {
        guard DataScannerViewController.isSupported,
              DataScannerViewController.isAvailable else {
            alertMessage = language.planningText(.scannerUnavailable)
            return
        }
        isShowingScanner = true
    }
}

private struct ReceptionParticipantView: View {
    @EnvironmentObject private var viewModel: EventViewModel
    @EnvironmentObject private var profileStore: ProfileStore

    let eventId: UUID
    let participantId: UUID

    private var event: Event? { viewModel.event(for: eventId) }
    private var language: AppLanguage { profileStore.activeLanguage }
    private var isLocked: Bool { !viewModel.canEdit(eventId) }
    private var entry: ReceptionEntry? {
        event?.planning.receptionPlan.entries.first {
            $0.participantId == participantId
        }
    }

    var body: some View {
        Group {
            if let event, let entry {
                List {
                    Section(language.planningText(.qrPass)) {
                        VStack(spacing: 16) {
                            Text(
                                event.displayName(
                                    for: participantId,
                                    language: language
                                )
                            )
                            .font(.title3.bold())

                            if let image = qrImage(
                                for: entry.qrPayload(eventId: eventId)
                            ) {
                                Image(uiImage: image)
                                    .interpolation(.none)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: 240)
                                    .accessibilityLabel(
                                        language.planningText(.qrPass)
                                    )
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }

                    Section(language.planningText(.checkInSummary)) {
                        LabeledContent(
                            language.planningText(.status),
                            value: language.planningText(
                                entry.isCheckedIn ? .checkedIn : .notCheckedIn
                            )
                        )

                        if let checkedInAt = entry.checkedInAt {
                            LabeledContent(
                                language.planningText(.checkedInAt),
                                value: checkedInAt.formatted(
                                    date: .abbreviated,
                                    time: .shortened
                                )
                            )
                        }

                        if !isLocked {
                            Button {
                                viewModel.setReceptionCheckIn(
                                    participantId: participantId,
                                    checkedIn: !entry.isCheckedIn,
                                    in: eventId
                                )
                            } label: {
                                Label(
                                    language.planningText(
                                        entry.isCheckedIn
                                            ? .undoCheckIn
                                            : .checkIn
                                    ),
                                    systemImage: entry.isCheckedIn
                                        ? "arrow.uturn.backward.circle"
                                        : "checkmark.circle.fill"
                                )
                            }
                            .foregroundStyle(
                                entry.isCheckedIn
                                    ? AppTheme.warning
                                    : AppTheme.success
                            )
                        }
                    }
                }
            } else {
                ContentUnavailableView(
                    language.planningText(.qrPass),
                    systemImage: "qrcode"
                )
            }
        }
        .navigationTitle(language.planningText(.qrPass))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func qrImage(for payload: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(payload.utf8)
        filter.correctionLevel = "M"

        guard let output = filter.outputImage?.transformed(
            by: CGAffineTransform(scaleX: 10, y: 10)
        ), let cgImage = CIContext().createCGImage(
            output,
            from: output.extent
        ) else { return nil }

        return UIImage(cgImage: cgImage)
    }
}

private struct QRCodeScannerView: UIViewControllerRepresentable {
    let onScanned: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onScanned: onScanned)
    }

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.qr])],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: true,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        try? scanner.startScanning()
        return scanner
    }

    func updateUIViewController(
        _ uiViewController: DataScannerViewController,
        context: Context
    ) {}

    static func dismantleUIViewController(
        _ uiViewController: DataScannerViewController,
        coordinator: Coordinator
    ) {
        uiViewController.stopScanning()
    }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        private let onScanned: (String) -> Void
        private var hasScanned = false

        init(onScanned: @escaping (String) -> Void) {
            self.onScanned = onScanned
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didAdd addedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            guard !hasScanned else { return }

            for item in addedItems {
                guard case let .barcode(barcode) = item,
                      let payload = barcode.payloadStringValue else { continue }
                hasScanned = true
                dataScanner.stopScanning()
                onScanned(payload)
                return
            }
        }
    }
}
