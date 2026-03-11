import SwiftUI

struct CalendarGridView: View {
    let selectedMonth: Date
    let dailyTotals: [Int: Double]
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

    var body: some View {
        VStack(spacing: 8) {
            // Weekday headers
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.system(.caption2, design: .rounded, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Day cells
            LazyVGrid(columns: columns, spacing: 2) {
                // Empty cells before the 1st
                ForEach(0..<firstWeekday, id: \.self) { _ in
                    Color.clear
                        .frame(height: 56)
                }

                // Actual days
                ForEach(1...daysInMonth, id: \.self) { day in
                    Button {
                        onDayTapped?(day)
                    } label: {
                        DayCellView(
                            day: day,
                            total: dailyTotals[day],
                            isToday: day == todayDay
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Day Cell

struct DayCellView: View {
    let day: Int
    let total: Double?
    let isToday: Bool

    var body: some View {
        VStack(spacing: 2) {
            Text("\(day)")
                .font(.system(.caption, design: .rounded, weight: isToday ? .bold : .regular))
                .foregroundStyle(isToday ? .white : .primary)

            if let total, total > 0 {
                Text(formattedAmount(total))
                    .font(.system(size: 8, weight: .medium, design: .rounded))
                    .foregroundStyle(isToday ? .white.opacity(0.8) : .orange)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
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
