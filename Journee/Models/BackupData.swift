import Foundation

// MARK: - Data Transfer Objects

struct CategoryDTO: Codable {
    let id: UUID
    let name: String
    let icon: String
    let colorHex: String
}

struct ExpenseDTO: Codable {
    let id: UUID
    let amount: Double
    let date: Date
    let note: String?
    let categoryName: String?
    let isIncome: Bool
}

struct MonthlyBudgetDTO: Codable {
    let id: UUID
    let month: Int
    let year: Int
    let amount: Double
}

struct BackupData: Codable {
    let version: Int
    let exportDate: Date
    let categories: [CategoryDTO]
    let expenses: [ExpenseDTO]
    let budgets: [MonthlyBudgetDTO]

    init(categories: [CategoryDTO], expenses: [ExpenseDTO], budgets: [MonthlyBudgetDTO]) {
        self.version = 1
        self.exportDate = Date()
        self.categories = categories
        self.expenses = expenses
        self.budgets = budgets
    }
}
