import Foundation

// MARK: - Data Transfer Objects

struct HeadCategoryDTO: Codable {
    let id: UUID
    let name: String
    let icon: String
    let colorHex: String
}

struct CategoryDTO: Codable {
    let id: UUID
    let name: String
    let icon: String
    let colorHex: String
    let headCategory: String?
    let headCategoryID: UUID?

    /// Backward-compatible init with defaults for new fields
    init(id: UUID, name: String, icon: String, colorHex: String, headCategory: String? = nil, headCategoryID: UUID? = nil) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.headCategory = headCategory
        self.headCategoryID = headCategoryID
    }

    /// Codable: decode missing fields with defaults for backward-compat with older backups
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        icon = try container.decode(String.self, forKey: .icon)
        colorHex = try container.decode(String.self, forKey: .colorHex)
        headCategory = try container.decodeIfPresent(String.self, forKey: .headCategory)
        headCategoryID = try container.decodeIfPresent(UUID.self, forKey: .headCategoryID)
    }
}

struct ExpenseDTO: Codable {
    let id: UUID
    let amount: Double
    let date: Date
    let note: String?
    let categoryName: String?
    let categoryID: UUID?
    let headCategory: String?
    let isIncome: Bool
    let isTransfer: Bool
    let isExcludedFromBudget: Bool

    /// Backward-compatible init with defaults for new fields
    init(id: UUID, amount: Double, date: Date, note: String?, categoryName: String?, categoryID: UUID? = nil, headCategory: String? = nil, isIncome: Bool, isTransfer: Bool = false, isExcludedFromBudget: Bool = false) {
        self.id = id
        self.amount = amount
        self.date = date
        self.note = note
        self.categoryName = categoryName
        self.categoryID = categoryID
        self.headCategory = headCategory
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
        categoryID = try container.decodeIfPresent(UUID.self, forKey: .categoryID)
        headCategory = try container.decodeIfPresent(String.self, forKey: .headCategory)
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
    let headCategories: [HeadCategoryDTO]?
    let categories: [CategoryDTO]
    let expenses: [ExpenseDTO]
    let budgets: [MonthlyBudgetDTO]

    init(headCategories: [HeadCategoryDTO]? = nil, categories: [CategoryDTO], expenses: [ExpenseDTO], budgets: [MonthlyBudgetDTO]) {
        self.version = 2
        self.exportDate = Date()
        self.headCategories = headCategories
        self.categories = categories
        self.expenses = expenses
        self.budgets = budgets
    }
    
    /// Codable: decode with backward compatibility for version 1 files
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decode(Int.self, forKey: .version)
        exportDate = try container.decode(Date.self, forKey: .exportDate)
        headCategories = try container.decodeIfPresent([HeadCategoryDTO].self, forKey: .headCategories)
        categories = try container.decode([CategoryDTO].self, forKey: .categories)
        expenses = try container.decode([ExpenseDTO].self, forKey: .expenses)
        budgets = try container.decode([MonthlyBudgetDTO].self, forKey: .budgets)
    }
}
