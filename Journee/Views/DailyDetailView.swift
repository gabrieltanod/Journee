import SwiftUI

struct DailyDetailView: View {
    @Bindable var viewModel: DashboardViewModel
    let date: Date

    @State private var showAddSheet: Bool = false
    @State private var expenseToEdit: Expense?

    private var dayExpenses: [Expense] {
        viewModel.expenses(for: date)
    }

    var body: some View {
        Group {
            if dayExpenses.isEmpty {
                emptyState
            } else {
                expenseList
            }
        }
        .navigationTitle(formattedDate)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddExpenseSheet(viewModel: viewModel, prefilledDate: date)
                .presentationDetents([.large])
        }
        .sheet(item: $expenseToEdit) { expense in
            AddExpenseSheet(viewModel: viewModel, existingExpense: expense)
                .presentationDetents([.large])
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundStyle(.primary.opacity(0.12))

            Text("No entries yet")
                .font(.system(.body, design: .rounded, weight: .medium))
                .foregroundStyle(.secondary)

            Button {
                showAddSheet = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Add Entry")
                        .font(.system(.body, design: .rounded, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
//                        .fill(Color(hex: "1C1C1E"))
                )
            }

            Spacer()
        }
    }

    // MARK: - Expense List

    private var expenseList: some View {
        List {
            ForEach(dayExpenses, id: \.id) { expense in
                Button {
                    expenseToEdit = expense
                } label: {
                    ExpenseRow(expense: expense)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
            .onDelete(perform: deleteExpenses)
        }
        .listStyle(.plain)
    }

    // MARK: - Delete

    private func deleteExpenses(at offsets: IndexSet) {
        for index in offsets {
            let expense = dayExpenses[index]
            viewModel.deleteExpense(expense)
        }
    }

    // MARK: - Formatting

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
}

// MARK: - Expense Row

struct ExpenseRow: View {
    let expense: Expense

    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            if let category = expense.category {
                Image(systemName: category.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(hex: category.colorHex))
                    )
            } else {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.gray.opacity(0.5))
                    )
            }

            // Details
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(expense.category?.name ?? "Uncategorized")
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(.primary)

                    if expense.isIncome {
                        Text("INCOME")
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color(hex: "22C55E")))
                    }
                }

                if let note = expense.note, !note.isEmpty {
                    Text(note)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Amount — green for income, default for expense
            Text(formattedCurrency(expense.amount))
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(expense.isIncome ? Color(hex: "22C55E") : .primary)
        }
        .padding(.vertical, 4)
    }

    private func formattedCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "Rp"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "Rp0"
    }
}
