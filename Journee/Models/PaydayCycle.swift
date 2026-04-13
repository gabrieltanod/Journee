import Foundation

/// Represents a custom budget cycle based on a payday date.
/// For example, if payday is 25, a cycle runs from the 25th of one month to the 24th of the next.
struct PaydayCycle: Equatable {
    let startDate: Date
    let endDate: Date

    private static var calendar: Calendar { Calendar.current }

    // MARK: - Factory

    /// Calculate the cycle containing a given reference date.
    /// - Parameters:
    ///   - date: Any date to find the containing cycle for.
    ///   - payday: The day of the month the cycle starts (1–28).
    /// - Returns: A `PaydayCycle` with the computed start and end dates.
    static func cycle(containing date: Date, payday: Int) -> PaydayCycle {
        let cal = calendar
        let clampedPayday = max(1, min(28, payday))

        let dayOfMonth = cal.component(.day, from: date)
        let year = cal.component(.year, from: date)
        let month = cal.component(.month, from: date)

        var startComps = DateComponents()
        startComps.day = clampedPayday
        startComps.hour = 0
        startComps.minute = 0
        startComps.second = 0

        if dayOfMonth >= clampedPayday {
            // We're in the cycle that started this month
            startComps.year = year
            startComps.month = month
        } else {
            // We're in the cycle that started last month
            if month == 1 {
                startComps.year = year - 1
                startComps.month = 12
            } else {
                startComps.year = year
                startComps.month = month - 1
            }
        }

        guard let start = cal.date(from: startComps) else {
            // Fallback: shouldn't happen with valid inputs
            return PaydayCycle(startDate: date, endDate: date)
        }

        // End date is one day before the next cycle's start
        guard let nextStart = cal.date(byAdding: .month, value: 1, to: start),
              let end = cal.date(byAdding: .day, value: -1, to: nextStart)
        else {
            return PaydayCycle(startDate: start, endDate: start)
        }

        let startOfStart = cal.startOfDay(for: start)
        let endOfEnd = cal.date(bySettingHour: 23, minute: 59, second: 59, of: end) ?? end

        return PaydayCycle(startDate: startOfStart, endDate: endOfEnd)
    }

    // MARK: - Navigation

    /// Returns the next cycle.
    func next(payday: Int) -> PaydayCycle {
        let cal = Self.calendar
        guard let nextStart = cal.date(byAdding: .month, value: 1, to: startDate) else { return self }
        return PaydayCycle.cycle(containing: nextStart, payday: payday)
    }

    /// Returns the previous cycle.
    func previous(payday: Int) -> PaydayCycle {
        let cal = Self.calendar
        guard let prevDate = cal.date(byAdding: .day, value: -1, to: startDate) else { return self }
        return PaydayCycle.cycle(containing: prevDate, payday: payday)
    }

    // MARK: - Date Enumeration

    /// All dates in the cycle, from startDate to endDate inclusive.
    var allDates: [Date] {
        let cal = Self.calendar
        var dates: [Date] = []
        var current = cal.startOfDay(for: startDate)
        let end = cal.startOfDay(for: endDate)

        while current <= end {
            dates.append(current)
            guard let next = cal.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }
        return dates
    }

    // MARK: - Display

    /// Formatted label like "Feb 25 – Mar 24" or "Mar 1 – Mar 31" 
    var label: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: startDate)) – \(formatter.string(from: endDate))"
    }

    /// Whether today falls within this cycle.
    var isCurrentCycle: Bool {
        let cal = Self.calendar
        let today = cal.startOfDay(for: Date())
        let start = cal.startOfDay(for: startDate)
        let end = cal.startOfDay(for: endDate)
        return today >= start && today <= end
    }

    // MARK: - Budget Key

    /// Month component of the cycle's start date (for budget storage).
    var startMonth: Int {
        Self.calendar.component(.month, from: startDate)
    }

    /// Year component of the cycle's start date (for budget storage).
    var startYear: Int {
        Self.calendar.component(.year, from: startDate)
    }

    // MARK: - Query Helpers

    /// The start date clamped to start-of-day for fetch predicates.
    var fetchStartDate: Date {
        Self.calendar.startOfDay(for: startDate)
    }

    /// The end date set to 23:59:59 for fetch predicates.
    var fetchEndDate: Date {
        Self.calendar.date(bySettingHour: 23, minute: 59, second: 59, of: endDate) ?? endDate
    }
}
