import Foundation
import SwiftData
import SwiftUI

// MARK: - Grouping Models

struct CycleGroup: Identifiable {
    let id: String
    let title: String // "Feb 25 – Mar 24"
    let dayGroups: [DayGroup]
}

struct DayGroup: Identifiable {
    let id: String // "yyyy-MM-dd"
    let title: String // "Wednesday, 9 Mar"
    let expenses: [Expense]
}

@Observable
final class HistoryViewModel {
    private var modelContext: ModelContext
    private var payday: Int

    var allExpenses: [Expense] = []
    var searchText: String = ""

    init(modelContext: ModelContext, payday: Int = 1) {
        self.modelContext = modelContext
        self.payday = payday
        loadData()
    }

    // MARK: - Payday Update

    func updatePayday(_ newPayday: Int) {
        payday = newPayday
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

    // MARK: - Grouped by Cycle

    var groupedByCycle: [CycleGroup] {
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE, d MMM"

        let dayKeyFormatter = DateFormatter()
        dayKeyFormatter.dateFormat = "yyyy-MM-dd"

        // Map each expense to its cycle
        var cycleDict: [String: (cycle: PaydayCycle, expenses: [Expense])] = [:]

        for expense in allExpenses {
            let cycle = PaydayCycle.cycle(containing: expense.date, payday: payday)
            let cycleKey = dayKeyFormatter.string(from: cycle.startDate)

            if cycleDict[cycleKey] == nil {
                cycleDict[cycleKey] = (cycle: cycle, expenses: [])
            }
            cycleDict[cycleKey]!.expenses.append(expense)
        }

        // Sort cycles descending by start date
        let sortedCycles = cycleDict.sorted { $0.value.cycle.startDate > $1.value.cycle.startDate }

        return sortedCycles.map { cycleKey, cycleData in
            // Group by day within cycle
            var dayDict: [String: (title: String, date: Date, expenses: [Expense])] = [:]

            for expense in cycleData.expenses {
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

            return CycleGroup(
                id: cycleKey,
                title: cycleData.cycle.label,
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
