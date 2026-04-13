import Foundation
import SwiftData
import SwiftUI

// MARK: - Daily Total

struct DailyTotal {
    var expense: Double = 0
    var income: Double = 0
}

@Observable
final class DashboardViewModel {
    private var modelContext: ModelContext
    private var payday: Int

    var currentBudget: MonthlyBudget?
    var expenses: [Expense] = []
    var categories: [Category] = []
    var currentCycle: PaydayCycle
    var showBudgetPrompt: Bool = false
    var showAddExpense: Bool = false

    init(modelContext: ModelContext, payday: Int = 1) {
        self.modelContext = modelContext
        self.payday = payday
        self.currentCycle = PaydayCycle.cycle(containing: Date(), payday: payday)
        loadData()
        seedCategoriesIfNeeded()
    }

    // MARK: - Payday Update

    func updatePayday(_ newPayday: Int) {
        payday = newPayday
        currentCycle = PaydayCycle.cycle(containing: currentCycle.startDate, payday: newPayday)
        loadData()
    }

    // MARK: - Data Loading

    func loadData() {
        loadBudget()
        loadExpenses()
        loadCategories()
    }

    private func loadBudget() {
        let month = currentCycle.startMonth
        let year = currentCycle.startYear

        let descriptor = FetchDescriptor<MonthlyBudget>(
            predicate: #Predicate { $0.month == month && $0.year == year }
        )
        currentBudget = try? modelContext.fetch(descriptor).first
    }

    private func loadExpenses() {
        let start = currentCycle.fetchStartDate
        let end = currentCycle.fetchEndDate

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

    var hasBudget: Bool {
        currentBudget != nil
    }

    private func seedCategoriesIfNeeded() {
        let descriptor = FetchDescriptor<Category>()
        let existing = (try? modelContext.fetch(descriptor)) ?? []

        if existing.isEmpty {
            for cat in Category.defaults {
                modelContext.insert(cat)
            }
            try? modelContext.save()
            loadCategories()
        } else {
            let hasIncome = existing.contains { $0.name == "Income" }
            if !hasIncome {
                let incomeCat = Category(name: "Income", icon: "banknote.fill", colorHex: "22C55E")
                modelContext.insert(incomeCat)
                try? modelContext.save()
                loadCategories()
            }
        }
    }

    // MARK: - Computed Properties

    var remainingBudget: Double {
        (currentBudget?.amount ?? 0) - totalSpent
    }

    var totalSpent: Double {
        expenses.filter { !$0.isIncome }.reduce(0) { $0 + $1.amount }
    }

    var totalIncome: Double {
        expenses.filter { $0.isIncome }.reduce(0) { $0 + $1.amount }
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

    /// Returns a dictionary of [Date (start-of-day): DailyTotal] with separated income/expense
    var dailyTotals: [Date: DailyTotal] {
        let calendar = Calendar.current
        var totals: [Date: DailyTotal] = [:]
        for expense in expenses {
            let dayKey = calendar.startOfDay(for: expense.date)
            if totals[dayKey] == nil {
                totals[dayKey] = DailyTotal()
            }
            if expense.isIncome {
                totals[dayKey]!.income += expense.amount
            } else {
                totals[dayKey]!.expense += expense.amount
            }
        }
        return totals
    }

    var cycleLabel: String {
        currentCycle.label
    }

    var isCurrentCycle: Bool {
        currentCycle.isCurrentCycle
    }

    // MARK: - Cycle Navigation

    func nextCycle() {
        currentCycle = currentCycle.next(payday: payday)
        loadData()
    }

    func previousCycle() {
        currentCycle = currentCycle.previous(payday: payday)
        loadData()
    }

    // MARK: - Budget

    func saveBudget(amount: Double) {
        let month = currentCycle.startMonth
        let year = currentCycle.startYear

        if let existing = currentBudget {
            existing.amount = amount
        } else {
            let budget = MonthlyBudget(month: month, year: year, amount: amount)
            modelContext.insert(budget)
        }
        try? modelContext.save()
        showBudgetPrompt = false
        loadData()
    }

    // MARK: - Expenses

    func saveExpense(amount: Double, date: Date, note: String?, category: Category?, isIncome: Bool = false) {
        let expense = Expense(amount: amount, date: date, note: note, category: category, isIncome: isIncome)
        modelContext.insert(expense)
        try? modelContext.save()
        loadData()
    }

    func updateExpense(_ expense: Expense, amount: Double, date: Date, note: String?, category: Category?, isIncome: Bool = false) {
        expense.amount = amount
        expense.date = date
        expense.note = note
        expense.category = category
        expense.isIncome = isIncome
        try? modelContext.save()
        loadData()
    }

    func deleteExpense(_ expense: Expense) {
        modelContext.delete(expense)
        try? modelContext.save()
        loadData()
    }

    func expenses(for date: Date) -> [Expense] {
        let calendar = Calendar.current
        return expenses.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }

    func addCategory(name: String, icon: String, colorHex: String) {
        let category = Category(name: name, icon: icon, colorHex: colorHex)
        modelContext.insert(category)
        try? modelContext.save()
        loadCategories()
    }

    /// Returns the "Income" category, creating it if needed
    func incomeCategory() -> Category? {
        if let existing = categories.first(where: { $0.name == "Income" }) {
            return existing
        }
        let incomeCat = Category(name: "Income", icon: "banknote.fill", colorHex: "22C55E")
        modelContext.insert(incomeCat)
        try? modelContext.save()
        loadCategories()
        return categories.first(where: { $0.name == "Income" })
    }
}
