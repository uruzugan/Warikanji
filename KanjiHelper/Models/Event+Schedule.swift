import Foundation

extension Event {
    var hasEnded: Bool {
        Date() > endDate
    }

    func scheduleText(for language: AppLanguage, includeYear: Bool = false) -> String {
        let locale = Locale(identifier: language.localeIdentifier)
        let start = DateFormatter()
        start.locale = locale

        if language == .japanese {
            start.dateFormat = includeYear ? "yyyy年M月d日(E) HH:mm" : "M月d日(E) HH:mm"
        } else {
            start.dateStyle = includeYear ? .medium : .short
            start.timeStyle = .short
        }

        guard endDate > date else {
            return start.string(from: date)
        }

        let sameDay = Calendar.current.isDate(date, inSameDayAs: endDate)
        let end = DateFormatter()
        end.locale = locale

        if language == .japanese {
            end.dateFormat = sameDay ? "HH:mm" : includeYear ? "yyyy年M月d日(E) HH:mm" : "M月d日(E) HH:mm"
        } else {
            end.dateStyle = sameDay ? .none : includeYear ? .medium : .short
            end.timeStyle = .short
        }

        return "\(start.string(from: date))\(language == .japanese ? "〜" : " – ")\(end.string(from: endDate))"
    }
}
