import SwiftUI
import AudioToolbox

struct PayerRouletteView: View {
    @EnvironmentObject private var profileStore: ProfileStore
    @Environment(\.dismiss) private var dismiss
    @AppStorage("rouletteSoundEnabled") private var soundEnabled = false

    let participants: [EventParticipant]
    let onConfirm: (UUID) -> Void

    @State private var selectedIds: Set<UUID>
    @State private var displayed: EventParticipant?
    @State private var result: EventParticipant?
    @State private var isRunning = false

    private var language: AppLanguage { profileStore.activeLanguage }
    private var candidates: [EventParticipant] { participants.filter { selectedIds.contains($0.id) } }
    private var displayedName: String? { displayed.map(name) }

    init(participants: [EventParticipant], onConfirm: @escaping (UUID) -> Void) {
        self.participants = participants
        self.onConfirm = onConfirm
        _selectedIds = State(initialValue: Set(participants.map(\.id)))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                RouletteDisplayCard(name: displayedName, isRunning: isRunning, hasResult: result != nil)
                actionArea

                RouletteCandidateCard(
                    participants: participants,
                    selectedIds: $selectedIds,
                    disabled: isRunning
                ) {
                    displayed = nil
                    result = nil
                }

                RouletteSoundCard(enabled: $soundEnabled, disabled: isRunning)
            }
            .padding()
        }
        .background(AppTheme.background)
        .navigationTitle(language.roulette(.title))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(language.roulette(.close)) { dismiss() }
            }
        }
        .tint(AppTheme.primary)
    }

    private var actionArea: some View {
        VStack(spacing: 10) {
            if let result {
                Button { onConfirm(result.id) } label: {
                    Label(language.rouletteWinner(name(result)), systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppTheme.gradient)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                }
                .buttonStyle(.plain)

                Button(action: startRoulette) {
                    Label(language.roulette(.spinAgain), systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            } else {
                Button(action: startRoulette) {
                    Label(
                        language.roulette(isRunning ? .spinning : .spin),
                        systemImage: "die.face.5.fill"
                    )
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppTheme.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                }
                .buttonStyle(.plain)
                .disabled(isRunning || candidates.isEmpty)
                .opacity(candidates.isEmpty ? 0.4 : 1)

                Button(action: showInstantResult) {
                    Label(language.roulette(.instantResult), systemImage: "bolt.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(isRunning || candidates.isEmpty)
            }
        }
        .appCard()
    }

    private func startRoulette() {
        guard !isRunning, let final = candidates.randomElement() else { return }

        result = nil
        isRunning = true

        let delays = [
            0.07, 0.07, 0.08, 0.08, 0.09, 0.10, 0.11, 0.12,
            0.14, 0.16, 0.19, 0.22, 0.26, 0.31, 0.38, 0.46
        ]

        runStep(0, delays, final)
    }

    private func runStep(_ index: Int, _ delays: [Double], _ final: EventParticipant) {
        guard index < delays.count else {
            displayed = final
            result = final
            isRunning = false
            resultFeedback()
            return
        }

        if let next = candidates.randomElement() {
            displayed = next
            tickFeedback()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + delays[index]) {
            runStep(index + 1, delays, final)
        }
    }

    private func showInstantResult() {
        guard let participant = candidates.randomElement() else { return }
        displayed = participant
        result = participant
        resultFeedback()
    }

    private func tickFeedback() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if soundEnabled { AudioServicesPlaySystemSound(1104) }
    }

    private func resultFeedback() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        if soundEnabled { AudioServicesPlaySystemSound(1111) }
    }

    private func name(_ participant: EventParticipant) -> String {
        guard let index = participants.firstIndex(where: { $0.id == participant.id }) else {
            return language.roulette(.participant)
        }

        let name = participant.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? language.rouletteParticipant(index + 1) : name
    }
}
