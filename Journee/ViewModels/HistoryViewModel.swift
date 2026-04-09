import Foundation
import SwiftData
import SwiftUI

// MARK: - Grouping Models

struct MonthGroup: Identifiable {
    let id: String // "yyyy-MM"
    let title: String // "April 2026"
    let dayGroups: [DayGroup]
}

struct DayGroup: Identifiable {
    let id: String // "yyyy-MM-dd"
    let title: String // "Wednesday, 9"
    let expenses: [Expense]
}

@Observable
final class HistoryViewModel {
    private var modelContext: ModelContext

    var allExpenses: [Expense] = []
    var searchText: String = ""

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadData()
    }

    // MARK: - Data Loading

    func loadData() {
        let descriptor = FetchDescriptor<Expense>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        allExpenses = (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Search State

    var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Filtered (Search Active)

    var filteredExpenses: [Expense] {
        let query = searchText.lowercased().trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return [] }

        return allExpenses.filter { expense in
            let noteMatch = expense.note?.lowercased().contains(query) ?? false
            let categoryMatch = expense.category?.name.lowercased().contains(query) ?? false
            return noteMatch || categoryMatch
        }
    }

    // MARK: - Grouped (Default)

    var groupedByMonth: [MonthGroup] {
        let calendar = Calendar.current
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMMM yyyy"

        let monthKeyFormatter = DateFormatter()
        monthKeyFormatter.dateFormat = "yyyy-MM"

        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE, d"

        let dayKeyFormatter = DateFormatter()
        dayKeyFormatter.dateFormat = "yyyy-MM-dd"

        // Group by month
        var monthDict: [String: (title: String, date: Date, expenses: [Expense])] = [:]

        for expense in allExpenses {
            let monthKey = monthKeyFormatter.string(from: expense.date)
            if monthDict[monthKey] == nil {
                monthDict[monthKey] = (
                    title: monthFormatter.string(from: expense.date),
                    date: expense.date,
                    expenses: []
                )
            }
            monthDict[monthKey]!.expenses.append(expense)
        }

        // Sort months descending
        let sortedMonths = monthDict.sorted { $0.value.date > $1.value.date }

        return sortedMonths.map { monthKey, monthData in
            // Group by day within month
            var dayDict: [String: (title: String, date: Date, expenses: [Expense])] = [:]

            for expense in monthData.expenses {
                let dayKey = dayKeyFormatter.string(from: expense.date)
                if dayDict[dayKey] == nil {
                    dayDict[dayKey] = (
                        title: dayFormatter.string(from: expense.date),
                        date: expense.date,
                        expenses: []
                    )
                }
                dayDict[dayKey]!.expenses.append(expense)
            }

            // Sort days descending
            let sortedDays = dayDict.sorted { $0.value.date > $1.value.date }

            let dayGroups = sortedDays.map { dayKey, dayData in
                DayGroup(
                    id: dayKey,
                    title: dayData.title,
                    expenses: dayData.expenses.sorted { $0.date > $1.date }
                )
            }

            return MonthGroup(
                id: monthKey,
                title: monthData.title,
                dayGroups: dayGroups
            )
        }
    }

    // MARK: - Mutations

    func deleteExpense(_ expense: Expense) {
        modelContext.delete(expense)
        try? modelContext.save()
        loadData()
    }
}
