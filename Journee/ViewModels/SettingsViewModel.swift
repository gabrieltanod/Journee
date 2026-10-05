import Foundation
import SwiftData
import SwiftUI

@Observable
final class SettingsViewModel {
    private var modelContext: ModelContext

    var exportURL: URL?
    var isExporting: Bool = false
    var importSuccess: Bool = false
    var importSummary: String = ""
    var showImportAlert: Bool = false
    var errorMessage: String?
    var showErrorAlert: Bool = false

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Export

    func exportBackup() {
        do {
            // Fetch all head categories
            let headCategoryDescriptor = FetchDescriptor<HeadCategory>(sortBy: [SortDescriptor(\.name)])
            let headCategories = try modelContext.fetch(headCategoryDescriptor)

            // Fetch all categories
            let categoryDescriptor = FetchDescriptor<Category>(sortBy: [SortDescriptor(\.name)])
            let categories = try modelContext.fetch(categoryDescriptor)

            // Fetch all expenses
            let expenseDescriptor = FetchDescriptor<Expense>(sortBy: [SortDescriptor(\.date, order: .reverse)])
            let expenses = try modelContext.fetch(expenseDescriptor)

            // Fetch all budgets
            let budgetDescriptor = FetchDescriptor<MonthlyBudget>()
            let budgets = try modelContext.fetch(budgetDescriptor)

            // Map to DTOs
            let headCategoryDTOs = headCategories.map { headCat in
                HeadCategoryDTO(
                    id: headCat.id,
                    name: headCat.name,
                    icon: headCat.icon,
                    colorHex: headCat.colorHex
                )
            }

            let categoryDTOs = categories.map { cat in
                CategoryDTO(
                    id: cat.id,
                    name: cat.name,
                    icon: cat.icon,
                    colorHex: cat.colorHex,
                    headCategory: cat.headCategory?.name,
                    headCategoryID: cat.headCategory?.id
                )
            }

            let expenseDTOs = expenses.map { exp in
                ExpenseDTO(
                    id: exp.id,
                    amount: exp.amount,
                    date: exp.date,
                    note: exp.note,
                    categoryName: exp.category?.name,
                    categoryID: exp.category?.id,
                    headCategory: exp.category?.headCategory?.name,
                    isIncome: exp.isIncome,
                    isTransfer: exp.isTransfer,
                    isExcludedFromBudget: exp.isExcludedFromBudget
                )
            }

            let budgetDTOs = budgets.map { b in
                MonthlyBudgetDTO(
                    id: b.id,
                    month: b.month,
                    year: b.year,
                    amount: b.amount
                )
            }

            let backup = BackupData(
                headCategories: headCategoryDTOs,
                categories: categoryDTOs,
                expenses: expenseDTOs,
                budgets: budgetDTOs
            )

            // Encode to JSON
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(backup)

            // Write to temp file
            let fileName = "Journee_Backup_\(formattedExportDate()).json"
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            try data.write(to: tempURL)

            exportURL = tempURL
            isExporting = true
        } catch {
            errorMessage = "Export failed: \(error.localizedDescription)"
            showErrorAlert = true
        }
    }

    private func formattedExportDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    // MARK: - Import

    func importBackup(from url: URL) {
        do {
            // Access security-scoped resource
            let accessing = url.startAccessingSecurityScopedResource()
            defer {
                if accessing { url.stopAccessingSecurityScopedResource() }
            }

            let data = try Data(contentsOf: url)

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let backup = try decoder.decode(BackupData.self, from: data)

            var categoriesAdded = 0
            var expensesAdded = 0
            var budgetsAdded = 0

            // --- Category Merge ---
            let existingCategoryDescriptor = FetchDescriptor<Category>()
            let existingCategories = try modelContext.fetch(existingCategoryDescriptor)
            
            // For v2 files: track categories by ID and create a map for name+head lookup
            // For v1 files: fall back to name-only lookup
            var categoryByID: [UUID: Category] = [:]
            var categoryByNameAndHead: [String: Category] = [:] // Key: "name|head" or "name" if no head
            
            for cat in existingCategories {
                categoryByID[cat.id] = cat
                let key = cat.headCategory?.name != nil ? "\(cat.name)|\(cat.headCategory!.name)" : cat.name
                categoryByNameAndHead[key] = cat
            }

            // Also need to handle head categories
            let existingHeadCategoryDescriptor = FetchDescriptor<HeadCategory>()
            let existingHeadCategories = try modelContext.fetch(existingHeadCategoryDescriptor)
            var headCategoryByID: [UUID: HeadCategory] = [:]
            var headCategoryByName: [String: HeadCategory] = [:]
            
            for headCat in existingHeadCategories {
                headCategoryByID[headCat.id] = headCat
                headCategoryByName[headCat.name] = headCat
            }
            
            // Import head categories from backup (v2 files only)
            if let backupHeadCategories = backup.headCategories {
                for dto in backupHeadCategories {
                    if headCategoryByID[dto.id] == nil && headCategoryByName[dto.name] == nil {
                        let headCat = HeadCategory(name: dto.name, icon: dto.icon, colorHex: dto.colorHex)
                        headCat.id = dto.id
                        modelContext.insert(headCat)
                        headCategoryByID[headCat.id] = headCat
                        headCategoryByName[dto.name] = headCat
                    }
                }
            }

            for dto in backup.categories {
                // Check if we already have this category by ID (for v2 files)
                if categoryByID[dto.id] != nil {
                    // Category already exists with same ID, skip
                    continue
                }
                
                // Try to match by name and head category
                let lookupKey = dto.headCategory != nil ? "\(dto.name)|\(dto.headCategory!)" : dto.name
                
                if categoryByNameAndHead[lookupKey] == nil {
                    // Need to create a new category
                    let newCat = Category(name: dto.name, icon: dto.icon, colorHex: dto.colorHex)
                    
                    // For v2 files: set head category if available
                    if let headCatName = dto.headCategory {
                        // Try to find existing head category by name or ID
                        let headCat: HeadCategory?
                        if let headCatID = dto.headCategoryID, let existingHead = headCategoryByID[headCatID] {
                            headCat = existingHead
                        } else if let existingHead = headCategoryByName[headCatName] {
                            headCat = existingHead
                        } else {
                            // Create new head category
                            headCat = HeadCategory(name: headCatName, icon: "person.fill", colorHex: "000000")
                            modelContext.insert(headCat!)
                            headCategoryByID[headCat!.id] = headCat
                            headCategoryByName[headCatName] = headCat
                        }
                        newCat.headCategory = headCat
                    }
                    
                    // Preserve original UUID
                    newCat.id = dto.id
                    modelContext.insert(newCat)
                    
                    // Update our maps
                    categoryByID[newCat.id] = newCat
                    categoryByNameAndHead[lookupKey] = newCat
                    categoriesAdded += 1
                }
            }

            // --- Expense Merge ---
            let existingExpenseDescriptor = FetchDescriptor<Expense>()
            let existingExpenses = try modelContext.fetch(existingExpenseDescriptor)
            let existingExpenseIDs = Set(existingExpenses.map { $0.id })

            for dto in backup.expenses {
                if !existingExpenseIDs.contains(dto.id) {
                    let linkedCategory: Category?
                    
                    // For v2 files: try to find category by ID first
                    if let categoryID = dto.categoryID, let foundCategory = categoryByID[categoryID] {
                        linkedCategory = foundCategory
                    } else if let categoryName = dto.categoryName {
                        // For v1 files or v2 files without ID: try name+head lookup
                        let lookupKey = dto.headCategory != nil ? "\(categoryName)|\(dto.headCategory!)" : categoryName
                        linkedCategory = categoryByNameAndHead[lookupKey] ?? categoryByNameAndHead[categoryName]
                    } else {
                        linkedCategory = nil
                    }
                    
                    let txType: TransactionType = dto.isTransfer ? .transfer : (dto.isIncome ? .income : .expense)
                    let expense = Expense(
                        amount: dto.amount,
                        date: dto.date,
                        note: dto.note,
                        category: linkedCategory,
                        transactionType: txType,
                        isExcludedFromBudget: dto.isExcludedFromBudget
                    )
                    // Preserve original UUID
                    expense.id = dto.id
                    modelContext.insert(expense)
                    expensesAdded += 1
                }
            }

            // --- Budget Merge ---
            let existingBudgetDescriptor = FetchDescriptor<MonthlyBudget>()
            let existingBudgets = try modelContext.fetch(existingBudgetDescriptor)
            let existingBudgetKeys = Set(existingBudgets.map { "\($0.month)-\($0.year)" })

            for dto in backup.budgets {
                let key = "\(dto.month)-\(dto.year)"
                if !existingBudgetKeys.contains(key) {
                    let budget = MonthlyBudget(month: dto.month, year: dto.year, amount: dto.amount)
                    budget.id = dto.id
                    modelContext.insert(budget)
                    budgetsAdded += 1
                }
            }

            try modelContext.save()

            // Build summary
            var parts: [String] = []
            if categoriesAdded > 0 { parts.append("\(categoriesAdded) categories") }
            if expensesAdded > 0 { parts.append("\(expensesAdded) transactions") }
            if budgetsAdded > 0 { parts.append("\(budgetsAdded) budgets") }

            if parts.isEmpty {
                importSummary = "All data already exists. Nothing new was imported."
            } else {
                importSummary = "Imported \(parts.joined(separator: ", "))."
            }
            importSuccess = true
            showImportAlert = true
        } catch {
            errorMessage = "Import failed: \(error.localizedDescription)"
            showErrorAlert = true
        }
    }
}
