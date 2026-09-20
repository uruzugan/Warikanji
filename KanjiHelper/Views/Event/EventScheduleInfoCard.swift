import SwiftUI

struct EventScheduleInfoCard: View {
    @Binding var title: String
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Binding var location: String

    let language: AppLanguage

    private func t(_ ja: String, _ en: String, _ zhHans: String, _ zhHant: String, _ ko: String, _ es: String, _ pt: String) -> String {
        language.text(ja: ja, en: en, zhHans: zhHans, zhHant: zhHant, ko: ko, es: es, pt: pt)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            EventSectionTitle(
                title: language.eventText(.basicInfo),
                symbol: "pencil.and.list.clipboard"
            )

            VStack(spacing: 0) {
                EventInputRow(icon: "textformat", title: language.eventText(.eventName)) {
                    TextField(language.eventText(.eventNameExample), text: $title)
                        .multilineTextAlignment(.trailing)
                }

                Divider().padding(.leading, 44)

                EventInputRow(
                    icon: "calendar.badge.clock",
                    title: t("開始日時", "Starts", "开始时间", "開始時間", "시작 일시", "Inicio", "Início")
                ) {
                    DatePicker(
                        "",
                        selection: $startDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .labelsHidden()
                    .environment(\.locale, Locale(identifier: language.localeIdentifier))
                }

                Divider().padding(.leading, 44)

                EventInputRow(
                    icon: "calendar.badge.checkmark",
                    title: t("終了日時", "Ends", "结束时间", "結束時間", "종료 일시", "Fin", "Fim")
                ) {
                    DatePicker(
                        "",
                        selection: $endDate,
                        in: startDate...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .labelsHidden()
                    .environment(\.locale, Locale(identifier: language.localeIdentifier))
                }

                Divider().padding(.leading, 44)

                EventInputRow(icon: "mappin.and.ellipse", title: language.eventText(.location)) {
                    TextField(language.eventText(.optional), text: $location)
                        .multilineTextAlignment(.trailing)
                }
            }
            .appCard()
        }
        .onChange(of: startDate) {
            if endDate < startDate {
                endDate = startDate
            }
        }
    }
}
