import SwiftUI
import SwiftData

struct WalletDetailView: View {
    @Bindable var viewModel: WalletsViewModel
    @Bindable var wallet: Wallet
    @Environment(\.modelContext) private var modelContext
    @AppStorage("payday") private var payday: Int = 1

    @State private var expenseToEdit: Expense?
    @State private var showDeleteAlert: Bool = false

    @Environment(\.dismiss) private var dismiss

    private var sortedExpenses: [Expense] {
        viewModel.expenses(for: wallet)
    }

    var body: some View {
        Group {
            if sortedExpenses.isEmpty {
                emptyState
            } else {
                transactionList
            }
        }
        .navigationTitle("\(wallet.emoji) \(wallet.name)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !wallet.isDefault {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .alert("Delete Wallet", isPresented: $showDeleteAlert) {
            Button("Delete All Transactions", role: .destructive) {
                viewModel.deleteWallet(wallet, keepTransactions: false)
                dismiss()
            }
            Button("Keep Transactions (Unlink)") {
                viewModel.deleteWallet(wallet, keepTransactions: true)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("What should happen to the \(sortedExpenses.count) transaction(s) in this wallet?")
        }
        .sheet(item: $expenseToEdit) { expense in
            AddExpenseSheet(
                viewModel: DashboardViewModel(modelContext: modelContext, payday: payday),
                existingExpense: expense
            )
            .presentationDetents([.large])
            .onDisappear {
                viewModel.loadWallets()
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Text(wallet.emoji)
                .font(.system(size: 48))

            Text("No transactions yet")
                .font(.system(.body, design: .rounded, weight: .medium))
                .foregroundStyle(.secondary)

            Text("Transactions assigned to this wallet will appear here")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Transaction List

    private var transactionList: some View {
        List {
            // Balance summary section
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Balance")
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundStyle(.secondary)

                        Text(wallet.calculatedBalance.formattedRupiah)
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .foregroundStyle(.primary)
                    }

                    Spacer()

                    Text(wallet.emoji)
                        .font(.system(size: 36))
                }
                .listRowBackground(Color(hex: wallet.colorHex).opacity(0.1))
            }

            // Transactions
            Section {
                ForEach(sortedExpenses, id: \.id) { expense in
                    Button {
                        expenseToEdit = expense
                    } label: {
                        WalletTransactionRow(expense: expense)
                    }
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                }
                .onDelete(perform: deleteExpenses)
            } header: {
                Text("Transactions")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(nil)
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Delete

    private func deleteExpenses(at offsets: IndexSet) {
        for index in offsets {
            let expense = sortedExpenses[index]
            modelContext.delete(expense)
        }
        try? modelContext.save()
        viewModel.loadWallets()
    }
}

// MARK: - Wallet Transaction Row

struct WalletTransactionRow: View {
    let expense: Expense

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            if expense.transactionType == .transfer {
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
                HStack(spacing: 6) {
                    if expense.transactionType == .transfer {
                        Text(expense.wallet?.name ?? "–")
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                            .foregroundStyle(.primary)

                        Image(systemName: "arrow.right")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.secondary)

                        Text(expense.destinationWallet?.name ?? "–")
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                            .foregroundStyle(.primary)

                        Text("TRANSFER")
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color(hex: "64748B")))
                    } else {
                        Text(expense.category?.name ?? "Uncategorized")
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                            .foregroundStyle(.primary)

                        if expense.transactionType == .income {
                            Text("INCOME")
                                .font(.system(size: 8, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color(hex: "22C55E")))
                        }
                    }
                }

                if let note = expense.note, !note.isEmpty {
                    Text(note)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Text(formattedDate(expense.date))
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.tertiary)
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
