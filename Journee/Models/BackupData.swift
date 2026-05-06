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
    let isTransfer: Bool
    let isExcludedFromBudget: Bool

    /// Backward-compatible init with defaults for new fields
    init(id: UUID, amount: Double, date: Date, note: String?, categoryName: String?, isIncome: Bool, isTransfer: Bool = false, isExcludedFromBudget: Bool = false) {
        self.id = id
        self.amount = amount
        self.date = date
        self.note = note
        self.categoryName = categoryName
        self.isIncome = isIncome
        self.isTransfer = isTransfer
        self.isExcludedFromBudget = isExcludedFromBudget
    }

    /// Codable: decode missing fields with defaults for backward-compat with older backups
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        amount = try container.decode(Double.self, forKey: .amount)
        date = try container.decode(Date.self, forKey: .date)
        note = try container.decodeIfPresent(String.self, forKey: .note)
        categoryName = try container.decodeIfPresent(String.self, forKey: .categoryName)
        isIncome = try container.decode(Bool.self, forKey: .isIncome)
        isTransfer = try container.decodeIfPresent(Bool.self, forKey: .isTransfer) ?? false
        isExcludedFromBudget = try container.decodeIfPresent(Bool.self, forKey: .isExcludedFromBudget) ?? false
    }
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
