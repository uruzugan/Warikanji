import SwiftUI

struct ExpenseRatioEditor: View {
    @EnvironmentObject private var profileStore: ProfileStore

    let participants: [EventParticipant]
    let expenseId: UUID
    @Binding var conditions: [ExpenseCondition]
    @Binding var names: [UUID: String]
    @Binding var fixedIds: Set<UUID>

    @State private var weightTexts: [UUID: String] = [:]

    private let tolerance = 0.000001
    private var language: AppLanguage { profileStore.activeLanguage }
    private var included: [EventParticipant] { participants.filter { isIncluded($0.id) } }
    private var adjustable: [EventParticipant] { included.filter { !fixedIds.contains($0.id) } }
    private var target: Double { Double(included.count) }
    private var total: Double { included.reduce(0) { $0 + weight($1.id) } }

    private var fixedTotal: Double {
        included.filter { fixedIds.contains($0.id) }.reduce(0) { $0 + weight($1.id) }
    }

    private var fixedOverTarget: Bool { fixedTotal > target + tolerance }
    private var canAutoAdjust: Bool { !adjustable.isEmpty && !fixedOverTarget }

    private var copy: (
        ratio: String, over: String, auto: String, included: String, excluded: String,
        name: String, share: String, fixed: String, fix: String
    ) {
        switch language {
        case .japanese:
            return ("比率調整", "固定した比率だけで基準値を超えています", "固定していない人を自動調整",
                    "負担対象", "対象外", "名前（任意）", "負担比率", "この比率を固定中", "この比率を固定")
        case .english:
            return ("Adjust Ratios", "The fixed ratios already exceed the target.", "Auto-adjust unlocked participants",
                    "Included", "Excluded", "Name (Optional)", "Share Ratio", "Ratio Locked", "Lock This Ratio")
        case .simplifiedChinese:
            return ("调整比例", "固定的比例已经超过基准值", "自动调整未固定的参与者",
                    "参与分摊", "不参与", "姓名（可选）", "分摊比例", "比例已固定", "固定此比例")
        case .traditionalChinese:
            return ("調整比例", "固定的比例已超過基準值", "自動調整未固定的參加者",
                    "參與分攤", "不參與", "姓名（選填）", "分攤比例", "比例已固定", "固定此比例")
        case .korean:
            return ("비율 조정", "고정된 비율만으로 기준값을 초과했습니다", "고정하지 않은 참가자 자동 조정",
                    "부담 대상", "대상 제외", "이름 (선택)", "부담 비율", "비율 고정 중", "이 비율 고정")
        case .spanish:
            return ("Ajustar proporciones", "Las proporciones fijadas superan el objetivo.", "Ajustar automáticamente los no fijados",
                    "Incluido", "Excluido", "Nombre (opcional)", "Proporción", "Proporción fijada", "Fijar proporción")
        case .portuguese:
            return ("Ajustar proporções", "As proporções fixadas excedem o valor-alvo.", "Ajustar automaticamente os não fixados",
                    "Incluído", "Excluído", "Nome (opcional)", "Proporção", "Proporção fixada", "Fixar proporção")
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            summary
            participantList
        }
        .onAppear { prepare() }
    }

    private var summary: some View {
        VStack(spacing: 12) {
            HStack {
                Label(copy.ratio, systemImage: "slider.horizontal.3")
                    .font(.headline)

                Spacer()

                Text(format(total))
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(abs(total - target) <= tolerance ? AppTheme.success : AppTheme.warning)

                Text("/ \(format(target))")
                    .foregroundStyle(.secondary)
            }

            if fixedOverTarget {
                Label(copy.over, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(AppTheme.danger)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button(action: autoAdjust) {
                Label(copy.auto, systemImage: "wand.and.stars")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.primary)
            .disabled(!canAutoAdjust)
        }
        .appCard()
    }

    private var participantList: some View {
        VStack(spacing: 0) {
            ForEach(Array(participants.enumerated()), id: \.element.id) { index, participant in
                row(participant, fallback: participantFallback(index + 1))

                if index < participants.count - 1 {
                    Divider().padding(.vertical, 12)
                }
            }
        }
        .appCard()
    }

    private func row(_ participant: EventParticipant, fallback: String) -> some View {
        let id = participant.id
        let active = isIncluded(id)

        return VStack(spacing: 12) {
            HStack {
                Image(systemName: "person.crop.circle.fill")
                    .font(.title2)
                    .foregroundStyle(active ? AppTheme.primary : Color.secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(displayName(participant, fallback: fallback))
                        .font(.headline)

                    Text(active ? copy.included : copy.excluded)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Toggle("", isOn: includedBinding(id))
                    .labelsHidden()
            }

            TextField(copy.name, text: nameBinding(id))
                .disabled(!active)
                .inputStyle()

            if active {
                ratioControls(id)
            }
        }
        .opacity(active ? 1 : 0.6)
    }

    private func ratioControls(_ id: UUID) -> some View {
        VStack(spacing: 10) {
            HStack {
                Label(copy.share, systemImage: "percent")
                    .font(.subheadline.bold())

                Spacer()

                TextField("1.0", text: weightBinding(id))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .font(.headline.monospacedDigit())
                    .frame(width: 90)
                    .inputStyle()
            }

            HStack(spacing: 8) {
                changeButton("-1") { adjust(id, -1) }
                changeButton("-0.1") { adjust(id, -0.1) }

                Spacer()

                changeButton("+0.1") { adjust(id, 0.1) }
                changeButton("+1") { adjust(id, 1) }
            }

            Toggle(isOn: fixedBinding(id)) {
                Label(
                    fixedIds.contains(id) ? copy.fixed : copy.fix,
                    systemImage: fixedIds.contains(id) ? "lock.fill" : "lock.open"
                )
                .font(.caption.bold())
                .foregroundStyle(fixedIds.contains(id) ? AppTheme.primary : Color.secondary)
            }
        }
        .padding(12)
        .background(
            fixedIds.contains(id)
                ? AppTheme.primary.opacity(0.07)
                : Color(uiColor: .tertiarySystemGroupedBackground)
        )
        .clipShape(RoundedRectangle(cornerRadius: 15))
    }

    private func changeButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .font(.caption.bold())
            .buttonStyle(.bordered)
            .controlSize(.small)
    }

    private func prepare() {
        for participant in participants {
            ensureCondition(participant.id)

            if names[participant.id] == nil {
                names[participant.id] = participant.name
            }

            weightTexts[participant.id] = format(weight(participant.id))
        }
    }

    private func ensureCondition(_ id: UUID) {
        guard !conditions.contains(where: { $0.participantId == id }) else { return }
        conditions.append(ExpenseCondition(expenseId: expenseId, participantId: id))
    }

    private func conditionIndex(_ id: UUID) -> Int? {
        conditions.firstIndex { $0.participantId == id }
    }

    private func isIncluded(_ id: UUID) -> Bool {
        guard let index = conditionIndex(id) else { return true }
        return conditions[index].isIncluded
    }

    private func weight(_ id: UUID) -> Double {
        guard let index = conditionIndex(id) else { return 1 }
        return max(conditions[index].customWeight, 0)
    }

    private func setWeight(_ value: Double, _ id: UUID) {
        ensureCondition(id)
        guard let index = conditionIndex(id) else { return }

        let normalized = max((value * 1_000_000).rounded() / 1_000_000, 0)
        conditions[index].customWeight = normalized
        weightTexts[id] = format(normalized)
    }

    private func adjust(_ id: UUID, _ amount: Double) {
        setWeight(weight(id) + amount, id)
    }

    private func autoAdjust() {
        guard canAutoAdjust else { return }

        let remaining = max(target - fixedTotal, 0)
        let each = remaining / Double(adjustable.count)

        for participant in adjustable {
            setWeight(each, participant.id)
        }
    }

    private func displayName(_ participant: EventParticipant, fallback: String) -> String {
        let name = names[participant.id, default: participant.name]
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return name.isEmpty ? fallback : name
    }

    private func participantFallback(_ number: Int) -> String {
        switch language {
        case .japanese: return "参加者\(number)"
        case .english: return "Participant \(number)"
        case .simplifiedChinese: return "参与者\(number)"
        case .traditionalChinese: return "參加者\(number)"
        case .korean: return "참가자 \(number)"
        case .spanish, .portuguese: return "Participante \(number)"
        }
    }

    private func includedBinding(_ id: UUID) -> Binding<Bool> {
        Binding(
            get: { isIncluded(id) },
            set: { value in
                ensureCondition(id)
                guard let index = conditionIndex(id) else { return }

                conditions[index].isIncluded = value

                if !value {
                    fixedIds.remove(id)
                }
            }
        )
    }

    private func nameBinding(_ id: UUID) -> Binding<String> {
        Binding(
            get: { names[id] ?? "" },
            set: { names[id] = $0 }
        )
    }

    private func fixedBinding(_ id: UUID) -> Binding<Bool> {
        Binding(
            get: { fixedIds.contains(id) },
            set: { value in
                if value {
                    fixedIds.insert(id)
                } else {
                    fixedIds.remove(id)
                }
            }
        )
    }

    private func weightBinding(_ id: UUID) -> Binding<String> {
        Binding(
            get: { weightTexts[id] ?? format(weight(id)) },
            set: {
                weightTexts[id] = $0

                let normalized = $0.replacingOccurrences(of: ",", with: ".")
                guard let value = Double(normalized),
                      value.isFinite,
                      value >= 0 else { return }

                setWeight(value, id)
            }
        )
    }

    private func format(_ value: Double) -> String {
        var text = String(format: "%.6f", value)

        while text.last == "0" {
            text.removeLast()
        }

        if text.last == "." {
            text.append("0")
        }

        return text
    }
}
