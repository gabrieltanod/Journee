import SwiftUI
import SwiftData

struct CategoryDetailView: View {
    @Environment(\.modelContext) private var modelContext

    let categoryName: String
    let categoryIcon: String
    let categoryColorHex: String
    let cycle: PaydayCycle

    @State private var expenses: [Expense] = []
    @State private var expenseToEdit: Expense?

    private var isUncategorized: Bool {
        categoryName == "Uncategorized"
    }

    private var isIncomeCategory: Bool {
        categoryName == "Income"
    }

    var body: some View {
        Group {
            if expenses.isEmpty {
                emptyState
            } else {
                expenseList
            }
        }
        .navigationTitle(categoryName)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $expenseToEdit) { expense in
            CategoryExpenseEditSheet(expense: expense) {
                loadExpenses()
            }
        }
        .onAppear {
            loadExpenses()
        }
    }

    // MARK: - Data Loading

    private func loadExpenses() {
        let start = cycle.fetchStartDate
        let end = cycle.fetchEndDate

        let descriptor = FetchDescriptor<Expense>(
            predicate: #Predicate { $0.date >= start && $0.date <= end },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let allExpenses = (try? modelContext.fetch(descriptor)) ?? []

        if isIncomeCategory {
            expenses = allExpenses.filter { $0.isIncome }
        } else if isUncategorized {
            expenses = allExpenses.filter { $0.category == nil && !$0.isIncome }
        } else {
            expenses = allExpenses.filter { $0.category?.name == categoryName && !$0.isIncome }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: categoryIcon)
                .font(.system(size: 40))
                .foregroundStyle(Color(hex: categoryColorHex).opacity(0.3))

            Text(isIncomeCategory ? "No income" : "No expenses")
                .font(.system(.body, design: .rounded, weight: .medium))
                .foregroundStyle(.secondary)

            Spacer()
        }
    }

    // MARK: - Expense List

    private var expenseList: some View {
        List {
            // Summary header
            Section {
                HStack(spacing: 12) {
                    Image(systemName: categoryIcon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color(hex: categoryColorHex))
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(expenses.count) \(isIncomeCategory ? "entry" : "expense")\(expenses.count == 1 ? "" : (isIncomeCategory ? "" : "s"))")
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                            .foregroundStyle(.secondary)

                        Text(formattedCurrency(expenses.reduce(0) { $0 + $1.amount }))
                            .font(.system(.title3, design: .rounded, weight: .bold))
                            .foregroundStyle(isIncomeCategory ? Color(hex: "22C55E") : .primary)
                    }

                    Spacer()
                }
                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
            }

            // Expense rows
            Section {
                ForEach(expenses, id: \.id) { expense in
                    Button {
                        expenseToEdit = expense
                    } label: {
                        CategoryExpenseRow(expense: expense)
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
                .onDelete(perform: deleteExpenses)
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Delete

    private func deleteExpenses(at offsets: IndexSet) {
        for index in offsets {
            let expense = expenses[index]
            modelContext.delete(expense)
        }
        try? modelContext.save()
        loadExpenses()
    }

    // MARK: - Helpers

    private func formattedCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "Rp"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "Rp0"
    }
}

// MARK: - Expense Row

struct CategoryExpenseRow: View {
    let expense: Expense

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                if let note = expense.note, !note.isEmpty {
                    Text(note)
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(.primary)
                } else {
                    Text("No note")
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                Text(formattedDate(expense.date))
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(formattedCurrency(expense.amount))
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(expense.isIncome ? Color(hex: "22C55E") : .primary)
        }
        .padding(.vertical, 4)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: date)
    }

    private func formattedCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "Rp"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "Rp0"
    }
}

// MARK: - Edit Sheet (lightweight, self-contained)

struct CategoryExpenseEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let expense: Expense
    var onSave: () -> Void

    @State private var amountText: String = ""
    @State private var note: String = ""
    @State private var selectedDate: Date = Date()
    @State private var selectedCategory: Category?
    @State private var categories: [Category] = []
    @State private var isIncome: Bool = false

    private var isValid: Bool {
        guard let val = Double(amountText), val > 0 else { return false }
        return true
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Type picker (Income / Expense)
                    Picker("Type", selection: $isIncome) {
                        Text("Expense").tag(false)
                        Text("Income").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: isIncome) { _, newValue in
                        if newValue {
                            selectedCategory = categories.first(where: { $0.name == "Income" })
                        } else {
                            if selectedCategory?.name == "Income" {
                                selectedCategory = nil
                            }
                        }
                    }

                    // Amount
                    VStack(spacing: 8) {
                        Text("Amount")
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("Rp")
                                .font(.system(.title3, design: .rounded, weight: .medium))
                                .foregroundStyle(.secondary)

                            TextField("0", text: $amountText)
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .keyboardType(.numberPad)
                        }

                        Rectangle()
                            .fill(Color.primary.opacity(0.08))
                            .frame(height: 1)
                    }

                    // Category (hidden when Income)
                    if !isIncome {
                        VStack(spacing: 8) {
                            Text("Category")
                                .font(.system(.caption, design: .rounded, weight: .medium))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(categories.filter { $0.name != "Income" }, id: \.id) { category in
                                        CategoryChip(
                                            category: category,
                                            isSelected: selectedCategory?.id == category.id
                                        )
                                        .onTapGesture {
                                            withAnimation(.easeInOut(duration: 0.15)) {
                                                selectedCategory = category
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        // Show income category indicator
                        HStack(spacing: 8) {
                            Image(systemName: "banknote.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "22C55E"))

                            Text("Income")
                                .font(.system(.subheadline, design: .rounded, weight: .medium))
                                .foregroundStyle(.primary)

                            Spacer()

                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(Color(hex: "22C55E"))
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color(hex: "22C55E").opacity(0.1))
                        )
                    }

                    // Note
                    VStack(spacing: 8) {
                        Text("Note")
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        TextField("What's this for?", text: $note)
                            .font(.system(.body, design: .rounded))
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color(.tertiarySystemFill))
                            )
                    }

                    // Date
                    VStack(spacing: 8) {
                        Text("Date")
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        DatePicker("", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(20)
            }
            .navigationTitle(isIncome ? "Edit Income" : "Edit Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .font(.system(.body, design: .rounded))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .disabled(!isValid)
                }
            }
            .onAppear {
                amountText = String(format: "%.0f", expense.amount)
                note = expense.note ?? ""
                selectedDate = expense.date
                selectedCategory = expense.category
                isIncome = expense.isIncome
                loadCategories()
            }
        }
    }

    private func loadCategories() {
        let descriptor = FetchDescriptor<Category>(sortBy: [SortDescriptor(\.name)])
        categories = (try? modelContext.fetch(descriptor)) ?? []
    }

    private func saveChanges() {
        guard let amount = Double(amountText) else { return }
        expense.amount = amount
        expense.date = selectedDate
        expense.note = note.isEmpty ? nil : note
        expense.category = selectedCategory
        expense.isIncome = isIncome
        try? modelContext.save()
        onSave()
        dismiss()
    }
}
