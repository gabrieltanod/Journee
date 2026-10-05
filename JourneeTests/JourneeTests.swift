import Testing
import SwiftData
@testable import Journee

struct BackupTests {
    
    // MARK: - Test Setup
    
    func createTestModelContainer() throws -> ModelContainer {
        let schema = Schema([
            Expense.self,
            Category.self,
            HeadCategory.self,
            Wallet.self,
            MonthlyBudget.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [modelConfiguration])
    }
    
    // MARK: - Test 1: V2 Export Round Trip
    
    @Test func testV2ExportRoundTrip() async throws {
        // Create test container
        let container = try createTestModelContainer()
        let modelContext = container.mainContext
        
        // Create test data
        let headCategory1 = HeadCategory(name: "Self", icon: "person.fill", colorHex: "FF6B6B")
        let headCategory2 = HeadCategory(name: "Pacarans", icon: "heart.fill", colorHex: "F472B6")
        
        let category1 = Category(name: "Food", icon: "fork.knife", colorHex: "4ECDC4")
        category1.headCategory = headCategory1
        
        let category2 = Category(name: "Food", icon: "fork.knife", colorHex: "A78BFA")
        category2.headCategory = headCategory2
        
        let expense1 = Expense(
            amount: 25.0,
            date: Date(),
            note: "Lunch",
            category: category1,
            transactionType: .expense
        )
        
        let expense2 = Expense(
            amount: 15.0,
            date: Date().addingTimeInterval(-86400), // Yesterday
            note: "Dinner date",
            category: category2,
            transactionType: .expense
        )
        
        // Insert test data
        modelContext.insert(headCategory1)
        modelContext.insert(headCategory2)
        modelContext.insert(category1)
        modelContext.insert(category2)
        modelContext.insert(expense1)
        modelContext.insert(expense2)
        try modelContext.save()
        
        // Create view model and export
        let viewModel = SettingsViewModel(modelContext: modelContext)
        viewModel.exportBackup()
        
        // Verify export was successful
        #expect(viewModel.exportURL != nil)
        #expect(viewModel.isExporting == true)
        
        // Read the exported file
        guard let exportURL = viewModel.exportURL else {
            Issue.record("Export URL is nil")
            return
        }
        
        let data = try Data(contentsOf: exportURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backup = try decoder.decode(BackupData.self, from: data)
        
        // Verify version is 2
        #expect(backup.version == 2)
        
        // Verify head categories are included
        #expect(backup.headCategories?.count == 2)
        
        // Verify categories include head category info
        let foodCategories = backup.categories.filter { $0.name == "Food" }
        #expect(foodCategories.count == 2)
        
        // Verify each food category has correct head category
        let selfFood = foodCategories.first { $0.headCategory == "Self" }
        let pacaransFood = foodCategories.first { $0.headCategory == "Pacarans" }
        #expect(selfFood != nil)
        #expect(pacaransFood != nil)
        
        // Verify expenses have categoryID and headCategory
        #expect(backup.expenses.count == 2)
        for expense in backup.expenses {
            #expect(expense.categoryID != nil)
            #expect(expense.headCategory != nil)
        }
        
        // Clean up
        try FileManager.default.removeItem(at: exportURL)
    }
    
    // MARK: - Test 2: Import V1 File (Backward Compatibility)
    
    @Test func testImportV1File() async throws {
        // Create a v1 backup JSON (simulating old format)
        let v1BackupJSON = """
        {
          "version": 1,
          "exportDate": "2024-01-01T12:00:00Z",
          "categories": [
            {
              "id": "\(UUID().uuidString)",
              "name": "Food",
              "icon": "fork.knife",
              "colorHex": "FF6B6B"
            },
            {
              "id": "\(UUID().uuidString)",
              "name": "Transport",
              "icon": "car.fill",
              "colorHex": "4ECDC4"
            }
          ],
          "expenses": [
            {
              "id": "\(UUID().uuidString)",
              "amount": 50.0,
              "date": "2024-01-01T10:00:00Z",
              "note": "Groceries",
              "categoryName": "Food",
              "isIncome": false,
              "isTransfer": false,
              "isExcludedFromBudget": false
            }
          ],
          "budgets": []
        }
        """
        
        // Write to temp file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("v1_backup.json")
        try v1BackupJSON.data(using: .utf8)?.write(to: tempURL)
        
        // Create test container
        let container = try createTestModelContainer()
        let modelContext = container.mainContext
        
        // Create view model and import
        let viewModel = SettingsViewModel(modelContext: modelContext)
        viewModel.importBackup(from: tempURL)
        
        // Verify import was successful
        #expect(viewModel.importSuccess == true)
        
        // Verify categories were imported (without head categories)
        let categoryDescriptor = FetchDescriptor<Category>()
        let importedCategories = try modelContext.fetch(categoryDescriptor)
        #expect(importedCategories.count == 2)
        
        // Verify expense was imported
        let expenseDescriptor = FetchDescriptor<Expense>()
        let importedExpenses = try modelContext.fetch(expenseDescriptor)
        #expect(importedExpenses.count == 1)
        
        // Verify expense has category link
        let importedExpense = importedExpenses.first
        #expect(importedExpense?.category?.name == "Food")
        
        // Clean up
        try FileManager.default.removeItem(at: tempURL)
    }
    
    // MARK: - Test 3: Duplicate Category Names Under Different Heads
    
    @Test func testDuplicateCategoryNamesDifferentHeads() async throws {
        // Create test container
        let container = try createTestModelContainer()
        let modelContext = container.mainContext
        
        // Create view model
        let viewModel = SettingsViewModel(modelContext: modelContext)
        
        // Create test data with duplicate category names under different heads
        let headCategory1 = HeadCategory(name: "Self", icon: "person.fill", colorHex: "FF6B6B")
        let headCategory2 = HeadCategory(name: "Pacarans", icon: "heart.fill", colorHex: "F472B6")
        
        let category1 = Category(name: "Food", icon: "fork.knife", colorHex: "4ECDC4")
        category1.headCategory = headCategory1
        
        let category2 = Category(name: "Food", icon: "fork.knife", colorHex: "A78BFA")
        category2.headCategory = headCategory2
        
        let category3 = Category(name: "Transport", icon: "car.fill", colorHex: "22C55E")
        category3.headCategory = headCategory1
        
        // Insert test data
        modelContext.insert(headCategory1)
        modelContext.insert(headCategory2)
        modelContext.insert(category1)
        modelContext.insert(category2)
        modelContext.insert(category3)
        try modelContext.save()
        
        // Export backup
        viewModel.exportBackup()
        
        // Verify export was successful
        #expect(viewModel.exportURL != nil)
        
        // Clear the container
        for category in try modelContext.fetch(FetchDescriptor<Category>()) {
            modelContext.delete(category)
        }
        for headCat in try modelContext.fetch(FetchDescriptor<HeadCategory>()) {
            modelContext.delete(headCat)
        }
        try modelContext.save()
        
        // Import the backup
        guard let exportURL = viewModel.exportURL else {
            Issue.record("Export URL is nil")
            return
        }
        
        viewModel.importBackup(from: exportURL)
        
        // Verify import was successful
        #expect(viewModel.importSuccess == true)
        
        // Verify both head categories were imported
        let headCatDescriptor = FetchDescriptor<HeadCategory>()
        let importedHeads = try modelContext.fetch(headCatDescriptor)
        #expect(importedHeads.count == 2)
        
        // Verify all three categories were imported
        let catDescriptor = FetchDescriptor<Category>()
        let importedCategories = try modelContext.fetch(catDescriptor)
        #expect(importedCategories.count == 3)
        
        // Verify duplicate category names are correctly linked to their head categories
        let selfFoodCategories = importedCategories.filter { $0.name == "Food" && $0.headCategory?.name == "Self" }
        let pacaransFoodCategories = importedCategories.filter { $0.name == "Food" && $0.headCategory?.name == "Pacarans" }
        
        #expect(selfFoodCategories.count == 1)
        #expect(pacaransFoodCategories.count == 1)
        
        // Clean up
        try FileManager.default.removeItem(at: exportURL)
    }
    
    // MARK: - Test 4: Export With Null/Empty Values
    
    @Test func testExportWithNullValues() async throws {
        // Create test container
        let container = try createTestModelContainer()
        let modelContext = container.mainContext
        
        // Create test data with null/empty values
        let expense1 = Expense(
            amount: 100.0,
            date: Date(),
            note: nil,  // nil note
            category: nil,  // no category (transfer)
            transactionType: .transfer
        )
        
        let expense2 = Expense(
            amount: 50.0,
            date: Date(),
            note: "",
            category: nil,
            transactionType: .income
        )
        
        // Insert test data
        modelContext.insert(expense1)
        modelContext.insert(expense2)
        try modelContext.save()
        
        // Create view model and export
        let viewModel = SettingsViewModel(modelContext: modelContext)
        viewModel.exportBackup()
        
        // Verify export was successful
        #expect(viewModel.exportURL != nil)
        
        // Read the exported file
        guard let exportURL = viewModel.exportURL else {
            Issue.record("Export URL is nil")
            return
        }
        
        let data = try Data(contentsOf: exportURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backup = try decoder.decode(BackupData.self, from: data)
        
        // Verify expenses have null values encoded safely
        #expect(backup.expenses.count == 2)
        
        for expense in backup.expenses {
            #expect(expense.categoryName == nil)
            #expect(expense.categoryID == nil)
            #expect(expense.headCategory == nil)
        }
        
        // Verify JSON can be encoded/decoded without errors
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let reencodedData = try encoder.encode(backup)
        #expect(reencodedData.count > 0)
        
        // Clean up
        try FileManager.default.removeItem(at: exportURL)
    }
}

struct JourneeTests {

    @Test func example() async throws {
        // Placeholder test
    }
}
