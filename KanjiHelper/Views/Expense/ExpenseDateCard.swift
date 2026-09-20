import SwiftUI

struct ExpenseDateCard: View {
    @Binding var hasDate: Bool
    @Binding var date: Date

    let event: Event?
    let language: AppLanguage

    private func t(_ ja: String, _ en: String, _ zhHans: String, _ zhHant: String, _ ko: String, _ es: String, _ pt: String) -> String {
        language.text(ja: ja, en: en, zhHans: zhHans, zhHant: zhHant, ko: ko, es: es, pt: pt)
    }

    private var dateRange: ClosedRange<Date>? {
        guard let event else { return nil }

        let calendar = Calendar.current
        let start = calendar.startOfDay(for: event.date)
        let endStart = calendar.startOfDay(for: event.endDate)
        let end = calendar.date(byAdding: .day, value: 1, to: endStart)?.addingTimeInterval(-1) ?? event.endDate

        return start...max(start, end)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(
                    t("日付", "Date", "日期", "日期", "날짜", "Fecha", "Data"),
                    systemImage: "calendar"
                )
                .font(.headline)
                .foregroundStyle(AppTheme.primary)

                Spacer()

                Toggle(
                    t("日付を記録", "Add Date", "记录日期", "記錄日期", "날짜 기록", "Añadir fecha", "Adicionar data"),
                    isOn: $hasDate
                )
                .labelsHidden()
            }

            if hasDate {
                if let dateRange {
                    DatePicker("", selection: $date, in: dateRange, displayedComponents: .date)
                        .labelsHidden()
                        .environment(\.locale, Locale(identifier: language.localeIdentifier))
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    DatePicker("", selection: $date, displayedComponents: .date)
                        .labelsHidden()
                        .environment(\.locale, Locale(identifier: language.localeIdentifier))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            Text(t(
                "旅行など複数日にわたるイベントでは、費用が発生した日を記録できます。",
                "For multi-day events, you can record the day this expense occurred.",
                "多日活动中，可以记录这笔费用发生的日期。",
                "多日活動中，可以記錄這筆費用發生的日期。",
                "여러 날에 걸친 이벤트에서는 비용이 발생한 날짜를 기록할 수 있습니다.",
                "En eventos de varios días, puedes registrar el día en que se produjo el gasto.",
                "Em eventos de vários dias, você pode registrar o dia em que a despesa ocorreu."
            ))
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .appCard()
    }
}
