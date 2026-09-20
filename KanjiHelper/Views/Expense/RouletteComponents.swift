import SwiftUI

struct RouletteDisplayCard: View {
    @EnvironmentObject private var profileStore: ProfileStore

    let name: String?
    let isRunning: Bool
    let hasResult: Bool

    private var language: AppLanguage { profileStore.activeLanguage }

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: hasResult ? "party.popper.fill" : "die.face.5.fill")
                .font(.system(size: 42))
                .foregroundStyle(.white)

            Text(language.roulette(isRunning ? .spinning : hasResult ? .payerIs : .whoPays))
                .font(.subheadline.bold())
                .foregroundStyle(.white.opacity(0.8))

            Text(name ?? language.roulette(.startPrompt))
                .font(.title2.bold())
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(AppTheme.gradient)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

struct RouletteCandidateCard: View {
    @EnvironmentObject private var profileStore: ProfileStore

    let participants: [EventParticipant]
    @Binding var selectedIds: Set<UUID>
    let disabled: Bool
    let onChange: () -> Void

    private var language: AppLanguage { profileStore.activeLanguage }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label(language.roulette(.candidates), systemImage: "person.3.fill")
                    .font(.headline)
                    .foregroundStyle(AppTheme.primary)

                Spacer()

                Text("\(selectedIds.count)/\(participants.count) \(language.participantUnit(for: participants.count))")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }

            ForEach(Array(participants.enumerated()), id: \.element.id) { index, participant in
                row(participant, index)
            }

            Button {
                if selectedIds.count == participants.count {
                    selectedIds.removeAll()
                } else {
                    selectedIds = Set(participants.map(\.id))
                }

                onChange()
            } label: {
                Text(
                    language.roulette(
                        selectedIds.count == participants.count
                            ? .deselectAll
                            : .selectAll
                    )
                )
                .font(.caption.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(AppTheme.primary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 11))
            }
            .buttonStyle(.plain)
            .disabled(disabled)

            if selectedIds.isEmpty {
                Label(
                    language.roulette(.chooseCandidate),
                    systemImage: "exclamationmark.triangle.fill"
                )
                .font(.caption)
                .foregroundStyle(AppTheme.danger)
            }
        }
        .appCard()
    }

    private func row(_ participant: EventParticipant, _ index: Int) -> some View {
        let selected = selectedIds.contains(participant.id)

        return Button {
            if selected {
                selectedIds.remove(participant.id)
            } else {
                selectedIds.insert(participant.id)
            }

            onChange()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "person.fill")
                    .foregroundStyle(selected ? AppTheme.primary : Color.secondary)
                    .frame(width: 38, height: 38)
                    .background(
                        selected
                            ? AppTheme.primary.opacity(0.12)
                            : Color.secondary.opacity(0.08)
                    )
                    .clipShape(Circle())

                Text(displayName(participant, index))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(selected ? AppTheme.primary : Color.secondary)
            }
            .padding(10)
            .background(selected ? AppTheme.primary.opacity(0.06) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 13))
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }

    private func displayName(_ participant: EventParticipant, _ index: Int) -> String {
        let name = participant.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? language.rouletteParticipant(index + 1) : name
    }
}

struct RouletteSoundCard: View {
    @EnvironmentObject private var profileStore: ProfileStore

    @Binding var enabled: Bool
    let disabled: Bool

    private var language: AppLanguage { profileStore.activeLanguage }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(language.roulette(.settings), systemImage: "gearshape.fill")
                .font(.headline)
                .foregroundStyle(AppTheme.primary)

            Toggle(isOn: $enabled) {
                Label(
                    language.roulette(.sound),
                    systemImage: enabled
                        ? "speaker.wave.2.fill"
                        : "speaker.slash.fill"
                )
            }
            .disabled(disabled)

            Text(language.roulette(.soundDescription))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .appCard()
    }
}

enum RouletteText: Int {
    case title, close, spinAgain, spinning, spin, instantResult
    case participant, payerIs, whoPays, startPrompt, candidates
    case deselectAll, selectAll, chooseCandidate, settings, sound, soundDescription
}

private let rouletteTexts: [[String]] = [
    ["会計ルーレット", "Payer Roulette", "付款轮盘", "付款輪盤", "결제 룰렛", "Ruleta de pago", "Roleta de pagamento"],
    ["閉じる", "Close", "关闭", "關閉", "닫기", "Cerrar", "Fechar"],
    ["もう一度回す", "Spin Again", "再转一次", "再轉一次", "다시 돌리기", "Girar otra vez", "Girar novamente"],
    ["抽選中...", "Choosing...", "抽选中...", "抽選中...", "추첨 중...", "Eligiendo...", "Sorteando..."],
    ["ルーレットを回す", "Spin the Roulette", "转动轮盘", "轉動輪盤", "룰렛 돌리기", "Girar la ruleta", "Girar a roleta"],
    ["すぐに結果を見る", "Show Result Now", "立即查看结果", "立即查看結果", "바로 결과 보기", "Ver resultado ahora", "Ver resultado agora"],
    ["参加者", "Participant", "参与者", "參加者", "참가자", "Participante", "Participante"],
    ["会計担当は...", "The payer is...", "付款人是...", "付款人是...", "결제 담당은...", "La persona que paga es...", "Quem paga é..."],
    ["誰が払う？", "Who pays?", "谁来付款？", "誰來付款？", "누가 낼까요?", "¿Quién paga?", "Quem paga?"],
    ["ルーレットを回そう", "Spin the roulette", "转动轮盘吧", "轉動輪盤吧", "룰렛을 돌려보세요", "Gira la ruleta", "Gire a roleta"],
    ["候補者", "Candidates", "候选人", "候選人", "후보자", "Candidatos", "Candidatos"],
    ["全員の選択を解除", "Deselect All", "取消全选", "取消全選", "모두 선택 해제", "Deseleccionar todos", "Desmarcar todos"],
    ["全員を選択", "Select All", "全选", "全選", "모두 선택", "Seleccionar todos", "Selecionar todos"],
    ["候補者を1人以上選択してください", "Select at least one candidate.", "请至少选择一名候选人。", "請至少選擇一名候選人。", "후보자를 한 명 이상 선택하세요.", "Selecciona al menos un candidato.", "Selecione pelo menos um candidato."],
    ["設定", "Settings", "设置", "設定", "설정", "Ajustes", "Configurações"],
    ["サウンド", "Sound", "声音", "音效", "사운드", "Sonido", "Som"],
    ["抽選中と結果発表時に効果音を鳴らします。初期設定はOFFです。", "Plays sounds while choosing and when the result appears. Off by default.", "抽选和公布结果时播放音效。默认关闭。", "抽選和公布結果時播放音效。預設關閉。", "추첨 중과 결과 발표 시 효과음을 재생합니다. 기본값은 꺼짐입니다.", "Reproduce sonidos durante el sorteo y al mostrar el resultado. Está desactivado por defecto.", "Reproduz sons durante o sorteio e ao mostrar o resultado. Desativado por padrão."]
]

extension AppLanguage {
    func roulette(_ key: RouletteText) -> String {
        rouletteTexts[key.rawValue][rouletteIndex]
    }

    func rouletteParticipant(_ number: Int) -> String {
        switch self {
        case .japanese: return "参加者\(number)"
        case .english: return "Participant \(number)"
        case .simplifiedChinese: return "参与者\(number)"
        case .traditionalChinese: return "參加者\(number)"
        case .korean: return "참가자 \(number)"
        case .spanish, .portuguese: return "Participante \(number)"
        }
    }

    func rouletteWinner(_ name: String) -> String {
        switch self {
        case .japanese: return "\(name)さんに決定"
        case .english: return "Choose \(name)"
        case .simplifiedChinese: return "确定由\(name)付款"
        case .traditionalChinese: return "確定由\(name)付款"
        case .korean: return "\(name)님으로 결정"
        case .spanish: return "Elegir a \(name)"
        case .portuguese: return "Escolher \(name)"
        }
    }

    private var rouletteIndex: Int {
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
