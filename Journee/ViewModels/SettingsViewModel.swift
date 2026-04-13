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
            let categoryDTOs = categories.map { cat in
                CategoryDTO(
                    id: cat.id,
                    name: cat.name,
                    icon: cat.icon,
                    colorHex: cat.colorHex
                )
            }

            let expenseDTOs = expenses.map { exp in
                ExpenseDTO(
                    id: exp.id,
                    amount: exp.amount,
                    date: exp.date,
                    note: exp.note,
                    categoryName: exp.category?.name,
                    isIncome: exp.isIncome
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
            var categoryMap: [String: Category] = [:]
            for cat in existingCategories {
                categoryMap[cat.name] = cat
            }

            for dto in backup.categories {
                if categoryMap[dto.name] == nil {
                    let newCat = Category(name: dto.name, icon: dto.icon, colorHex: dto.colorHex)
                    modelContext.insert(newCat)
                    categoryMap[dto.name] = newCat
                    categoriesAdded += 1
                }
            }

            // --- Expense Merge ---
            let existingExpenseDescriptor = FetchDescriptor<Expense>()
            let existingExpenses = try modelContext.fetch(existingExpenseDescriptor)
            let existingExpenseIDs = Set(existingExpenses.map { $0.id })

            for dto in backup.expenses {
                if !existingExpenseIDs.contains(dto.id) {
                    let linkedCategory = dto.categoryName.flatMap { categoryMap[$0] }
                    let expense = Expense(
                        amount: dto.amount,
                        date: dto.date,
                        note: dto.note,
                        category: linkedCategory,
                        isIncome: dto.isIncome
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
