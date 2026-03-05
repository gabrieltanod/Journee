import Foundation
import SwiftData
import SwiftUI

@Observable
final class DashboardViewModel {
    private var modelContext: ModelContext

    var currentBudget: MonthlyBudget?
    var expenses: [Expense] = []
    var categories: [Category] = []
    var selectedMonth: Date = Date()
    var showBudgetPrompt: Bool = false
    var showAddExpense: Bool = false

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadData()
        seedCategoriesIfNeeded()
    }

    // MARK: - Data Loading

    func loadData() {
        loadBudget()
        loadExpenses()
        loadCategories()
        checkBudgetPrompt()
    }

    private func loadBudget() {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: selectedMonth)
        let year = calendar.component(.year, from: selectedMonth)

        let descriptor = FetchDescriptor<MonthlyBudget>(
            predicate: #Predicate { $0.month == month && $0.year == year }
        )
        currentBudget = try? modelContext.fetch(descriptor).first
    }

    private func loadExpenses() {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month], from: selectedMonth)
        guard let startOfMonth = calendar.date(from: comps),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)
        else { return }

        let start = calendar.startOfDay(for: startOfMonth)
        let end = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: endOfMonth) ?? endOfMonth

        let descriptor = FetchDescriptor<Expense>(
            predicate: #Predicate { $0.date >= start && $0.date <= end },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        expenses = (try? modelContext.fetch(descriptor)) ?? []
    }

    private func loadCategories() {
        let descriptor = FetchDescriptor<Category>(sortBy: [SortDescriptor(\.name)])
        categories = (try? modelContext.fetch(descriptor)) ?? []
    }

    private func checkBudgetPrompt() {
        showBudgetPrompt = currentBudget == nil
    }

    private func seedCategoriesIfNeeded() {
        let descriptor = FetchDescriptor<Category>()
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0
        if count == 0 {
            for cat in Category.defaults {
                modelContext.insert(cat)
            }
            try? modelContext.save()
            loadCategories()
        }
    }

    // MARK: - Computed Properties

    var remainingBudget: Double {
        let totalSpent = expenses.reduce(0) { $0 + $1.amount }
        return (currentBudget?.amount ?? 0) - totalSpent
    }

    var totalSpent: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    var budgetAmount: Double {
        currentBudget?.amount ?? 0
    }

    var spentPercentage: Double {
        guard budgetAmount > 0 else { return 0 }
        return min(totalSpent / budgetAmount, 1.0)
    }

    var isOverBudget: Bool {
        remainingBudget < 0
    }

    /// Returns a dictionary of [dayOfMonth: totalSpent]
    var dailyTotals: [Int: Double] {
        let calendar = Calendar.current
        var totals: [Int: Double] = [:]
        for expense in expenses {
            let day = calendar.component(.day, from: expense.date)
            totals[day, default: 0] += expense.amount
        }
        return totals
    }

    var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedMonth)
    }

    var isCurrentMonth: Bool {
        let calendar = Calendar.current
        return calendar.isDate(selectedMonth, equalTo: Date(), toGranularity: .month)
    }

    // MARK: - Month Navigation

    func nextMonth() {
        if let newDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) {
            selectedMonth = newDate
            loadData()
        }
    }

    func previousMonth() {
        if let newDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) {
            selectedMonth = newDate
            loadData()
        }
    }

    // MARK: - Budget

    func saveBudget(amount: Double) {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: selectedMonth)
        let year = calendar.component(.year, from: selectedMonth)

        let budget = MonthlyBudget(month: month, year: year, amount: amount)
        modelContext.insert(budget)
        try? modelContext.save()
        loadData()
    }

    // MARK: - Expenses

    func saveExpense(amount: Double, date: Date, note: String?, category: Category?) {
        let expense = Expense(amount: amount, date: date, note: note, category: category)
        modelContext.insert(expense)
        try? modelContext.save()
        loadData()
    }

    func addCategory(name: String, icon: String, colorHex: String) {
        let category = Category(name: name, icon: icon, colorHex: colorHex)
        modelContext.insert(category)
        try? modelContext.save()
        loadCategories()
    }
}
