import SwiftUI

struct CalendarGridView: View {
    let selectedMonth: Date
    let dailyTotals: [Int: DailyTotal]
    var onDayTapped: ((Int) -> Void)?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)
    private let weekdaySymbols = Calendar.current.veryShortWeekdaySymbols

    private var calendar: Calendar { Calendar.current }

    private var daysInMonth: Int {
        calendar.range(of: .day, in: .month, for: selectedMonth)?.count ?? 30
    }

    /// Weekday index (0 = Sunday) of the 1st day of the month
    private var firstWeekday: Int {
        let comps = calendar.dateComponents([.year, .month], from: selectedMonth)
        guard let firstDay = calendar.date(from: comps) else { return 0 }
        return calendar.component(.weekday, from: firstDay) - 1
    }

    private var todayDay: Int? {
        guard calendar.isDate(selectedMonth, equalTo: Date(), toGranularity: .month) else { return nil }
        return calendar.component(.day, from: Date())
    }

    /// A unified array of cell models: nil = empty spacer, Int = day number
    private var calendarCells: [CalendarCell] {
        var cells: [CalendarCell] = []
        // Leading empty cells
        for i in 0..<firstWeekday {
            cells.append(CalendarCell(id: -i - 1, day: nil))
        }
        // Day cells
        for day in 1...daysInMonth {
            cells.append(CalendarCell(id: day, day: day))
        }
        return cells
    }

    var body: some View {
        VStack(spacing: 8) {
            // Weekday headers — use Array.indices to avoid duplicate-ID issue
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(.system(.caption2, design: .rounded, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Day cells — single ForEach with unique IDs
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(calendarCells) { cell in
                    if let day = cell.day {
                        Button {
                            onDayTapped?(day)
                        } label: {
                            DayCellView(
                                day: day,
                                dailyTotal: dailyTotals[day],
                                isToday: day == todayDay
                            )
                        }
                        .buttonStyle(.plain)
                    } else {
                        Color.clear
                            .frame(height: 56)
                    }
                }
            }
        }
    }
}

private struct CalendarCell: Identifiable {
    let id: Int
    let day: Int?
}

// MARK: - Day Cell

struct DayCellView: View {
    let day: Int
    let dailyTotal: DailyTotal?
    let isToday: Bool

    var body: some View {
        VStack(spacing: 1) {
            Text("\(day)")
                .font(.system(.caption, design: .rounded, weight: isToday ? .bold : .regular))
                .foregroundStyle(isToday ? .white : .primary)

            if let total = dailyTotal {
                if total.income > 0 && total.expense > 0 {
                    // Both: green income on top, orange expense on bottom
                    VStack(spacing: 0) {
                        Text(formattedAmount(total.income))
                            .font(.system(size: 7, weight: .medium, design: .rounded))
                            .foregroundStyle(isToday ? .white.opacity(0.8) : Color(hex: "22C55E"))
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)

                        Text(formattedAmount(total.expense))
                            .font(.system(size: 7, weight: .medium, design: .rounded))
                            .foregroundStyle(isToday ? .white.opacity(0.8) : .orange)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                } else if total.income > 0 {
                    // Income only — green
                    Text(formattedAmount(total.income))
                        .font(.system(size: 8, weight: .medium, design: .rounded))
                        .foregroundStyle(isToday ? .white.opacity(0.8) : Color(hex: "22C55E"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                } else if total.expense > 0 {
                    // Expense only — orange (original behavior)
                    Text(formattedAmount(total.expense))
                        .font(.system(size: 8, weight: .medium, design: .rounded))
                        .foregroundStyle(isToday ? .white.opacity(0.8) : .orange)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isToday ? Color.primary : Color(.tertiarySystemFill))
        )
    }

    private func formattedAmount(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "%.1fM", value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "%.0fK", value / 1_000)
        }
        return String(format: "%.0f", value)
    }
}
