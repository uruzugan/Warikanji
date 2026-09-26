import SwiftUI

struct EventCreateHero: View {
    let title: String
    let eventType: EventType
    let date: Date
    let participantCount: Int
    let language: AppLanguage

    private var titleText: String {
        let value = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? Event.untitledName(for: language) : value
    }

    private var dateText: String {
        date.formatted(Date.FormatStyle().month(.defaultDigits).day(.defaultDigits).locale(Locale(identifier: language.localeIdentifier)))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 14) {
                Image(systemName: eventType.symbolName)
                    .font(.system(size: 25, weight: .semibold))
                    .frame(width: 58, height: 58)
                    .background(.white.opacity(0.18))
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                VStack(alignment: .leading, spacing: 5) {
                    Text(language.eventText(.event)).font(.caption.bold()).opacity(0.75)
                    Text(titleText).font(.title3.bold()).lineLimit(2).minimumScaleFactor(0.75)
                }

                Spacer()
            }

            HStack(spacing: 0) {
                stat(eventType.displayName(for: language), language.eventText(.type), eventType.symbolName)
                divider
                stat("\(participantCount) \(language.participantUnit(for: participantCount))", language.eventText(.participants), "person.2.fill")
                divider
                stat(dateText, language.eventText(.date), "calendar")
            }
        }
        .foregroundStyle(.white)
        .padding(20)
        .background(AppTheme.gradient)
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .shadow(color: AppTheme.primary.opacity(0.18), radius: 14, y: 7)
    }

    private var divider: some View {
        Rectangle().fill(.white.opacity(0.22)).frame(width: 1, height: 44)
    }

    private func stat(_ value: String, _ title: String, _ symbol: String) -> some View {
        VStack(spacing: 5) {
            Image(systemName: symbol).font(.caption)
            Text(value).font(.subheadline.bold()).lineLimit(2).minimumScaleFactor(0.5).multilineTextAlignment(.center)
            Text(title).font(.caption2).lineLimit(1).minimumScaleFactor(0.65).opacity(0.72)
        }
        .frame(maxWidth: .infinity)
    }
}

struct EventBasicInfoCard: View {
    @Binding var title: String
    @Binding var date: Date
    @Binding var location: String
    let language: AppLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            EventSectionTitle(title: language.eventText(.basicInfo), symbol: "pencil.and.list.clipboard")

            VStack(spacing: 0) {
                EventInputRow(icon: "textformat", title: language.eventText(.eventName)) {
                    TextField(language.eventText(.optional), text: $title).multilineTextAlignment(.trailing)
                }

                Divider().padding(.leading, 44)

                EventInputRow(icon: "calendar", title: language.eventText(.dateTime)) {
                    DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                        .environment(\.locale, Locale(identifier: language.localeIdentifier))
                }

                Divider().padding(.leading, 44)

                EventInputRow(icon: "mappin.and.ellipse", title: language.eventText(.location)) {
                    TextField(language.eventText(.optional), text: $location).multilineTextAlignment(.trailing)
                }
            }
            .appCard()
        }
    }
}

struct EventTypePickerCard: View {
    @Binding var eventType: EventType
    let language: AppLanguage

    private let columns = Array(repeating: GridItem(.flexible()), count: 3)

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                EventSectionTitle(title: language.eventText(.eventType), symbol: "square.grid.2x2.fill")
                Text(language.eventText(.chooseEventType)).font(.caption).foregroundStyle(.secondary)
            }

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(EventType.allCases) { type in typeButton(type) }
            }
        }
        .appCard()
    }

    private func typeButton(_ type: EventType) -> some View {
        let selected = eventType == type

        return Button {
            withAnimation(.easeInOut(duration: 0.15)) { eventType = type }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: type.symbolName)
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 34, height: 34)
                    .background(selected ? AppTheme.primary.opacity(0.14) : Color.clear)
                    .clipShape(Circle())

                Text(type.displayName(for: language))
                    .font(.caption.bold())
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(selected ? AppTheme.primary : Color.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 86)
            .background(selected ? AppTheme.primary.opacity(0.08) : Color(uiColor: .tertiarySystemGroupedBackground))
            .overlay {
                RoundedRectangle(cornerRadius: 15).stroke(selected ? AppTheme.primary : Color.clear, lineWidth: 1.5)
            }
            .clipShape(RoundedRectangle(cornerRadius: 15))
        }
        .buttonStyle(.plain)
    }
}

struct EventParticipantCountCard: View {
    @Binding var participantCount: Int
    let language: AppLanguage
    var minimumCount = 1

    private let quickAmounts = [2, 4, 6, 8, 10]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            EventSectionTitle(title: language.eventText(.participants), symbol: "person.2.fill")

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 16) { description; Spacer(); countView }

                VStack(alignment: .leading, spacing: 12) {
                    description
                    HStack { Spacer(); countView }
                }
            }

            HStack(spacing: 12) {
                stepButton(symbol: "minus", disabled: participantCount <= minimumCount) {
                    participantCount = max(minimumCount, participantCount - 1)
                }

                stepButton(symbol: "plus", disabled: participantCount >= 999) {
                    participantCount = min(999, participantCount + 1)
                }

                Spacer()
                Text(language.eventText(.oneAtATime)).font(.caption).foregroundStyle(.secondary)
            }

            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    ForEach(quickAmounts, id: \.self) { quickButton($0, adding: false) }
                }

                HStack(spacing: 8) {
                    ForEach(quickAmounts, id: \.self) { quickButton($0, adding: true) }
                }
            }
        }
        .appCard()
    }

    private var description: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(language.eventText(.howManyPeople)).font(.subheadline.bold())

            Text(language.eventText(minimumCount > 1 ? .participantMinimum : .participantHelp))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var countView: some View {
        HStack(alignment: .lastTextBaseline, spacing: 4) {
            Text("\(participantCount)")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.primary)
                .monospacedDigit()

            Text(language.participantUnit(for: participantCount))
                .font(.caption.bold())
                .foregroundStyle(.secondary)
        }
    }

    private func stepButton(symbol: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.headline)
                .frame(width: 48, height: 38)
                .background(Color(uiColor: .tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.35 : 1)
    }

    private func quickButton(_ amount: Int, adding: Bool) -> some View {
        let disabled = adding ? participantCount >= 999 : participantCount <= minimumCount
        let color = adding ? AppTheme.primary : AppTheme.danger

        return Button {
            participantCount = adding
                ? min(999, participantCount + amount)
                : max(minimumCount, participantCount - amount)
        } label: {
            Text("\(adding ? "+" : "-")\(amount)")
                .font(.caption.bold())
                .foregroundStyle(color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(color.opacity(0.08))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.35 : 1)
    }
}

struct EventMemoCard: View {
    @Binding var memo: String
    let language: AppLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                EventSectionTitle(title: language.eventText(.memo), symbol: "note.text")
                Text(language.eventText(.memoHelp)).font(.caption).foregroundStyle(.secondary)
            }

            TextField(language.eventText(.memoPlaceholder), text: $memo, axis: .vertical)
                .lineLimit(3...6)
                .inputStyle()
        }
        .appCard()
    }
}

struct EventSectionTitle: View {
    let title: String
    let symbol: String

    var body: some View {
        Label(title, systemImage: symbol)
            .font(.headline)
            .foregroundStyle(.primary)
            .labelStyle(EventSectionLabelStyle())
    }
}

private struct EventSectionLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            configuration.icon.foregroundStyle(AppTheme.primary)
            configuration.title
        }
    }
}

struct EventInputRow<Content: View>: View {
    let icon: String
    let title: String
    @ViewBuilder let content: Content

    init(icon: String, title: String, @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.title = title
        self.content = content()
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) { rowLabel; Spacer(minLength: 8); content }

            VStack(alignment: .leading, spacing: 10) {
                rowLabel
                content.frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(.vertical, 10)
    }

    private var rowLabel: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.caption.bold())
                .foregroundStyle(AppTheme.primary)
                .frame(width: 32, height: 32)
                .background(AppTheme.primary.opacity(0.09))
                .clipShape(Circle())

            Text(title)
                .font(.subheadline.bold())
                .lineLimit(2)
                .minimumScaleFactor(0.75)
        }
    }
}
