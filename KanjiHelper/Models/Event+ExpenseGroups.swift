import Foundation

struct ExpenseDayGroup: Identifiable {
    let date: Date
    let expenses: [Expense]

    var id: Date { date }
    var totalAmount: Int { expenses.reduce(0) { $0 + $1.amount } }
}

extension Event {
    var hasDatedExpenses: Bool {
        expenses.contains { $0.date != nil }
    }

    var datedExpenseGroups: [ExpenseDayGroup] {
        let calendar = Calendar.current

        let dated = expenses.compactMap { expense -> (Date, Expense)? in
            guard let date = expense.date else { return nil }
            return (calendar.startOfDay(for: date), expense)
        }

        return Dictionary(grouping: dated, by: \.0)
            .map { ExpenseDayGroup(date: $0.key, expenses: $0.value.map(\.1)) }
            .sorted { $0.date < $1.date }
    }

    var undatedExpenses: [Expense] {
        expenses.filter { $0.date == nil }
    }

    func expenseDayNumber(for date: Date) -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: self.date)
        let target = calendar.startOfDay(for: date)
        return max((calendar.dateComponents([.day], from: start, to: target).day ?? 0) + 1, 1)
    }

    func expenseDayTitle(for date: Date, language: AppLanguage) -> String {
        let day = expenseDayNumber(for: date)

        return language.text(
            ja: "\(day)日目",
            en: "Day \(day)",
            zhHans: "第\(day)天",
            zhHant: "第\(day)天",
            ko: "\(day)일차",
            es: "Día \(day)",
            pt: "Dia \(day)"
        )
    }

    func expenseDateText(_ date: Date, language: AppLanguage) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language.localeIdentifier)

        if language == .japanese {
            formatter.dateFormat = "M月d日(E)"
        } else {
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
        }

        return formatter.string(from: date)
    }

    func expenseGroupTitle(for date: Date, language: AppLanguage) -> String {
        "\(expenseDayTitle(for: date, language: language)) · \(expenseDateText(date, language: language))"
    }

    func expenseBreakdownLines(for language: AppLanguage) -> [String] {
        guard hasDatedExpenses else { return [] }

        let sectionTitle = language.text(
            ja: "日別費用",
            en: "Expenses by Day",
            zhHans: "每日费用",
            zhHant: "每日費用",
            ko: "날짜별 비용",
            es: "Gastos por día",
            pt: "Despesas por dia"
        )

        var lines = [sectionTitle]

        for group in datedExpenseGroups {
            let groupTitle = expenseGroupTitle(for: group.date, language: language)
            let subtotal = currency.formatted(minorUnits: group.totalAmount)

            lines.append("【\(groupTitle)・\(subtotal)】")

            for expense in group.expenses {
                lines.append("・\(expense.title)：\(currency.formatted(minorUnits: expense.amount))")
            }
        }

        if !undatedExpenses.isEmpty {
            let noDateTitle = language.text(
                ja: "日付なし",
                en: "No Date",
                zhHans: "无日期",
                zhHant: "無日期",
                ko: "날짜 없음",
                es: "Sin fecha",
                pt: "Sem data"
            )

            lines.append("【\(noDateTitle)】")

            for expense in undatedExpenses {
                lines.append("・\(expense.title)：\(currency.formatted(minorUnits: expense.amount))")
            }
        }

        return lines
    }
}
