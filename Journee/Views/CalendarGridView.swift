import SwiftUI

struct CalendarGridView: View {
    let cycle: PaydayCycle
    let dailyTotals: [Date: DailyTotal]
    var onDayTapped: ((Date) -> Void)?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)
    private let weekdaySymbols = Calendar.current.veryShortWeekdaySymbols

    private var calendar: Calendar { Calendar.current }

    /// Weekday index (0 = Sunday) of the cycle's start date
    private var startWeekdayOffset: Int {
        calendar.component(.weekday, from: cycle.startDate) - 1
    }

    /// Today as start-of-day for comparison
    private var todayDate: Date {
        calendar.startOfDay(for: Date())
    }

    /// Build cell array: leading empty placeholders + actual dates
    private var calendarCells: [CycleCalendarCell] {
        var cells: [CycleCalendarCell] = []

        // Leading empty cells to align start date to correct weekday column
        for i in 0..<startWeekdayOffset {
            cells.append(CycleCalendarCell(id: "empty-\(i)", date: nil))
        }

        // Actual date cells
        let dates = cycle.allDates
        let dateKeyFormatter = DateFormatter()
        dateKeyFormatter.dateFormat = "yyyy-MM-dd"

        for date in dates {
            cells.append(CycleCalendarCell(
                id: dateKeyFormatter.string(from: date),
                date: date
            ))
        }

        return cells
    }

    var body: some View {
        VStack(spacing: 8) {
            // Weekday headers
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(.system(.caption2, design: .rounded, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Day cells
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(calendarCells) { cell in
                    if let date = cell.date {
                        Button {
                            onDayTapped?(date)
                        } label: {
                            CycleDayCellView(
                                date: date,
                                dailyTotal: dailyTotals[calendar.startOfDay(for: date)],
                                isToday: calendar.startOfDay(for: date) == todayDate
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

// MARK: - Cell Model

private struct CycleCalendarCell: Identifiable {
    let id: String
    let date: Date?
}

// MARK: - Day Cell

struct CycleDayCellView: View {
    let date: Date
    let dailyTotal: DailyTotal?
    let isToday: Bool

    private var dayNumber: Int {
        Calendar.current.component(.day, from: date)
    }

    /// Show month abbreviation on the 1st day of any month within the cycle
    private var monthLabel: String? {
        if dayNumber == 1 {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM"
            return formatter.string(from: date)
        }
        return nil
    }

    var body: some View {
        VStack(spacing: 1) {
            // Day number + optional month label
            if let month = monthLabel {
                VStack(spacing: 0) {
                    Text("\(dayNumber)")
                        .font(.system(size: 11, weight: isToday ? .bold : .regular, design: .rounded))
                        .foregroundStyle(isToday ? .white : .primary)

                    Text(month)
                        .font(.system(size: 7, weight: .semibold, design: .rounded))
                        .foregroundStyle(isToday ? .white.opacity(0.7) : .secondary)
                }
            } else {
                Text("\(dayNumber)")
                    .font(.system(.caption, design: .rounded, weight: isToday ? .bold : .regular))
                    .foregroundStyle(isToday ? .white : .primary)
            }

            if let total = dailyTotal {
                if total.income > 0 && total.expense > 0 {
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
                    Text(formattedAmount(total.income))
                        .font(.system(size: 8, weight: .medium, design: .rounded))
                        .foregroundStyle(isToday ? .white.opacity(0.8) : Color(hex: "22C55E"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                } else if total.expense > 0 {
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
                .fill(isToday ? Color.black : Color(.tertiarySystemFill))
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
