import SwiftUI
import UIKit

struct EventShareCardView: View {
    let event: Event
    let language: AppLanguage

    private var locationText: String {
        event.location.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var memoText: String {
        event.memo.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func t(_ ja: String, _ en: String, _ zhHans: String, _ zhHant: String, _ ko: String, _ es: String, _ pt: String) -> String {
        language.text(ja: ja, en: en, zhHans: zhHans, zhHant: zhHant, ko: ko, es: es, pt: pt)
    }

    var body: some View {
        ZStack {
            AppTheme.gradient

            Circle()
                .fill(.white.opacity(0.08))
                .frame(width: 280, height: 280)
                .offset(x: 150, y: -180)

            Circle()
                .fill(.white.opacity(0.06))
                .frame(width: 230, height: 230)
                .offset(x: -170, y: 190)

            VStack(alignment: .leading, spacing: 0) {
                header
                Spacer().frame(height: 30)
                eventHeader
                Spacer().frame(height: 22)
                informationCard

                if event.hasDatedExpenses {
                    Spacer().frame(height: 16)
                    expenseSection
                }

                Spacer().frame(height: 28)
                footer
            }
            .padding(28)
        }
        .frame(width: 360)
        .fixedSize(horizontal: false, vertical: true)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "person.3.sequence.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(.white.opacity(0.18))
                .clipShape(RoundedRectangle(cornerRadius: 11))

            VStack(alignment: .leading, spacing: 1) {
                Text(language.appName)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(language.tagline)
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()

            Image(systemName: "sparkles")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    private var eventHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 7) {
                Image(systemName: event.eventType.symbolName)
                Text(event.eventType.displayName(for: language))
            }
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(.white.opacity(0.8))
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .background(.white.opacity(0.14))
            .clipShape(Capsule())

            Text(event.title)
                .font(.system(size: 31, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
    }

    private var informationCard: some View {
        VStack(spacing: 0) {
            informationRow(
                symbol: "calendar",
                title: language.eventText(.dateTime),
                value: event.scheduleText(for: language, includeYear: true),
                lineLimit: 2
            )

            if !locationText.isEmpty {
                divider
                informationRow(
                    symbol: "mappin.and.ellipse",
                    title: language.eventText(.location),
                    value: locationText
                )
            }

            divider

            informationRow(
                symbol: "person.2.fill",
                title: language.eventText(.participants),
                value: "\(event.participants.count) \(language.participantUnit(for: event.participants.count))"
            )

            if !memoText.isEmpty {
                divider
                informationRow(
                    symbol: "note.text",
                    title: language.eventText(.memo),
                    value: memoText,
                    lineLimit: 2
                )
            }
        }
        .padding(.horizontal, 16)
        .background(.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var expenseSection: some View {
        VStack(alignment: .leading, spacing: 9) {
            Label(
                t("日別費用", "Expenses by Day", "每日费用", "每日費用", "날짜별 비용", "Gastos por día", "Despesas por dia"),
                systemImage: "list.bullet.rectangle"
            )
            .font(.system(size: 11, weight: .bold))

            ForEach(event.datedExpenseGroups) { group in
                VStack(spacing: 4) {
                    HStack {
                        Text(event.expenseGroupTitle(for: group.date, language: language))
                            .fontWeight(.bold)

                        Spacer()

                        Text(event.currency.formatted(minorUnits: group.totalAmount))
                            .fontWeight(.bold)
                    }

                    ForEach(group.expenses) { expense in
                        HStack {
                            Text("• \(expense.title)")
                                .lineLimit(1)

                            Spacer()

                            Text(event.currency.formatted(minorUnits: expense.amount))
                        }
                        .opacity(0.8)
                    }
                }
            }

            if !event.undatedExpenses.isEmpty {
                VStack(spacing: 4) {
                    Text(t("日付なし", "No Date", "无日期", "無日期", "날짜 없음", "Sin fecha", "Sem data"))
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(event.undatedExpenses) { expense in
                        HStack {
                            Text("• \(expense.title)")
                                .lineLimit(1)

                            Spacer()

                            Text(event.currency.formatted(minorUnits: expense.amount))
                        }
                        .opacity(0.8)
                    }
                }
            }
        }
        .font(.system(size: 9))
        .foregroundStyle(.white)
        .padding(14)
        .background(.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var divider: some View {
        Divider().overlay(.white.opacity(0.15))
    }

    private func informationRow(symbol: String, title: String, value: String, lineLimit: Int = 1) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 13))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(.white.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.65))

                Text(value)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(lineLimit)
                    .minimumScaleFactor(0.75)
            }

            Spacer()
        }
        .padding(.vertical, 10)
    }

    private var footer: some View {
        HStack {
            Text(t(
                "予定をみんなに共有しよう",
                "Share the plan with everyone",
                "和大家分享这个计划",
                "和大家分享這個計畫",
                "모두에게 일정을 공유하세요",
                "Comparte el plan con todos",
                "Compartilhe o plano com todos"
            ))
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(.white.opacity(0.65))

            Spacer()

            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.65))
        }
    }
}

@MainActor
enum EventShareCardRenderer {
    static func makeImage(event: Event, language: AppLanguage) -> UIImage? {
        let card = EventShareCardView(event: event, language: language)
            .environment(\.colorScheme, .light)

        let renderer = ImageRenderer(content: card)
        renderer.scale = 3
        return renderer.uiImage
    }
}
