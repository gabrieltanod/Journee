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
    var headCategories: [HeadCategory] = []
    var wallets: [Wallet] = []
    var currentCycle: PaydayCycle
    var showBudgetPrompt: Bool = false
    var showAddExpense: Bool = false

    init(modelContext: ModelContext, payday: Int = 1) {
        self.modelContext = modelContext
        self.payday = payday
        self.currentCycle = PaydayCycle.cycle(containing: Date(), payday: payday)
        loadData()
        seedCategoriesIfNeeded()
        seedDefaultWalletIfNeeded()
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
        loadHeadCategories()
        loadWallets()
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

    private func loadHeadCategories() {
        let descriptor = FetchDescriptor<HeadCategory>(sortBy: [SortDescriptor(\.name)])
        headCategories = (try? modelContext.fetch(descriptor)) ?? []
    }

    private func loadWallets() {
        let descriptor = FetchDescriptor<Wallet>(sortBy: [SortDescriptor(\.name)])
        wallets = (try? modelContext.fetch(descriptor)) ?? []
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

    /// One-time migration: create default "Cash" wallet and assign all unlinked expenses to it.
    private func seedDefaultWalletIfNeeded() {
        let descriptor = FetchDescriptor<Wallet>()
        let existingWallets = (try? modelContext.fetch(descriptor)) ?? []

        let hasCash = existingWallets.contains { $0.name == "Cash" && $0.isDefault }
        guard !hasCash else { return }

        // Create default Cash wallet
        let cashWallet = Wallet(
            name: "Cash",
            emoji: "💵",
            colorHex: "22C55E",
            initialBalance: 0,
            isDefault: true
        )
        modelContext.insert(cashWallet)

        // Assign all existing unlinked expenses to Cash
        let expenseDescriptor = FetchDescriptor<Expense>()
        let allExpenses = (try? modelContext.fetch(expenseDescriptor)) ?? []
        for expense in allExpenses where expense.wallet == nil {
            expense.wallet = cashWallet
        }

        try? modelContext.save()
        loadWallets()
    }

    // MARK: - Computed Properties

    var remainingBudget: Double {
        (currentBudget?.amount ?? 0) - totalSpentForBudget
    }

    /// Total spent counting only budget-included expenses (for budget card)
    /// Excludes transfers and budget-excluded items
    var totalSpentForBudget: Double {
        expenses.filter { $0.transactionType == .expense && !$0.isExcludedFromBudget }.reduce(0) { $0 + $1.amount }
    }

    /// Total spent including ALL non-transfer expenses (for summary row)
    var totalSpent: Double {
        expenses.filter { $0.transactionType == .expense }.reduce(0) { $0 + $1.amount }
    }

    var totalIncome: Double {
        expenses.filter { $0.transactionType == .income }.reduce(0) { $0 + $1.amount }
    }

    var budgetAmount: Double {
        currentBudget?.amount ?? 0
    }

    var spentPercentage: Double {
        guard budgetAmount > 0 else { return 0 }
        return min(totalSpentForBudget / budgetAmount, 1.0)
    }

    var isOverBudget: Bool {
        remainingBudget < 0
    }

    /// Returns a dictionary of [Date (start-of-day): DailyTotal] with separated income/expense
    /// Transfers are excluded from daily totals (they're net-zero)
    var dailyTotals: [Date: DailyTotal] {
        let calendar = Calendar.current
        var totals: [Date: DailyTotal] = [:]
        for expense in expenses where expense.transactionType != .transfer {
            let dayKey = calendar.startOfDay(for: expense.date)
            if totals[dayKey] == nil {
                totals[dayKey] = DailyTotal()
            }
            if expense.transactionType == .income {
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

    func saveExpense(amount: Double, date: Date, note: String?, category: Category?, transactionType: TransactionType = .expense, wallet: Wallet? = nil, destinationWallet: Wallet? = nil, isExcludedFromBudget: Bool = false) {
        let expense = Expense(amount: amount, date: date, note: note, category: category, transactionType: transactionType, wallet: wallet, destinationWallet: destinationWallet, isExcludedFromBudget: isExcludedFromBudget)
        modelContext.insert(expense)
        try? modelContext.save()
        loadData()
    }

    func updateExpense(_ expense: Expense, amount: Double, date: Date, note: String?, category: Category?, transactionType: TransactionType = .expense, wallet: Wallet? = nil, destinationWallet: Wallet? = nil, isExcludedFromBudget: Bool = false) {
        expense.amount = amount
        expense.date = date
        expense.note = note
        expense.category = category
        expense.isIncome = (transactionType == .income)
        expense.isTransfer = (transactionType == .transfer)
        expense.wallet = wallet
        expense.destinationWallet = destinationWallet
        expense.isExcludedFromBudget = isExcludedFromBudget
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

    func addHeadCategory(name: String, icon: String, colorHex: String) {
        let head = HeadCategory(name: name, icon: icon, colorHex: colorHex)
        modelContext.insert(head)
        try? modelContext.save()
        loadHeadCategories()
    }

    /// Sub-categories inherit the parent HeadCategory's color
    func addSubCategory(name: String, icon: String, under headCategory: HeadCategory) {
        let category = Category(name: name, icon: icon, colorHex: headCategory.colorHex)
        category.headCategory = headCategory
        modelContext.insert(category)
        try? modelContext.save()
        loadCategories()
        loadHeadCategories()
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

    func deleteCategory(_ category: Category) {
        modelContext.delete(category)
        try? modelContext.save()
        loadCategories()
        loadHeadCategories()
    }

    func deleteHeadCategory(_ headCategory: HeadCategory) {
        modelContext.delete(headCategory)
        try? modelContext.save()
        loadCategories()
        loadHeadCategories()
    }

    func updateCategory(_ category: Category, name: String, icon: String, headCategory: HeadCategory?) {
        category.name = name
        category.icon = icon
        category.headCategory = headCategory
        if let head = headCategory {
            category.colorHex = head.colorHex
        }
        try? modelContext.save()
        loadCategories()
        loadHeadCategories()
    }

    func updateHeadCategory(_ headCategory: HeadCategory, name: String, icon: String, colorHex: String) {
        headCategory.name = name
        headCategory.icon = icon
        headCategory.colorHex = colorHex
        
        // Update sub-category colors
        let children = categories.filter { $0.headCategory?.id == headCategory.id }
        for child in children {
            child.colorHex = colorHex
        }
        
        try? modelContext.save()
        loadCategories()
        loadHeadCategories()
    }

    /// Returns the default "Cash" wallet
    func defaultWallet() -> Wallet? {
        wallets.first(where: { $0.isDefault })
    }
}
