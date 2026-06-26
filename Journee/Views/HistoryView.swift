import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("payday") private var payday: Int = 1
    @State private var viewModel: HistoryViewModel?

    var body: some View {
        Group {
            if let viewModel {
                HistoryContent(viewModel: viewModel)
            } else {
                Color(.systemBackground)
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = HistoryViewModel(modelContext: modelContext, payday: payday)
            }
        }
        .onChange(of: payday) { _, newValue in
            viewModel?.updatePayday(newValue)
        }
    }
}

// MARK: - Content

struct HistoryContent: View {
    @Bindable var viewModel: HistoryViewModel
    @State private var expenseToEdit: Expense?
    @AppStorage("payday") private var payday: Int = 1
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.allExpenses.isEmpty {
                    emptyState
                } else if viewModel.isSearching {
                    searchResultsList
                } else {
                    groupedList
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .searchable(
                text: $viewModel.searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search by note or category"
            )
            .sheet(item: $expenseToEdit) { expense in
                AddExpenseSheet(
                    viewModel: DashboardViewModel(modelContext: modelContext, payday: payday),
                    existingExpense: expense
                )
                .presentationDetents([.large])
                .onDisappear {
                    viewModel.loadData()
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.primary.opacity(0.12))

            Text("No transactions yet")
                .font(.system(.body, design: .rounded, weight: .medium))
                .foregroundStyle(.secondary)

            Text("Your history will appear here")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.tertiary)

            Spacer()
        }
    }

    // MARK: - Grouped List (Default)

    private var groupedList: some View {
        List {
            ForEach(viewModel.groupedByCycle) { cycleGroup in
                Section {
                    ForEach(cycleGroup.dayGroups) { dayGroup in
                        // Day sub-header
                        Text(dayGroup.title)
                            .font(.system(.caption, design: .rounded, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .textCase(nil)
                            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 4, trailing: 16))
                            .listRowSeparator(.hidden)

                        // Expense rows for this day
                        ForEach(dayGroup.expenses, id: \.id) { expense in
                            Button {
                                expenseToEdit = expense
                            } label: {
                                HistoryRow(expense: expense)
                            }
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        }
                        .onDelete { offsets in
                            for offset in offsets {
                                viewModel.deleteExpense(dayGroup.expenses[offset])
                            }
                        }
                    }
                } header: {
                    Text(cycleGroup.title)
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(.primary)
                        .textCase(nil)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Search Results (Flat)

    private var searchResultsList: some View {
        Group {
            if viewModel.filteredExpenses.isEmpty {
                VStack(spacing: 12) {
                    Spacer()

                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 36))
                        .foregroundStyle(.primary.opacity(0.12))

                    Text("No results for \"\(viewModel.searchText)\"")
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .foregroundStyle(.secondary)

                    Spacer()
                }
            } else {
                List {
                    ForEach(viewModel.filteredExpenses, id: \.id) { expense in
                        Button {
                            expenseToEdit = expense
                        } label: {
                            HistoryRow(expense: expense, showDate: true)
                        }
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }
}

// MARK: - History Row

struct HistoryRow: View {
    let expense: Expense
    var showDate: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            if expense.transactionType == .transfer {
                // Transfer icon
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(Color(hex: "64748B"))
                    )
            } else if let category = expense.category {
                Image(systemName: category.icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(Color(hex: category.colorHex))
                    )
            } else {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(Color.gray.opacity(0.5))
                    )
            }

            // Details
            VStack(alignment: .leading, spacing: 2) {
                if expense.transactionType == .transfer {
                    // Transfer: "Source ➔ Destination"
                    HStack(spacing: 4) {
                        Text(expense.wallet?.name ?? "–")
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                            .foregroundStyle(.primary)

                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.secondary)

                        Text(expense.destinationWallet?.name ?? "–")
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                            .foregroundStyle(.primary)
                    }
                } else {
                    Text(expense.category?.name ?? "Uncategorized")
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(.primary)
                }

                if let note = expense.note, !note.isEmpty {
                    Text(note)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if showDate {
                    Text(formattedDate(expense.date))
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            // Amount
            Text(formattedAmount(expense))
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(amountColor)
        }
        .padding(.vertical, 4)
    }

    private var amountColor: Color {
        switch expense.transactionType {
        case .income: return Color(hex: "22C55E")
        case .transfer: return .secondary
        case .expense: return .primary
        }
    }

    private func formattedAmount(_ expense: Expense) -> String {
        switch expense.transactionType {
        case .income: return "+" + expense.amount.formattedRupiah
        case .transfer: return expense.amount.formattedRupiah
        case .expense: return expense.amount.formattedRupiah
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: date)
    }
}


