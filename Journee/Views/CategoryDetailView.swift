import SwiftUI
import SwiftData

struct CategoryDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("payday") private var payday: Int = 1

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
            AddExpenseSheet(
                viewModel: DashboardViewModel(modelContext: modelContext, payday: payday),
                existingExpense: expense
            )
            .presentationDetents([.large])
            .onDisappear {
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
            expenses = allExpenses.filter { $0.transactionType == .income }
        } else if isUncategorized {
            expenses = allExpenses.filter { $0.category == nil && $0.transactionType == .expense }
        } else {
            expenses = allExpenses.filter { $0.category?.name == categoryName && $0.transactionType == .expense }
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
        return value.formattedRupiah
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
                .foregroundStyle(expense.transactionType == .income ? Color(hex: "22C55E") : .primary)
        }
        .padding(.vertical, 4)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: date)
    }

    private func formattedCurrency(_ value: Double) -> String {
        return value.formattedRupiah
    }
}


